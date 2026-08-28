//! Sandbox Linux por agente (slice 0.5 — THREAT-MODEL §2, H.9a adelantado).
//!
//! Contrato del contenedor (frontera del sandbox):
//!   CPU 1 · RAM 512MB · pids 128 · red OFF · rootfs read-only · non-root
//!   · no-new-privileges · ALL caps dropped · tmpfs /tmp (64MB) · timeout duro
//!
//! Disco 1GB: --storage-opt size solo aplica con drivers concretos (overlay2
//! con pquota xfs) — se declara en `SandboxLimits` y se aplica best-effort;
//! el worker lo reporta en `inspect_limits` para que el gate sea provable.

use bollard::container::{
    Config, CreateContainerOptions, KillContainerOptions, LogsOptions, RemoveContainerOptions,
    WaitContainerOptions,
};
use bollard::secret::HostConfig;
use bollard::Docker;
use futures::StreamExt;
use std::collections::HashMap;
use std::time::Duration;

/// Límites canónicos del sandbox (THREAT-MODEL).
#[derive(Debug, Clone, Copy)]
pub struct SandboxLimits {
    pub cpus: i64,          // nano CPUs (1 core = 1_000_000_000)
    pub memory_bytes: i64,  // 512MB
    pub pids: i64,          // 128
    pub disk_bytes: i64,    // 1GB (best-effort según storage driver)
    pub timeout: Duration,  // 60s por defecto
}

impl Default for SandboxLimits {
    fn default() -> Self {
        Self {
            cpus: 1_000_000_000,
            memory_bytes: 512 * 1024 * 1024,
            pids: 128,
            disk_bytes: 1024 * 1024 * 1024,
            timeout: Duration::from_secs(60),
        }
    }
}

/// Resultado de una ejecución sandboxesada.
#[derive(Debug, Clone)]
pub struct SandboxResult {
    pub exit_code: i64,
    pub timed_out: bool,
    pub logs: String,
    pub container: String,
}

#[derive(Debug, thiserror::Error)]
pub enum SandboxError {
    #[error("docker: {0}")]
    Docker(#[from] bollard::errors::Error),
    #[error("timeout del sandbox tras {0:?}")]
    Timeout(Duration),
}

const NAME_PREFIX: &str = "canvas-sbx";

fn build_config(limits: &SandboxLimits, image: &str, cmd: &[String], disk: bool) -> Config<String> {
    let mut tmpfs = HashMap::new();
    tmpfs.insert("/tmp".to_string(), "rw,noexec,nosuid,size=64m".to_string());
    let mut storage_opt = HashMap::new();
    storage_opt.insert("size".to_string(), format!("{}b", limits.disk_bytes));

    Config {
        image: Some(image.to_string()),
        cmd: Some(cmd.to_vec()),
        user: Some("1000:1000".to_string()), // non-root
        host_config: Some(HostConfig {
            nano_cpus: Some(limits.cpus),
            memory: Some(limits.memory_bytes),
            pids_limit: Some(limits.pids),
            network_mode: Some("none".to_string()), // red OFF
            readonly_rootfs: Some(true),            // rootfs read-only
            security_opt: Some(vec!["no-new-privileges:true".to_string()]),
            cap_drop: Some(vec!["ALL".to_string()]),
            tmpfs: Some(tmpfs),
            storage_opt: if disk { Some(storage_opt) } else { None },
            ..Default::default()
        }),
        ..Default::default()
    }
}

/// Arranca un sandbox y devuelve su nombre (para chaos/kill externo).
pub async fn start_sandboxed(
    docker: &Docker,
    limits: &SandboxLimits,
    image: &str,
    cmd: &[String],
) -> Result<String, SandboxError> {
    let name = format!("{NAME_PREFIX}-{}", uuid::Uuid::new_v4());
    let disk = *std::env::var("SANDBOX_DISK_OPT")
        .ok()
        .and_then(|v| v.parse::<bool>().ok())
        .get_or_insert(false);
    docker
        .create_container(
            Some(CreateContainerOptions { name: name.as_str(), platform: None }),
            build_config(limits, image, cmd, disk),
        )
        .await?;
    docker.start_container(&name, None::<bollard::container::StartContainerOptions<String>>).await?;
    Ok(name)
}

/// Mata un sandbox en ejecución (chaos / cancelación del agente).
pub async fn kill_sandboxed(docker: &Docker, name: &str) -> Result<(), SandboxError> {
    docker
        .kill_container(name, Some(KillContainerOptions { signal: "SIGKILL" }))
        .await?;
    Ok(())
}

/// Ejecuta un comando en el sandbox con timeout duro: spawn → wait(select) →
/// kill si excede → logs → remove SIEMPRE (no deja contenedores huérfanos).
pub async fn run_sandboxed(
    docker: &Docker,
    limits: &SandboxLimits,
    image: &str,
    cmd: &[String],
) -> Result<SandboxResult, SandboxError> {
    let name = start_sandboxed(docker, limits, image, cmd).await?;
    let mut wait = docker.wait_container(&name, None::<WaitContainerOptions<String>>);

    let mut timed_out = false;
    // NOTA bollard: salidas con código ≠ 0 llegan como
    // Err(DockerContainerWaitError{code}) — ES la forma del exit code, no un error.
    let exit_code = tokio::select! {
        res = wait.next() => {
            match res {
                Some(Ok(w)) => w.status_code,
                Some(Err(bollard::errors::Error::DockerContainerWaitError { code, .. })) => code,
                Some(Err(e)) => { cleanup(docker, &name).await; return Err(e.into()); }
                None => { cleanup(docker, &name).await; return Err(SandboxError::Docker(bollard::errors::Error::IOError { err: std::io::Error::other("stream wait terminó") })); }
            }
        }
        _ = tokio::time::sleep(limits.timeout) => {
            timed_out = true;
            let _ = kill_sandboxed(docker, &name).await;
            match wait.next().await {
                Some(Ok(w)) => w.status_code, // 137 = SIGKILL
                Some(Err(bollard::errors::Error::DockerContainerWaitError { code, .. })) => code,
                _ => -1,
            }
        }
    };

    // logs (stdout+stderr) tras la salida
    let mut logs_stream = docker.logs(
        &name,
        Some(LogsOptions::<String> {
            stdout: true,
            stderr: true,
            follow: false,
            timestamps: false,
            ..Default::default()
        }),
    );
    let mut logs = String::new();
    while let Some(chunk) = logs_stream.next().await {
        if let Ok(bytes) = chunk {
            logs.push_str(&bytes.to_string());
        }
    }

    cleanup(docker, &name).await;
    Ok(SandboxResult { exit_code, timed_out, logs, container: name })
}

/// Remove forzado — el sandbox no deja huérfanos aunque alguien olvide llamar.
pub async fn cleanup(docker: &Docker, name: &str) {
    let _ = docker
        .remove_container(
            name,
            Some(RemoveContainerOptions { force: true, v: true, ..Default::default() }),
        )
        .await;
}

/// Contrato provable: lee los límites reales del contenedor (gate H.9a).
pub async fn inspect_limits(docker: &Docker, name: &str) -> Result<SandboxLimits, SandboxError> {
    let inspect = docker.inspect_container(name, None).await?;
    let hc = inspect.host_config.unwrap_or_default();
    Ok(SandboxLimits {
        cpus: hc.nano_cpus.unwrap_or(0),
        memory_bytes: hc.memory.unwrap_or(0),
        pids: hc.pids_limit.unwrap_or(0),
        disk_bytes: hc
            .storage_opt
            .and_then(|s| s.get("size").and_then(|v| v.trim_end_matches('b').parse().ok()))
            .unwrap_or(0),
        timeout: Duration::from_secs(0), // el timeout no vive en el contenedor
    })
}

/// Flags del contrato que `inspect_limits` no captura (red/rootfs/seccomp/caps).
pub async fn inspect_contract(
    docker: &Docker,
    name: &str,
) -> Result<HashMap<String, String>, SandboxError> {
    let inspect = docker.inspect_container(name, None).await?;
    let hc = inspect.host_config.unwrap_or_default();
    let mut m = HashMap::new();
    m.insert("network_mode".into(), hc.network_mode.clone().unwrap_or_default());
    m.insert("readonly_rootfs".into(), hc.readonly_rootfs.unwrap_or(false).to_string());
    m.insert("no_new_privileges".into(), hc.security_opt.clone().unwrap_or_default().join(","));
    m.insert("cap_drop".into(), hc.cap_drop.clone().unwrap_or_default().join(","));
    m.insert("user".into(), inspect.config.and_then(|c| c.user).unwrap_or_default());
    Ok(m)
}
