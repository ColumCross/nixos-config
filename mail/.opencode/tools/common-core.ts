export type Account = string

const maxLimit = 50
const maxTextBytes = 100_000

export function account(value: string, configured: readonly string[]): Account {
  if (!configured.includes(value)) throw new Error("Unknown mail account")
  return value
}

export function limit(value: number | undefined): number {
  if (value === undefined) return 20
  if (!Number.isInteger(value) || value < 1 || value > maxLimit) throw new Error(`limit must be 1-${maxLimit}`)
  return value
}

export function cursor(value: number | undefined): number {
  if (value === undefined) return 0
  if (!Number.isInteger(value) || value < 0 || value > 100_000) throw new Error("cursor must be a non-negative integer")
  return value
}

export function messageID(value: string): string {
  if (!/^[A-Za-z0-9.@_+%=-]{1,512}$/.test(value)) throw new Error("Invalid message ID")
  return value
}

export function threadID(value: string): string {
  if (!/^[A-Za-z0-9._-]{1,512}$/.test(value)) throw new Error("Invalid thread ID")
  return value
}

export function boundedText(value: string): { text: string; truncated: boolean } {
  const bytes = new TextEncoder().encode(value)
  if (bytes.length <= maxTextBytes) return { text: value, truncated: false }
  return { text: new TextDecoder().decode(bytes.slice(0, maxTextBytes)), truncated: true }
}

export function parseJSON(value: string): unknown {
  try {
    return JSON.parse(value)
  } catch {
    throw new Error("notmuch returned invalid JSON")
  }
}

export function headers(value: unknown): Record<string, string> {
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
