export type AgentRole = "dev" | "qa" | "reviewer" | "pm" | "devops";

export type AgentStatus =
  | "idle"
  | "working"
  | "blocked"
  | "waiting_approval"
  | "offline";

export interface Agent {
  id: string;
  name: string;
  role: AgentRole;
  status: AgentStatus;
  skills: string[];
  avatar?: string;
  createdAt: string;
  updatedAt: string;
}
