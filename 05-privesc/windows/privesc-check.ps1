# Nombre: privesc-check-windows
# Descripción: Enumeración de vectores de escalada de privilegios en Windows: tokens, parches, servicios con ruta no entrecomillada/reescribible y autoruns.
# Tags: windows, privesc, enumeration, service, registry
# Uso: powershell -ExecutionPolicy Bypass -File .\privesc-check.ps1

Write-Host "=== 1. PRIVILEGIOS DEL TOKEN ==="
whoami /priv

Write-Host "`n=== 2. PARCHES Y BUILD (buscar exploits) ==="
Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' | Select-Object ProductName,CurrentBuild,UBR
Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 10 HotFixID

Write-Host "`n=== 3. SERVICIOS (LocalSystem) con ruta ==="
Get-CimInstance Win32_Service | Where-Object StartName -match 'LocalSystem|SYSTEM' | Select-Object Name,StartName,PathName | Format-Table -AutoSize

Write-Host "`n=== 4. POSIBLES UNQUOTED PATHS (espacios sin comillas) ==="
Get-CimInstance Win32_Service | Where-Object {
    $_.PathName -and $_.PathName -notmatch '^"' -and $_.PathName -match '\s[^\s]+\s'
} | Select-Object Name,PathName | Format-Table -AutoSize
Write-Host "  > Revisa permisos de escritura en el binario: icacls <ruta>"
Write-Host "  > Recuerda: acceso de escritura al directorio + servicio LocalSystem = RCE como SYSTEM"

Write-Host "`n=== 5. AUTORUNS / STARTUP ==="
Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run','HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'

Write-Host "`n=== 6. ALWAYS INSTALL ELEVATED (MSI como admin) ==="
(Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Installer' -ErrorAction SilentlyContinue).AlwaysInstallElevated
(Get-ItemProperty 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Installer' -ErrorAction SilentlyContinue).AlwaysInstallElevated