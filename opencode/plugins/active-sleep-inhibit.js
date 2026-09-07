const systemdInhibit = "@systemdInhibit@"
const bash = "@bash@"
const sleep = "@sleep@"

const watchdog = `
  while kill -0 "$1" 2>/dev/null; do
    "${sleep}" 5
  done
`

export const ActiveSleepInhibit = async ({ client }) => {
  const inhibitors = new Map()

  const log = (level, message, extra = {}) =>
    client.app
      .log({
        body: {
          service: "active-sleep-inhibit",
          level,
          message,
          extra,
        },
      })
      .catch(() => {})

  const stop = (sessionID) => {
    const inhibitor = inhibitors.get(sessionID)
    if (!inhibitor) return

    inhibitors.delete(sessionID)
    if (inhibitor.exitCode === null) inhibitor.kill()
  }

  const start = (sessionID) => {
    if (inhibitors.has(sessionID)) return

    try {
      const inhibitor = Bun.spawn([
        systemdInhibit,
        "--what=idle:sleep",
        "--mode=block",
        "--who=opencode",
        "--why=OpenCode session is active",
        bash,
        "-c",
        watchdog,
        "active-sleep-inhibit",
        String(process.pid),
      ])

      inhibitors.set(sessionID, inhibitor)
      void inhibitor.exited.then((exitCode) => {
        if (inhibitors.get(sessionID) !== inhibitor) return
        inhibitors.delete(sessionID)
        if (exitCode !== 0) log("warn", "Session inhibitor exited unexpectedly", { sessionID, exitCode })
      })
    } catch (error) {
      log("error", "Failed to start session inhibitor", {
        sessionID,
        error: error instanceof Error ? error.message : String(error),
      })
    }
  }

  const update = (sessionID, status) => {
    if (status === "idle") {
      stop(sessionID)
      return
    }

    if (status === "busy" || status === "retry") start(sessionID)
  }

  const refresh = async () => {
    try {
      const response = await client.session.status()
      if (response.error) throw response.error
      for (const [sessionID, status] of Object.entries(response.data ?? {})) update(sessionID, status.type)
    } catch (error) {
      log("warn", "Failed to read existing session statuses", {
        error: error instanceof Error ? error.message : String(error),
      })
    }
  }

  // Plugin initialization runs before OpenCode's API is ready to answer requests.
  setTimeout(() => void refresh(), 0)

  return {
    event: async ({ event }) => {
      if (event.type === "session.status") {
        update(event.properties.sessionID, event.properties.status.type)
      }

      if (event.type === "session.deleted") stop(event.properties.sessionID)
    },
    dispose: async () => {
      for (const sessionID of inhibitors.keys()) stop(sessionID)
    },
  }
}
