import { account, configuredAccounts, configPath, tool } from "./common"

const HOME = process.env.HOME ?? "/home/colum"

async function count(selectedAccount: string): Promise<string> {
  const process = Bun.spawn(["/run/current-system/sw/bin/notmuch", `--config=${configPath(selectedAccount as never)}`, "count", "*"], { stdout: "pipe", stderr: "pipe" })
  if (await process.exited !== 0) return "unavailable"
  return (await new Response(process.stdout).text()).trim()
}

export default tool({
  description: "Return indexed message counts and last recorded synchronization state without contacting Gmail.",
  args: { account: tool.schema.string().optional().describe("Exact configured Gmail address or 'all'; defaults to all") },
  async execute(args) {
    const configured = await configuredAccounts()
    const selected = !args.account || args.account === "all" ? configured : [account(args.account, configured)]
    const results = await Promise.all(selected.map(async (selectedAccount) => {
      const statusPath = `${HOME}/.local/state/mail/status/${selectedAccount}`
      const statusFile = Bun.file(statusPath)
      return {
        account: selectedAccount,
        indexed_messages: await count(selectedAccount),
        status: await statusFile.exists() ? await statusFile.text() : "last_success=never\n",
      }
    }))
    return JSON.stringify({ accounts: results })
  },
})
