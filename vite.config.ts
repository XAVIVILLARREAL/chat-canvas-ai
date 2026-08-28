import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import path from "node:path";

export default defineConfig({
  plugins: [
    react({
      compiler: true,
    }),
  ],
  resolve: {
    alias: {
      "@": path.resolve(import.meta.dirname, "./src"),
    },
  },
  server: {
    port: 1420,
    strictPort: true,
    proxy: {
      // Dev: enruta /api al gateway Rust (crates/server, puerto 3030).
      // En producción, Tauri/nginx sirven /api en el mismo origen.
      "/api": {
        target: process.env.CANVAS_GATEWAY ?? "http://127.0.0.1:3030",
        changeOrigin: true,
      },
    },
  },
  envPrefix: ["VITE_", "TAURI_"],
  build: {
    target: "esnext",
    minify: !!process.env.TAURI_DEBUG ? false : true,
    sourcemap: !!process.env.TAURI_DEBUG,
  },
});
