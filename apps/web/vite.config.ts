import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'

const reactCompiler = {
  babel: {
    plugins: [['babel-plugin-react-compiler']],
  },
}

export default defineConfig({
  plugins: [react(reactCompiler), tailwindcss()],
  server: {
    port: 5173,
    proxy: {
      '/api': 'http://localhost:7688',
    },
  },
})
