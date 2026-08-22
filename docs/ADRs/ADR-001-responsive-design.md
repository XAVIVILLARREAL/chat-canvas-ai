# ADR-001: Responsive Design y Cross-Platform

> Fecha: 2026-08-21 . Estado: Aprobado . Contexto: Desktop + Mobile desde inicio

## Contexto

Empresa Dev es una app visual (canva 2D/3D, agentes, skills) que debe funcionar en:
- **Desktop:** Windows, macOS, Linux (pantallas 1024px+)
- **Mobile:** Android, iOS (pantallas 320px-1024px)

El riesgo es crear una app solo-desktop y despues re-adaptar mobile, generando deuda tecnica enorme. Las decisiones de responsive se definen **antes de tocar codigo**.

## Decisiones

### 1. Layout: AppShell adaptativo

**Decidido:** Un componente `AppShell` que cambia la estructura segun breakpoint.

**Desktop (>=1024px):**
```
+--------------------------------------------------+
| Header (fijo)                                     |
+--------+---------------------------+-------------+
| Sidebar| Area principal            | Right Panel |
| (nav)  | (canva/editor)            | (detalles)  |
| 240px  | flex-1                    | 320px       |
+--------+---------------------------+-------------+
```

**Tablet (768px-1024px):**
```
+--------------------------------------------------+
| Header (fijo)                                     |
+--------+-----------------------------------------+
| Sidebar| Area principal (overlay panel)           |
| (iconos)| (canva/editor)                          |
| 64px   | flex-1                                   |
+--------+-----------------------------------------+
```

**Mobile (<768px):**
```
+------------------+
| Header (fijo)    |
+------------------+
|                  |
| Area principal   |
| (fullscreen)     |
|                  |
+------------------+
| Bottom Nav (56px)|
+------------------+
```

### 2. Breakpoints (TailwindCSS defaults)

| Breakpoint | Width | Target |
|---|---|---|
| `sm` | 640px | Mobile landscape / tablet pequena |
| `md` | 768px | Tablet portrait |
| `lg` | 1024px | Desktop / tablet landscape |
| `xl` | 1280px | Desktop grande |
| `2xl` | 1536px | Ultrawide |

**Regla:** Usar breakpoints de Tailwind sin customizar. Si se necesita uno custom, documentar en ADR.

### 3. Canvas (ReactFlow) adaptativo

**Desktop:**
- Zoom: rueda del mouse + pinch
- Pan: click derecho / middle click / space+drag
- Drag and drop: natural
- Minimap: visible (posicion: bottom-left)
- Controls: fijos (bottom-left)
- Conexiones: directas (drag desde handle)

**Mobile:**
- Zoom: pinch-to-zoom (ya soportado por ReactFlow)
- Pan: un dedo (ya soportado)
- Drag and drop: long-press + drag (nodos)
- Minimap: oculto (ocupa mucho espacio)
- Controls: flotantes (bottom-right, 48px)
- Conexiones: via bottom sheet (tap nodo -> "Conectar" -> seleccionar target)

**Configuracion adaptativa:**
```typescript
// config/canvas.ts
export const canvasConfig = {
  mobile: {
    minZoom: 0.3,
    maxZoom: 2,
    nodesConnectable: false,
    minimap: { hidden: true },
    controls: { position: 'bottom-right' as const },
    nodeTypes: ['simple'], // simplificar nodos en mobile
  },
  desktop: {
    minZoom: 0.1,
    maxZoom: 4,
    nodesConnectable: true,
    minimap: { visible: true },
    controls: { position: 'bottom-left' as const },
    nodeTypes: ['full', 'simple'],
  },
};
```

### 4. Navegacion

**Desktop:** Sidebar horizontal o vertical (segun preferencia)
**Mobile:** Bottom Navigation Bar (max 5 items)

**Items del Bottom Nav:**
```
[Canva] [Agentes] [Skills] [Chat]
```

**Reglas:**
- Maximo 5 items en bottom nav
- Icono + label (label oculto si no cabe)
- Active state: icono coloreado
- Tap: navega + resetea stack de navegacion
- Long press: shortcut (futuro)

### 5. Paneles y detalle

**Desktop:** Right Panel (sidebar derecho, 320px) para detalles
**Mobile:** Bottom Sheet (deslizante desde abajo)

**Componente: `DetailPanel`**
```typescript
// Si es desktop: drawer derecho
// Si es mobile: bottom sheet con 3 estados:
//   - Collapsed (handle visible)
//   - Half (50% viewport)
//   - Full (90% viewport)
```

### 6. Touch targets (hit areas)

| Elemento | Desktop | Mobile |
|---|---|---|
| Botones | 32px min | 44px min |
| Links | 24px min | 44px min |
| Iconos clickables | 24px min | 44px min |
| List items | 32px min | 48px min |
| Drag handles | 16px min | 24px min |

**Razon:** Apple HIG y Material Design recomiendan 44px para touch.

### 7. Gestos mobile

| Gesto | Accion |
|---|---|
| Tap | Seleccionar / Activar |
| Long press | Context menu / Drag mode |
| Swipe left/right | Cambiar panel / Tab |
| Swipe down | Cerrar bottom sheet |
| Pinch | Zoom canvas |
| Two-finger pan | Pan canvas |
| Pull to refresh | Refrescar datos (listas) |

### 8. Animaciones

**Desktop:** Animaciones completas (transiciones, spring, stagger)
**Mobile:** Animaciones reducidas (respetar `prefers-reduced-motion`)

```css
/* En CSS */
@media (prefers-reduced-motion: reduce) {
  * {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}
```

### 9. Performance mobile

- **Lazy loading:** Solo cargar paneles visibles
- **Virtual scrolling:** Listas con >20 items (react-window o similar)
- **Image optimization:** `loading="lazy"`, `srcset` si aplica
- **Debounce:** En scroll, resize, search inputs
- **Memoizacion:** React.memo en componentes pesados (ya tenemos React Compiler)

### 10. Testing responsive

**Playwright debe testear ambas vistas:**
```typescript
// e2e/responsive.spec.ts
test.describe('Responsive', () => {
  test('mobile: bottom nav visible', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 812 }); // iPhone
    await page.goto('/');
    await expect(page.locator('[data-testid="bottom-nav"]')).toBeVisible();
    await expect(page.locator('[data-testid="sidebar"]')).not.toBeVisible();
  });

  test('desktop: sidebar visible', async ({ page }) => {
    await page.setViewportSize({ width: 1440, height: 900 });
    await page.goto('/');
    await expect(page.locator('[data-testid="sidebar"]')).toBeVisible();
    await expect(page.locator('[data-testid="bottom-nav"]')).not.toBeVisible();
  });
});
```

## Consecuencias

### Positivas
- App funciona bien desde el inicio en ambas plataformas
- Sin deuda tecnica de responsive
- Testing automatizado de ambas vistas
- UX consistente en desktop y mobile

### Negativas
- Complejidad inicial mayor (AppShell adaptativo)
- Mas tiempo de desarrollo en fases tempranas
- Need de testear en ambas vistas (pero Playwright lo automatiza)

### Riesgos mitigados
- ReactFlow ya soporta touch (no necesitamos libreria extra)
- TailwindCSS maneja breakpoints nativamente
- Tauri 2.0 soporta mobile (Android/iOS)

## References

- [Apple HIG - Responsive](https://developer.apple.com/design/human-interface-guidelines/layout)
- [Material Design - Responsive](https://m3.material.io/foundations/accessible-design/responsive-layout)
- [ReactFlow - Touch](https://reactflow.dev/learn/concepts/interactivity)
- [TailwindCSS - Responsive](https://tailwindcss.com/docs/responsive-design)
