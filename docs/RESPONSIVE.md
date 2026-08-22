# RESPONSIVE.md — Guia de Responsive Design

> Guia practica para desarrollar interfaces responsive en Empresa Dev. Siempre consultar antes de crear componentes UI.

## Hook principal: `useResponsive`

```typescript
// src/hooks/useResponsive.ts
import { useState, useEffect } from 'react';

type Breakpoint = 'mobile' | 'tablet' | 'desktop';

interface ResponsiveState {
  breakpoint: Breakpoint;
  isMobile: boolean;
  isTablet: boolean;
  isDesktop: boolean;
  width: number;
  height: number;
}

export function useResponsive(): ResponsiveState {
  const [state, setState] = useState<ResponsiveState>(() => {
    const w = window.innerWidth;
    return {
      breakpoint: getBreakpoint(w),
      isMobile: w < 768,
      isTablet: w >= 768 && w < 1024,
      isDesktop: w >= 1024,
      width: w,
      height: window.innerHeight,
    };
  });

  useEffect(() => {
    const handleResize = () => {
      const w = window.innerWidth;
      setState({
        breakpoint: getBreakpoint(w),
        isMobile: w < 768,
        isTablet: w >= 768 && w < 1024,
        isDesktop: w >= 1024,
        width: w,
        height: window.innerHeight,
      });
    };

    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, []);

  return state;
}

function getBreakpoint(width: number): Breakpoint {
  if (width < 768) return 'mobile';
  if (width < 1024) return 'tablet';
  return 'desktop';
}
```

## Componentes base

### AppShell

```typescript
// src/components/layout/AppShell.tsx
import { useResponsive } from '@/hooks/useResponsive';
import { MobileLayout } from './MobileLayout';
import { DesktopLayout } from './DesktopLayout';

export function AppShell({ children }: { children: React.ReactNode }) {
  const { isMobile } = useResponsive();

  return isMobile ? (
    <MobileLayout>{children}</MobileLayout>
  ) : (
    <DesktopLayout>{children}</DesktopLayout>
  );
}
```

### MobileLayout

```typescript
// src/components/layout/MobileLayout.tsx
import { useState } from 'react';
import { BottomNav } from './BottomNav';
import { MobileHeader } from './MobileHeader';

export function MobileLayout({ children }: { children: React.ReactNode }) {
  const [activeTab, setActiveTab] = useState('canva');

  return (
    <div className="flex flex-col h-screen bg-background">
      <MobileHeader />
      <main className="flex-1 overflow-auto">
        {children}
      </main>
      <BottomNav active={activeTab} onChange={setActiveTab} />
    </div>
  );
}
```

### DesktopLayout

```typescript
// src/components/layout/DesktopLayout.tsx
import { useState } from 'react';
import { Sidebar } from './Sidebar';
import { RightPanel } from './RightPanel';

export function DesktopLayout({ children }: { children: React.ReactNode }) {
  const [sidebarOpen, setSidebarOpen] = useState(true);
  const [panelOpen, setPanelOpen] = useState(true);

  return (
    <div className="flex h-screen bg-background">
      <Sidebar open={sidebarOpen} onToggle={() => setSidebarOpen(!sidebarOpen)} />
      <main className="flex-1 overflow-auto">
        {children}
      </main>
      <RightPanel open={panelOpen} onToggle={() => setPanelOpen(!panelOpen)} />
    </div>
  );
}
```

### BottomNav

```typescript
// src/components/layout/BottomNav.tsx
import { 
  CanvasIcon, 
  AgentIcon, 
  SkillIcon, 
  ChatIcon 
} from '@/components/icons';

const tabs = [
  { id: 'canva', label: 'Canva', icon: CanvasIcon },
  { id: 'agents', label: 'Agentes', icon: AgentIcon },
  { id: 'skills', label: 'Skills', icon: SkillIcon },
  { id: 'chat', label: 'Chat', icon: ChatIcon },
] as const;

interface BottomNavProps {
  active: string;
  onChange: (tab: string) => void;
}

export function BottomNav({ active, onChange }: BottomNavProps) {
  return (
    <nav 
      data-testid="bottom-nav"
      className="flex items-center justify-around h-14 bg-surface border-t border-border"
    >
      {tabs.map((tab) => (
        <button
          key={tab.id}
          onClick={() => onChange(tab.id)}
          className={`flex flex-col items-center justify-center flex-1 h-full
            ${active === tab.id ? 'text-primary' : 'text-muted-foreground'}`}
        >
          <tab.icon className="w-6 h-6" />
          <span className="text-xs mt-1">{tab.label}</span>
        </button>
      ))}
    </nav>
  );
}
```

## Canvas adaptativo

```typescript
// src/components/canvas/AdaptiveCanvas.tsx
import { ReactFlow } from '@xyflow/react';
import { useResponsive } from '@/hooks/useResponsive';

export function AdaptiveCanvas() {
  const { isMobile } = useResponsive();

  const config = isMobile ? {
    nodesConnectable: false,
    minimap: { hidden: true },
    controls: { position: 'bottom-right' as const },
    defaultViewport: { zoom: 1, x: 0, y: 0 },
    fitView: true,
  } : {
    nodesConnectable: true,
    minimap: { visible: true },
    controls: { position: 'bottom-left' as const },
    defaultViewport: { zoom: 0.8, x: 0, y: 0 },
    fitView: false,
  };

  return (
    <div className="w-full h-full">
      <ReactFlow
        {...config}
        className="bg-background"
      >
        {/* nodes y edges */}
      </ReactFlow>
    </div>
  );
}
```

## BottomSheet (para detalles en mobile)

```typescript
// src/components/ui/BottomSheet.tsx
import { useState, useRef, useEffect } from 'react';

interface BottomSheetProps {
  children: React.ReactNode;
  onClose: () => void;
}

export function BottomSheet({ children, onClose }: BottomSheetProps) {
  const [offset, setOffset] = useState(0);
  const sheetRef = useRef<HTMLDivElement>(null);

  // Cerrar con swipe down
  useEffect(() => {
    const el = sheetRef.current;
    if (!el) return;

    let startY = 0;

    const handleTouchStart = (e: TouchEvent) => {
      startY = e.touches[0].clientY;
    };

    const handleTouchMove = (e: TouchEvent) => {
      const diff = e.touches[0].clientY - startY;
      if (diff > 0) setOffset(diff);
    };

    const handleTouchEnd = () => {
      if (offset > 100) onClose();
      else setOffset(0);
    };

    el.addEventListener('touchstart', handleTouchStart);
    el.addEventListener('touchmove', handleTouchMove);
    el.addEventListener('touchend', handleTouchEnd);

    return () => {
      el.removeEventListener('touchstart', handleTouchStart);
      el.removeEventListener('touchmove', handleTouchMove);
      el.removeEventListener('touchend', handleTouchEnd);
    };
  }, [offset, onClose]);

  return (
    <div 
      ref={sheetRef}
      className="fixed inset-x-0 bottom-0 bg-surface rounded-t-2xl shadow-lg
        transition-transform duration-300 ease-out"
      style={{ transform: `translateY(${offset}px)` }}
    >
      {/* Handle */}
      <div className="flex justify-center pt-3 pb-2">
        <div className="w-10 h-1 rounded-full bg-muted-foreground/30" />
      </div>
      
      {/* Content */}
      <div className="px-4 pb-8 max-h-[80vh] overflow-auto">
        {children}
      </div>
    </div>
  );
}
```

## Clases TailwindCSS para responsive

### Visibilidad
```html
<!-- Solo mobile -->
<div className="md:hidden">...</div>

<!-- Solo desktop -->
<div className="hidden md:block">...</div>

<!-- Mobile y tablet -->
<div className="lg:hidden">...</div>

<!-- Solo desktop grande -->
<div className="hidden xl:block">...</div>
```

### Layout
```html
<!-- Mobile: columna, desktop: fila -->
<div className="flex flex-col md:flex-row">...</div>

<!-- Mobile: sin padding, desktop: con padding -->
<div className="p-2 md:p-4 lg:p-6">...</div>

<!-- Mobile: full width, desktop: fijo -->
<div className="w-full md:w-64 lg:w-80">...</div>
```

### Tipografia
```html
<!-- Mobile: texto pequeno, desktop: texto normal -->
<h1 className="text-lg md:text-2xl lg:text-3xl">...</h1>

<!-- Mobile: sin truncar, desktop: truncar -->
<p className="truncate md:whitespace-normal">...</p>
```

### Espaciado
```html
<!-- Mobile: gap pequeno, desktop: gap grande -->
<div className="gap-2 md:gap-4 lg:gap-6">...</div>

<!-- Mobile: margin minimo, desktop: margin mayor -->
<div className="mb-2 md:mb-4 lg:mb-8">...</div>
```

## Touch targets

```css
/* En tu CSS global o tailwind.config */
@layer utilities {
  .touch-target {
    min-height: 44px;
    min-width: 44px;
  }
  
  .touch-target-sm {
    min-height: 32px;
    min-width: 32px;
  }
}
```

Uso:
```html
<button className="touch-target">...</button>
<a className="touch-target-sm">...</a>
```

## Testing responsive

```typescript
// e2e/responsive.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Responsive Design', () => {
  test.describe('Mobile', () => {
    test.use({ viewport: { width: 375, height: 812 } }); // iPhone

    test('bottom nav visible', async ({ page }) => {
      await page.goto('/');
      await expect(page.locator('[data-testid="bottom-nav"]')).toBeVisible();
    });

    test('sidebar hidden', async ({ page }) => {
      await page.goto('/');
      await expect(page.locator('[data-testid="sidebar"]')).not.toBeVisible();
    });

    test('canvas fullscreen', async ({ page }) => {
      await page.goto('/');
      const canvas = page.locator('[data-testid="canvas"]');
      const box = await canvas.boundingBox();
      expect(box?.width).toBeGreaterThan(300);
    });
  });

  test.describe('Desktop', () => {
    test.use({ viewport: { width: 1440, height: 900 } });

    test('sidebar visible', async ({ page }) => {
      await page.goto('/');
      await expect(page.locator('[data-testid="sidebar"]')).toBeVisible();
    });

    test('bottom nav hidden', async ({ page }) => {
      await page.goto('/');
      await expect(page.locator('[data-testid="bottom-nav"]')).not.toBeVisible();
    });

    test('right panel visible', async ({ page }) => {
      await page.goto('/');
      await expect(page.locator('[data-testid="right-panel"]')).toBeVisible();
    });
  });

  test.describe('Tablet', () => {
    test.use({ viewport: { width: 768, height: 1024 } }); // iPad

    test('sidebar collapses to icons', async ({ page }) => {
      await page.goto('/');
      const sidebar = page.locator('[data-testid="sidebar"]');
      const box = await sidebar.boundingBox();
      expect(box?.width).toBeLessThan(100); // solo iconos
    });
  });
});
```

## Checklist de responsive (antes de PR)

- [ ] Componente funciona en 375px (mobile)
- [ ] Componente funciona en 768px (tablet)
- [ ] Componente funciona en 1024px+ (desktop)
- [ ] Touch targets >= 44px en mobile
- [ ] Texto legible sin zoom
- [ ] Animaciones respetan `prefers-reduced-motion`
- [ ] No hay overflow horizontal
- [ ] Loading states en ambas vistas
- [ ] Tests Playwright pasan en mobile y desktop
