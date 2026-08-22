export interface CanvasNode {
  id: string;
  type: "agent" | "skill" | "task" | "company";
  position: { x: number; y: number };
  data: Record<string, unknown>;
  width?: number;
  height?: number;
}

export interface CanvasEdge {
  id: string;
  source: string;
  target: string;
  label?: string;
  animated?: boolean;
}

export interface CanvasState {
  nodes: CanvasNode[];
  edges: CanvasEdge[];
  zoom: number;
  position: { x: number; y: number };
}
