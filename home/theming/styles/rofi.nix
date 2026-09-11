{
  config = ''
    configuration {
      display-drun: "Apps";
      drun-display-format: "{name}";
      font: "JetBrains Mono 12";
    }

    @theme "~/.config/rofi/themes/current.rasi"
  '';

  dark = ''
    * { background: #000000; foreground: #00ffff; selected-foreground: #00ffff; border-color: #00ffff; background-color: transparent; text-color: @foreground; margin: 0px; padding: 0px; spacing: 0px; }
    window { background-color: @background; border: 2px; border-color: @border-color; border-radius: 0px; width: 960px; height: 540px; padding: 10px; }
    mainbox { children: [inputbar, listview]; background-color: transparent; }
    inputbar { children: [prompt, entry]; background-color: transparent; border: 0px 0px 2px 0px; border-color: @border-color; padding: 10px; margin: 0px 0px 10px 0px; }
    prompt { text-color: @foreground; padding: 0px 10px 0px 0px; }
    entry { placeholder: "Search..."; placeholder-color: #555555; text-color: @foreground; }
    listview { lines: 10; columns: 1; scrollbar: false; }
    element { padding: 8px; border-radius: 0px; }
    element selected { background-color: transparent; text-color: @selected-foreground; border: 2px; border-color: @selected-foreground; }
    element-text { background-color: transparent; text-color: inherit; vertical-align: 0.5; }
    element-icon { size: 24px; padding: 0px 10px 0px 0px; background-color: transparent; }
  '';

  light = ''
    * { background: #ffffff; foreground: #282a36; selected-foreground: #0077aa; border-color: #0077aa; background-color: transparent; text-color: @foreground; margin: 0px; padding: 0px; spacing: 0px; }
    window { background-color: @background; border: 2px; border-color: @border-color; border-radius: 0px; width: 960px; height: 540px; padding: 10px; }
    mainbox { children: [inputbar, listview]; background-color: transparent; }
    inputbar { children: [prompt, entry]; background-color: transparent; border: 0px 0px 2px 0px; border-color: @border-color; padding: 10px; margin: 0px 0px 10px 0px; }
    prompt { text-color: @foreground; padding: 0px 10px 0px 0px; }
    entry { placeholder: "Search..."; placeholder-color: #aaaaaa; text-color: @foreground; }
    listview { lines: 10; columns: 1; scrollbar: false; }
    element { padding: 8px; border-radius: 0px; }
    element selected { background-color: transparent; text-color: @selected-foreground; border: 2px; border-color: @selected-foreground; }
    element-text { background-color: transparent; text-color: inherit; vertical-align: 0.5; }
    element-icon { size: 24px; padding: 0px 10px 0px 0px; background-color: transparent; }
  '';
}
