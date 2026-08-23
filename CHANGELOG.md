# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- **Clean Uninstall no longer wipes the whole CLSID branch.** It used to run
  `reg delete "HKCU\Software\Classes\Wow6432Node\CLSID" /f`, which removes the COM
  registration of every 32-bit application for that user. It now reuses the same
  targeted registry scanner as Reset and deletes only the keys IDM created, and it
  also cleans `HKU\<sid>\Software\DownloadManager` when HKCU is not synced.
- **Install / Update [4] no longer dead-ends after activation.** It called `:_activate`,
  which never returns (it falls through to `:done`), so everything after the call was
  unreachable and `_unattended=1` made the script exit instead of returning to the menu.
  It now jumps to `:_activate` with a new `_skipprompt` flag so the name is asked once.
- **Update check compares versions numerically** using `[version]` instead of string
  equality, so an older remote version is no longer reported as an available update.
- **Restore Settings** pointed users at option `[6]` to create a backup; it is `[5]`.
- **Registry permission handling no longer aborts the scan.** `RtlAdjustPrivilege` is
  now set up once instead of rebuilding the P/Invoke type for every key, `Take-Permissions`
  returns early on a null key, and the whole routine is wrapped in try/catch, so one
  protected key cannot stop the scan. Ported from upstream v3.1.1.

### Added
- **IDM host blocking**, ported from upstream and extended. Activation points the nine
  IDM validation domains at `0.0.0.0` so IDM cannot phone home and revoke the serial.
  Unlike upstream this is reversible: every line carries a `# IAS` marker, the original
  hosts file is backed up to `%SystemRoot%\Temp` before the first change of each run,
  and both Reset [3] and Clean Uninstall [7] remove the entries again. The rewrite is
  line by line, so hosts entries the user added themselves are preserved.
- **Helper subroutines** `:prepare_operation_ui`, `:create_clsid_backup`,
  `:regscan_delete`, `:regscan_lock`, `:regscan_lock_toggle`, `:block_idm_hosts`,
  `:unblock_idm_hosts` — replacing blocks that were copy-pasted between Activate,
  Reset and Clean Uninstall.

### Changed
- **Activation is now a five-step flow** matching upstream: block hosts, delete every
  existing CLSID key (including stale locked ones from an earlier run), write the
  serial, trigger the download, then lock. Previously the keys were locked without
  being deleted first, so a second activation run had nothing left to work with.
- **Test downloads pull from neutral hosts** (`raw.githubusercontent.com`,
  `google.com`, `github.com`) instead of IDM's own servers, which are blocked at that
  point, and success is now confirmed by counting CLSID keys before and after the run
  rather than by the presence of the downloaded file alone.
- **Connectivity check probes `github.com`** instead of `internetdownloadmanager.com`,
  which the script blocks on purpose.
- **Install / Update [4] lifts the hosts block** before downloading the installer.
- Registry backups go to `%_wtemp%`, which falls back from `%SystemRoot%\Temp` to
  `%TEMP%` if the first is not writable.
- Argument parsing uses `%%~A` over `%*` instead of stripping every quote from `%*`.
- All embedded PowerShell is invoked through `. ([scriptblock]::create(...))` instead
  of `iex`.
- Dropped the dead `+ $key.Substring(20)` from serial generation — on a 20-character
  string it always produced an empty string, a leftover from a 25-character version.

### Changed (earlier in this cycle)
- **Install / Update [4] resolves the current IDM build** from the official download
  page instead of using a hardcoded `idman642build25.exe`, falling back to that build
  if the page cannot be parsed.
- **`ias.ps1` warns instead of staying silent when integrity is not verified.** With no
  `-ExpectedHash` (the default for `irm ... | iex`), it now says so explicitly, and it
  refuses any download URL that is not `https://`.
- Documentation: corrected the line-count and version figures in `project_summary.md`,
  and replaced the inaccurate "no external server communication" claim in both
  `README.md` and `project_summary.md` with the actual list of hosts contacted.

---

## [3.2.0] - 2026-02-01

### Added
- **Smart Auto-Update Feature** [8]: Improved update system that automatically downloads, installs, and restarts the script.
- **Enhanced Freeze Trial** [2]: Further optimized specifically for IDM stability (Highly Recommended).
- **Streamlined Menu**: Removed deprecated "Generate License" feature for simplicity.
- **Improved Serial Key Handling**: Activation now uses consistent internal logic for serial generation.

### Changed
- Reordered menu items for better usability:
  - Activation: Activate, Freeze, Reset
  - Tools: Install/Update, Backup, Restore
  - Other: Clean Uninstall, Check Update, Help
- Removed "Generate New License" menu [4] to avoid confusion with main activation.
- `_check_update` function now handles the entire update process automatically.

### Fixed
- Fixed crash issues in "Check Status" menu on certain systems.
- Fixed "Clean Uninstall" to properly remove all scheduled tasks.
- Resolved path issues by using environment variables (`%ProgramFiles%`, etc.) instead of hardcoded paths.
- Removed unreliable ASCII art elements that caused display glitches in some locales.

---

## [3.1.0] - 2026-02-01

### Added
- **Custom Name Registration**: Enter your own First Name and Last Name during activation
- **ASCII Art Banner**: Modern visual branding with "IDM SCRIPT" logo
- **Check IDM Status** [4]: View IDM version, registration info, and activation status
- **Backup Settings** [6]: Export IDM settings to Documents folder
- **Restore Settings** [7]: Import previously backed up settings
- **Check Script Update** [9]: Compare local version with GitHub latest
- **Clean Uninstall** [8]: Complete IDM removal including registry cleanup
- **Auto-Fix Features**: Automatic fixes for PowerShell, WMI, and connection issues
- **Retry Mechanism**: 3 retries with DNS flush for connection problems

### Changed
- Redesigned menu with categorized sections (Activation, Tools, Other)
- Modern box-style layout with Unicode characters and emoji icons
- Files renamed to lowercase (`ias.cmd`, `ias.ps1`, `contributing.md`, `project_summary.md`)
- Enhanced color scheme with green/yellow highlights
- Repository moved to imrosyd/idm-script

### Improved
- PowerShell auto-fix: Sets execution policy to Bypass automatically
- WMI auto-fix: Restarts winmgmt service if needed
- Better error messages with manual fix instructions

---

## [3.0.0] - 2025-12-04

### Added
- Initial public release
- Interactive menu system with color-coded output
- Full IDM activation functionality
- Trial period freeze feature
- Reset activation and trial option
- Automatic registry backup system
- Smart CLSID registry key detection and management
- Support for x86, x64, and ARM64 architectures
- Command-line parameters for unattended operation (`/act`, `/frz`, `/res`)
- Comprehensive error handling and user guidance
- PowerShell-based registry scanning engine
- Internet connectivity verification
- IDM process management (auto-kill when needed)
- Windows 7/8/8.1/10/11 and Server compatibility

### Features
- **Registry Management**: Intelligent CLSID key detection, locking, and deletion
- **Multi-Architecture**: Full support for x86, x64, and ARM64 Windows systems
- **Safety First**: Creates timestamped registry backups before any modifications
- **User-Friendly**: Color-coded interface with clear status messages
- **Flexible Modes**: Both interactive menu and command-line operation
- **Smart Detection**: Automatically locates IDM installation path
- **Robust Error Handling**: Validates PowerShell, WMI, and system requirements

### Technical Details
- PowerShell execution environment validation
- Administrator privilege enforcement
- QuickEdit mode handling for better UX
- Terminal/ConHost compatibility layer
- Session-aware user SID detection
- HKCU/HKU registry synchronization check

### Documentation
- Comprehensive README.md with usage instructions
- MIT License
- CHANGELOG.md for version tracking

---

## Release Notes

### v3.0.0 - Initial Release

This is the first public release of the IDM Activation Script. The script has been designed from the ground up with a focus on:

1. **Reliability**: Robust error handling and validation at every step
2. **Safety**: Automatic backups before any registry modifications
3. **Compatibility**: Wide OS and architecture support
4. **Usability**: Clean interface with helpful guidance
5. **Flexibility**: Multiple operation modes (interactive and CLI)

The script combines the best practices and features from multiple activation approaches while maintaining a clean, maintainable codebase with no external dependencies beyond standard Windows components.

### Known Limitations
- Requires administrator privileges
- Internet connection needed for initial setup
- May not work with all IDM versions (trial freeze recommended)
- Some antivirus software may flag the script (false positive)

### Recommendations
- Use "Freeze Trial" option for best long-term results
- Always run with administrator rights
- Keep Windows and PowerShell updated
- Create manual registry backups if needed

---

[Unreleased]: https://github.com/imrosyd/idm-script/compare/v3.2.0...HEAD
[3.2.0]: https://github.com/imrosyd/idm-script/releases/tag/v3.2.0
[3.1.0]: https://github.com/imrosyd/idm-script/releases/tag/v3.1.0
[3.0.0]: https://github.com/imrosyd/idm-script/releases/tag/v3.0.0
