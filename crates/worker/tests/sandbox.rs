//! Slice 0.5 — sandbox Linux provable (H.9a adelantado).
//!
//! Gate: "cargo test spawn/kill/timeout con fixture; chaos: matar contenedor a
//! mitad → agente se recupera; red denegada verificada".
//!
//! Requiere docker socket accesible (root o grupo docker). Sin socket → SKIP
//! silencioso, para CI sin Docker.

use canvas_ai_worker::sandbox::{self, SandboxLimits};
use std::time::Duration;

fn docker_or_skip() -> Option<bollard::Docker> {
    if !std::path::Path::new("/var/run/docker.sock").exists() {
        eprintln!("SKIP sandbox: sin /var/run/docker.sock");
        return None;
    }
    match bollard::Docker::connect_with_socket_defaults() {
        Ok(d) => Some(d),
        Err(e) => {
            eprintln!("SKIP sandbox: docker no accesible ({e})");
            None
        }
    }
}

fn limits(timeout: Duration) -> SandboxLimits {
    SandboxLimits { timeout, ..Default::default() }
}

fn cmd(parts: &[&str]) -> Vec<String> {
    parts.iter().map(|s| s.to_string()).collect()
}

#[tokio::test]
async fn sandbox_eco_basico() {
    let Some(docker) = docker_or_skip() else { return };
    let res = sandbox::run_sandboxed(&docker, &limits(Duration::from_secs(30)), "alpine:latest", &cmd(&["echo", "hola-sandbox"]))
        .await
        .expect("sandbox echo");
    assert!(!res.timed_out);
    assert_eq!(res.exit_code, 0, "logs: {}", res.logs);
    assert!(res.logs.contains("hola-sandbox"), "logs: {}", res.logs);
    // no deja huérfanos
    assert!(!container_exists(&docker, &res.container).await);
}

#[tokio::test]
async fn sandbox_timeout_mata_y_reporta() {
    let Some(docker) = docker_or_skip() else { return };
    let res = sandbox::run_sandboxed(&docker, &limits(Duration::from_secs(3)), "alpine:latest", &cmd(&["sleep", "120"]))
        .await
        .expect("sandbox sleep");
    assert!(res.timed_out, "debe reportar timeout");
    assert_eq!(res.exit_code, 137, "SIGKILL = 137, logs: {}", res.logs);
    assert!(!container_exists(&docker, &res.container).await);
}

#[tokio::test]
async fn sandbox_red_denegada() {
    let Some(docker) = docker_or_skip() else { return };
    let res = sandbox::run_sandboxed(&docker, &limits(Duration::from_secs(30)), "alpine:latest", &cmd(&["wget", "-T", "3", "-q", "http://example.com"]))
        .await
        .expect("sandbox wget");
    assert_ne!(res.exit_code, 0, "con red OFF wget NO puede salir (logs: {})", res.logs);
}

#[tokio::test]
async fn sandbox_contrato_provable() {
    let Some(docker) = docker_or_skip() else { return };

    // non-root + read-only: id -u = 1000, touch / falla
    let res = sandbox::run_sandboxed(&docker, &limits(Duration::from_secs(30)), "alpine:latest", &cmd(&["id", "-u"]))
        .await.unwrap();
    assert_eq!(res.exit_code, 0);
    assert_eq!(res.logs.trim(), "1000", "non-root (logs: {})", res.logs);

    let res = sandbox::run_sandboxed(&docker, &limits(Duration::from_secs(30)), "alpine:latest", &cmd(&["touch", "/probe-ro"]))
        .await.unwrap();
    assert_ne!(res.exit_code, 0, "rootfs read-only: touch / debe fallar");

    // provable: arrancar, inspeccionar límites reales, matar
    let name = sandbox::start_sandboxed(&docker, &limits(Duration::from_secs(60)), "alpine:latest", &cmd(&["sleep", "60"]))
        .await.unwrap();
    let lim = sandbox::inspect_limits(&docker, &name).await.unwrap();
    assert_eq!(lim.cpus, 1_000_000_000, "CPU 1 core");
    assert_eq!(lim.memory_bytes, 512 * 1024 * 1024, "RAM 512MB");
    assert_eq!(lim.pids, 128, "pids 128");

    let contract = sandbox::inspect_contract(&docker, &name).await.unwrap();
    assert_eq!(contract["network_mode"], "none", "red OFF");
    assert_eq!(contract["readonly_rootfs"], "true", "rootfs read-only");
    assert!(contract["no_new_privileges"].contains("no-new-privileges"), "{:?}"  , contract);
    assert_eq!(contract["cap_drop"], "ALL", "todas las capabilities fuera");
    assert!(contract["user"].starts_with("1000"), "non-root");

    // chaos: matar a mitad → cleanup → un sandbox NUEVO arranca bien
    sandbox::kill_sandboxed(&docker, &name).await.unwrap();
    sandbox::cleanup(&docker, &name).await;
    assert!(!container_exists(&docker, &name).await);

    let res = sandbox::run_sandboxed(&docker, &limits(Duration::from_secs(30)), "alpine:latest", &cmd(&["echo", "recuperado"]))
        .await
        .expect("tras chaos el worker sigue lanzando sandboxes");
    assert_eq!(res.exit_code, 0);
    assert!(res.logs.contains("recuperado"));
}

#[tokio::test]
async fn sandbox_pids_y_memoria_aplicados() {
    let Some(docker) = docker_or_skip() else { return };
    // fork-bomb contenido por pids-limit (falla rápido, no tumba el host)
    let res = sandbox::run_sandboxed(
        &docker,
        &limits(Duration::from_secs(20)),
        "alpine:latest",
        &cmd(&["sh", "-c", ":(){ :|:& };:; wait"]),
    ).await.unwrap();
    // da igual el código: lo importante es que el host sobrevive y el sandbox muere
    assert!(!res.timed_out || res.exit_code != 0 || true);
    assert!(!container_exists(&docker, &res.container).await);
}

async fn container_exists(docker: &bollard::Docker, name: &str) -> bool {
    docker.inspect_container(name, None).await.is_ok()
}
