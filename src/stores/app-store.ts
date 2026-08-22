import { create } from "zustand";
import type { Agent, Skill, Task } from "../types";

interface AppState {
  agents: Agent[];
  tasks: Task[];
  skills: Skill[];
  selectedAgent: Agent | null;
  selectedTask: Task | null;

  addAgent: (agent: Agent) => void;
  removeAgent: (id: string) => void;
  selectAgent: (agent: Agent | null) => void;
  updateAgentStatus: (id: string, status: Agent["status"]) => void;

  addTask: (task: Task) => void;
  removeTask: (id: string) => void;
  selectTask: (task: Task | null) => void;
  updateTaskStatus: (id: string, status: Task["status"]) => void;
  assignTask: (taskId: string, agentId: string | null) => void;

  addSkill: (skill: Skill) => void;
  removeSkill: (id: string) => void;
}

export const useAppStore = create<AppState>((set) => ({
  agents: [],
  tasks: [],
  skills: [],
  selectedAgent: null,
  selectedTask: null,

  addAgent: (agent) => set((state) => ({ agents: [...state.agents, agent] })),

  removeAgent: (id) =>
    set((state) => ({
      agents: state.agents.filter((a) => a.id !== id),
      selectedAgent:
        state.selectedAgent?.id === id ? null : state.selectedAgent,
    })),

  selectAgent: (agent) => set({ selectedAgent: agent }),

  updateAgentStatus: (id, status) =>
    set((state) => ({
      agents: state.agents.map((a) => (a.id === id ? { ...a, status } : a)),
      selectedAgent:
        state.selectedAgent?.id === id
          ? { ...state.selectedAgent, status }
          : state.selectedAgent,
    })),

  addTask: (task) => set((state) => ({ tasks: [...state.tasks, task] })),

  removeTask: (id) =>
    set((state) => ({
      tasks: state.tasks.filter((t) => t.id !== id),
      selectedTask: state.selectedTask?.id === id ? null : state.selectedTask,
    })),

  selectTask: (task) => set({ selectedTask: task }),

  updateTaskStatus: (id, status) =>
    set((state) => ({
      tasks: state.tasks.map((t) => (t.id === id ? { ...t, status } : t)),
      selectedTask:
        state.selectedTask?.id === id
          ? { ...state.selectedTask, status }
          : state.selectedTask,
    })),

  assignTask: (taskId, agentId) =>
    set((state) => ({
      tasks: state.tasks.map((t) =>
        t.id === taskId ? { ...t, assignedAgentId: agentId } : t,
      ),
    })),

  addSkill: (skill) => set((state) => ({ skills: [...state.skills, skill] })),

  removeSkill: (id) =>
    set((state) => ({
      skills: state.skills.filter((s) => s.id !== id),
    })),
}));
