export type AgentStatus = "idle" | "working" | "blocked" | "error";

export type AgentRole =
  | "dev"
  | "qa"
  | "reviewer"
  | "pm"
  | "devops"
  | "designer";

export interface Agent {
  id: string;
  name: string;
  role: AgentRole;
  status: AgentStatus;
  skills: string[];
}

export interface Task {
  id: string;
  title: string;
  description: string;
  status: "todo" | "doing" | "review" | "done";
  assignedAgentId: string | null;
  criteria: string[];
  result?: string;
}

export interface Skill {
  id: string;
  name: string;
  description: string;
  triggers: string[];
  dialect: "opencode" | "cursor" | "claude-code" | "custom";
}
