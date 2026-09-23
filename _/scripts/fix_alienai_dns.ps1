# Run as Administrator: bypass ISP DNS lock for alienai.id
# Right-click PowerShell -> Run as administrator, then:
#   & 'D:\c35\_\scripts\fix_alienai_dns.ps1'

$hostsPath = 'C:\Windows\System32\drivers\etc\hosts'
$entry = '168.110.219.43 alienai.id'
$marker = '# alienai.id ISP DNS bypass'

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error 'Run this script as Administrator.'
    exit 1
}

$content = Get-Content $hostsPath -ErrorAction Stop
if ($content -match 'alienai\.id') {
    Write-Host 'hosts already contains alienai.id - skipping'
} else {
    Add-Content -Path $hostsPath -Value "`n$marker`n$entry" -Encoding ASCII
    Write-Host "Added: $entry"
}

ipconfig /flushdns | Out-Null
Write-Host 'DNS cache flushed. Test: curl -sI https://alienai.id/'
