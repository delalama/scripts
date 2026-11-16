# microKORG XL+ → Surge XT (Windows)

A small PowerShell monitor for Windows. It watches for the USB connection of a Korg microKORG XL+:

- When the microKORG XL+ is connected or powered on, it opens Surge XT.
- When the microKORG XL+ is disconnected or powered off, it closes Surge XT.
- It does not launch a second Surge XT process if Surge XT is already running.
- The monitor checks the device every two seconds.

## Files

- `detectar_korg.ps1` — the PowerShell monitor.
- `README.md` — setup and usage instructions.

## Requirements

- Windows PowerShell 5.1 (included with Windows).
- The microKORG XL+ connected to the PC by USB.
- Surge XT installed.
- The Windows `Get-PnpDevice` cmdlet (available on standard modern Windows installations).

## Before using it on another PC

The script contains two machine-specific values. Check and, if necessary, change them near the top of `detectar_korg.ps1`:

### 1. microKORG USB device ID

Current value:

```powershell
$KorgID = 'USB\VID_0944&PID_0126\6&F151579&0&3'
```

To find the ID on your PC:

1. Connect and power on the microKORG XL+.
2. Open PowerShell.
3. Run:

```powershell
Get-PnpDevice -PresentOnly |
Where-Object { $_.FriendlyName -match 'KORG|microKORG' } |
Format-Table Status, FriendlyName, InstanceId -AutoSize
```

Use the `InstanceId` of the physical USB device, which begins with `USB\VID_0944&PID_0126`, not one of the `SWD\MIDISRV` or `SWD\MMDEVAPI` MIDI endpoint entries.

### 2. Surge XT executable path

Current value:

```powershell
$SurgePath = 'C:\Program Files\Surge Synth Team\Surge XT\Surge XT.exe'
```

If Surge XT is installed elsewhere, replace this with the full path to `Surge XT.exe`.

## Test it manually

1. Save `detectar_korg.ps1` in a folder, for example:

   `C:\dev\scripts on\detectar_korg.ps1`

2. Open PowerShell and run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\dev\scripts on\detectar_korg.ps1"
```

3. Turn the microKORG XL+ off and on to test the open/close behavior.
4. Stop the monitor with `Ctrl+C`.

The script runs continuously while that PowerShell process is open.

## Start it automatically when you sign in to Windows

The following commands create a Task Scheduler task for the current Windows user. Update the script path if you saved it somewhere else.

Run this in PowerShell:

```powershell
$ScriptPath = 'C:\dev\scripts on\detectar_korg.ps1'
$ScriptFolder = Split-Path -Parent $ScriptPath

$Action = New-ScheduledTaskAction `
    -Execute "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" `
    -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$ScriptPath`"" `
    -WorkingDirectory $ScriptFolder

$Trigger = New-ScheduledTaskTrigger -AtLogOn

$Principal = New-ScheduledTaskPrincipal `
    -UserId "$env:USERDOMAIN\$env:USERNAME" `
    -LogonType Interactive `
    -RunLevel Limited

$Settings = New-ScheduledTaskSettingsSet `
    -ExecutionTimeLimit ([TimeSpan]::Zero) `
    -MultipleInstances IgnoreNew

# If the task already exists, remove it before recreating it.
Unregister-ScheduledTask -TaskName 'MicroKORG Surge XT' -Confirm:$false -ErrorAction SilentlyContinue

Register-ScheduledTask `
    -TaskName 'MicroKORG Surge XT' `
    -Action $Action `
    -Trigger $Trigger `
    -Principal $Principal `
    -Settings $Settings `
    -Description 'Opens Surge XT when the microKORG XL+ is connected and closes it when disconnected.'

Start-ScheduledTask -TaskName 'MicroKORG Surge XT'
```

Check that the task is running:

```powershell
Get-ScheduledTask -TaskName 'MicroKORG Surge XT' |
Select-Object TaskName, State
```

Expected state: `Running`.

After this setup, the monitor starts automatically each time the current user signs in to Windows.

## Stop or remove the automatic task

Stop it temporarily:

```powershell
Stop-ScheduledTask -TaskName 'MicroKORG Surge XT'
```

Start it again:

```powershell
Start-ScheduledTask -TaskName 'MicroKORG Surge XT'
```

Remove the scheduled task:

```powershell
Unregister-ScheduledTask -TaskName 'MicroKORG Surge XT' -Confirm:$false
```

## Notes and limitations

- The monitor must remain running for automatic open/close behavior to work.
- The scheduled task starts at Windows sign-in, not before sign-in.
- The script closes the Surge XT process with `Stop-Process`. This is a forced process termination; unsaved changes or settings in Surge XT may be lost.
- If Surge XT was already open before the microKORG is switched on, the script leaves that instance running. When the microKORG is later switched off, the script will close Surge XT.
- The script identifies this specific microKORG USB instance. A different computer or USB setup may assign a different device instance ID.
