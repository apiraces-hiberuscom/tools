# update-index.ps1
# Regenera la tabla de herramientas del README.md raíz escaneando las cabeceras de metadatos
# (# Nombre, # Descripción) de todos los archivos del repositorio.
# Uso: powershell -ExecutionPolicy Bypass -File .\scripts\update-index.ps1

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$readme = Join-Path $root 'README.md'

if (-not (Test-Path -LiteralPath $readme)) {
    throw "No se encuentra $readme"
}

function Get-Meta {
    param([string]$Path, [string]$Key)
    $pattern = "(?im)^#\s*$Key\s*[:：]\s*(.+)\s*$"
    foreach ($line in Get-Content -LiteralPath $Path -TotalCount 30 -Encoding UTF8) {
        if ($line -match $pattern) {
            return $matches[1].Trim()
        }
    }
    return $null
}

$files = Get-ChildItem -LiteralPath $root -Recurse -File | Where-Object {
    $_.Name -ne 'README.md' -and
    $_.FullName -notmatch '\.git\\' -and
    $_.FullName -notmatch '\\scripts\\' -and
    $_.FullName -notmatch '\\templates\\'
} | Sort-Object FullName

$rows = foreach ($f in $files) {
    $rel = $f.FullName.Substring($root.Length + 1) -replace '\\', '/'
    $name = Get-Meta $f.FullName 'Nombre'
    $desc = Get-Meta $f.FullName 'Descripción'
    if (-not $name) { $name = $f.BaseName }
    if (-not $desc) { $desc = '' }
    "| [$name]($rel) | $desc |"
}

$table = @(
    '| Herramienta | Descripción |'
    '| --- | --- |'
) + $rows

$tableText = $table -join "`n"
$block = "<!-- INICIO-INDICE -->`n$tableText`n<!-- FIN-INDICE -->"

$content = Get-Content -LiteralPath $readme -Raw -Encoding UTF8
$start = $content.IndexOf('<!-- INICIO-INDICE -->')
$end = $content.IndexOf('<!-- FIN-INDICE -->')

if ($start -lt 0 -or $end -lt 0 -or $end -le $start) {
    throw "El README.md no contiene los marcadores <!-- INICIO-INDICE --> / <!-- FIN-INDICE -->"
}

$endIdx = $end + '<!-- FIN-INDICE -->'.Length
$newContent = $content.Substring(0, $start) + $block + $content.Substring($endIdx)

Set-Content -LiteralPath $readme -Value $newContent -Encoding UTF8
Write-Host "Indice regenerado: $($rows.Count) herramienta(s) indexada(s)."