import { account, boundedText, configuredAccounts, messageID, parseJSON, runNotmuch, tool } from "./common"

export default tool({
  description: "Read exactly one indexed message without changing tags or unread state.",
  args: {
    account: tool.schema.string().describe("Exact configured Gmail address"),
    message_id: tool.schema.string().describe("Message-ID returned by mail_search"),
  },
  async execute(args) {
    const selectedAccount = account(args.account, await configuredAccounts())
    const id = messageID(args.message_id)
    const output = await runNotmuch(selectedAccount, ["show", "--format=json", "--format-version=2", "--entire-thread=false", "--decrypt=false", `id:${id}`])
    const bounded = boundedText(output)
    return JSON.stringify({ account: selectedAccount, message_id: id, truncated: bounded.truncated, message: parseJSON(bounded.text) })
  },
})
