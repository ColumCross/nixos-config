import { tool } from "@opencode-ai/plugin"

type Account = string

const HOME = process.env.HOME ?? "/home/colum"
const notmuch = "/run/current-system/sw/bin/notmuch"

async function configuredAccounts(): Promise<Account[]> {
  const configuration = await Bun.file(`${HOME}/.config/mail/accounts.json`).json() as { accounts?: Array<{ address?: unknown }> }
  const accounts = configuration.accounts?.map((entry) => entry.address) ?? []
  if (accounts.length === 0 || accounts.some((entry) => typeof entry !== "string" || !/^[^@/\s]+@[^@/\s]+\.[^@/\s]+$/.test(entry))) {
    throw new Error("Mail account configuration is invalid")
  }
  return accounts
}

function account(value: string, configured: readonly Account[]): Account {
  if (!configured.includes(value)) throw new Error("Unknown mail account")
  return value
}

function messageID(value: string): string {
  const normalized = value.startsWith("id:") ? value.slice(3) : value
  if (!/^[A-Za-z0-9.@_+%=-]{1,512}$/.test(normalized)) throw new Error("Invalid message ID")
  return normalized
}

function tag(value: string): string {
  if (!/^[A-Za-z0-9][A-Za-z0-9._+=@/-]{0,255}$/.test(value)) throw new Error("Invalid mail tag")
  return value
}

function parseJSON(value: string): unknown {
  try {
    return JSON.parse(value)
  } catch {
    throw new Error("notmuch returned invalid JSON")
  }
}

function headers(value: unknown): Record<string, string> {
  if (Array.isArray(value)) {
    for (const item of value) {
      const found = headers(item)
      if (Object.keys(found).length > 0) return found
    }
  }
  if (value && typeof value === "object") {
    const record = value as Record<string, unknown>
    if (record.headers && typeof record.headers === "object" && !Array.isArray(record.headers)) {
      return Object.fromEntries(Object.entries(record.headers as Record<string, unknown>).filter((entry): entry is [string, string] => typeof entry[1] === "string"))
    }
    for (const item of Object.values(record)) {
      const found = headers(item)
      if (Object.keys(found).length > 0) return found
    }
  }
  return {}
}

function tags(value: unknown): string[] {
  if (Array.isArray(value)) {
    for (const item of value) {
      const found = tags(item)
      if (found.length > 0) return found
    }
  }
  if (value && typeof value === "object") {
    const record = value as Record<string, unknown>
    if (Array.isArray(record.tags) && record.tags.every((tag) => typeof tag === "string")) return record.tags
    for (const item of Object.values(record)) {
      const found = tags(item)
      if (found.length > 0) return found
    }
  }
  return []
}

async function runNotmuch(selectedAccount: Account, args: string[]): Promise<string> {
  const process = Bun.spawn([notmuch, `--config=${HOME}/.config/notmuch/${selectedAccount}.conf`, ...args], { stdout: "pipe", stderr: "pipe" })
  const [code, stdout, stderr] = await Promise.all([process.exited, new Response(process.stdout).text(), new Response(process.stderr).text()])
  if (code !== 0) throw new Error(`notmuch failed: ${stderr.trim() || "unknown error"}`)
  return stdout
}

async function runCommand(command: string, args: string[]): Promise<string> {
  const process = Bun.spawn([command, ...args], { stdout: "pipe", stderr: "pipe" })
  const [code, stdout, stderr] = await Promise.all([process.exited, new Response(process.stdout).text(), new Response(process.stderr).text()])
  if (code !== 0) throw new Error(`${command} failed: ${stderr.trim() || stdout.trim() || "unknown error"}`)
  return stdout
}

export const search = tool({
  description: "Run any valid read-only Notmuch query against one configured account or all accounts and return message metadata.",
  args: {
    account: tool.schema.string().describe("Exact configured Gmail address or 'all'"),
    query: tool.schema.string().min(1).describe("Any valid Notmuch search query"),
    sort: tool.schema.enum(["newest-first", "oldest-first"]).optional().describe("Optional Notmuch result order"),
    limit: tool.schema.number().int().min(1).optional().describe("Optional maximum results per account; omit for all results"),
    offset: tool.schema.number().int().min(0).optional().describe("Optional zero-based result offset"),
  },
  async execute(args) {
    const configured = await configuredAccounts()
    const selected = args.account === "all" ? configured : [account(args.account, configured)]
    const accounts = await Promise.all(selected.map(async (selectedAccount) => {
      const searchArgs = ["search", "--format=json", "--output=messages"]
      if (args.sort) searchArgs.push(`--sort=${args.sort}`)
      if (args.limit !== undefined) searchArgs.push(`--limit=${args.limit}`)
      if (args.offset !== undefined) searchArgs.push(`--offset=${args.offset}`)
      searchArgs.push(args.query)
      const output = await runNotmuch(selectedAccount, searchArgs)
      const hits = parseJSON(output)
      if (!Array.isArray(hits)) throw new Error("notmuch returned an invalid search result")
      const results = []
      for (const hit of hits) {
        if (typeof hit !== "string") throw new Error("notmuch returned a message without an ID")
        const id = messageID(hit)
        const metadata = await runNotmuch(selectedAccount, ["show", "--format=json", "--format-version=2", "--entire-thread=false", "--body=false", "--decrypt=false", `id:${id}`])
        const parsed = parseJSON(metadata)
        const fields = headers(parsed)
        results.push({ message_id: id, sender: fields.From ?? null, subject: fields.Subject ?? null, date: fields.Date ?? null, tags: tags(parsed) })
      }
      return { account: selectedAccount, results }
    }))
    return JSON.stringify({ query: args.query, sort: args.sort ?? null, limit: args.limit ?? null, offset: args.offset ?? null, accounts })
  },
})

export const read = tool({
  description: "Read exactly one indexed message without changing tags or unread state.",
  args: {
    account: tool.schema.string().describe("Exact configured Gmail address"),
    message_id: tool.schema.string().describe("Message-ID returned by mail_search"),
  },
  async execute(args) {
    const selectedAccount = account(args.account, await configuredAccounts())
    const id = messageID(args.message_id)
    const output = await runNotmuch(selectedAccount, ["show", "--format=json", "--format-version=2", "--entire-thread=false", "--decrypt=false", `id:${id}`])
    return JSON.stringify({ account: selectedAccount, message_id: id, message: parseJSON(output) })
  },
})

export const labels = tool({
  description: "List all local Notmuch tags, including Gmail system labels and synchronized Gmail labels, for one configured account or all accounts.",
  args: {
    account: tool.schema.string().optional().describe("Exact configured Gmail address or 'all'; defaults to all"),
  },
  async execute(args) {
    const configured = await configuredAccounts()
    const selected = !args.account || args.account === "all" ? configured : [account(args.account, configured)]
    const accounts = await Promise.all(selected.map(async (selectedAccount) => {
      const output = await runNotmuch(selectedAccount, ["search", "--format=json", "--output=tags", "*"])
      const result = parseJSON(output)
      if (!Array.isArray(result) || result.some((value) => typeof value !== "string")) throw new Error("notmuch returned invalid tags")
      return { account: selectedAccount, tags: result }
    }))
    return JSON.stringify({ accounts })
  },
})

export const update = tool({
  description: "Apply Gmail-compatible tag additions and removals to every message matching any valid Notmuch query. It can star, mark read or unread, archive, move, restore, mark spam, and change Gmail labels. Adding the trash tag is forbidden.",
  args: {
    account: tool.schema.string().describe("Exact configured Gmail address"),
    query: tool.schema.string().min(1).describe("Any valid Notmuch query identifying messages to update"),
    add_tags: tool.schema.array(tool.schema.string()).optional().describe("Tags to add, such as flagged, unread, important, inbox, spam, marked-for-deletion, or a Gmail label"),
    remove_tags: tool.schema.array(tool.schema.string()).optional().describe("Tags to remove, such as flagged, unread, important, inbox, spam, marked-for-deletion, trash, or a Gmail label"),
  },
  async execute(args) {
    const selectedAccount = account(args.account, await configuredAccounts())
    const add = [...new Set((args.add_tags ?? []).map(tag))]
    const remove = [...new Set((args.remove_tags ?? []).map(tag))]
    if (add.length === 0 && remove.length === 0) throw new Error("Specify at least one tag to add or remove")
    if (add.some((value) => value.toLowerCase() === "trash")) throw new Error("Moving messages to Trash is forbidden")
    if (add.some((value) => remove.includes(value))) throw new Error("A tag cannot be both added and removed")
    await runNotmuch(selectedAccount, ["tag", ...add.map((value) => `+${value}`), ...remove.map((value) => `-${value}`), "--", args.query])
    return JSON.stringify({ account: selectedAccount, query: args.query, added_tags: add, removed_tags: remove, updated: true })
  },
})

export const sync = tool({
  description: "Synchronize one configured Gmail account or all accounts with Gmail using the existing locked mail-sync workflow. Use only when the user explicitly requests synchronization.",
  args: {
    account: tool.schema.string().describe("Exact configured Gmail address or 'all'"),
  },
  async execute(args) {
    const configured = await configuredAccounts()
    const selected = args.account === "all" ? "all" : account(args.account, configured)
    const output = await runCommand("mail-sync", [selected])
    return JSON.stringify({ account: selected, synchronized: true, output: output.trim() })
  },
})
