export type SkillCategory =
  | "frontend"
  | "backend"
  | "testing"
  | "devops"
  | "design"
  | "data";

export interface Skill {
  id: string;
  name: string;
  description: string;
  category: SkillCategory;
  dialect: "opencode" | "cursor" | "claude_code";
  content: string;
  version: string;
  createdAt: string;
  updatedAt: string;
}
