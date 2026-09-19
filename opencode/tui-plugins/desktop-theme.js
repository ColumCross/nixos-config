const themeStateFile = "@themeStateFile@"

const tui = async (api) => {
  if (!process.env.NVIM) return

  const sync = async () => {
    try {
      const theme = (await Bun.file(themeStateFile).text()).trim()
      if ((theme === "dark" || theme === "light") && api.theme.mode() !== theme) {
        api.keymap.dispatchCommand("theme.switch_mode")
      }
    } catch {
      // The desktop may not have initialized the theme state yet.
    }
  }

  const onSignal = () => void sync()
  process.on("SIGUSR2", onSignal)
  api.lifecycle.onDispose(() => process.off("SIGUSR2", onSignal))
  setTimeout(() => void sync(), 0)
}

export default {
  id: "desktop-theme",
  tui,
}
