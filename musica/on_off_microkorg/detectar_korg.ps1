# MICROKORG XL+ -> Surge XT
# Opens Surge XT when the Korg is connected and closes it when disconnected.

$KorgID = 'USB\VID_0944&PID_0126\6&F151579&0&3'
$SurgePath = 'C:\Program Files\Surge Synth Team\Surge XT\Surge XT.exe'
$SurgeProcess = [System.IO.Path]::GetFileNameWithoutExtension($SurgePath)

# $null makes the first check handle the current device state:
# if the Korg is already connected when this monitor starts, Surge XT opens.
$WasConnected = $null

while ($true) {
    $Korg = Get-PnpDevice -PresentOnly -InstanceId $KorgID -ErrorAction SilentlyContinue
    $IsConnected = ($null -ne $Korg)

    # Korg connected / powered on
    if ($IsConnected -and $WasConnected -ne $true) {
        $Running = Get-Process -Name $SurgeProcess -ErrorAction SilentlyContinue

        if (-not $Running -and (Test-Path $SurgePath)) {
            Start-Process -FilePath $SurgePath
        }
    }

    # Korg disconnected / powered off
    if (-not $IsConnected -and $WasConnected -eq $true) {
        Get-Process -Name $SurgeProcess -ErrorAction SilentlyContinue |
            Stop-Process
    }

    $WasConnected = $IsConnected
    Start-Sleep -Seconds 2
}
