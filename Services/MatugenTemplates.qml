pragma Singleton

import QtQuick
import Quickshell
import "../Commons" as QsCommons

Singleton {
  id: root

  // === TOML Configuration Builder ===
  
  // Build complete TOML configuration for Matugen
  function buildConfigToml() {
    const templates = []
    const mode = QsCommons.Settings.data.colorSchemes.darkMode ? "dark" : "light"

    templates.push(buildTemplate(
      "yaqs-colors",
      Quickshell.shellDir + "/Assets/MatugenTemplates/yaqs-colors.json",
      QsCommons.Settings.configDir + "colors.json"
    ))
    
    // GTK Theme (GTK3 and GTK4)
    if (QsCommons.Settings.data.templates.gtk) {
      templates.push(buildTemplate(
        "gtk3",
        Quickshell.shellDir + "/Assets/MatugenTemplates/gtk-colors.css",
        "~/.config/gtk-3.0/colors.css",
        `gsettings set org.gnome.desktop.interface gtk-theme ''`
      ))
      templates.push(buildTemplate(
        "gtk4",
        Quickshell.shellDir + "/Assets/MatugenTemplates/gtk-colors.css",
        "~/.config/gtk-4.0/colors.css"
      ))
    }
    
    // Qt Theme (qt5ct and qt6ct)
    if (QsCommons.Settings.data.templates.qt) {
      templates.push(buildTemplate(
        "qt5ct",
        Quickshell.shellDir + "/Assets/MatugenTemplates/qtct-colors.conf",
        "~/.config/qt5ct/colors/yaqs.conf"
      ))
      templates.push(buildTemplate(
        "qt6ct",
        Quickshell.shellDir + "/Assets/MatugenTemplates/qtct-colors.conf",
        "~/.config/qt6ct/colors/yaqs.conf"
      ))
    }
    
    // KDE Color Scheme
    if (QsCommons.Settings.data.templates.kcolorscheme) {
      templates.push(buildTemplate(
        "color-scheme",
        Quickshell.shellDir + "/Assets/MatugenTemplates/Matugen.colors",
        "~/.local/share/color-schemes/Matugen.colors"
      ))
    }
    
    // Kitty Terminal
    if (QsCommons.Settings.data.templates.kitty) {
      templates.push(buildTemplate(
        "kitty",
        Quickshell.shellDir + "/Assets/MatugenTemplates/Terminal/kitty.conf",
        "~/.config/kitty/themes/yaqs.conf",
        "pkill -SIGUSR1 kitty"
      ))
    }
    
    // Foot Terminal
    if (QsCommons.Settings.data.templates.foot) {
      templates.push(buildTemplate(
        "foot",
        Quickshell.shellDir + "/Assets/MatugenTemplates/Terminal/foot",
        "~/.config/foot/themes/yaqs",
        "pkill -SIGUSR1 foot"
      ))
    }
    
    // Ghostty Terminal
    if (QsCommons.Settings.data.templates.ghostty) {
      templates.push(buildTemplate(
        "ghostty",
        Quickshell.shellDir + "/Assets/MatugenTemplates/Terminal/ghostty",
        "~/.config/ghostty/themes/yaqs",
        "pkill -SIGUSR2 ghostty"
      ))
    }
    
    // Btop System Monitor
    if (QsCommons.Settings.data.templates.btop) {
      templates.push(buildTemplate(
        "btop",
        Quickshell.shellDir + "/Assets/MatugenTemplates/btop.theme",
        "~/.config/btop/themes/yaqs.theme"
      ))
    }
    
    // Hyprland Window Manager
    if (QsCommons.Settings.data.templates.hyprland) {
      templates.push(buildTemplate(
        "hyprland",
        Quickshell.shellDir + "/Assets/MatugenTemplates/hyprland-colors.conf",
        "~/.config/hypr/colors.conf",
        "hyprctl reload"
      ))
    }
    
    // Discord Clients (all use same CSS template)
    const discordClients = [
      { key: "discord_vesktop", path: "~/.config/vesktop/themes/yaqs.theme.css" },
      { key: "discord_webcord", path: "~/.config/webcord/themes/yaqs.theme.css" },
      { key: "discord_armcord", path: "~/.config/armcord/themes/yaqs.theme.css" },
      { key: "discord_equibop", path: "~/.config/equibop/themes/yaqs.theme.css" },
      { key: "discord_lightcord", path: "~/.config/lightcord/themes/yaqs.theme.css" },
      { key: "discord_dorion", path: "~/.config/dorion/themes/yaqs.theme.css" },
      { key: "discord_vencord", path: "~/.config/discord/themes/yaqs.theme.css" }
    ]
    
    discordClients.forEach(client => {
      if (QsCommons.Settings.data.templates[client.key]) {
        templates.push(buildTemplate(
          client.key,
          Quickshell.shellDir + "/Assets/MatugenTemplates/midnight-discord.css",
          client.path
        ))
      }
    })
    
    // Pywalfox (Firefox/Thunderbird theming)
    if (QsCommons.Settings.data.templates.pywalfox) {
      templates.push(buildTemplate(
        "pywalfox",
        Quickshell.shellDir + "/Assets/MatugenTemplates/pywalfox-colors.json",
        "~/.cache/wal/colors.json",
        "pywalfox update 2>/dev/null || true"
      ))
    }
    
    // Return complete TOML configuration
    return "[config]\n\n" + templates.join("\n\n") + "\n"
  }
  
  // Build a single [[templates.name]] TOML section
  function buildTemplate(name, inputPath, outputPath, postHook) {
    let config = `[templates.${name}]\n`
    config += `input_path = "${inputPath}"\n`
    config += `output_path = "${outputPath}"`
    if (postHook) {
      config += `\npost_hook = "${postHook}"`
    }
    return config
  }
}

