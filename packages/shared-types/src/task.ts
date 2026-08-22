export type TaskStatus =
  | "pending"
  | "in_progress"
  | "review"
  | "testing"
  | "done"
  | "blocked";

export type TaskPriority = "low" | "medium" | "high" | "critical";

export interface Task {
  id: string;
  title: string;
  description: string;
  status: TaskStatus;
  priority: TaskPriority;
  assignedAgentId?: string;
  acceptanceCriteria: string[];
  testResults?: TestResult[];
  createdAt: string;
  updatedAt: string;
}

export interface TestResult {
  id: string;
  taskId: string;
  passed: boolean;
  output: string;
  timestamp: string;
}
