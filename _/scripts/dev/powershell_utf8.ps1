# Dot-source from $PROFILE so Set-Content / Out-File / Add-Content default to UTF-8, not UTF-16 LE.
# PowerShell 5.1 still uses UTF-16 for ">" / ">>" redirection - avoid those for source files; prefer PS 7 (pwsh).
$ErrorActionPreference = 'Stop'

if ($env:C35_PS_UTF8 -eq '1') { return }
$env:C35_PS_UTF8 = '1'

$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
[Console]::InputEncoding = $utf8NoBom
[Console]::OutputEncoding = $utf8NoBom
$OutputEncoding = $utf8NoBom

if ($PSVersionTable.PSVersion.Major -ge 7) {
    $PSDefaultParameterValues['Out-File:Encoding'] = 'utf8NoBOM'
    $PSDefaultParameterValues['Set-Content:Encoding'] = 'utf8NoBOM'
    $PSDefaultParameterValues['Add-Content:Encoding'] = 'utf8NoBOM'
} else {
    $PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
    $PSDefaultParameterValues['Set-Content:Encoding'] = 'utf8'
    $PSDefaultParameterValues['Add-Content:Encoding'] = 'utf8'
}