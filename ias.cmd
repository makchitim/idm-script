@set iasver=3.2.0
@setlocal DisableDelayedExpansion
@echo off



::============================================================================
::
::   IDM Activation Script (IAS)
::
::   Homepage: https://github.com/omartazul/IDM-Activation-Script
::
::       Author: omartazul
::
::============================================================================



::  To activate, run the script with "/act" parameter or change 0 to 1 in below line
set _activate=0

::  To Freeze the 30 days trial period, run the script with "/frz" parameter or change 0 to 1 in below line
set _freeze=0

::  To reset the activation and trial, run the script with "/res" parameter or change 0 to 1 in below line
set _reset=0

::  If value is changed in above lines or parameter is used then script will run in unattended mode

::========================================================================================================================================

::  Set Path variable, it helps if it is misconfigured in the system

set "PATH=%SystemRoot%\System32;%SystemRoot%\System32\wbem;%SystemRoot%\System32\WindowsPowerShell\v1.0\"
if exist "%SystemRoot%\Sysnative\reg.exe" (
set "PATH=%SystemRoot%\Sysnative;%SystemRoot%\Sysnative\wbem;%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\;%PATH%"
)

:: Re-launch the script with x64 process if it was initiated by x86 process on x64 bit Windows
:: or with ARM64 process if it was initiated by x86/ARM32 process on ARM64 Windows

set "_cmdf=%~f0"
for %%# in (%*) do (
if /i "%%#"=="r1" set r1=1
if /i "%%#"=="r2" set r2=1
)

if exist %SystemRoot%\Sysnative\cmd.exe if not defined r1 (
setlocal EnableDelayedExpansion
start %SystemRoot%\Sysnative\cmd.exe /c ""!_cmdf!" %* r1"
exit /b
)

:: Re-launch the script with ARM32 process if it was initiated by x64 process on ARM64 Windows

if exist %SystemRoot%\SysArm32\cmd.exe if %PROCESSOR_ARCHITECTURE%==AMD64 if not defined r2 (
setlocal EnableDelayedExpansion
start %SystemRoot%\SysArm32\cmd.exe /c ""!_cmdf!" %* r2"
exit /b
)

::========================================================================================================================================

set "repo=https://github.com/imrosyd/idm-script"

::  Check if Null service is working, it's important for the batch script

sc query Null | find /i "RUNNING"
if %errorlevel% NEQ 0 (
echo:
echo Null service is not running, script may crash...
echo:
echo:
echo For help, visit: %repo%
echo:
echo:
ping 127.0.0.1 -n 10
)
cls

::  Check LF line ending

pushd "%~dp0"
>nul findstr /v "$" "%~nx0" && (
echo:
echo Error: Script either has LF line ending issue or an empty line at the end of the script is missing.
echo:
ping 127.0.0.1 -n 6 >nul
popd
exit /b
)
popd

::========================================================================================================================================

cls
color 07
title  IDM Activation Script %iasver%

set _args=
set _elev=
set _unattended=0

set _args=%*
for %%A in (%*) do (
if /i "%%~A"=="-el"  set _elev=1
if /i "%%~A"=="/res" set _reset=1
if /i "%%~A"=="/frz" set _freeze=1
if /i "%%~A"=="/act" set _activate=1
)

for %%A in (%_activate% %_freeze% %_reset%) do (if "%%A"=="1" set _unattended=1)

::========================================================================================================================================

set "nul1=1>nul"
set "nul2=2>nul"
set "nul6=2^>nul"
set "nul=>nul 2>&1"

set psc=powershell.exe
set winbuild=1
for /f "tokens=6 delims=[]. " %%G in ('ver') do set winbuild=%%G

set _NCS=1
if %winbuild% LSS 10586 set _NCS=0
if %winbuild% GEQ 10586 reg query "HKCU\Console" /v ForceV2 %nul2% | find /i "0x0" %nul1% && (set _NCS=0)

if %_NCS% EQU 1 (
for /F %%a in ('echo prompt $E ^| cmd') do set "esc=%%a"
set     "Red="41;97m""
set    "Gray="100;97m""
set   "Green="42;97m""
set  "_White="40;37m""
set  "_Green="40;92m""
set "_Yellow="40;93m""
) else (
set     "Red="Red" "white""
set    "Gray="Darkgray" "white""
set   "Green="DarkGreen" "white""
set  "_White="Black" "Gray""
set  "_Green="Black" "Green""
set "_Yellow="Black" "Yellow""
)

set "nceline=echo: &echo ==== ERROR ==== &echo:"
set "eline=echo: &call :_color %Red% "==== ERROR ====" &echo:"
set "line=___________________________________________________________________________________________________"
set "_buf={$W=$Host.UI.RawUI.WindowSize;$B=$Host.UI.RawUI.BufferSize;$W.Height=34;$B.Height=300;$Host.UI.RawUI.WindowSize=$W;$Host.UI.RawUI.BufferSize=$B;}"

::========================================================================================================================================

if %winbuild% LSS 7600 (
%nceline%
echo Unsupported OS version Detected [%winbuild%].
echo Project is supported only for Windows 7/8/8.1/10/11 and their Server equivalent.
goto done2
)

for %%# in (powershell.exe) do @if "%%~$PATH:#"=="" (
%nceline%
echo Unable to find powershell.exe in the system.
goto done2
)

::========================================================================================================================================

::  Fix for the special characters limitation in path name

set "_work=%~dp0"
if "%_work:~-1%"=="\" set "_work=%_work:~0,-1%"

set "_batf=%~f0"
set "_batp=%_batf:'=''%"

set _PSarg="""%~f0""" -el %_args%
set _PSarg=%_PSarg:'=''%

set "_ttemp=%userprofile%\AppData\Local\Temp"

setlocal EnableDelayedExpansion

::========================================================================================================================================

echo "!_batf!" | find /i "!_ttemp!" %nul1% && (
if /i not "!_work!"=="!_ttemp!" (
%eline%
echo Script is launched from the temp folder,
echo Most likely you are running the script directly from the archive file.
echo:
echo Extract the archive file and launch the script from the extracted folder.
goto done2
)
)

::========================================================================================================================================

::  Check PowerShell

REM :PowerShellTest: $ExecutionContext.SessionState.LanguageMode :PowerShellTest:

%psc% "$f=[io.file]::ReadAllText('!_batp!') -split ':PowerShellTest:\s*'; . ([scriptblock]::create($f[1]))" | find /i "FullLanguage" %nul1% || (
%eline%
echo PowerShell is not working. Please run:
echo Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force
echo:
goto done2
)

::========================================================================================================================================

::  Elevate script as admin and pass arguments and preventing loop

%nul1% fltmc || (
if not defined _elev %psc% "start cmd.exe -arg '/c \"!_PSarg!\"' -verb runas" && exit /b
%eline%
echo This script requires admin privileges.
echo To do so, right click on this script and select 'Run as administrator'.
goto done2
)

::========================================================================================================================================

::  Disable QuickEdit and launch from conhost.exe to avoid Terminal app

set quedit=
set terminal=

if %_unattended%==1 (
set quedit=1
set terminal=1
)

for %%# in (%_args%) do (if /i "%%#"=="-qedit" set quedit=1)

if %winbuild% LSS 10586 (
reg query HKCU\Console /v QuickEdit %nul2% | find /i "0x0" %nul1% && set quedit=1
)

if %winbuild% GEQ 17763 (
set "launchcmd=start conhost.exe %psc%"
) else (
set "launchcmd=%psc%"
)

set "d1=$t=[AppDomain]::CurrentDomain.DefineDynamicAssembly(4, 1).DefineDynamicModule(2, $False).DefineType(0);"
set "d2=$t.DefinePInvokeMethod('GetStdHandle', 'kernel32.dll', 22, 1, [IntPtr], @([Int32]), 1, 3).SetImplementationFlags(128);"
set "d3=$t.DefinePInvokeMethod('SetConsoleMode', 'kernel32.dll', 22, 1, [Boolean], @([IntPtr], [Int32]), 1, 3).SetImplementationFlags(128);"
set "d4=$k=$t.CreateType(); $b=$k::SetConsoleMode($k::GetStdHandle(-10), 0x0080);"

if defined quedit goto :skipQE
%launchcmd% "%d1% %d2% %d3% %d4% & cmd.exe '/c' '!_PSarg! -qedit'" &exit /b
:skipQE

::========================================================================================================================================

cls
title  IDM Activation Script %iasver%

echo:
echo Initializing...

::  Check WMI

%psc% "Get-WmiObject -Class Win32_ComputerSystem | Select-Object -Property CreationClassName" %nul2% | find /i "computersystem" %nul1% || (
%eline%
echo WMI is not working. Please run:
echo   net stop winmgmt /y
echo   net start winmgmt
echo:
goto done2
)

::  Check user account SID

set _sid=
for /f "delims=" %%a in ('%psc% "([System.Security.Principal.NTAccount](Get-WmiObject -Class Win32_ComputerSystem).UserName).Translate([System.Security.Principal.SecurityIdentifier]).Value" %nul6%') do (set _sid=%%a)
 
reg query HKU\%_sid%\Software %nul% || (
for /f "delims=" %%a in ('%psc% "$explorerProc = Get-Process -Name explorer | Where-Object {$_.SessionId -eq (Get-Process -Id $pid).SessionId} | Select-Object -First 1; $sid = (gwmi -Query ('Select * From Win32_Process Where ProcessID=' + $explorerProc.Id)).GetOwnerSid().Sid; $sid" %nul6%') do (set _sid=%%a)
)

reg query HKU\%_sid%\Software %nul% || (
%eline%
echo:
echo [%_sid%]
echo User Account SID not found. Aborting...
echo:
echo For help, visit: %repo%
goto done2
)

::========================================================================================================================================

::  Check if the current user SID is syncing with the HKCU entries

%nul% reg delete HKCU\IAS_TEST /f
%nul% reg delete HKU\%_sid%\IAS_TEST /f

set HKCUsync=$null
%nul% reg add HKCU\IAS_TEST
%nul% reg query HKU\%_sid%\IAS_TEST && (
set HKCUsync=1
)

%nul% reg delete HKCU\IAS_TEST /f
%nul% reg delete HKU\%_sid%\IAS_TEST /f

::  Below code also works for ARM64 Windows 10 (including x64 bit emulation)

for /f "skip=2 tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PROCESSOR_ARCHITECTURE') do set arch=%%b
if /i not "%arch%"=="x86" set arch=x64

if "%arch%"=="x86" (
set "CLSID=HKCU\Software\Classes\CLSID"
set "CLSID2=HKU\%_sid%\Software\Classes\CLSID"
set "HKLM=HKLM\Software\Internet Download Manager"
) else (
set "CLSID=HKCU\Software\Classes\Wow6432Node\CLSID"
set "CLSID2=HKU\%_sid%\Software\Classes\Wow6432Node\CLSID"
set "HKLM=HKLM\SOFTWARE\Wow6432Node\Internet Download Manager"
)

for /f "tokens=2*" %%a in ('reg query "HKU\%_sid%\Software\DownloadManager" /v ExePath %nul6%') do call set "IDMan=%%b"

if not exist "%IDMan%" (
if %arch%==x64 set "IDMan=%ProgramFiles(x86)%\Internet Download Manager\IDMan.exe"
if %arch%==x86 set "IDMan=%ProgramFiles%\Internet Download Manager\IDMan.exe"
)

::  Working folder for registry backups and IDM test downloads, with fallbacks

set "_wtemp=%SystemRoot%\Temp"
if not exist "%_wtemp%" md "%_wtemp%" %nul%
if not exist "%_wtemp%" set "_wtemp=%TEMP%"
if not exist "%_wtemp%" set "_wtemp=%_ttemp%"
if not exist "%_wtemp%" md "%_wtemp%" %nul%

::  IDM validation servers, blocked during activation and restored on reset

set "_hosts=%SystemRoot%\System32\drivers\etc\hosts"
set "_idmdom=@('tonec.com','www.tonec.com','internetdownloadmanager.com','www.internetdownloadmanager.com','secure.internetdownloadmanager.com','idmmzs.com','www.idmmzs.com','idmzs.com','www.idmzs.com')"

set "idmcheck=tasklist /fi "imagename eq idman.exe" | findstr /i "idman.exe" %nul1%"

::  Check CLSID registry access

%nul% reg add %CLSID2%\IAS_TEST
%nul% reg query %CLSID2%\IAS_TEST || (
%eline%
echo Failed to write in %CLSID2%
echo:
echo For help, visit: %repo%
goto done2
)

%nul% reg delete %CLSID2%\IAS_TEST /f

::========================================================================================================================================

if %_reset%==1 goto :_reset
if %_activate%==1 (set frz=0&goto :_activate)
if %_freeze%==1 (set frz=1&goto :_activate)

:MainMenu

cls
set "_skipprompt="
title  IDM Activation Script %iasver%
if not defined terminal mode 76, 29

::  Lightweight status line - existing lookups only, nothing new is queried.

set "_mstatus=Not installed"
if exist "%IDMan%" (
set "_mstatus=Installed, not registered"
reg query "HKU\%_sid%\Software\DownloadManager" /v Serial %nul% && set "_mstatus=Installed and registered"
)

echo:
echo   ============================================================
call :_color %_Green% "         I D M   A C T I V A T I O N   S C R I P T"
echo   ============================================================
echo    v%iasver%                      github.com/imrosyd/idm-script
echo   ------------------------------------------------------------
echo    %_mstatus%
echo   ------------------------------------------------------------
echo:
echo    ACTIVATION
echo      [1]  Activate IDM
echo      [2]  Freeze Trial Period
echo      [3]  Reset Activation / Trial
echo:
echo    TOOLS
echo      [4]  Install / Update IDM
echo      [5]  Backup Settings
echo      [6]  Restore Settings
echo:
echo    OTHER
echo      [7]  Clean Uninstall IDM
echo      [8]  Check Script Update
echo      [H]  Help / Documentation
echo      [0]  Exit
echo   ============================================================
echo    Enter your choice [1-8, H, 0]:
choice /C:12345678H0 /N
set _erl=%errorlevel%

if %_erl%==10 exit /b
if %_erl%==9 start https://github.com/imrosyd/idm-script & goto MainMenu
if %_erl%==8 goto :_check_update
if %_erl%==7 goto :_clean_uninstall
if %_erl%==6 goto :_restore_settings
if %_erl%==5 goto :_backup_settings
if %_erl%==4 goto :_install_idm
if %_erl%==3 goto _reset
if %_erl%==2 (set frz=1&goto :_activate)
if %_erl%==1 (set frz=0&goto :_activate)
goto :MainMenu

::========================================================================================================================================

:_install_idm

cls
echo:
echo   ============================================================
echo                      INSTALL / UPDATE IDM
echo   ============================================================
echo:
echo   Terminating IDM process...
taskkill /f /im idman.exe >nul 2>&1

::  The installer is served from an IDM domain that activation blocks in the
::  hosts file. Lift the block so the download can go through; activation
::  puts it back afterwards.
call :unblock_idm_hosts

echo:
echo   Downloading IDM installer from official website...
echo:

set "idm_installer=%SystemRoot%\Temp\idman_setup.exe"

:: Resolve the latest installer name from the official download page
set "idm_url="
for /f "delims=" %%a in ('%psc% "try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $p = Invoke-WebRequest -Uri 'https://www.internetdownloadmanager.com/download.html' -UseBasicParsing; $m = [regex]::Matches($p.Content, 'idman\d+build\d+\.exe'); if ($m.Count) { 'https://mirror2.internetdownloadmanager.com/' + $m[0].Value } } catch {}" %nul6%') do set "idm_url=%%a"

if not defined idm_url (
echo   Unable to detect the latest build, falling back to a known one...
set "idm_url=https://mirror2.internetdownloadmanager.com/idman642build25.exe"
)

echo   Source: !idm_url!
echo:
%psc% "try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '!idm_url!' -OutFile '%idm_installer%' -UseBasicParsing; Write-Host 'Download successful' } catch { Write-Host 'Download failed' }"

if not exist "%idm_installer%" (
echo:
echo   ERROR: Failed to download IDM installer.
echo:
echo   Please download manually from:
echo   https://www.internetdownloadmanager.com/download.html
echo:
echo   ============================================================
echo:
echo   Press any key to return to menu...
pause >nul
goto MainMenu
)

echo:
echo   Download completed successfully!
echo:
echo   Starting IDM installer...
echo:
echo   ============================================================
echo:
echo   Please follow the installation wizard.
echo   Wait until installation is finished.
echo:
echo   ============================================================

:: Run the installer
start "" /wait "%idm_installer%"

:: Cleanup
if exist "%idm_installer%" del /f /q "%idm_installer%"

echo:
echo   Installation completed!
echo   Checking activation status...

:: Check if IDM is already registered
reg query "HKCU\Software\DownloadManager" /v Serial >nul 2>&1
if %errorlevel%==0 (
echo:
echo   [OK] IDM is already registered.
echo:
echo   ============================================================
echo:
echo   Press any key to return to menu...
pause >nul
goto MainMenu
)

echo:
echo   [!] IDM is NOT registered.
echo   Auto-activating now...
echo:

:: Prompt for registration details
echo:
echo   Enter registration details:
echo:
set "user_fname=" & set "user_lname=" & set "user_email="
set /p "user_fname=   First Name: "
set /p "user_lname=   Last Name: "

set "user_fname=!user_fname:"=!"
set "user_lname=!user_lname:"=!"
if "!user_fname!"=="" set "user_fname=TRIAL"
if "!user_lname!"=="" set "user_lname=USER"
if "!user_email!"=="" set "user_email=!user_fname!.!user_lname!@gmail.com"

echo:
echo   Activating IDM...
echo:

:: Hand over to the activation routine, it ends at :done and returns to the menu.
:: _skipprompt keeps it from asking for the name a second time.
set "frz=0"
set "_skipprompt=1"
goto :_activate

::========================================================================================================================================

:_backup_settings

cls
echo:
echo   ============================================================
echo                     BACKUP IDM SETTINGS
echo   ============================================================
echo:

set "backup_dir=%userprofile%\Documents\IDM_Backup"

if not exist "%backup_dir%" mkdir "%backup_dir%"

::  A %date%-substring timestamp assumes a US-style date format and breaks
::  under other regional settings; it also only has day precision, so a
::  second backup on the same day silently overwrote the first one.
set "_bktime="
for /f "delims=" %%a in ('%psc% "(Get-Date).ToString('yyyyMMdd-HHmmss')"') do set "_bktime=%%a"
if not defined _bktime set "_bktime=%random%"
set "backup_file=%backup_dir%\idm_settings_%_bktime%.reg"

echo   Creating backup of IDM settings...
echo:

reg export "HKCU\Software\DownloadManager" "%backup_file%" /y %nul2%

if exist "%backup_file%" (
echo   Backup created successfully!
echo:
echo   Backup saved to:
echo   %backup_file%
) else (
echo   Failed to create backup.
)
echo:
echo   ============================================================
echo:
echo   Press any key to return to menu...
pause >nul
goto MainMenu

::========================================================================================================================================

:_restore_settings

cls
echo:
echo   ============================================================
echo                    RESTORE IDM SETTINGS
echo   ============================================================
echo:

set "backup_dir=%userprofile%\Documents\IDM_Backup"

if not exist "%backup_dir%\*.reg" (
echo   No backup files found in %backup_dir%
echo:
echo   Please create a backup first using option [5].
goto done
)

echo   Available backup files:
echo:
set /a count=0
for %%f in ("%backup_dir%\*.reg") do (
set /a count+=1
echo      [!count!] %%~nxf
)
echo:
set /p "restore_choice=   Enter backup number to restore (or 0 to cancel): "

::  A stray " here would unbalance the quotes in the comparison below and
::  expose the rest of the line to cmd.exe as a live command separator.
set "restore_choice=!restore_choice:"=!"

if "%restore_choice%"=="0" goto MainMenu

set "_restore_target="
set /a idx=0
for %%f in ("%backup_dir%\*.reg") do (
set /a idx+=1
if "!idx!"=="%restore_choice%" (set "_restore_target=%%f" & set "_restore_name=%%~nxf")
)

if not defined _restore_target (
echo:
call :_color %Red% "Invalid selection - no backup matches that number."
echo:
echo   ============================================================
echo:
echo   Press any key to return to menu...
pause >nul
goto MainMenu
)

echo:
call :_color %_Yellow% "This overwrites your current IDM registration with: !_restore_name!"
choice /C:YN /N /M "   Continue? [Y/N]: "
if !errorlevel!==2 goto MainMenu

echo:
echo   Restoring: !_restore_name!
reg import "!_restore_target!" %nul2%
if !errorlevel!==0 (
echo   Settings restored successfully!
) else (
echo   Failed to restore settings.
)
echo:
echo   ============================================================
echo:
echo   Press any key to return to menu...
pause >nul
goto MainMenu

::========================================================================================================================================

:_check_update

cls
echo:
echo   ============================================================
echo                   CHECK FOR SCRIPT UPDATES
echo   ============================================================
echo:
echo   Current Version: v%iasver%
echo:
echo   Checking GitHub for latest version...
echo:

:: Check latest version from GitHub
for /f "delims=" %%a in ('powershell -Command "try { $r = Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/imrosyd/idm-script/main/ias.cmd' -UseBasicParsing; $m = [regex]::Match($r.Content, '@set iasver=([0-9.]+)'); if($m.Success){$m.Groups[1].Value}else{'error'} } catch { 'error' }"') do set "latest_ver=%%a"

if "%latest_ver%"=="error" (
echo   Unable to check for updates. Check your internet connection.
goto :update_done
)

set "_newer="
for /f "delims=" %%a in ('%psc% "try { if ([version]'%latest_ver%' -gt [version]'%iasver%') { 'yes' } } catch {}" %nul6%') do set "_newer=%%a"

if not "%_newer%"=="yes" (
echo   You are using the latest version.  [local v%iasver% ^| remote v%latest_ver%]
goto :update_done
)

echo   New version available: v%latest_ver%
echo:
choice /C:YN /M "   Do you want to update now? "
if !errorlevel!==2 goto :update_done

echo:
echo   Downloading update...
set "update_file=%temp%\ias_update.cmd"
powershell -Command "try { Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/imrosyd/idm-script/main/ias.cmd' -OutFile '%update_file%' -UseBasicParsing } catch { exit 1 }"

if not exist "%update_file%" (
echo:
echo   [!] Download failed. Please try again later.
goto :update_done
)

::  A truncated or corrupted download must not overwrite a working script.
::  Check size, normalize to CRLF the same way ias.ps1 already does for its
::  own downloads (raw.githubusercontent.com's line endings are not
::  guaranteed to match what this repository has stored), then require the
::  first line to look like an IAS script before anything is installed.

for %%s in ("%update_file%") do set "_upd_size=%%~zs"
if "%_upd_size%"=="0" (
del /f /q "%update_file%" %nul2%
%eline%
echo Downloaded update file is empty. Please try again later.
goto :update_done
)

%psc% "$c = [IO.File]::ReadAllText('%update_file%') -replace '\r?\n', [Environment]::NewLine; if (-not $c.EndsWith([Environment]::NewLine)) { $c += [Environment]::NewLine }; [IO.File]::WriteAllText('%update_file%', $c, [Text.Encoding]::ASCII)" %nul%

set "_upd_ok="
for /f "delims=" %%a in ('%psc% "Get-Content -Path '%update_file%' -TotalCount 1" %nul6%') do (
echo %%a | findstr /b /i "@set @echo" %nul1% && set "_upd_ok=1"
)

if not defined _upd_ok (
del /f /q "%update_file%" %nul2%
%eline%
echo Downloaded file does not look like an IAS script. Update aborted, nothing was changed.
goto :update_done
)

echo:
echo   [OK] Download verified!
echo   [..] Installing update...
echo:

:: Create updater script. A copy of the currently running script is kept at
:: %_prev% in case the update needs to be undone by hand.
set "updater=%temp%\updater.cmd"
set "_prev=%temp%\ias_previous.cmd"
copy /y "%~f0" "%_prev%" %nul1%
(
echo @echo off
echo timeout /t 2 /nobreak ^>nul
echo move /y "%update_file%" "%~f0" ^>nul
echo start "" "%~f0"
echo del "%%~f0"
) > "%updater%"

echo   A copy of the previous script was kept at:
echo   %_prev%
echo:

:: Run updater and exit
start "" "%updater%"
exit

:update_done
echo:
echo   ============================================================
echo:
echo   Press any key to return to menu...
pause >nul
goto MainMenu

::========================================================================================================================================

:_clean_uninstall

cls
echo:
echo   ============================================================
echo                     CLEAN UNINSTALL IDM
echo   ============================================================
echo:
echo   WARNING: This will completely remove IDM and all settings!
echo:
echo   This action will:
echo      - Uninstall IDM program
echo      - Remove all registry entries
echo      - Delete IDM data folders
echo:
choice /C:YN /N /M "   Are you sure you want to continue? [Y/N]: "
if !errorlevel!==2 goto MainMenu

echo:
echo   Closing IDM...
%idmcheck% && taskkill /f /im idman.exe %nul2%

echo   Uninstalling IDM...
if exist "%ProgramFiles(x86)%\Internet Download Manager\Uninstall.exe" (
start "" /wait "%ProgramFiles(x86)%\Internet Download Manager\Uninstall.exe" /S
) else if exist "%ProgramFiles%\Internet Download Manager\Uninstall.exe" (
start "" /wait "%ProgramFiles%\Internet Download Manager\Uninstall.exe" /S
)

echo   Cleaning registry...
reg delete "HKCU\Software\DownloadManager" /f %nul2%
if not %HKCUsync%==1 reg delete "HKU\%_sid%\Software\DownloadManager" /f %nul2%
reg delete "HKLM\SOFTWARE\Internet Download Manager" /f %nul2%
reg delete "HKLM\SOFTWARE\Wow6432Node\Internet Download Manager" /f %nul2%

::  Only remove the CLSID keys IDM created. Deleting the whole CLSID branch
::  would break COM registration for every other 32-bit application. Backed
::  up first, same as Activate and Reset.
call :create_clsid_backup
echo   Removing IDM trial keys from CLSID...
call :regscan_delete

::  A full uninstall must leave the hosts file as it was found.
echo   Restoring hosts file...
call :unblock_idm_hosts

echo   Removing data folders...
if exist "%appdata%\IDM" rd /s /q "%appdata%\IDM" %nul2%

echo:
echo   IDM has been completely removed from your system.
echo:
echo   ============================================================
echo:
echo   Press any key to return to menu...
pause >nul
goto MainMenu

:_reset

cls
call :prepare_operation_ui

echo:
%idmcheck% && taskkill /f /im idman.exe

call :create_clsid_backup

call :delete_queue
call :regscan_delete

::  Reset means a clean slate, so the hosts block has to come off too.
::  Leaving it would cut IDM off from its own servers indefinitely.
call :unblock_idm_hosts

call :add_key

echo:
echo %line%
echo:
call :_color %Green% "IDM reset process completed successfully."

goto done

:delete_queue

echo:
echo Deleting IDM registry keys...
echo:

for %%# in (
""HKCU\Software\DownloadManager" "/v" "FName""
""HKCU\Software\DownloadManager" "/v" "LName""
""HKCU\Software\DownloadManager" "/v" "Email""
""HKCU\Software\DownloadManager" "/v" "Serial""
""HKCU\Software\DownloadManager" "/v" "scansk""
""HKCU\Software\DownloadManager" "/v" "tvfrdt""
""HKCU\Software\DownloadManager" "/v" "radxcnt""
""HKCU\Software\DownloadManager" "/v" "LstCheck""
""HKCU\Software\DownloadManager" "/v" "ptrk_scdt""
""HKCU\Software\DownloadManager" "/v" "LastCheckQU""
"%HKLM%"
) do for /f "tokens=* delims=" %%A in ("%%~#") do (
set "reg="%%~A"" &reg query !reg! %nul% && call :del
)

if not %HKCUsync%==1 for %%# in (
""HKU\%_sid%\Software\DownloadManager" "/v" "FName""
""HKU\%_sid%\Software\DownloadManager" "/v" "LName""
""HKU\%_sid%\Software\DownloadManager" "/v" "Email""
""HKU\%_sid%\Software\DownloadManager" "/v" "Serial""
""HKU\%_sid%\Software\DownloadManager" "/v" "scansk""
""HKU\%_sid%\Software\DownloadManager" "/v" "tvfrdt""
""HKU\%_sid%\Software\DownloadManager" "/v" "radxcnt""
""HKU\%_sid%\Software\DownloadManager" "/v" "LstCheck""
""HKU\%_sid%\Software\DownloadManager" "/v" "ptrk_scdt""
""HKU\%_sid%\Software\DownloadManager" "/v" "LastCheckQU""
) do for /f "tokens=* delims=" %%A in ("%%~#") do (
set "reg="%%~A"" &reg query !reg! %nul% && call :del
)

exit /b

:del

reg delete %reg% /f %nul%

if "%errorlevel%"=="0" (
set "reg=%reg:"=%"
echo Deleted - !reg!
) else (
set "reg=%reg:"=%"
call :_color2 %Red% "Failed - !reg!"
)

exit /b

::========================================================================================================================================

:_activate

cls
call :prepare_operation_ui

if %frz%==0 if %_unattended%==0 if not defined _skipprompt (
echo:
echo %line%
echo:
echo      Note: Activation may not work for all users. IDM might show registration prompts.
echo:
call :_color2 %_White% "     " %_Green% "Using Freeze Trial option is recommended for best results."
echo %line%
echo:
choice /C:19 /N /M ">    [1] Go Back   [9] Continue with Activation : "
if !errorlevel!==1 goto :MainMenu
cls
echo:
echo %line%
echo:
call :_color %_Green% "Enter Registration Details:"
echo:
set "user_fname=" & set "user_lname=" & set "user_email="
set /p "user_fname=First Name: "
set /p "user_lname=Last Name: "
if "!user_fname!"=="" set "user_fname=User"
if "!user_lname!"=="" set "user_lname=IDM"
if "!user_email!"=="" set "user_email=!user_fname!.!user_lname!@gmail.com"
echo:
echo %line%
echo:
echo      Registering to: !user_fname! !user_lname!
echo:
echo %line%
)

echo:
if not exist "%IDMan%" (
call :_color %Red% "IDM [Internet Download Manager] is not installed."
echo You can download it from: https://www.internetdownloadmanager.com/download.html
goto done
)

:: Connectivity check. IDM's own domains get blocked in the hosts file as part
:: of activation, so probe a neutral host instead of internetdownloadmanager.com.

set _int=
set _retry=0

:internet_check
set /a _retry+=1
for /f "delims=[] tokens=2" %%# in ('ping -n 1 github.com') do (if not [%%#]==[] set _int=1)

if not defined _int (
%psc% "$t = New-Object Net.Sockets.TcpClient;try{$t.Connect('github.com', 443)}catch{};$t.Connected" | findstr /i "true" %nul1% && set _int=1
)

if not defined _int (
if %_retry% LSS 3 (
echo:
echo Connection attempt %_retry% failed. Retrying...
:: Flush DNS cache and retry
ipconfig /flushdns %nul2%
timeout /t 2 %nul1%
goto :internet_check
)
echo:
call :_color %Red% "No internet connection after 3 attempts."
echo:
echo Please check:
echo   - Your internet connection
echo   - Firewall/antivirus settings
echo   - Try: ipconfig /flushdns
echo:
goto done
)

if %_retry% GTR 1 (
echo Connection established after %_retry% attempts.
echo:
)

for /f "skip=2 tokens=2*" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ProductName 2^>nul') do set "regwinos=%%b"
for /f "skip=2 tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PROCESSOR_ARCHITECTURE') do set "regarch=%%b"
for /f "tokens=6-7 delims=[]. " %%i in ('ver') do if "%%j"=="" (set fullbuild=%%i) else (set fullbuild=%%i.%%j)
for /f "tokens=2*" %%a in ('reg query "HKU\%_sid%\Software\DownloadManager" /v idmvers %nul6%') do set "IDMver=%%b"

echo Checking System Info - [%regwinos% ^| Build %fullbuild% ^| %regarch% ^| IDM: %IDMver%]

%idmcheck% && (echo: & taskkill /f /im idman.exe)

call :create_clsid_backup

call :delete_queue
call :add_key

::  Stop IDM from reaching its validation servers before anything else happens.
call :block_idm_hosts

::  Step 1 - delete every existing IDM CLSID key, including stale locked ones
::  left behind by an earlier run. Those block IDM from creating fresh keys,
::  which is why running activation twice in a row used to fail.
call :regscan_delete

::  Step 2 - write the serial so IDM validates it and builds fresh CLSID keys.
if %frz%==0 call :register_IDM

::  Step 3 - trigger a download so IDM actually creates those keys.
call :download_files
if not defined _fileexist (
%eline%
echo Error: IDM did not complete the download trigger.
echo:
echo For help, visit: %repo%
goto :done
)

::  Step 4 - lock the fresh keys before IDM can use them to invalidate the serial.
call :regscan_lock_toggle

::  Step 5 - final lock pass over anything created in the meantime.
call :regscan_lock

::  Re-normalize the hosts entries after IDM has run.
call :block_idm_hosts

echo:
echo %line%
echo:
if %frz%==0 (
call :_color %Green% "IDM activation process completed successfully."
echo:
call :_color %Gray% "Note: If registration prompts appear, use Freeze Trial option instead."
) else (
call :_color %Green% "IDM 30-day trial period has been frozen successfully."
echo:
call :_color %Gray% "Note: If IDM shows registration popup, try reinstalling IDM."
)

::========================================================================================================================================

:done

echo %line%
echo:
echo:
if %_unattended%==1 timeout /t 2 & exit /b

if defined terminal (
call :_color %_Yellow% "Press 0 key to return to menu..."
choice /c 0 /n
) else (
call :_color %_Yellow% "Press any key to return to menu..."
pause %nul1%
)
goto MainMenu

:done2

if %_unattended%==1 timeout /t 2 & exit /b

if defined terminal (
echo Press 0 key to exit...
choice /c 0 /n
) else (
echo Press any key to exit...
pause %nul1%
)
exit /b

::========================================================================================================================================

:_rcont

reg add %reg% %nul%
call :add
exit /b

:register_IDM

echo:
echo Applying registration details...
echo:

if not defined user_fname set "user_fname=User"
if not defined user_lname set "user_lname=IDM"
if not defined user_email set "user_email=!user_fname!.!user_lname!@gmail.com"

::  Strip the quote character before these values are embedded in a quoted
::  reg.exe argument below. cmd.exe treats &, |, etc. as literal text while
::  inside balanced quotes, but a stray " in the typed name would unbalance
::  them and expose the rest of the line to the shell. Registration fields
::  are typed by the person running the script, so this is defense in depth
::  against a stray keystroke rather than a hostile third party.
set "fname=!user_fname:"=!"
set "lname=!user_lname:"=!"
set "email=!user_email:"=!"
if "!fname!"=="" set "fname=User"
if "!lname!"=="" set "lname=IDM"
if "!email!"=="" set "email=!fname!.!lname!@gmail.com"

for /f "delims=" %%a in ('%psc% "$key = -join ((Get-Random -Count 20 -InputObject ([char[]]('ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'))));$key = ($key.Substring(0, 5) + '-' + $key.Substring(5, 5) + '-' + $key.Substring(10, 5) + '-' + $key.Substring(15, 5));Write-Output $key" %nul6%') do (set key=%%a)

echo Registering to: %fname% %lname%
echo:

set "reg=HKCU\SOFTWARE\DownloadManager /v FName /t REG_SZ /d "%fname%"" & call :_rcont
set "reg=HKCU\SOFTWARE\DownloadManager /v LName /t REG_SZ /d "%lname%"" & call :_rcont
set "reg=HKCU\SOFTWARE\DownloadManager /v Email /t REG_SZ /d "%email%"" & call :_rcont
set "reg=HKCU\SOFTWARE\DownloadManager /v Serial /t REG_SZ /d "%key%"" & call :_rcont

if not %HKCUsync%==1 (
set "reg=HKU\%_sid%\SOFTWARE\DownloadManager /v FName /t REG_SZ /d "%fname%"" & call :_rcont
set "reg=HKU\%_sid%\SOFTWARE\DownloadManager /v LName /t REG_SZ /d "%lname%"" & call :_rcont
set "reg=HKU\%_sid%\SOFTWARE\DownloadManager /v Email /t REG_SZ /d "%email%"" & call :_rcont
set "reg=HKU\%_sid%\SOFTWARE\DownloadManager /v Serial /t REG_SZ /d "%key%"" & call :_rcont
)
exit /b

:download_files

echo:
echo Triggering a download to initialize IDM CLSID registry keys...
echo:

set "file=%_wtemp%\ias_temp.png"
set _fileexist=
if exist "%file%" del /f /q "%file%"

::  Count the CLSID keys before IDM runs, so we can tell afterwards whether it
::  actually created its validation keys even if the file itself never landed.
if "%arch%"=="x86" (set "_clsid_reg=HKCU\Software\Classes\CLSID") else (set "_clsid_reg=HKCU\Software\Classes\Wow6432Node\CLSID")
set /a _base_count=0
for /f %%C in ('reg query "%_clsid_reg%" 2^>nul ^| find /c "HKEY_"') do set /a _base_count=%%C
echo Baseline CLSID key count: %_base_count%

::  IDM's own domains are blocked at this point, so pull from neutral hosts.
::  First one that works wins.
set link=https://raw.githubusercontent.com/imrosyd/idm-script/main/LICENSE
call :download
if defined _fileexist goto :dl_done

set link=https://www.google.com/favicon.ico
call :download
if defined _fileexist goto :dl_done

set link=https://github.com/favicon.ico
call :download

:dl_done

echo:
timeout /t 3 %nul1%
%idmcheck% && taskkill /f /im idman.exe
if exist "%file%" del /f /q "%file%"

set /a _new_count=0
for /f %%C in ('reg query "%_clsid_reg%" 2^>nul ^| find /c "HKEY_"') do set /a _new_count=%%C
echo CLSID key count after IDM run: %_new_count%

if %_new_count% GTR %_base_count% (
echo New CLSID keys created, activation hooks detected.
set _fileexist=1
)
exit /b

:download

set /a attempt=0
if exist "%file%" del /f /q "%file%"
start "" /B "%IDMan%" /n /d "%link%" /p "%_wtemp%" /f ias_temp.png

:check_file

timeout /t 1 %nul1%
set /a attempt+=1
if exist "%file%" set _fileexist=1&exit /b
if %attempt% GEQ 25 exit /b
goto :check_file

::========================================================================================================================================

:add_key

echo:
echo Adding registry keys...
echo:

set "reg="%HKLM%" /v "AdvIntDriverEnabled2""

reg add %reg% /t REG_DWORD /d "1" /f %nul%

:add

if "%errorlevel%"=="0" (
set "reg=%reg:"=%"
echo Added - !reg!
) else (
set "reg=%reg:"=%"
call :_color2 %Red% "Failed - !reg!"
)
exit /b

::========================================================================================================================================

:prepare_operation_ui

if not %HKCUsync%==1 (
if not defined terminal mode 153, 35
) else (
if not defined terminal mode 113, 35
)
if not defined terminal %psc% "&%_buf%" %nul%
exit /b

::========================================================================================================================================

:create_clsid_backup

set _time=
for /f %%a in ('%psc% "(Get-Date).ToString('yyyyMMdd-HHmmssfff')"') do set _time=%%a

echo:
echo Creating backup of CLSID registry keys in %_wtemp%

if not exist "%_wtemp%" md "%_wtemp%" %nul%

reg export %CLSID% "%_wtemp%\_Backup_HKCU_CLSID_%_time%.reg"
if not %HKCUsync%==1 reg export %CLSID2% "%_wtemp%\_Backup_HKU-%_sid%_CLSID_%_time%.reg"
exit /b

::========================================================================================================================================

::  The three registry scanner modes. All three run the same PowerShell block
::  stored at the end of this file, only the switches differ.

:regscan_delete

%psc% "$sid = '%_sid%'; $HKCUsync = %HKCUsync%; $lockKey = $null; $deleteKey = 1; $f=[io.file]::ReadAllText('!_batp!') -split ':regscan\:.*'; . ([scriptblock]::create($f[1]))"
exit /b

:regscan_lock_toggle

%psc% "$sid = '%_sid%'; $HKCUsync = %HKCUsync%; $lockKey = 1; $deleteKey = $null; $toggle = 1; $f=[io.file]::ReadAllText('!_batp!') -split ':regscan\:.*'; . ([scriptblock]::create($f[1]))"
exit /b

:regscan_lock

%psc% "$sid = '%_sid%'; $HKCUsync = %HKCUsync%; $lockKey = 1; $deleteKey = $null; $f=[io.file]::ReadAllText('!_batp!') -split ':regscan\:.*'; . ([scriptblock]::create($f[1]))"
exit /b

::========================================================================================================================================

::  Hosts file handling.
::
::  Activation points IDM's validation domains at 0.0.0.0 so IDM cannot phone
::  home and invalidate the serial. Every line this script writes carries a
::  "# IAS" marker, and both routines below rewrite the file line by line so
::  entries the user put there themselves are left untouched.
::
::  Reset [3] and Clean Uninstall [7] undo the block, so the change is never
::  one-way. A copy of the original file is kept in %_wtemp% before the first
::  modification of each run.

:block_idm_hosts

echo:
echo Blocking IDM validation servers in hosts file...
echo:

if not exist "%_hosts%" (
call :_color %Red% "hosts file not found - skipping"
exit /b
)

attrib -R "%_hosts%" %nul1%

if not defined _hostsbak (
set _hostsbak=1
for /f %%a in ('%psc% "(Get-Date).ToString('yyyyMMdd-HHmmssfff')"') do copy /y "%_hosts%" "%_wtemp%\_Backup_hosts_%%a.txt" %nul%
)

%psc% "$h='%_hosts%'; $t=$h+'.ias_tmp'; $d=%_idmdom%; $c=@(Get-Content -LiteralPath $h -ErrorAction SilentlyContinue); $new=@(); foreach($ln in $c){ $drop=$false; foreach($x in $d){ if($ln -match ('^\s*#?\s*0\.0\.0\.0\s+'+[regex]::Escape($x)+'(\s|$)')){ $drop=$true; break } }; if(-not $drop){ $new+=$ln } }; foreach($x in $d){ $new+=('0.0.0.0 '+$x+'  # IAS') }; Set-Content -LiteralPath $t -Value $new -Encoding ASCII -ErrorAction Stop; Move-Item -LiteralPath $t -Destination $h -Force -ErrorAction Stop" %nul%

if errorlevel 1 (
call :_color %Red% "Failed to write hosts file - is it locked by antivirus?"
exit /b
)

for %%D in (
"tonec.com"
"www.tonec.com"
"internetdownloadmanager.com"
"www.internetdownloadmanager.com"
"secure.internetdownloadmanager.com"
"idmmzs.com"
"www.idmmzs.com"
"idmzs.com"
"www.idmzs.com"
) do echo Blocked - %%~D

ipconfig /flushdns %nul%
exit /b

:unblock_idm_hosts

if not exist "%_hosts%" exit /b

attrib -R "%_hosts%" %nul1%

%psc% "$h='%_hosts%'; $t=$h+'.ias_tmp'; $d=%_idmdom%; $c=@(Get-Content -LiteralPath $h -ErrorAction SilentlyContinue); $new=@(); foreach($ln in $c){ $drop=$false; foreach($x in $d){ if($ln -match ('^\s*#?\s*0\.0\.0\.0\s+'+[regex]::Escape($x)+'(\s|$)')){ $drop=$true; break } }; if(-not $drop){ $new+=$ln } }; if($new.Count -ne $c.Count){ Set-Content -LiteralPath $t -Value $new -Encoding ASCII -ErrorAction SilentlyContinue; if(Test-Path -LiteralPath $t){ Move-Item -LiteralPath $t -Destination $h -Force -ErrorAction SilentlyContinue } }" %nul%

ipconfig /flushdns %nul%
exit /b

::========================================================================================================================================

:regscan:
$finalValues = @()

#  Privileges are adjusted once here rather than per key. Doing it inside
#  Take-Permissions meant re-creating the P/Invoke type for every single key,
#  which is where the intermittent lock failures came from.

$AssemblyBuilder = [AppDomain]::CurrentDomain.DefineDynamicAssembly(4, 1)
$ModuleBuilder = $AssemblyBuilder.DefineDynamicModule(2, $False)
$TypeBuilder = $ModuleBuilder.DefineType(0)
$TypeBuilder.DefinePInvokeMethod('RtlAdjustPrivilege', 'ntdll.dll', 'Public, Static', 1, [int], @([int], [bool], [bool], [bool].MakeByRefType()), 1, 3) | Out-Null
$PrivilegeClass = $TypeBuilder.CreateType()
9,17,18 | ForEach-Object { $PrivilegeClass::RtlAdjustPrivilege($_, $true, $false, [ref]$false) | Out-Null }

$arch = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment').PROCESSOR_ARCHITECTURE
if ($arch -eq "x86") {
  $regPaths = @("HKCU:\Software\Classes\CLSID", "Registry::HKEY_USERS\$sid\Software\Classes\CLSID")
} else {
  $regPaths = @("HKCU:\Software\Classes\WOW6432Node\CLSID", "Registry::HKEY_USERS\$sid\Software\Classes\Wow6432Node\CLSID")
}

foreach ($regPath in $regPaths) {
    if (($regPath -match "HKEY_USERS") -and ($HKCUsync -ne $null)) {
        continue
    }
	
	Write-Host
	Write-Host "Scanning registry keys in $regPath"
	Write-Host
	
    $subKeys = Get-ChildItem -Path $regPath -ErrorAction SilentlyContinue -ErrorVariable lockedKeys | Where-Object { $_.PSChildName -match '^\{[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}\}$' }

    foreach ($lockedKey in $lockedKeys) {
        $leafValue = Split-Path -Path $lockedKey.TargetObject -Leaf
        $finalValues += $leafValue
        Write-Output "$leafValue - Found locked key"
    }

    if ($subKeys -eq $null) {
	continue
	}
	
	$subKeysToExclude = "LocalServer32", "InProcServer32", "InProcHandler32"

    $filteredKeys = $subKeys | Where-Object { !($_.GetSubKeyNames() | Where-Object { $subKeysToExclude -contains $_ }) }

    foreach ($key in $filteredKeys) {
        $fullPath = $key.PSPath
        $keyValues = Get-ItemProperty -Path $fullPath -ErrorAction SilentlyContinue
        $defaultValue = $keyValues.PSObject.Properties | Where-Object { $_.Name -eq '(default)' } | Select-Object -ExpandProperty Value

        if (($defaultValue -match "^\d+$") -and ($key.SubKeyCount -eq 0)) {
            $finalValues += $($key.PSChildName)
            Write-Output "$($key.PSChildName) - Found numeric default value"
            continue
        }
        if (($defaultValue -match "\+|=") -and ($key.SubKeyCount -eq 0)) {
            $finalValues += $($key.PSChildName)
            Write-Output "$($key.PSChildName) - Found special characters in default"
            continue
        }
        $versionValue = Get-ItemProperty -Path "$fullPath\Version" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty '(default)' -ErrorAction SilentlyContinue
        if (($versionValue -match "^\d+$") -and ($key.SubKeyCount -eq 1)) {
            $finalValues += $($key.PSChildName)
            Write-Output "$($key.PSChildName) - Found version subkey"
            continue
        }
        $keyValues.PSObject.Properties | ForEach-Object {
            if ($_.Name -match "MData|Model|scansk|Therad") {
                $finalValues += $($key.PSChildName)
                Write-Output "$($key.PSChildName) - Found suspicious properties"
                continue
            }
        }
        if (($key.ValueCount -eq 0) -and ($key.SubKeyCount -eq 0)) {
            $finalValues += $($key.PSChildName)
            Write-Output "$($key.PSChildName) - Found empty key"
            continue
        }
    }
}

$finalValues = @($finalValues | Select-Object -Unique)

if ($finalValues -ne $null) {
    Write-Host
    if ($lockKey -ne $null) {
        Write-Host "Locking registry keys..."
    }
    if ($deleteKey -ne $null) {
        Write-Host "Deleting registry keys..."
    }
    Write-Host
} else {
    Write-Host "No target registry keys found."
	Exit
}

if (($finalValues.Count -gt 20) -and ($toggle -ne $null)) {
	$lockKey = $null
	$deleteKey = 1
    Write-Host "Key count exceeds threshold. Switching to delete mode..."
	Write-Host
}

function Take-Permissions {
    param($rootKey, $regKey)

    $SID = New-Object System.Security.Principal.SecurityIdentifier('S-1-5-32-544')
    $IDN = ($SID.Translate([System.Security.Principal.NTAccount])).Value
    $Admin = New-Object System.Security.Principal.NTAccount($IDN)

    $everyone = New-Object System.Security.Principal.SecurityIdentifier('S-1-1-0')
    $none = New-Object System.Security.Principal.SecurityIdentifier('S-1-0-0')

    try {
        $key = [Microsoft.Win32.Registry]::$rootKey.OpenSubKey($regkey, 'ReadWriteSubTree', 'TakeOwnership')
        if ($null -eq $key) { return }

        $acl = New-Object System.Security.AccessControl.RegistrySecurity
        $acl.SetOwner($Admin)
        $key.SetAccessControl($acl)

        $key = $key.OpenSubKey('', 'ReadWriteSubTree', 'ChangePermissions')
        $rule = New-Object System.Security.AccessControl.RegistryAccessRule($everyone, 'FullControl', 'ContainerInherit', 'None', 'Allow')
        $acl.ResetAccessRule($rule)
        $key.SetAccessControl($acl)

        if ($lockKey -ne $null) {
            $acl = New-Object System.Security.AccessControl.RegistrySecurity
            $acl.SetOwner($none)
            $key.SetAccessControl($acl)

            $key = $key.OpenSubKey('', 'ReadWriteSubTree', 'ChangePermissions')
            $rule = New-Object System.Security.AccessControl.RegistryAccessRule($everyone, 'FullControl', 'Deny')
            $acl.ResetAccessRule($rule)
            $key.SetAccessControl($acl)
        }
    } catch {
        # A key that vanishes mid-scan or is protected beyond our reach must not
        # take the whole scan down with it.
    }
}

foreach ($regPath in $regPaths) {
    if (($regPath -match "HKEY_USERS") -and ($HKCUsync -ne $null)) {
        continue
    }
    foreach ($finalValue in $finalValues) {
        $fullPath = Join-Path -Path $regPath -ChildPath $finalValue
        if ($fullPath -match 'HKCU:') {
            $rootKey = 'CurrentUser'
        } else {
            $rootKey = 'Users'
        }

        $position = $fullPath.IndexOf("\")
        $regKey = $fullPath.Substring($position + 1)

        if ($lockKey -ne $null) {
            if (-not (Test-Path -Path $fullPath -ErrorAction SilentlyContinue)) { New-Item -Path $fullPath -Force -ErrorAction SilentlyContinue | Out-Null }
            Take-Permissions $rootKey $regKey
            try {
                Remove-Item -Path $fullPath -Force -Recurse -ErrorAction Stop
                Write-Host -back 'DarkRed' -fore 'white' "Failed - $fullPath"
            }
            catch {
                Write-Host "Locked - $fullPath"
            }
        }

        if ($deleteKey -ne $null) {
            if (Test-Path -Path $fullPath) {
                Remove-Item -Path $fullPath -Force -Recurse -ErrorAction SilentlyContinue
                if (Test-Path -Path $fullPath) {
                    Take-Permissions $rootKey $regKey
                    try {
                        Remove-Item -Path $fullPath -Force -Recurse -ErrorAction Stop
                        Write-Host "Deleted - $fullPath"
                    }
                    catch {
                        Write-Host -back 'DarkRed' -fore 'white' "Failed - $fullPath"
                    }
                }
                else {
                    Write-Host "Deleted - $fullPath"
                }
            }
        }
    }
}
:regscan:

::========================================================================================================================================

:_color

if %_NCS% EQU 1 (
echo %esc%[%~1%~2%esc%[0m
) else (
%psc% write-host -back '%1' -fore '%2' '%3'
)
exit /b

:_color2

if %_NCS% EQU 1 (
echo %esc%[%~1%~2%esc%[%~3%~4%esc%[0m
) else (
%psc% write-host -back '%1' -fore '%2' '%3' -NoNewline; write-host -back '%4' -fore '%5' '%6'
)
exit /b

::========================================================================================================================================
:: Leave empty line below

