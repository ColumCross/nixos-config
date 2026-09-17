import { account, configuredAccounts, cursor, limit, messageID, parseJSON, runNotmuch, threadID, tool } from "./common"

export default tool({
  description: "Read a bounded chronological portion of one account-scoped Notmuch thread.",
  args: {
    account: tool.schema.string().describe("Exact configured Gmail address"),
    thread_id: tool.schema.string().describe("Thread ID returned by mail_search for the same account"),
    limit: tool.schema.number().int().optional().describe("Maximum messages, 1-50; defaults to 20"),
    cursor: tool.schema.number().int().optional().describe("Zero-based message offset; defaults to 0"),
  },
  async execute(args) {
    const selectedAccount = account(args.account, await configuredAccounts())
    const id = threadID(args.thread_id)
    const pageSize = limit(args.limit)
    const offset = cursor(args.cursor)
    const search = await runNotmuch(selectedAccount, ["search", "--format=json", "--output=messages", "--sort=oldest", `--limit=${pageSize}`, `--offset=${offset}`, `thread:${id}`])
    const hits = parseJSON(search)
    if (!Array.isArray(hits)) throw new Error("notmuch returned an invalid thread search result")
    const messages = await Promise.all(hits.map(async (hit) => {
      if (!hit || typeof hit !== "object" || !("id" in hit) || typeof hit.id !== "string") throw new Error("notmuch returned a message without an ID")
      const selectedID = messageID(hit.id)
      const output = await runNotmuch(selectedAccount, ["show", "--format=json", "--format-version=2", "--entire-thread=false", "--decrypt=false", `id:${selectedID}`])
      return { message_id: selectedID, message: parseJSON(output) }
    }))
    return JSON.stringify({ account: selectedAccount, thread_id: id, limit: pageSize, cursor: offset, messages, truncated: false })
  },
})
