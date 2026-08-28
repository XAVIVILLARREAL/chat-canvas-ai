//! Slice 0.6 — exporta el contrato del gateway:
//!   1. docs/openapi.json            (paths + schemas, fuente: OPS en api.rs)
//!   2. src/types/api-generated.ts   (tipos TS generados desde ese mismo JSON)
//! Uso: cargo run -p canvas-ai-server --bin export-openapi

use canvas_ai_server::api::build_openapi;
use serde_json::Value;
use std::collections::BTreeMap;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    // 1) OpenAPI
    let spec = build_openapi();
    let openapi_path = concat!(env!("CARGO_MANIFEST_DIR"), "/../../docs/openapi.json");
    std::fs::write(openapi_path, serde_json::to_string_pretty(&spec)?)?;
    let paths = spec["paths"].as_object().map(|p| p.len()).unwrap_or(0);
    let schemas = spec["components"]["schemas"].as_object().map(|s| s.len()).unwrap_or(0);
    println!("OpenAPI exportado: {openapi_path} ({paths} paths, {schemas} schemas)");

    // 2) Tipos TypeScript generados DESDE el propio OpenAPI (fuente única).
    //    (specta-typescript 0.0.12 prohíbe BigInt sin opt-in y nuestros payloads
    //     llevan serde_json::Value; el mapper propio cubre nuestro subset exacto.)
    let ts = generate_ts(&spec);
    let ts_path = concat!(env!("CARGO_MANIFEST_DIR"), "/../../src/types/api-generated.ts");
    std::fs::write(ts_path, &ts)?;
    println!("Tipos TS exportados: {ts_path} ({} líneas)", ts.lines().count());
    Ok(())
}

/// JSON Schema (subset schemars) → TypeScript.
fn generate_ts(spec: &Value) -> String {
    // namespace global: todas las definitions de todos los componentes
    let mut defs: BTreeMap<String, Value> = Default::default();
    for sch in spec["components"]["schemas"].as_object().expect("schemas").values() {
        if let Some(d) = sch.get("definitions").and_then(|d| d.as_object()) {
            for (k, v) in d {
                defs.entry(k.clone()).or_insert_with(|| v.clone());
            }
        }
    }

    let mut out = String::from(
        "// AUTO-GENERADO: cargo run -p canvas-ai-server --bin export-openapi — NO editar a mano.\n",
    );
    out.push_str("// Fuente única: structs Rust del server/core (docs/openapi.json).\n\n");

    let mut emitted: std::collections::BTreeSet<String> = Default::default();
    for (name, def) in &defs {
        if def.get("type").and_then(|t| t.as_str()) == Some("object")
            && def.get("properties").is_none()
            && def.get("additionalProperties").is_none()
        {
            continue; // objetos vacíos sin información
        }
        emitted.insert(sanitize(name));
        out.push_str(&format!("export type {} = {};\n\n", sanitize(name), schema_to_ts(def, &defs)));
    }
    // componentes: omitir si el nombre ya salió como definition (mismo tipo)
    for (name, sch) in spec["components"]["schemas"].as_object().expect("schemas") {
        if !emitted.insert(sanitize(name)) {
            continue;
        }
        out.push_str(&format!("export type {} = {};\n\n", sanitize(name), schema_to_ts(sch, &defs)));
    }
    out
}

fn sanitize(name: &str) -> String {
    name.replace('-', "_")
}

fn schema_to_ts(schema: &Value, defs: &BTreeMap<String, Value>) -> String {
    if let Some(r) = schema.get("$ref").and_then(|r| r.as_str()) {
        let name = r.rsplit('/').next().unwrap_or("unknown");
        return sanitize(name);
    }
    if let Some(any_of) = schema.get("anyOf").and_then(|a| a.as_array()) {
        let parts: Vec<String> = any_of.iter().map(|s| schema_to_ts(s, defs)).collect();
        return parts.join(" | ");
    }
    if let Some(all_of) = schema.get("allOf").and_then(|a| a.as_array()) {
        let parts: Vec<String> = all_of.iter().map(|s| schema_to_ts(s, defs)).collect();
        return parts.join(" & ");
    }
    let ty = schema.get("type").and_then(|t| t.as_str()).unwrap_or("");
    match ty {
        "string" => {
            if let Some(en) = schema.get("enum").and_then(|e| e.as_array()) {
                let variants: Vec<String> = en
                    .iter()
                    .filter_map(|v| v.as_str().map(|s| format!("\"{s}\"")))
                    .collect();
                if !variants.is_empty() {
                    return variants.join(" | ");
                }
            }
            "string".into()
        }
        "integer" | "number" => "number".into(),
        "boolean" => "boolean".into(),
        "array" => {
            let items = schema
                .get("items")
                .map(|i| schema_to_ts(i, defs))
                .unwrap_or_else(|| "unknown".into());
            if items.contains(' ') {
                format!("({items})[]")
            } else {
                format!("{items}[]")
            }
        }
        "object" | "" => {
            if let Some(props) = schema.get("properties").and_then(|p| p.as_object()) {
                let required: Vec<&str> = schema
                    .get("required")
                    .and_then(|r| r.as_array())
                    .map(|a| a.iter().filter_map(|v| v.as_str()).collect())
                    .unwrap_or_default();
                let mut fields: Vec<String> = Vec::new();
                for (k, v) in props {
                    let opt = if required.contains(&k.as_str()) { "" } else { "?" };
                    fields.push(format!("  {k}{opt}: {};", schema_to_ts(v, defs)));
                }
                format!("{{\n{}\n}}", fields.join("\n"))
            } else if let Some(ap) = schema.get("additionalProperties") {
                if ap.is_boolean() {
                    "Record<string, never>".into()
                } else {
                    format!("Record<string, {}>", schema_to_ts(ap, defs))
                }
            } else {
                "Record<string, unknown>".into()
            }
        }
        "null" => "null".into(),
        _ => "unknown".into(),
    }
}
