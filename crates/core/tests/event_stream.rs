//! Slice 0.3 — event_stream: ledger inmutable + taxonomía + eventos de producto.
//! Gate: "append-only rechazado · seed project→session→message→rung ·
//! cada evento de producto emitido al crear datos".

use canvas_ai_core::repo::{self, product_events, Rung};
use serde_json::json;

#[tokio::test]
async fn ledger_append_only_rechaza_mutation() {
    let db = repo::connect("sqlite::memory:").await.unwrap();
    repo::project_create(&db, "p1", "uno").await.unwrap();
    repo::session_create(&db, "s1", "p1", "sesión").await.unwrap();
    let id = repo::event_append(&db, "s1", "PROMPT", "primer rung", None, None, 0, 0.0, None, None).await.unwrap();
    assert!(id > 0);

    // UPDATE → rechazado por trigger
    let err = sqlx::query("UPDATE event_stream SET summary = 'tampered' WHERE id = ?1")
        .bind(id).execute(&db).await;
    assert!(err.is_err(), "UPDATE debe ser rechazado");
    assert!(err.unwrap_err().to_string().contains("append-only"));

    // DELETE → rechazado por trigger
    let err = sqlx::query("DELETE FROM event_stream WHERE id = ?1")
        .bind(id).execute(&db).await;
    assert!(err.is_err(), "DELETE debe ser rechazado");
    assert!(err.unwrap_err().to_string().contains("append-only"));

    // el rung sigue intacto (inmutable): session.created + PROMPT
    let evs = repo::event_list_by_session(&db, "s1").await.unwrap();
    assert_eq!(evs.len(), 2, "session.created (auto) + PROMPT");
    assert_eq!(evs[1].summary, "primer rung");
}

#[tokio::test]
async fn seed_project_session_message_rung_y_product_events() {
    let db = repo::connect("sqlite::memory:").await.unwrap();

    // project → session → message → rungs
    repo::project_create(&db, "p1", "proyecto").await.unwrap();
    repo::session_create(&db, "s1", "p1", "chat con agente").await.unwrap();
    repo::message_create(&db, "m1", "s1", "user", "haz X", None, Some(10), None, None, &json!({})).await.unwrap();
    repo::message_create(&db, "m2", "s1", "assistant", "hecho", Some("free-model"), Some(3), Some(20), Some(0.0005), &json!({})).await.unwrap();

    // rungs tipados con emit_event
    repo::emit_event(&db, "s1", Rung::Phase, "fase: plan", Some(&json!({"phase": "plan"})), None, 0, 0.0, Some("agent"), Some("a1")).await.unwrap();
    repo::emit_event(&db, "s1", Rung::Diff, "patch inicial", Some(&json!({"lines_added": 42})), None, 0, 0.0, Some("agent"), Some("a1")).await.unwrap();
    repo::emit_event(&db, "s1", Rung::TestResult, "suite verde", Some(&json!({"pass": true})), None, 0, 0.0, Some("agent"), Some("a1")).await.unwrap();
    repo::emit_event(&db, "s1", Rung::Decision, "aprobar approach", Some(&json!({"decision": "x"})), None, 0, 0.0, Some("user"), Some("u1")).await.unwrap();
    repo::emit_event(&db, "s1", Rung::Delivery, "entrega aceptada", Some(&json!({"artifact": "x.ts"})), None, 0, 0.0, Some("user"), Some("u1")).await.unwrap();

    // eventos de producto auto-emitidos al crear datos:
    let evs = repo::event_list_by_session(&db, "s1").await.unwrap();
    let tipos: Vec<&str> = evs.iter().map(|e| e.event_type.as_str()).collect();
    assert!(tipos.contains(&product_events::SESSION_CREATED), "session.created auto-emitido, hubo: {tipos:?}");
    assert!(tipos.contains(&product_events::MESSAGE_STREAMED), "message.streamed auto-emitido");
    assert!(tipos.contains(&"PROMPT") == false, "sin PROMPT en este flujo (solo rungs explícitos)");

    // conteo esperado: session.created(1) + 2×message.streamed + 5 rungs = 8
    assert_eq!(evs.len(), 8, "eventos: {tipos:?}");

    // skill.created anclado a sesión
    let skill = repo::skill_create(&db, "sk1", "p1", "revisor", &json!({"role":"reviewer"}), "r").await.unwrap();
    let _ = skill;
    // skill_domain_create emite solo con ancla:
    // (probamos vía dominio)
    drop(db);

    let db = repo::connect("sqlite::memory:").await.unwrap();
    repo::project_create(&db, "p1", "p").await.unwrap();
    repo::session_create(&db, "s1", "p1", "s").await.unwrap();
    let sk = canvas_ai_core::domain::Skill::new("sk1".into(), "revisor".into(),
        canvas_ai_core::domain::SkillCategory::Custom, "u1".into());
    repo::skill_domain_create(&db, "p1", &sk, Some("s1")).await.unwrap();
    let evs = repo::event_list_by_session(&db, "s1").await.unwrap();
    assert!(evs.iter().any(|e| e.event_type == product_events::SKILL_CREATED),
        "skill.created emitido con ancla de sesión");

    // sin ancla → NO emite (y no rompe): la creación sigue OK
    let sk2 = canvas_ai_core::domain::Skill::new("sk2".into(), "otro".into(),
        canvas_ai_core::domain::SkillCategory::Custom, "u1".into());
    repo::skill_domain_create(&db, "p1", &sk2, None).await.unwrap();
    assert!(repo::skill_domain_get(&db, "sk2").await.unwrap().is_some());
}

#[tokio::test]
async fn taxonomia_rungs_strings_canonicos() {
    assert_eq!(Rung::Prompt.as_str(), "PROMPT");
    assert_eq!(Rung::Phase.as_str(), "PHASE");
    assert_eq!(Rung::Diff.as_str(), "DIFF");
    assert_eq!(Rung::TestResult.as_str(), "TEST_RESULT");
    assert_eq!(Rung::Decision.as_str(), "DECISION");
    assert_eq!(Rung::Escalation.as_str(), "ESCALATION");
    assert_eq!(Rung::Delivery.as_str(), "DELIVERY");
}
