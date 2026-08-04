import { Annotation, StateGraph, START, END } from '@langchain/langgraph'

export type Ticket = {
  id: string
  title: string
  description: string
  directory: string
}

export type JobStatus = 'pending' | 'planning' | 'implementing' | 'verifying' | 'reviewing' | 'done' | 'failed'

export type JobResult = {
  ticket: Ticket
  status: JobStatus
  plan?: string
  implementation?: string
  verification?: string
  review?: string
  error?: string
  evidence?: { tool: string; output: string }[]
}

// Runner: inyectado por el server (llama a opencode para ejecutar el trabajo real)
export type Runner = {
  runPrompt: (directory: string, prompt: string, maxTokens?: number) => Promise<string>
  runUITest: (directory: string, url: string) => Promise<string>
}

export const JobAnnotation = Annotation.Root({
  ticket: Annotation<Ticket>,
  runner: Annotation<Runner>,
  status: Annotation<JobStatus>,
  plan: Annotation<string>,
  implementation: Annotation<string>,
  verification: Annotation<string>,
  review: Annotation<string>,
  error: Annotation<string>,
  evidence: Annotation<{ tool: string; output: string }[]>,
})

async function planNode(state: typeof JobAnnotation.State) {
  const { ticket, runner } = state
  const prompt = `Eres el Project Lead de una empresa de desarrollo. Crea un plan breve (3-5 pasos) para este ticket:
TITULO: ${ticket.title}
DESCRIPCION: ${ticket.description}
Directorio de trabajo: ${ticket.directory}
Responde solo con el plan numerado, conciso.`
  const plan = await runner.runPrompt(ticket.directory, prompt)
  return { status: 'implementing' as JobStatus, plan }
}

async function implementNode(state: typeof JobAnnotation.State) {
  const { ticket, runner, plan } = state
  const prompt = `Eres un Implementador senior. Ejecuta este ticket en el directorio ${ticket.directory}.
PLAN APROBADO:
${plan}
TAREA: ${ticket.title} - ${ticket.description}
Implementa la solucion. Si necesitas crear o editar archivos, hazlo. Si puedes correr tests, corrlos y reporta el resultado.`
  const implementation = await runner.runPrompt(ticket.directory, prompt)
  return { status: 'verifying' as JobStatus, implementation }
}

async function verifyNode(state: typeof JobAnnotation.State) {
  const { ticket, runner, implementation } = state
  // UI Tester: verificar en navegador real (Chrome headless via runner)
  const url = process.env.APP_URL ?? 'https://empresa-dev.xtremediagnostics.com'
  const verification = await runner.runUITest(ticket.directory, url)
  return { status: 'reviewing' as JobStatus, verification: `Implementacion: ${(implementation ?? '').slice(0, 200)}\n\nVerificacion UI: ${verification}` }
}

async function reviewNode(state: typeof JobAnnotation.State) {
  const { ticket, runner, verification } = state
  const prompt = `Eres el Reviewer. Revisa el resultado de este ticket:
TITULO: ${ticket.title}
RESULTADO:
${verification}
Dictamina: APROBADO o NECESITA CAMBIOS (con una frase de justificacion).`
  const review = await runner.runPrompt(ticket.directory, prompt)
  const approved = /aprobad/i.test(review)
  return { status: (approved ? 'done' : 'failed') as JobStatus, review }
}

export function buildGraph(runner: Runner) {
  const g = new StateGraph(JobAnnotation)
    .addNode('planner', planNode)
    .addNode('implementer', implementNode)
    .addNode('tester', verifyNode)
    .addNode('reviewer', reviewNode)
    .addEdge(START, 'planner')
    .addEdge('planner', 'implementer')
    .addEdge('implementer', 'tester')
    .addEdge('tester', 'reviewer')
    .addEdge('reviewer', END)
    .compile()

  return {
    async run(ticket: Ticket): Promise<JobResult> {
      const res = await g.invoke({
        ticket,
        runner,
        status: 'planning',
        plan: '',
        implementation: '',
        verification: '',
        review: '',
        error: '',
        evidence: [],
      })
      return {
        ticket,
        status: res.status ?? 'done',
        plan: res.plan,
        implementation: res.implementation,
        verification: res.verification,
        review: res.review,
        error: res.error,
        evidence: res.evidence,
      }
    },
  }
}
