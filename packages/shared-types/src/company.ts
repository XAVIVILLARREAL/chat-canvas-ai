import type { Agent } from "./agent";
import type { Skill } from "./skill";

export interface Company {
  id: string;
  name: string;
  description: string;
  agents: Agent[];
  skills: Skill[];
  settings: CompanySettings;
  createdAt: string;
  updatedAt: string;
}

export interface CompanySettings {
  maxAgents: number;
  autoAssignTasks: boolean;
  notificationsEnabled: boolean;
  theme: "light" | "dark" | "system";
}
