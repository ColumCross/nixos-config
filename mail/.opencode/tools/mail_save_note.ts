import { tool } from "./common"

const HOME = process.env.HOME ?? "/home/colum"
const notes = `${HOME}/Mail/notes`

export default tool({
  description: "Save a private Markdown summary, classification proposal, or unsent reply draft under Mail/notes.",
  args: {
    kind: tool.schema.enum(["summary", "classification", "reply-draft"]).describe("The note type"),
    title: tool.schema.string().min(1).max(200).describe("Human-readable note title"),
    content: tool.schema.string().min(1).max(100000).describe("Markdown note content"),
    references: tool.schema.array(tool.schema.string().max(600)).max(100).describe("Account and message or thread references"),
  },
  async execute(args) {
    const slug = args.title.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "").slice(0, 80) || "note"
    const name = `${new Date().toISOString().replace(/[:.]/g, "-")}-${args.kind}-${slug}-${crypto.randomUUID()}.md`
    const path = `${notes}/${name}`
    if (!path.startsWith(`${notes}/`) || path.includes("..")) throw new Error("Unsafe note path")
    const references = args.references.map((reference) => `- ${reference}`).join("\n")
    await Bun.write(path, `# ${args.title}\n\nKind: ${args.kind}\n\n## References\n${references}\n\n## Content\n${args.content}\n`)
    return JSON.stringify({ path, saved: true })
  },
})
