#requires -RunAsAdministrator

$ErrorActionPreference = "SilentlyContinue"

# ============================================================
# AUDITORÍA DE SEGURIDAD DE WINDOWS
# Solo lectura. No elimina, bloquea ni modifica nada.
# ============================================================

$StartTime = Get-Date
$Computer = $env:COMPUTERNAME
$ReportPath = "$env:USERPROFILE\Desktop\Auditoria-Windows-$($Computer)-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"

$Findings = @()
$Warnings = @()
$Info = @()

function Add-Finding {
    param(
        [string]$Severity,
        [string]$Category,
        [string]$Title,
        [string]$Details,
        [string]$Recommendation
    )

    $script:Findings += [PSCustomObject]@{
        Severity       = $Severity
        Category       = $Category
        Title          = $Title
        Details        = $Details
        Recommendation = $Recommendation
    }
}

function Section {
    param([string]$Name)

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host " $Name" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
}

# Cache para no repetir consultas de IPs
$script:IPCache = @{}

function Get-IPInfo {
    param([string]$IPAddress)

    if ($script:IPCache.ContainsKey($IPAddress)) {
        return $script:IPCache[$IPAddress]
    }

    try {
        $Response = Invoke-RestMethod -Uri "http://ip-api.com/json/$IPAddress" -TimeoutSec 3
        $Info = [PSCustomObject]@{
            IP       = $IPAddress
            ISP      = $Response.isp
            Org      = $Response.org
            AS       = $Response.as
            Country  = $Response.country
            City     = $Response.city
            Proxy    = $Response.proxy
            Hosting  = $Response.hosting
            Status   = $Response.status
        }
    } catch {
        $Info = [PSCustomObject]@{
            IP       = $IPAddress
            ISP      = "No disponible"
            Org      = "No disponible"
            AS       = "No disponible"
            Country  = "No disponible"
            City     = "No disponible"
            Proxy    = $false
            Hosting  = $false
            Status   = "error"
        }
    }

    $script:IPCache[$IPAddress] = $Info
    return $Info
}

function Get-ProcessDetails {
    param([int]$PID)

    $Result = [PSCustomObject]@{
        CommandLine    = "No disponible"
        ParentName    = "No disponible"
        ParentPID     = 0
        Signature     = "No disponible"
        SignatureOK   = $false
        StartTime     = "No disponible"
    }

    try {
        $ProcInfo = Get-CimInstance Win32_Process -Filter "ProcessId=$PID"
        if ($ProcInfo) {
            $Result.CommandLine = $ProcInfo.CommandLine
            $Result.ParentPID = $ProcInfo.ParentProcessId

            $ParentProc = Get-Process -Id $ProcInfo.ParentProcessId -ErrorAction SilentlyContinue
            if ($ParentProc) {
                $Result.ParentName = "$($ParentProc.ProcessName) (PID $($ProcInfo.ParentProcessId))"
            }
        }

        $Process = Get-Process -Id $PID -ErrorAction SilentlyContinue
        if ($Process) {
            $Result.StartTime = $Process.StartTime
        }

        $Path = $ProcInfo.ExecutablePath
        if ($Path -and (Test-Path $Path)) {
            $Sig = Get-AuthenticodeSignature -FilePath $Path
            $Result.Signature = "$($Sig.Status) ($($Sig.SignerCertificate.Subject))"
            $Result.SignatureOK = $Sig.Status -eq "Valid"
        }
    } catch {
        # Silently continue
    }

    return $Result
}

# ============================================================
# INFORMACIÓN BÁSICA
# ============================================================

Section "INFORMACIÓN DEL EQUIPO"

$OS = Get-CimInstance Win32_OperatingSystem
$ComputerSystem = Get-CimInstance Win32_ComputerSystem

Write-Host "Equipo: $Computer"
Write-Host "Usuario: $env:USERNAME"
Write-Host "Windows: $($OS.Caption)"
Write-Host "Versión: $($OS.Version)"
Write-Host "Arquitectura: $($OS.OSArchitecture)"
Write-Host "Fabricante: $($ComputerSystem.Manufacturer)"
Write-Host "Modelo: $($ComputerSystem.Model)"

# ============================================================
# WINDOWS DEFENDER
# ============================================================

Section "WINDOWS DEFENDER"

$Defender = Get-MpComputerStatus

if ($Defender) {
    Write-Host "Antivirus activo: $($Defender.AntivirusEnabled)"
    Write-Host "Protección tiempo real: $($Defender.RealTimeProtectionEnabled)"
    Write-Host "Protección comportamiento: $($Defender.BehaviorMonitorEnabled)"
    Write-Host "Firmas: $($Defender.AntivirusSignatureVersion)"
    Write-Host "Última actualización: $($Defender.AntivirusSignatureLastUpdated)"

    if (-not $Defender.AntivirusEnabled) {
        Add-Finding `
            "HIGH" `
            "DEFENDER" `
            "Windows Defender está desactivado" `
            "El antivirus integrado de Windows aparece desactivado. Si no utilizas otro antivirus, esto reduce considerablemente la protección." `
            "Comprueba si existe otro antivirus instalado. Si no existe, activa Microsoft Defender."
    }

    if (-not $Defender.RealTimeProtectionEnabled) {
        Add-Finding `
            "HIGH" `
            "DEFENDER" `
            "Protección en tiempo real desactivada" `
            "Microsoft Defender no está realizando protección en tiempo real." `
            "Comprueba por qué está desactivada. No la habilites automáticamente si existe un antivirus corporativo gestionando el equipo."
    }

    $Threats = Get-MpThreat
    if ($Threats) {
        foreach ($Threat in $Threats) {
            $ThreatName = $Threat.ThreatName
            $Severity = $Threat.ThreatStatusDefaultAction

            Add-Finding `
                "CRITICAL" `
                "DEFENDER" `
                "Microsoft Defender ha registrado una amenaza" `
                "Nombre detectado: $ThreatName. Estado/acción registrada por Defender: $Severity." `
                "Revisa el historial de protección de Windows Defender y determina si la amenaza fue eliminada o permanece activa."
        }
    }
}

# ============================================================
# USUARIOS
# ============================================================

Section "USUARIOS Y SESIONES"

$Users = Get-LocalUser

foreach ($User in $Users) {
    Write-Host "$($User.Name) | Activa=$($User.Enabled) | Último inicio=$($User.LastLogon)"
}

$AdminMembers = Get-LocalGroupMember -Group "Administrators"

foreach ($Admin in $AdminMembers) {
    $AdminName = $Admin.Name

    if ($AdminName -notmatch "Administrator|Administrador|WDAGUtilityAccount") {
        Add-Finding `
            "INFO" `
            "USUARIOS" `
            "Cuenta con privilegios administrativos" `
            "La cuenta '$AdminName' pertenece al grupo Administrators. Esto no significa que sea maliciosa, pero una cuenta administrativa desconocida merece revisión." `
            "Comprueba que reconoces la cuenta y que realmente necesita privilegios administrativos."
    }
}

$Sessions = quser 2>$null

if ($Sessions) {
    Write-Host ""
    Write-Host "Sesiones actualmente conectadas:"
    $Sessions | ForEach-Object { Write-Host $_ }

    $NonConsoleSessions = $Sessions | Select-String "rdp-tcp"
    if ($NonConsoleSessions) {
        Add-Finding `
            "HIGH" `
            "RDP" `
            "Existe una sesión de Escritorio Remoto" `
            "Se ha detectado una sesión RDP activa. Esto puede ser completamente legítimo, pero si no utilizas Escritorio Remoto debes investigarlo." `
            "Comprueba quién inició la sesión y revisa los eventos de seguridad de Windows."
    }
}

# ============================================================
# RDP
# ============================================================

Section "ESCRITORIO REMOTO"

$RDP = Get-ItemProperty `
    "HKLM:\System\CurrentControlSet\Control\Terminal Server" `
    -Name fDenyTSConnections

if ($RDP.fDenyTSConnections -eq 0) {
    Add-Finding `
        "MEDIUM" `
        "RDP" `
        "Escritorio Remoto está habilitado" `
        "Windows permite conexiones RDP entrantes. Esto no implica una infección, pero aumenta la superficie de ataque." `
        "Si no utilizas Escritorio Remoto, considera deshabilitarlo."

    Write-Host "RDP: HABILITADO"
} else {
    Write-Host "RDP: DESHABILITADO"
}

# ============================================================
# CONEXIONES DE RED
# ============================================================

Section "CONEXIONES DE RED"

# Procesos legítimos conocidos que normalmente tienen conexiones externas
$KnownProcesses = @(
    "chrome", "msedge", "firefox", "opera", "brave", "vivaldi", "waterfox",
    "outlook", "teams", "onedrive", "msedge", "lync", "skype",
    "spotify", "discord", "slack", "zoom", "telegram", "whatsapp",
    "steam", "epicgameslauncher", "gog",
    "svchost", "lsass", "services", "spoolsv", "csrss", "smss", "wininit",
    "explorer", "SearchHost", "SearchApp", "MsMpEng", "SecurityHealthService",
    "RuntimeBroker", "dllhost", "conhost", "StartMenuExperienceHost",
    "PhoneExperienceHost", "TextInputHost", "ShellExperienceHost",
    "NisSrv", "WmiPrvSE", "TrustedInstaller", "TiWorker"
)

# ASNs de proveedores cloud/conocidos (se verifican contra el campo 'as' de ip-api.com)
$KnownCloudAS = @(
    "Microsoft", "Google", "Amazon", "Cloudflare", "Akamai", "Fastly",
    "Meta", "Apple", "Oracle", "DigitalOcean", "OVH", "Hetzner"
)

$Connections = Get-NetTCPConnection -State Established
$ConnectionCount = 0

foreach ($Connection in $Connections) {
    $RemoteIP = $Connection.RemoteAddress
    $RemotePort = $Connection.RemotePort
    $PID = $Connection.OwningProcess

    # Saltar IPs privadas y loopback
    if (
        $RemoteIP -eq "127.0.0.1" -or
        $RemoteIP -eq "::1" -or
        $RemoteIP -like "192.168.*" -or
        $RemoteIP -like "10.*" -or
        $RemoteIP -like "172.16.*" -or
        $RemoteIP -like "172.17.*" -or
        $RemoteIP -like "172.18.*" -or
        $RemoteIP -like "172.19.*" -or
        $RemoteIP -like "172.2*" -or
        $RemoteIP -like "172.3*"
    ) {
        continue
    }

    $ConnectionCount++
    $Process = Get-Process -Id $PID -ErrorAction SilentlyContinue

    if (-not $Process) {
        continue
    }

    $ProcessName = $Process.ProcessName

    # Obtener detalles completos del proceso
    $ProcDetails = Get-ProcessDetails -PID $PID
    $Path = (Get-CimInstance Win32_Process -Filter "ProcessId=$PID" -ErrorAction SilentlyContinue).ExecutablePath

    # Consultar IP externa
    $IPOutput = Get-IPInfo -IPAddress $RemoteIP

    # --- SALIDA DETALLADA ---
    Write-Host ""
    Write-Host "----- Conexión #$ConnectionCount -----" -ForegroundColor White
    Write-Host "Proceso:    $ProcessName (PID $PID)"
    Write-Host "Ruta:       $Path"
    Write-Host "Remoto:     $RemoteIP`:$RemotePort"
    Write-Host "Inicio:     $($ProcDetails.StartTime)"
    Write-Host "Padre:      $($ProcDetails.ParentName)"
    Write-Host "Comando:    $($ProcDetails.CommandLine)"
    Write-Host "Firma:      $($ProcDetails.Signature)"
    Write-Host "IP Info:    ISP=$($IPOutput.ISP) | Org=$($IPOutput.Org) | $($IPOutput.AS)"
    Write-Host "Ubicación:  $($IPOutput.City), $($IPOutput.Country)"

    # Indicadores de riesgo de la IP
    $IPOptions = @()
    if ($IPOutput.Proxy) { $IPOptions += "PROXY/VPN" }
    if ($IPOutput.Hosting) { $IPOptions += "DATACENTER/HOSTING" }
    if ($IPOptions.Count -gt 0) {
        Write-Host "IP Flags:   $($IPOptions -join ', ')" -ForegroundColor Yellow
    }

    # --- CLASIFICACIÓN ---

    # 1. Verificar si es un proveedor cloud conocido
    $IsKnownCloud = $false
    foreach ($AS in $KnownCloudAS) {
        if ($IPOutput.AS -match $AS -or $IPOutput.Org -match $AS) {
            $IsKnownCloud = $true
            break
        }
    }

    # 2. Verificar si el proceso es conocido Y ejecuta desde System32 con firma válida
    $IsKnownProcess = $ProcessName -in $KnownProcesses
    $RunsFromSystem32 = $Path -and ($Path -match "C:\\Windows\\System32\\")
    $HasValidSignature = $ProcDetails.SignatureOK

    # 3. Detectar comandos sospechosos en la línea de comandos
    $CommandLine = $ProcDetails.CommandLine
    $SuspiciousCommand = $false
    $SuspiciousIndicators = @()

    if ($CommandLine -match "IEX|Invoke-Expression") {
        $SuspiciousIndicators += "Invoke-Expression"
        $SuspiciousCommand = $true
    }
    if ($CommandLine -match "New-Object\s+Net\.WebClient|DownloadString|DownloadFile|Invoke-WebRequest|Invoke-RestMethod") {
        $SuspiciousIndicators += "Descarga externa"
        $SuspiciousCommand = $true
    }
    if ($CommandLine -match "-enc\s|EncodedCommand|-e\s") {
        $SuspiciousIndicators += "Comando codificado (Base64)"
        $SuspiciousCommand = $true
    }
    if ($CommandLine -match "FromBase64String") {
        $SuspiciousIndicators += "Decodificación Base64"
        $SuspiciousCommand = $true
    }
    if ($CommandLine -match "Set-MpPreference.*-DisableRealtimeMonitoring") {
        $SuspiciousIndicators += "Desactivar Defender"
        $SuspiciousCommand = $true
    }
    if ($CommandLine -match "Add-MpPreference.*-ExclusionPath") {
        $SuspiciousIndicators += "Excluir ruta de Defender"
        $SuspiciousCommand = $true
    }

    # --- EVALUACIÓN FINAL ---

    if ($IsKnownCloud -and $IsKnownProcess) {
        # Proveedor conocido + proceso conocido = probablemente legítimo
        Write-Host "Clasificación: Legítimo (proveedor conocido + proceso habitual)" -ForegroundColor Green

    } elseif ($IsKnownProcess -and $RunsFromSystem32 -and $HasValidSignature) {
        # Proceso conocido desde System32 con firma válida
        Write-Host "Clasificación: Legítimo (sistema verificado)" -ForegroundColor Green

    } elseif ($SuspiciousCommand) {
        # Comandos sospechosos detectados → siempre alertar
        Write-Host "Clasificación: SOSPECHOSO (comandos inusuales detectados)" -ForegroundColor Red
        Add-Finding `
            "HIGH" `
            "RED/C2" `
            "Conexión con comandos sospechosos" `
            "Proceso: $ProcessName (PID $PID). Conexión a $RemoteIP`:$RemotePort. Ruta: $Path. Comando: $CommandLine. Indicadores: $($SuspiciousIndicators -join ', '). ISP: $($IPOutput.ISP). $($IPOutput.AS)." `
            "Investiga de inmediato. Los indicadores detectados son consistentes con comportamiento de C2/descarga de payloads."

    } elseif ($IPOutput.Proxy -or $IPOutput.Hosting) {
        # IP es proxy/VPN/datacenter con proceso no totalmente conocido
        Write-Host "Clasificación: REVISAR (conexión a datacenter/proxy)" -ForegroundColor Yellow
        Add-Finding `
            "MEDIUM" `
            "RED" `
            "Conexión a IP de datacenter o proxy" `
            "Proceso: $ProcessName (PID $PID). Conexión a $RemoteIP`:$RemotePort. IP clasificada como $($IPOptions -join ' '). ISP: $($IPOutput.ISP). Ruta: $Path. Comando: $CommandLine." `
            "Las conexiones a datacenters/proxies pueden ser legítimas (VPN, servicios cloud) o indicar exfiltración/C2. Comprueba si la aplicación necesita esta conexión."

    } elseif (-not $IsKnownProcess -and -not $HasValidSignature) {
        # Proceso desconocido sin firma
        Write-Host "Clasificación: REVISAR (proceso desconocido sin firma)" -ForegroundColor Yellow
        Add-Finding `
            "MEDIUM" `
            "RED" `
            "Proceso desconocido con conexión externa" `
            "Proceso: $ProcessName (PID $PID). Conexión a $RemoteIP`:$RemotePort. Ruta: $Path. Firma: $($ProcDetails.Signature). ISP: $($IPOutput.ISP). Comando: $CommandLine." `
            "El proceso no está en la lista de conocidos y no tiene firma digital válida. Identifica qué aplicación lo instaló."

    } elseif ($Path -and ($Path -match "\\AppData\\" -or $Path -match "\\Temp\\" -or $Path -match "\\Downloads\\")) {
        # Proceso desde ubicación sensible
        Write-Host "Clasificación: REVISAR (ejecutable en ubicación sensible)" -ForegroundColor Yellow
        Add-Finding `
            "MEDIUM" `
            "RED/PERSISTENCIA" `
            "Proceso conectado desde ubicación sensible" `
            "Proceso: $ProcessName (PID $PID). Conexión a $RemoteIP`:$RemotePort. Ruta: $Path. ISP: $($IPOutput.ISP). Comando: $CommandLine." `
            "Comprueba la firma digital del archivo y determina qué aplicación lo instaló."

    } else {
        Write-Host "Clasificación: Bajo riesgo (proceso habitual o firma válida)" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "Total conexiones externas analizadas: $ConnectionCount"

# ============================================================
# PUERTOS ESCUCHANDO
# ============================================================

Section "PUERTOS ESCUCHANDO"

$Listeners = Get-NetTCPConnection -State Listen

foreach ($Listener in $Listeners) {
    $Port = $Listener.LocalPort
    $PID = $Listener.OwningProcess
    $Process = Get-Process -Id $PID

    if ($Process) {
        $ProcessName = $Process.ProcessName
        Write-Host "$($Listener.LocalAddress):$Port -> $ProcessName (PID $PID)"

        if ($Port -eq 3389) {
            Add-Finding `
                "MEDIUM" `
                "RED/RDP" `
                "Puerto RDP escuchando" `
                "El proceso '$ProcessName' (PID $PID) está escuchando en el puerto 3389, utilizado normalmente por Escritorio Remoto." `
                "Si no utilizas RDP, investiga por qué está activo."
        }

        if ($Port -in @(4444, 5555, 6666, 1337)) {
            Add-Finding `
                "HIGH" `
                "RED" `
                "Puerto potencialmente sospechoso escuchando" `
                "El proceso '$ProcessName' (PID $PID) está escuchando en el puerto $Port. Estos puertos pueden tener usos legítimos, por lo que el puerto por sí solo NO confirma una infección." `
                "Identifica el proceso y verifica qué aplicación lo instaló."
        }
    }
}

# ============================================================
# PROCESOS DESDE UBICACIONES SOSPECHOSAS
# ============================================================

Section "PROCESOS Y EJECUTABLES"

$Processes = Get-CimInstance Win32_Process

foreach ($Proc in $Processes) {
    $Path = $Proc.ExecutablePath

    if (-not $Path) {
        continue
    }

    if (
        $Path -match "\\AppData\\Roaming\\" -or
        $Path -match "\\AppData\\Local\\Temp\\" -or
        $Path -match "\\Windows\\Temp\\" -or
        $Path -match "\\Downloads\\"
    ) {
        $Name = $Proc.Name

        Add-Finding `
            "MEDIUM" `
            "PROCESOS" `
            "Ejecutable ejecutándose desde una ubicación sensible" `
            "Proceso: $Name. PID: $($Proc.ProcessId). Ruta: $Path. Estas ubicaciones pueden ser utilizadas por aplicaciones legítimas, instaladores y actualizadores, pero también son comunes en malware." `
            "Comprueba la firma digital y la fecha del archivo. Si no reconoces el programa, investiga antes de ejecutarlo."
    }
}

# ============================================================
# INICIO AUTOMÁTICO
# ============================================================

Section "PROGRAMAS DE INICIO"

$Startup = Get-CimInstance Win32_StartupCommand

foreach ($Item in $Startup) {
    Write-Host ""
    Write-Host "Nombre: $($Item.Name)"
    Write-Host "Usuario: $($Item.User)"
    Write-Host "Comando: $($Item.Command)"

    if (
        $Item.Command -match "\\AppData\\" -or
        $Item.Command -match "\\Temp\\" -or
        $Item.Command -match "powershell.*-enc" -or
        $Item.Command -match "wscript" -or
        $Item.Command -match "cscript"
    ) {
        Add-Finding `
            "HIGH" `
            "PERSISTENCIA" `
            "Programa de inicio potencialmente sospechoso" `
            "Nombre: $($Item.Name). Usuario: $($Item.User). Comando: $($Item.Command)" `
            "Investiga el programa y comprueba si fue instalado intencionadamente."
    }
}

# ============================================================
# TAREAS PROGRAMADAS
# ============================================================

Section "TAREAS PROGRAMADAS"

$Tasks = Get-ScheduledTask

foreach ($Task in $Tasks) {
    $Actions = $Task.Actions | Out-String

    if (
        $Actions -match "AppData" -or
        $Actions -match "\\Temp\\" -or
        $Actions -match "powershell.*-enc" -or
        $Actions -match "wscript" -or
        $Actions -match "cscript"
    ) {
        Add-Finding `
            "HIGH" `
            "PERSISTENCIA" `
            "Tarea programada potencialmente sospechosa" `
            "Tarea: $($Task.TaskName). Ruta: $($Task.TaskPath). Acción: $Actions" `
            "Comprueba si la tarea pertenece a un programa legítimo instalado por ti o por Windows."
    }
}

# ============================================================
# SERVICIOS
# ============================================================

Section "SERVICIOS"

$Services = Get-CimInstance Win32_Service | Where-Object { $_.State -eq "Running" }

foreach ($Service in $Services) {
    $Path = $Service.PathName

    if (
        $Path -match "\\AppData\\" -or
        $Path -match "\\Temp\\" -or
        $Path -match "\\Downloads\\"
    ) {
        Add-Finding `
            "HIGH" `
            "PERSISTENCIA" `
            "Servicio ejecutándose desde una ubicación sensible" `
            "Servicio: $($Service.Name). DisplayName: $($Service.DisplayName). Ruta: $Path" `
            "Comprueba la firma digital y qué software instaló este servicio."
    }
}

# ============================================================
# ARCHIVO HOSTS
# ============================================================

Section "ARCHIVO HOSTS"

$HostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"

if (Test-Path $HostsPath) {
    $HostLines = Get-Content $HostsPath | Where-Object {
        $_ -and
        $_ -notmatch "^\s*#" -and
        $_ -notmatch "^\s*127\.0\.0\.1\s+localhost" -and
        $_ -notmatch "^\s*::1\s+localhost"
    }

    foreach ($Line in $HostLines) {
        Add-Finding `
            "MEDIUM" `
            "RED" `
            "Entrada personalizada en HOSTS" `
            "Se ha encontrado una entrada no estándar en $HostsPath : $Line" `
            "Comprueba si esa modificación fue realizada intencionadamente. Malware y software legítimo pueden modificar HOSTS."
    }
}

# ============================================================
# DNS
# ============================================================

Section "DNS"

$DNS = Get-DnsClientServerAddress | Where-Object { $_.ServerAddresses }

foreach ($Adapter in $DNS) {
    Write-Host "$($Adapter.InterfaceAlias): $($Adapter.ServerAddresses -join ', ')"
}

# ============================================================
# RESULTADO
# ============================================================

$Critical = @($Findings | Where-Object Severity -eq "CRITICAL").Count
$High = @($Findings | Where-Object Severity -eq "HIGH").Count
$Medium = @($Findings | Where-Object Severity -eq "MEDIUM").Count
$Info = @($Findings | Where-Object Severity -eq "INFO").Count

if ($Critical -gt 0) {
    $Status = "INFECTADO"
    $StatusColor = "Red"
} elseif ($High -ge 2) {
    $Status = "SOSPECHOSO"
    $StatusColor = "Yellow"
} elseif ($High -eq 1 -or $Medium -ge 3) {
    $Status = "SOSPECHOSO"
    $StatusColor = "Yellow"
} else {
    $Status = "LIMPIO"
    $StatusColor = "Green"
}

Section "RESULTADO FINAL"

Write-Host ""
Write-Host " $Status" -ForegroundColor $StatusColor
Write-Host ""
Write-Host "Indicadores críticos: $Critical"
Write-Host "Indicadores altos: $High"
Write-Host "Indicadores medios: $Medium"
Write-Host "Información: $Info"

# ============================================================
# MOTIVOS
# ============================================================

if ($Findings.Count -gt 0) {
    Write-Host ""
    Write-Host "MOTIVOS / HALLAZGOS" -ForegroundColor Cyan

    $Number = 1
    foreach ($Finding in $Findings) {
        Write-Host ""
        Write-Host "[$Number] [$($Finding.Severity)] $($Finding.Title)" -ForegroundColor Yellow
        Write-Host "Categoría: $($Finding.Category)"
        Write-Host ""
        Write-Host "Qué se encontró:"
        Write-Host "$($Finding.Details)"
        Write-Host ""
        Write-Host "Qué comprobar:"
        Write-Host "$($Finding.Recommendation)"
        $Number++
    }
} else {
    Write-Host ""
    Write-Host "No se han encontrado indicadores relevantes." -ForegroundColor Green
}

# ============================================================
# GUARDAR INFORME
# ============================================================

$Report = @()
$Report += "============================================================"
$Report += " AUDITORÍA DE SEGURIDAD DE WINDOWS"
$Report += "============================================================"
$Report += ""
$Report += "Equipo: $Computer"
$Report += "Usuario: $env:USERNAME"
$Report += "Fecha: $(Get-Date)"
$Report += ""
$Report += "RESULTADO: $Status"
$Report += ""
$Report += "Críticos: $Critical"
$Report += "Altos: $High"
$Report += "Medios: $Medium"
$Report += "Info: $Info"
$Report += ""
$Report += "============================================================"
$Report += " HALLAZGOS"
$Report += "============================================================"

$Number = 1
foreach ($Finding in $Findings) {
    $Report += ""
    $Report += "[$Number] [$($Finding.Severity)] $($Finding.Title)"
    $Report += "Categoría: $($Finding.Category)"
    $Report += ""
    $Report += "Qué se encontró:"
    $Report += $Finding.Details
    $Report += ""
    $Report += "Qué comprobar:"
    $Report += $Finding.Recommendation
    $Number++
}

$Report | Out-File -FilePath $ReportPath -Encoding UTF8

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " INFORME GUARDADO" -ForegroundColor Cyan
Write-Host "============================================================"
Write-Host ""
Write-Host $ReportPath
Write-Host ""
Write-Host "Auditoría terminada."