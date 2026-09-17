import { tool } from "@opencode-ai/plugin"
import { type Account } from "./common-core"
export { account, boundedText, cursor, headers, limit, messageID, parseJSON, threadID, type Account } from "./common-core"

export { tool }

const HOME = process.env.HOME ?? "/home/colum"
const notmuch = "/run/current-system/sw/bin/notmuch"

export async function configuredAccounts(): Promise<Account[]> {
  const configuration = await Bun.file(`${HOME}/.config/mail/accounts.json`).json() as { accounts?: Array<{ address?: unknown }> }
  if (!Array.isArray(configuration.accounts)) throw new Error("Mail account configuration is invalid")
  const accounts = configuration.accounts.map((entry) => entry.address)
  if (accounts.length === 0 || accounts.some((entry): entry is not string => typeof entry !== "string" || !/^[^@/\s]+@[^@/\s]+\.[^@/\s]+$/.test(entry))) {
    throw new Error("Mail account configuration is invalid")
  }
  return accounts
}

export function configPath(value: Account): string {
  return `${HOME}/.config/notmuch/${value}.conf`
}

export async function runNotmuch(value: Account, args: string[]): Promise<string> {
  const process = Bun.spawn([notmuch, `--config=${configPath(value)}`, ...args], {
    stdout: "pipe",
    stderr: "pipe",
  })
  const [code, stdout, stderr] = await Promise.all([process.exited, new Response(process.stdout).text(), new Response(process.stderr).text()])
  if (code !== 0) throw new Error(`notmuch failed: ${stderr.trim() || "unknown error"}`)
  return stdout
}
