## 🖌️ Oh My Posh Auto Installer Script
This script automates the installation and setup of [Oh My Posh](https://ohmyposh.dev), a prompt theme engine for customizing your terminal experience.

## ✨Features
 - **Theme Selection**: Users can choose between different themes from the list to customize the terminal's appearance.
 - **PowerShell Profile Configuration**: Automatically configures Oh My Posh for PowerShell 5/7, CMD, and Windows Terminal.
 - **Shortcut Configuration**: The script configures shortcuts for using on-my-posh automatically when starting any console.
 - **Installation of Additional Tools**: The menu offers online installation of the latest versions of essential tools, including:
   - **`Oh-My-Posh`**: A prompt theme engine for PowerShell that enhances the command-line interface with beautiful prompts and useful information.
   - **`PowerShell 7`**: The latest version of PowerShell available from GitHub, providing advanced scripting capabilities and improved performance.
   - **`Clink`**: The latest version of a command line enhancement for CMD, which integrates seamlessly with `oh-my-posh` to provide enhanced command-line features and shortcuts.
   - **`Nano`**: The latest version of a lightweight text editor for the terminal, ideal for quick edits and configuration file modifications.
   - **`Windows Terminal`**: A modern terminal application for Windows 10 and newer that supports multiple tabs, Unicode, and rich text, providing a powerful environment for command-line tools.
   - **`Terminal-Icons`**: A module that provides file type icons in the terminal, enhancing visual cues and making it easier to identify file types at a glance.
   - **`PSReadLine`**: A PowerShell module that improves the command-line experience by enabling autocompletion with the arrow keys and displaying a navigable menu of all available options when the Tab key is pressed. This feature enhances usability by making it easier to discover commands and parameters.

## 💡 How to use (Windows 10 and later ❤️)

### 🖱️ With nice menu

1.   Open PowerShell (not CMD). Right-click on the Windows start menu and find PowerShell (or Terminal), or `press Win` + S and type Powershell.
2.   Copy and paste the code below and press enter
```powershell
irm omp.scripts.wiki | iex; run
```
or direct link
```powershell
irm https://raw.githubusercontent.com/JustDj-Git/PSH/refs/heads/main/Scripts/oh-my-posh-OneClick/oh-my-posh-OneClick.ps1 | iex; run
```
3.   Menu will appear!
---

### 🔧 Parameters and Switches for CLI
The script accepts the following parameters and switches:

- **`-oh_theme`**: Sets the theme name for Oh-My-Posh (ex. `-oh_theme "dracula"`).
- **`-ohmp`**: Downloads and installs only Oh-My-Posh with necessary fonts and Powershell modules. Requires additional oh-my-posh configuration!
- **`-AIO`**: Downloads and installs all tools: Oh-My-Posh, PowerShell 7, Clink, Nano, Terminal-Icons module, Windows Terminal, and PowerShell profiles.
- **`-ps7`**: Downloads and installs PowerShell 7.
- **`-cmd`**: Downloads and installs Clink for enhanced CMD experience.
- **`-nano`**: Downloads and installs Nano text editor.
- **`-icons`**: Downloads and installs the Terminal-Icons module.
- **`-terminal`**: Downloads and installs Windows Terminal and configures it.
- **`-ps_profile`**: Configures the PowerShell profile for enhanced settings.
- **`-log`**: Enables logging, writing to the specified file. Accepts a full path and file name (ex. `-log "C:\Users\Username\Desktop\install_log.txt"`).
---
### 🛠️ CLI Examples
1. **Set Theme to "Dracula" and Install Multiple Tools**  
   This command sets `oh_theme` to "dracula" and installs Clink (`-cmd`), Terminal-Icons (`-icons`), Windows Terminal (`-terminal`), and configures the PowerShell profile (`-ps_profile`):

    ```powershell
    irm omp.scripts.wiki | iex; run -oh_theme "dracula" -cmd -icons -terminal -ps_profile
    ```

2. **Install Only Oh-My-Posh with Dracula Theme**  
   This command sets `oh_theme` to "dracula" and installs only Oh-My-Posh (`-ohmp`) with the required fonts:

    ```powershell
    irm omp.scripts.wiki | iex; run -oh_theme "dracula" -ohmp
    ```
---
