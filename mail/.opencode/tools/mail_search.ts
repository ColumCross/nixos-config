import { account, configuredAccounts, cursor, headers, limit, messageID, parseJSON, runNotmuch, tool } from "./common"

export default tool({
  description: "Search configured Notmuch databases for message metadata. Use one account or all; results retain account identity.",
  args: {
    account: tool.schema.string().describe("Exact configured Gmail address or 'all'"),
    query: tool.schema.string().min(1).max(2000).describe("A Notmuch query"),
    limit: tool.schema.number().int().optional().describe("Results per account, 1-50; defaults to 20"),
    cursor: tool.schema.number().int().optional().describe("Zero-based result offset; defaults to 0"),
  },
  async execute(args) {
    const configured = await configuredAccounts()
    const selected = args.account === "all" ? configured : [account(args.account, configured)]
    const pageSize = limit(args.limit)
    const offset = cursor(args.cursor)
    const results = await Promise.all(selected.map(async (selectedAccount) => {
      try {
        const output = await runNotmuch(selectedAccount, ["search", "--format=json", "--output=messages", "--sort=newest", `--limit=${pageSize}`, `--offset=${offset}`, args.query])
        const hits = parseJSON(output)
        if (!Array.isArray(hits)) throw new Error("notmuch returned an invalid search result")
        const results = await Promise.all(hits.map(async (hit) => {
          if (!hit || typeof hit !== "object" || !("id" in hit) || typeof hit.id !== "string") throw new Error("notmuch returned a message without an ID")
          const id = messageID(hit.id)
          const metadata = await runNotmuch(selectedAccount, ["show", "--format=json", "--format-version=2", "--entire-thread=false", "--body=false", "--decrypt=false", `id:${id}`])
          const fields = headers(parseJSON(metadata))
          const summary = hit as Record<string, unknown>
          return {
            message_id: id,
            thread_id: typeof summary.thread === "string" ? summary.thread : null,
            sender: fields.From ?? null,
            subject: fields.Subject ?? null,
            date: fields.Date ?? (typeof summary.date === "string" ? summary.date : null),
            tags: Array.isArray(summary.tags) ? summary.tags : [],
          }
        }))
        return { account: selectedAccount, results, error: null }
      } catch (error) {
        return { account: selectedAccount, results: [], error: error instanceof Error ? error.message : "search failed" }
      }
    }))
    return JSON.stringify({ query: args.query, limit: pageSize, cursor: offset, accounts: results })
  },
})
