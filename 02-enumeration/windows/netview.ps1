# Nombre: netview
# Descripción: Muestra los puertos TCP en estado LISTENING con su PID, proceso y servicio asociado.
# Tags: windows, network, netstat, tcp, listening
# Uso: powershell -ExecutionPolicy Bypass -File .\netview.ps1

netstat -ano -p tcp | Select-String "LISTENING" | ForEach-Object {
    $p = ($_ -replace '\s+', ' ').Trim().Split(' ')
    $port = ($p[1] -split ':')[-1]
    $procId = [int]$p[4]
    $proc = Get-Process -Id $procId -ErrorAction SilentlyContinue
    $services = Get-CimInstance Win32_Service -Filter "ProcessId=$procId" -ErrorAction SilentlyContinue

    [PSCustomObject]@{
        PUERTO   = $port
        PID      = $procId
        PROCESO  = $proc.ProcessName
        SERVICIO = ($services.DisplayName -join ', ')
        VERSIÓN  = if ($proc) { $proc.MainModule.FileVersionInfo.ProductVersion } else { "" }
    }
} | Format-Table -AutoSize