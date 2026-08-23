# IDM Activation Script v3.3.0

A powerful Windows batch script for activating Internet Download Manager (IDM) with modern UI, custom name registration, and comprehensive tools.

## Features

- **Clean Interface**
  - Categorized menu layout (Activation, Tools, Other)
  - Status line shows whether IDM is installed and registered before you choose

- **Activation Options**
  - Custom Name Registration (enter your own name)
  - Trial Period Freeze (Recommended)
  - Reset Activation/Trial

- **Tools**
  - Install/Update IDM directly
  - Backup & Restore Settings
  - Smart Auto-Update Feature (Automatically updates script)
  - Clean Uninstall (complete removal)

- **Auto-Fix Features**
  - PowerShell execution policy auto-fix
  - WMI service auto-restart
  - Connection retry with DNS flush

## Requirements

- Windows 7 or later (including Windows Server)
- Administrator privileges
- PowerShell (pre-installed on modern Windows)
- Internet Download Manager installed

## Usage

### Method 1: PowerShell (Recommended)

```powershell
irm s.id/idm-script | iex
```

### Method 2: Interactive Mode

1. Download `ias.cmd`
2. Right-click → **"Run as administrator"**
3. Choose from menu:

```
   IDM 6.42 build 25  |  Not registered
  ------------------------------------------------------------

   ACTIVATION
     [1]  Activate IDM
     [2]  Freeze Trial Period
     [3]  Reset Activation / Trial

   TOOLS
     [4]  Install / Update IDM
     [5]  Backup Settings
     [6]  Restore Settings

   OTHER
     [7]  Clean Uninstall IDM
     [8]  Check Script Update
     [H]  Help / Documentation
     [0]  Exit
```

The status line reflects whether IDM is installed and registered before you pick
anything.

**When selecting Activate IDM:**
- You will be prompted to enter your First Name and Last Name
- These details will appear in IDM's registration info
- Press Enter without typing to use default values
- A stray `"` in the name is stripped automatically before it reaches the registry

## How It Works

1. **Backup**: Exports the CLSID registry keys and copies the hosts file to `%SystemRoot%\Temp`
2. **Host Block**: Points IDM's validation domains at `0.0.0.0` so IDM cannot phone home
3. **Clean Slate**: Deletes every existing IDM CLSID key, including locked ones left by an earlier run
4. **Registration**: Writes your name and a serial, or skips this for Freeze Trial
5. **Trigger**: Makes IDM download a small test file so it rebuilds its CLSID keys
6. **Lock**: Takes ownership of the fresh keys and denies write access, so IDM can never revoke them

Steps 3 and 6 are why activation can now be run repeatedly. Earlier versions locked
the keys without deleting the old ones first, so a second run had nothing to work with.

## Backup & Restore

- **[5] Backup Settings** exports `HKCU\Software\DownloadManager` to
  `%userprofile%\Documents\IDM_Backup\idm_settings_<timestamp>.reg`, timestamped to
  the second so running it twice in one day keeps both backups instead of the second
  silently overwriting the first.
- **[6] Restore Settings** lists every `.reg` file in that folder, then asks for
  confirmation before overwriting your current registration. Picking a number with no
  matching backup reports "Invalid selection" instead of doing nothing silently.

This is separate from the CLSID backup that activation makes automatically on every
run — see [What Gets Changed On Your System](#what-gets-changed-on-your-system).

## Updating the Script

**[8] Check Script Update** compares the local version against
`raw.githubusercontent.com/imrosyd/idm-script`. Before installing anything it:

- Rejects the download if it came back empty
- Normalizes line endings to CRLF, since GitHub does not guarantee the same line
  endings the repository has stored
- Requires the first line to look like an IAS script

A copy of the script you were running is kept at `%TEMP%\ias_previous.cmd` in case you
ever need to roll an update back by hand.

## Recommendations

- **Freeze Trial** is recommended over activation for best long-term results
- Always run with administrator privileges
- Ensure IDM is installed before running the script
- Internet connection required for initial setup

## Troubleshooting

### Auto-Fix Features

The script includes automatic fixes for common issues:

| Issue | Auto-Fix |
|-------|----------|
| PowerShell restricted | Automatically sets execution policy to Bypass |
| WMI not working | Automatically restarts winmgmt service |
| Internet connection | Retries 3 times with DNS cache flush |

**Cannot reach internetdownloadmanager.com in the browser after activation**

That is the hosts block doing its job. Run Reset [3] to remove it, or edit
`%SystemRoot%\System32\drivers\etc\hosts` and delete the lines marked `# IAS`.

### Manual Fixes (if auto-fix fails)

**PowerShell is not working**
```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force
```

**WMI is not working**
```cmd
net stop winmgmt /y
net start winmgmt
```

**Cannot connect to internetdownloadmanager.com**
- Check your internet connection
- Verify firewall/antivirus settings
- Run: `ipconfig /flushdns`

## Security

- No usage data, telemetry, or personal information is ever sent anywhere
- The registration name you type stays in your local registry only

### What Gets Changed On Your System

| Change | Where | Undo |
|--------|-------|------|
| CLSID registry keys (deleted, then re-created and locked) | `HKCU\Software\Classes\Wow6432Node\CLSID` | Reset [3] |
| Registration name, e-mail, serial | `HKCU\Software\DownloadManager` | Reset [3] |
| **hosts file** — 9 IDM domains pointed at `0.0.0.0` | `%SystemRoot%\System32\drivers\etc\hosts` | Reset [3] or Clean Uninstall [7] |

Backups are written to `%SystemRoot%\Temp` before anything is modified:
`_Backup_HKCU_CLSID_<timestamp>.reg` and `_Backup_hosts_<timestamp>.txt`.

### About The hosts File

Activation blocks `tonec.com`, `internetdownloadmanager.com`, `idmzs.com`, `idmmzs.com`
and their `www`/`secure` variants. Without this, IDM contacts its servers, finds the
serial invalid, and undoes the activation.

Every line the script adds is marked with `# IAS`, and both routines rewrite the file
line by line, so entries you put there yourself are left alone. **This is fully
reversible** — run Reset [3] or Clean Uninstall [7] and the entries are removed.

Side effect worth knowing: while the block is active you cannot open
`internetdownloadmanager.com` in a browser. Menu [4] Install/Update lifts the block
automatically before downloading the installer.

### Network Connections

- `github.com` / `raw.githubusercontent.com` — connectivity check, test download, update check [8]
- `www.google.com` — fallback test download
- `mirror2.internetdownloadmanager.com` — IDM installer, menu [4] only

## Compatibility

| Windows Version | Support |
|----------------|---------|
| Windows 11     | ✅ Full |
| Windows 10     | ✅ Full |
| Windows 8.1    | ✅ Full |
| Windows 8      | ✅ Full |
| Windows 7      | ✅ Full |
| Windows Server | ✅ Full |

| Architecture | Support |
|-------------|---------|
| x64         | ✅ Full |
| x86         | ✅ Full |
| ARM64       | ✅ Full |

## Download IDM

Official IDM Download: [internetdownloadmanager.com](https://www.internetdownloadmanager.com/download.html)

## Version History

### v3.3.0 (2026-08-23)
- **NEW**: IDM host blocking, fully reversible via Reset [3] or Clean Uninstall [7]
- **FIX**: Clean Uninstall no longer wipes the entire CLSID branch
- **FIX**: activation deletes stale locked keys first, so it can be run repeatedly
- **FIX**: all wait loops work non-interactively (`timeout` silently did nothing)
- **FIX**: self-update validates the download before replacing the running script
- Menu redesigned to fit the window, with an IDM status line

### v3.2.0 (2026-02-01)
- **NEW**: Smart Auto-Update Feature
- **NEW**: Streamlined Menu Layout
- Removing deprecated Generate License feature
- Enhanced Freeze Trial stability

### v3.1.0 (2026-02-01)
- **NEW**: Custom name registration feature
- **NEW**: ASCII Art Banner & Modern UI
- **NEW**: Backup & Restore Settings
- Repository moved to imrosyd/idm-script
- Updated documentation

### v3.0 (2025-12-04)
- Initial release
- Full activation support
- Trial freeze functionality
- Registry backup system
- Multi-architecture support

## License

This project is released under the MIT License — see [LICENSE](LICENSE).

The copyright notice in that file names Md. Omar Faruk Tazul Islam, the
original author of the upstream project this was forked from (see
[Author](#author)). MIT requires that notice to stay as-is in any copy or
fork, which is why it doesn't name this repository's maintainer.

## Disclaimer

This script is for educational purposes only. Users should purchase a legitimate license from the official IDM website to support the developers.

## Author

**imrosyd**
- GitHub: [@imrosyd](https://github.com/imrosyd)
- Forked from: [omartazul/IDM-Activation-Script](https://github.com/omartazul/IDM-Activation-Script)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Support

For issues and questions:
- Open an issue on [GitHub](https://github.com/imrosyd/idm-script/issues)
- Check existing issues for solutions

---

⭐ If this project helped you, please consider giving it a star on GitHub!
