//! Dominio puro de Empresa Dev.
//!
//! Regla dura (ADR-005 D1): este crate NO depende de Tauri, HTTP ni I/O.
//! Aquí viven los tipos de dominio y las reglas de negocio puras que
//! comparten el shell Tauri (local) y el binario servidor (nube).

pub mod domain;
