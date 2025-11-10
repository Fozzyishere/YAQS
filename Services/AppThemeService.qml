pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../Commons" as QsCommons
import "../Helpers/ColorsConvert.js" as ColorsConvert

Singleton {
  id: root

  // === Configuration ===
  
  readonly property string dynamicConfigPath: QsCommons.Settings.cacheDir + "matugen.dynamic.toml"
  
  // === Reactivity: Automatic Regeneration ===
  
  // React to wallpaper changes
  // When wallpaper changes AND wallpaper mode is enabled, regenerate theme
  Connections {
    target: WallpaperService
    function onWallpaperChanged(screenName, path) {
      if (screenName === Screen.name && 
          QsCommons.Settings.data.colorSchemes.useWallpaperColors) {
        QsCommons.Logger.i("AppTheme", "Wallpaper changed, regenerating theme")
        generateFromWallpaper()
      }
    }
  }

  // React to dark mode changes
  // When dark/light mode toggles, regenerate with new mode
  Connections {
    target: QsCommons.Settings.data.colorSchemes
    function onDarkModeChanged() {
      QsCommons.Logger.i("AppTheme", "Dark mode changed, regenerating theme")
      generate()
    }
  }

  // === Public API ===
  
  function init() {
    QsCommons.Logger.i("AppTheme", "Service started")
  }

  // Main entry point - routes to appropriate generation mode
  function generate() {
    if (QsCommons.Settings.data.colorSchemes.useWallpaperColors) {
      generateFromWallpaper()
    } else {
      // Re-apply predefined scheme
      // This calls back to generateFromPredefinedScheme() via ColorSchemeService
      ColorSchemeService.applyScheme(
        QsCommons.Settings.data.colorSchemes.predefinedScheme
      )
    }
  }

  // === Mode 1: Wallpaper Color Generation ===
  
  // Generate themes from wallpaper using Matugen's image mode
  function generateFromWallpaper() {
    // Check if matugen is available
    if (!ProgramCheckerService.matugenAvailable) {
      QsCommons.Logger.w("AppTheme", "Matugen not available, skipping template generation")
      QsCommons.Logger.w("AppTheme", "Install matugen: paru -S matugen-bin")
      return
    }

    // Get current wallpaper with proper shell escaping
    const wp = WallpaperService.getWallpaper(Screen.name).replace(/'/g, "'\\''")
    if (!wp) {
      QsCommons.Logger.e("AppTheme", "No wallpaper found for screen:", Screen.name)
      return
    }

    // Build TOML configuration
    const content = MatugenTemplates.buildConfigToml()
    if (!content) {
      QsCommons.Logger.w("AppTheme", "No templates enabled, skipping generation")
      return
    }

    const mode = QsCommons.Settings.data.colorSchemes.darkMode ? "dark" : "light"
    const script = buildMatugenScript(content, wp, mode)

    QsCommons.Logger.i("AppTheme", "Generating theme from wallpaper (mode:", mode + ")")
    generateProcess.command = ["bash", "-lc", script]
    generateProcess.running = true
  }

  // Build bash script using heredoc for TOML generation
  // Heredoc with random delimiter prevents basic injection attacks
  function buildMatugenScript(content, wallpaper, mode) {
    const delimiter = "MATUGEN_CONFIG_EOF_" + Math.random().toString(36).substr(2, 9)
    const pathEsc = dynamicConfigPath.replace(/'/g, "'\\''")

    let script = `cat > '${pathEsc}' << '${delimiter}'\n${content}\n${delimiter}\n`
    
    script += `matugen image '${wallpaper}' --config '${pathEsc}' --mode ${mode} --type ${QsCommons.Settings.data.colorSchemes.matugenSchemeType}`
    
    script += buildUserTemplateCommand(wallpaper, mode)

    return script + "\n"
  }

  // Support for user-defined templates
  function buildUserTemplateCommand(input, mode) {
    if (!QsCommons.Settings.data.templates.enableUserTemplates) {
      return ""
    }

    const userConfigPath = getUserConfigPath()
    let script = "\n# Execute user config if it exists\n"
    script += `if [ -f '${userConfigPath}' ]; then\n`
    script += `  matugen image '${input}' --config '${userConfigPath}' --mode ${mode} --type ${QsCommons.Settings.data.colorSchemes.matugenSchemeType}\n`
    script += "fi"

    return script
  }

  function getUserConfigPath() {
    return (QsCommons.Settings.configDir + "user-templates.toml")
      .replace(/'/g, "'\\''")
  }

  // === Mode 2: Predefined Scheme Generation ===
  
  // Generate themes from predefined color scheme
  // Bypasses Matugen for predefined schemes
  function generateFromPredefinedScheme(schemeData) {
    QsCommons.Logger.i("AppTheme", "Generating theme from predefined scheme")

    // Handle terminal themes first (copied from ColorScheme directory)
    handleTerminalThemes()

    const isDarkMode = QsCommons.Settings.data.colorSchemes.darkMode
    const mode = isDarkMode ? "dark" : "light"
    const colors = schemeData[mode]

    // Generate Material Design 3 palette via JavaScript
    // This produces ~25 color tokens from the 5 seed colors
    const matugenColors = generatePalette(
      colors.mPrimary,
      colors.mSecondary,
      colors.mTertiary,
      colors.mError,
      colors.mSurface,
      isDarkMode
    )
    
    // Build bash script to process all templates
    let script = processAllTemplates(matugenColors, mode)
    
    // Add user templates if enabled
    script += buildUserTemplateCommandForPredefined(schemeData, mode)

    QsCommons.Logger.i("AppTheme", "Processing predefined scheme templates")
    generateProcess.command = ["bash", "-lc", script]
    generateProcess.running = true
  }

  // Generate Material Design 3 palette from 5 seed colors
  function generatePalette(primaryColor, secondaryColor, tertiaryColor, 
                           errorColor, backgroundColor, isDarkMode) {
    // Helper to format colors in Matugen's expected structure
    const c = hex => ({
      "default": {
        "hex": hex,
        "hex_stripped": hex.replace(/^#/, "")
      }
    })

    // Generate container colors (lighter/darker backgrounds)
    const primaryContainer = ColorsConvert.generateContainerColor(primaryColor, isDarkMode)
    const secondaryContainer = ColorsConvert.generateContainerColor(secondaryColor, isDarkMode)
    const tertiaryContainer = ColorsConvert.generateContainerColor(tertiaryColor, isDarkMode)

    // Generate "on" colors (text on colored backgrounds)
    const onPrimary = ColorsConvert.generateOnColor(primaryColor, isDarkMode)
    const onSecondary = ColorsConvert.generateOnColor(secondaryColor, isDarkMode)
    const onTertiary = ColorsConvert.generateOnColor(tertiaryColor, isDarkMode)
    const onBackground = ColorsConvert.generateOnColor(backgroundColor, isDarkMode)

    const onPrimaryContainer = ColorsConvert.generateOnColor(primaryContainer, isDarkMode)
    const onSecondaryContainer = ColorsConvert.generateOnColor(secondaryContainer, isDarkMode)
    const onTertiaryContainer = ColorsConvert.generateOnColor(tertiaryContainer, isDarkMode)

    // Generate error colors
    const errorContainer = ColorsConvert.generateContainerColor(errorColor, isDarkMode)
    const onError = ColorsConvert.generateOnColor(errorColor, isDarkMode)
    const onErrorContainer = ColorsConvert.generateOnColor(errorContainer, isDarkMode)

    // Surface is same as background in Material Design 3
    const surface = backgroundColor
    const onSurface = onBackground

    // Generate surface variant (slightly different tone)
    const surfaceVariant = ColorsConvert.adjustLightness(backgroundColor, isDarkMode ? 5 : -3)
    const onSurfaceVariant = ColorsConvert.generateOnColor(surfaceVariant, isDarkMode)

    // Generate surface containers (5 elevation levels)
    const surfaceContainerLowest = ColorsConvert.generateSurfaceVariant(backgroundColor, 0, isDarkMode)
    const surfaceContainerLow = ColorsConvert.generateSurfaceVariant(backgroundColor, 1, isDarkMode)
    const surfaceContainer = ColorsConvert.generateSurfaceVariant(backgroundColor, 2, isDarkMode)
    const surfaceContainerHigh = ColorsConvert.generateSurfaceVariant(backgroundColor, 3, isDarkMode)
    const surfaceContainerHighest = ColorsConvert.generateSurfaceVariant(backgroundColor, 4, isDarkMode)

    // Outline colors (for borders/dividers)
    const outline = isDarkMode ? "#938f99" : "#79747e"
    const outlineVariant = ColorsConvert.adjustLightness(outline, isDarkMode ? -10 : 10)

    // Shadow is always very dark
    const shadow = "#000000"

    // Return complete palette in Matugen's expected structure
    return {
      "primary": c(primaryColor),
      "on_primary": c(onPrimary),
      "primary_container": c(primaryContainer),
      "on_primary_container": c(onPrimaryContainer),
      "secondary": c(secondaryColor),
      "on_secondary": c(onSecondary),
      "secondary_container": c(secondaryContainer),
      "on_secondary_container": c(onSecondaryContainer),
      "tertiary": c(tertiaryColor),
      "on_tertiary": c(onTertiary),
      "tertiary_container": c(tertiaryContainer),
      "on_tertiary_container": c(onTertiaryContainer),
      "error": c(errorColor),
      "on_error": c(onError),
      "error_container": c(errorContainer),
      "on_error_container": c(onErrorContainer),
      "background": c(backgroundColor),
      "on_background": c(onBackground),
      "surface": c(surface),
      "on_surface": c(onSurface),
      "surface_variant": c(surfaceVariant),
      "on_surface_variant": c(onSurfaceVariant),
      "surface_container_lowest": c(surfaceContainerLowest),
      "surface_container_low": c(surfaceContainerLow),
      "surface_container": c(surfaceContainer),
      "surface_container_high": c(surfaceContainerHigh),
      "surface_container_highest": c(surfaceContainerHighest),
      "outline": c(outline),
      "outline_variant": c(outlineVariant),
      "shadow": c(shadow)
    }
  }

  // Process all enabled templates for predefined mode
  // 
  // Strategy: Copy template → sed replace colors → post-hook
  // This avoids Matugen's JSON mode which doesn't produce good results
  function processAllTemplates(colors, mode) {
    let script = ""
    const homeDir = Quickshell.env("HOME")
    const templatesDir = Quickshell.shellDir + "/Assets/MatugenTemplates"

    // Process shell colors (always)
    script += processShellColors(colors, homeDir)

    // Process application templates based on settings
    const templateConfigs = {
      "gtk": {
        "template": "gtk-colors.css",
        "outputs": [
          "~/.config/gtk-3.0/colors.css",
          "~/.config/gtk-4.0/colors.css"
        ],
        "postHook": `gsettings set org.gnome.desktop.interface gtk-theme ""\n`
      },
      "qt": {
        "template": "qtct-colors.conf",
        "outputs": [
          "~/.config/qt5ct/colors/yaqs.conf",
          "~/.config/qt6ct/colors/yaqs.conf"
        ]
      },
      "kcolorscheme": {
        "template": "Matugen.colors",
        "outputs": ["~/.local/share/color-schemes/Matugen.colors"]
      },
      "btop": {
        "template": "btop.theme",
        "outputs": ["~/.config/btop/themes/yaqs.theme"]
      },
      "hyprland": {
        "template": "hyprland-colors.conf",
        "outputs": ["~/.config/hypr/colors.conf"],
        "postHook": "hyprctl reload 2>/dev/null || true\n"
      },
      "pywalfox": {
        "template": "pywalfox-colors.json",
        "outputs": ["~/.cache/wal/colors.json"],
        "postHook": "pywalfox update 2>/dev/null || true\n"
      }
    }

    // Process Discord clients (all use same template)
    const discordClients = {
      "discord_vesktop": "~/.config/vesktop/themes/yaqs.theme.css",
      "discord_webcord": "~/.config/webcord/themes/yaqs.theme.css",
      "discord_armcord": "~/.config/armcord/themes/yaqs.theme.css",
      "discord_equibop": "~/.config/equibop/themes/yaqs.theme.css",
      "discord_lightcord": "~/.config/lightcord/themes/yaqs.theme.css",
      "discord_dorion": "~/.config/dorion/themes/yaqs.theme.css",
      "discord_vencord": "~/.config/discord/themes/yaqs.theme.css"
    }

    // Process regular templates
    Object.keys(templateConfigs).forEach(appName => {
      if (QsCommons.Settings.data.templates[appName]) {
        script += processTemplate(
          templatesDir,
          templateConfigs[appName],
          colors,
          homeDir
        )
      }
    })

    // Process Discord clients with directory check
    Object.keys(discordClients).forEach(clientKey => {
      if (QsCommons.Settings.data.templates[clientKey]) {
        script += processDiscordTemplate(
          templatesDir,
          discordClients[clientKey],
          colors,
          homeDir
        )
      }
    })

    // Note: Terminal themes are handled differently for predefined schemes
    // They use pre-made terminal theme files from ColorScheme directory
    // This is done in ColorSchemeService, not here

    return script
  }

  // Process shell colors (yaqs-colors.json → colors.json)
  // This template is always processed to update Color.qml
  function processShellColors(colors, homeDir) {
    const outputPath = QsCommons.Settings.configDir + "colors.json"
    const template = Quickshell.shellDir + "/Assets/MatugenTemplates/yaqs-colors.json"
    
    let script = `mkdir -p $(dirname '${outputPath}')\n`
    script += `cp '${template}' '${outputPath}'\n`
    script += replaceColorsInFile(outputPath, colors)
    
    return script
  }

  // Process a regular template (GTK, Qt, KColorScheme, Pywalfox)
  function processTemplate(templatesDir, config, colors, homeDir) {
    let script = ""
    const templatePath = `${templatesDir}/${config.template}`

    config.outputs.forEach(outputPath => {
      const fullPath = outputPath.replace("~", homeDir)
      const outputDir = fullPath.substring(0, fullPath.lastIndexOf('/'))

      script += `mkdir -p '${outputDir}'\n`
      script += `cp '${templatePath}' '${fullPath}'\n`
      script += replaceColorsInFile(fullPath, colors)
    })

    if (config.postHook) {
      script += config.postHook
    }

    return script
  }

  // Process Discord client template with directory check
  // Only creates theme if Discord client is actually installed
  function processDiscordTemplate(templatesDir, outputPath, colors, homeDir) {
    const fullPath = outputPath.replace("~", homeDir)
    const outputDir = fullPath.substring(0, fullPath.lastIndexOf('/'))
    const baseConfigDir = outputDir.replace("/themes", "")
    const templatePath = `${templatesDir}/midnight-discord.css`

    let script = `if [ -d "${baseConfigDir}" ]; then\n`
    script += `  mkdir -p '${outputDir}'\n`
    script += `  cp '${templatePath}' '${fullPath}'\n`
    script += `  ` + replaceColorsInFile(fullPath, colors)
    script += `else\n`
    script += `  echo "Discord client at ${baseConfigDir} not found, skipping"\n`
    script += `fi\n`

    return script
  }

  // Replace color placeholders in file using sed
  // 
  // Handles both {{colors.primary.default.hex}} and {{colors.primary.default.hex_stripped}}
  // This regex pattern matches both forms and replaces with same value
  function replaceColorsInFile(filePath, colors) {
    let script = ""
    Object.keys(colors).forEach(colorKey => {
      const colorValue = colors[colorKey].default.hex
      const escapedColor = colorValue.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
      // Regex matches: {{colors.primary.default.hex}} or {{colors.primary.default.hex_stripped}}
      script += `sed -i 's/{{colors\\.${colorKey}\\.default\\.hex\\(_stripped\\)\\?}}/${escapedColor}/g' '${filePath}'\n`
    })
    return script
  }

  // === Terminal Theme Handling (Predefined Mode) ===
  
  // Use hand-crafted terminal themes from ColorScheme directory
  function handleTerminalThemes() {
    const commands = []
    const homeDir = Quickshell.env("HOME")
    
    // Terminal configurations
    const terminalPaths = {
      "kitty": "~/.config/kitty/themes/yaqs.conf",
      "foot": "~/.config/foot/themes/yaqs",
      "ghostty": "~/.config/ghostty/themes/yaqs"
    }

    Object.keys(terminalPaths).forEach(terminal => {
      if (QsCommons.Settings.data.templates[terminal]) {
        const outputPath = terminalPaths[terminal].replace("~", homeDir)
        const outputDir = outputPath.substring(0, outputPath.lastIndexOf('/'))
        const templatePath = getTerminalColorsTemplate(terminal)

        commands.push(`mkdir -p '${outputDir}'`)
        commands.push(`cp -f '${templatePath}' '${outputPath}'`)
        commands.push(`echo "  ✓ ${terminal} theme copied"`)
      }
    })

    if (commands.length > 0) {
      QsCommons.Logger.d("AppTheme", "Copying terminal themes from ColorScheme directory")
      copyProcess.command = ["bash", "-lc", commands.join('; ')]
      copyProcess.running = true
    }
  }

  // Get path to terminal theme file from ColorScheme directory
  function getTerminalColorsTemplate(terminal) {
    let colorScheme = QsCommons.Settings.data.colorSchemes.predefinedScheme
    const mode = QsCommons.Settings.data.colorSchemes.darkMode ? 'dark' : 'light'

    // Handle scheme name mapping (some schemes have spaces or special names)
    const schemeNameMap = {
      "Tokyo Night": "Tokyo-Night"
    }
    colorScheme = schemeNameMap[colorScheme] || colorScheme
    
    // Kitty uses .conf extension, others don't
    const extension = terminal === 'kitty' ? ".conf" : ""

    return `${Quickshell.shellDir}/Assets/ColorScheme/${colorScheme}/terminal/${terminal}/${colorScheme}-${mode}${extension}`
  }

  // === Process: Terminal Theme Copy ===
  
  Process {
    id: copyProcess
    workingDirectory: Quickshell.shellDir
    running: false
    
    stdout: SplitParser {
      onRead: function(data) {
        QsCommons.Logger.d("AppTheme", data)
      }
    }
    
    stderr: StdioCollector {
      onStreamFinished: {
        if (this.text) {
          QsCommons.Logger.d("AppTheme", "Copy stderr:", this.text)
        }
      }
    }
  }

  // Support for user templates in predefined mode
  // Creates temporary JSON file with palette and runs matugen json command
  function buildUserTemplateCommandForPredefined(schemeData, mode) {
    if (!QsCommons.Settings.data.templates.enableUserTemplates) {
      return ""
    }

    const userConfigPath = getUserConfigPath()
    const isDarkMode = QsCommons.Settings.data.colorSchemes.darkMode
    const colors = schemeData[mode]

    // Generate palette for user templates
    const matugenColors = generatePalette(
      colors.mPrimary,
      colors.mSecondary,
      colors.mTertiary,
      colors.mError,
      colors.mSurface,
      isDarkMode
    )

    const tempJsonPath = QsCommons.Settings.cacheDir + "predefined-colors.json"
    const tempJsonPathEsc = tempJsonPath.replace(/'/g, "'\\''")

    let script = "\n# Execute user templates with predefined scheme colors\n"
    script += `if [ -f '${userConfigPath}' ]; then\n`
    
    // Write palette to temp JSON file
    script += `  cat > '${tempJsonPathEsc}' << 'EOF'\n`
    script += JSON.stringify({ "colors": matugenColors }, null, 2) + "\n"
    script += "EOF\n"
    
    // Use matugen json subcommand
    script += `  matugen json '${tempJsonPathEsc}' --config '${userConfigPath}' --mode ${mode}\n`
    script += "fi"

    return script
  }

  // === Process: Theme Generation ===
  
  Process {
    id: generateProcess
    workingDirectory: Quickshell.shellDir
    running: false
    
    stdout: StdioCollector {
      onStreamFinished: {
        if (this.text) {
          QsCommons.Logger.d("AppTheme", "Process stdout:", this.text)
        }
      }
    }
    
    stderr: StdioCollector {
      onStreamFinished: {
        if (this.text) {
          QsCommons.Logger.d("AppTheme", "Process stderr:", this.text)
        }
      }
    }
    
    onExited: function(exitCode) {
      if (exitCode !== 0) {
        QsCommons.Logger.e("AppTheme", "Template generation failed with exit code:", exitCode)
      } else {
        QsCommons.Logger.i("AppTheme", "Template generation completed successfully")
      }
    }
  }
}

