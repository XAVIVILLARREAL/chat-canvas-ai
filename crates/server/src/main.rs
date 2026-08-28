//! Binario del servidor Canvas AI — la lógica vive en `canvas_ai_server::api`.

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    canvas_ai_server::api::serve().await
}
