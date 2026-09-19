const hyprctl = "@hyprctl@"
const notifySend = "@notifySend@"

const kittyPID = Number(process.env.KITTY_PID)
const nestedInNeovim = Boolean(process.env.NVIM) && Number.isInteger(kittyPID)

const title = (value) => {
  if (typeof value !== "string") return "OpenCode"
  const clean = value.replace(/[\u0000-\u001f\u007f]/g, " ").trim()
  return clean.slice(0, 80) || "OpenCode"
}

export const DesktopNotifications = async ({ client }) => {
  if (!nestedInNeovim) return {}

  const sessions = new Map()
  const active = new Set()
  const errored = new Set()
  const permissions = new Set()
  const questions = new Set()

  const kittyFocused = async () => {
    try {
      const process = Bun.spawn([hyprctl, "activewindow", "-j"], { stdout: "pipe", stderr: "ignore" })
      const output = await new Response(process.stdout).text()
      if ((await process.exited) !== 0) return true
      return JSON.parse(output).pid === kittyPID
    } catch {
      return true
    }
  }

  const session = async (sessionID) => {
    const cached = sessions.get(sessionID)
    if (cached) return cached

    try {
      const response = await client.session.get({ path: { id: sessionID } })
      if (response.error || !response.data) return
      sessions.set(sessionID, response.data)
      return response.data
    } catch {
      return
    }
  }

  const notify = async (sessionID, message, urgency = "normal") => {
    if (await kittyFocused()) return
    const info = await session(sessionID)
    if (!info || info.parentID !== undefined) return

    try {
      Bun.spawn([
        notifySend,
        "--app-name=OpenCode",
        `--urgency=${urgency}`,
        "OpenCode",
        `${title(info.title)}: ${message}`,
      ], { stdout: "ignore", stderr: "ignore" })
    } catch {
      // Dunst availability must not affect OpenCode's event processing.
    }
  }

  const refresh = async () => {
    try {
      const [listed, statuses] = await Promise.all([client.session.list(), client.session.status()])
      if (!listed.error) {
        for (const info of listed.data ?? []) sessions.set(info.id, info)
      }
      if (!statuses.error) {
        for (const [sessionID, status] of Object.entries(statuses.data ?? {})) {
          if (status.type === "busy" || status.type === "retry") active.add(sessionID)
        }
      }
    } catch {
      // Plugin initialization can precede API readiness.
    }
  }

  setTimeout(() => void refresh(), 0)

  return {
    event: async ({ event }) => {
      if (event.type === "session.created" || event.type === "session.updated") {
        sessions.set(event.properties.info.id, event.properties.info)
        return
      }

      if (event.type === "session.deleted") {
        const sessionID = event.properties.info.id
        sessions.delete(sessionID)
        active.delete(sessionID)
        errored.delete(sessionID)
        return
      }

      if (event.type === "session.status") {
        const { sessionID, status } = event.properties
        if (status.type === "busy" || status.type === "retry") {
          active.add(sessionID)
          errored.delete(sessionID)
          return
        }
        if (status.type === "idle" && active.delete(sessionID) && !errored.delete(sessionID)) {
          await notify(sessionID, "Session completed")
        }
        return
      }

      if (event.type === "session.error" && event.properties.sessionID && active.has(event.properties.sessionID)) {
        errored.add(event.properties.sessionID)
        await notify(event.properties.sessionID, "Session error", "critical")
        return
      }

      if (event.type === "permission.asked") {
        if (permissions.has(event.properties.id)) return
        permissions.add(event.properties.id)
        await notify(event.properties.sessionID, "Permission needs input", "critical")
        return
      }
      if (event.type === "permission.replied") {
        permissions.delete(event.properties.requestID)
        return
      }

      if (event.type === "question.asked") {
        if (questions.has(event.properties.id)) return
        questions.add(event.properties.id)
        await notify(event.properties.sessionID, "Question needs input", "critical")
        return
      }
      if (event.type === "question.replied" || event.type === "question.rejected") {
        questions.delete(event.properties.requestID)
      }
    },
  }
}
