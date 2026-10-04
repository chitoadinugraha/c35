# Sync marketing HTML from locales/en.json and locales/id.json (UTF-8, no BOM).
# Run after changing clients/web/locales/*.json or index.html / status.html templates.
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
)

$ErrorActionPreference = 'Stop'
$web = Join-Path $RepoRoot 'clients\web'
$locales = Join-Path $web 'locales'

function Read-JsonDict([string]$path) {
    $raw = [IO.File]::ReadAllText($path, [Text.UTF8Encoding]::new($false))
    return ($raw | ConvertFrom-Json)
}

function HtmlEncodeText([string]$s) {
    if ($null -eq $s) { return '' }
    return [System.Net.WebUtility]::HtmlEncode($s)
}

function Set-I18nInnerText([string]$html, [string]$key, [string]$text) {
    $enc = HtmlEncodeText($text)
    $keyEsc = [regex]::Escape($key)
    if ($html -notmatch "data-i18n=`"$keyEsc`"") { return $html }
    $rx = [regex]::new("(?s)(<(\w+)\b[^>]*\bdata-i18n=`"$keyEsc`"[^>]*>)(.*?)(</\2>)")
    if (-not $rx.IsMatch($html)) { return $html }
    return $rx.Replace($html, "`${1}$enc`${4}", 1)
}

function Apply-LocaleDict([string]$html, $dict, [string[]]$prefixSkip) {
    $out = $html
    foreach ($prop in $dict.PSObject.Properties) {
        if ($prop.Name.StartsWith('seo.')) { continue }
        $skipKey = $false
        foreach ($pfx in $prefixSkip) {
            if ($prop.Name.StartsWith($pfx)) { $skipKey = $true; break }
        }
        if ($skipKey) { continue }
        $out = Set-I18nInnerText $out $prop.Name ([string]$prop.Value)
    }
    return $out
}

function Inject-SeoHead(
    [string]$html,
    $dict,
    [string]$lang,
    [string]$canonical,
    [string]$hreflangEn,
    [string]$hreflangId
) {
    $title = HtmlEncodeText([string]$dict.'seo.title')
    $desc = HtmlEncodeText([string]$dict.'seo.description')
    $keywords = HtmlEncodeText([string]$dict.'seo.keywords')
    $ogTitle = HtmlEncodeText([string]$dict.'seo.ogTitle')
    $ogDesc = HtmlEncodeText([string]$dict.'seo.ogDescription')
    $jsonLd = ([string]$dict.'seo.jsonLdDescription') -replace '\\', '\\\\' -replace '"', '\"'
    $ogLocale = if ($lang -eq 'id') { 'id_ID' } else { 'en_US' }
    $ogLocaleAlt = if ($lang -eq 'id') { 'en_US' } else { 'id_ID' }

    $html = $html -replace '<html lang="[^"]*"', "<html lang=`"$lang`""
    $html = $html -replace 'data-site-locale="[^"]*"', "data-site-locale=`"$lang`""

    $html = $html -replace '<title>[^<]*</title>', "<title>$title</title>"
    $html = $html -replace '<meta name="title" content="[^"]*">', "<meta name=`"title`" content=`"$title`">"
    $html = $html -replace '<meta name="description" content="[^"]*">', "<meta name=`"description`" content=`"$desc`">"
    $html = $html -replace '<meta name="keywords" content="[^"]*">', "<meta name=`"keywords`" content=`"$keywords`">"
    $html = $html -replace '<link rel="canonical" href="[^"]*">', "<link rel=`"canonical`" href=`"$canonical`">"

    $hrefBlock = @"
  <link rel="alternate" hreflang="en" href="$hreflangEn">
  <link rel="alternate" hreflang="id" href="$hreflangId">
  <link rel="alternate" hreflang="x-default" href="$hreflangEn">
"@
    if ($html -match '<!-- hreflang:begin -->') {
        $html = [regex]::Replace(
            $html,
            '(?s)<!-- hreflang:begin -->.*?<!-- hreflang:end -->',
            "<!-- hreflang:begin -->`n$hrefBlock  <!-- hreflang:end -->"
        )
    }

    $html = $html -replace '<meta property="og:url" content="[^"]*">', "<meta property=`"og:url`" content=`"$canonical`">"
    $html = $html -replace '<meta property="og:title" content="[^"]*">', "<meta property=`"og:title`" content=`"$ogTitle`">"
    $html = $html -replace '<meta property="og:description" content="[^"]*">', "<meta property=`"og:description`" content=`"$ogDesc`">"
    $html = $html -replace '<meta property="og:locale" content="[^"]*">', "<meta property=`"og:locale`" content=`"$ogLocale`">"
    $html = $html -replace '<meta property="og:locale:alternate" content="[^"]*">', "<meta property=`"og:locale:alternate`" content=`"$ogLocaleAlt`">"

    $html = $html -replace '<meta name="twitter:url" content="[^"]*">', "<meta name=`"twitter:url`" content=`"$canonical`">"
    $html = $html -replace '<meta name="twitter:title" content="[^"]*">', "<meta name=`"twitter:title`" content=`"$ogTitle`">"
    $html = $html -replace '<meta name="twitter:description" content="[^"]*">', "<meta name=`"twitter:description`" content=`"$ogDesc`">"

    $html = [regex]::Replace(
        $html,
        '(?s)"description":\s*"[^"]*"',
        "`"description`": `"$jsonLd`"",
        1
    )
    return $html
}

function Write-Utf8NoBom([string]$path, [string]$content) {
    $dir = Split-Path $path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [IO.File]::WriteAllText($path, $content, [Text.UTF8Encoding]::new($false))
}

$en = Read-JsonDict (Join-Path $locales 'en.json')
$id = Read-JsonDict (Join-Path $locales 'id.json')

$homeTpl = [IO.File]::ReadAllText((Join-Path $web 'index.html'), [Text.UTF8Encoding]::new($false))
if ($homeTpl -notmatch 'data-site-locale=') {
    throw 'index.html must include data-site-locale on <html>'
}

$homeEn = Apply-LocaleDict $homeTpl $en @('status.')
$homeEn = Inject-SeoHead $homeEn $en 'en' 'https://alienai.id/' 'https://alienai.id/' 'https://alienai.id/id/'
Write-Utf8NoBom (Join-Path $web 'index.html') $homeEn

$homeId = Apply-LocaleDict $homeTpl $id @('status.')
$homeId = Inject-SeoHead $homeId $id 'id' 'https://alienai.id/id/' 'https://alienai.id/' 'https://alienai.id/id/'

$statusTpl = [IO.File]::ReadAllText((Join-Path $web 'status.html'), [Text.UTF8Encoding]::new($false))
if ($statusTpl -notmatch 'data-site-locale=') {
    throw 'status.html must include data-site-locale on <html>'
}

function Inject-SeoStatus(
    [string]$html,
    [string]$lang,
    [string]$canonical,
    [string]$hreflangEn,
    [string]$hreflangId,
    [string]$title,
    [string]$description
) {
    $desc = HtmlEncodeText($description)
    $html = $html -replace '<html lang="[^"]*"', "<html lang=`"$lang`""
    $html = $html -replace 'data-site-locale="[^"]*"', "data-site-locale=`"$lang`""
    $html = $html -replace '<title>[^<]*</title>', "<title>$title</title>"
    $html = $html -replace '<meta name="description" content="[^"]*">', "<meta name=`"description`" content=`"$desc`">"
    $html = $html -replace '<link rel="canonical" href="[^"]*">', "<link rel=`"canonical`" href=`"$canonical`">"
    $hrefBlock = @"
  <link rel="alternate" hreflang="en" href="$hreflangEn">
  <link rel="alternate" hreflang="id" href="$hreflangId">
  <link rel="alternate" hreflang="x-default" href="$hreflangEn">
"@
    $html = [regex]::Replace(
        $html,
        '(?s)<!-- hreflang:begin -->.*?<!-- hreflang:end -->',
        "<!-- hreflang:begin -->`n$hrefBlock  <!-- hreflang:end -->"
    )
    return $html
}

function Fix-IdNavLinks([string]$html) {
    $html = $html -replace 'href="/status"', 'href="/id/status"'
    $html = $html -replace '<a href="/" class="flex items-center gap-3 group', '<a href="/id/" class="flex items-center gap-3 group'
    $html = $html -replace '<a href="/" class="flex items-center gap-2.5 group', '<a href="/id/" class="flex items-center gap-2.5 group'
    $html = $html -replace '(<a href=")/(" class="px-2.5 py-1 rounded-md bg-white/10)', '<a href="/id/" class="px-2.5 py-1 rounded-md bg-white/10'
    $html = $html -replace '(data-i18n="status.home"[^>]*href=")/"', 'data-i18n="status.home" href="/id/"'
    if ($html -notmatch 'data-i18n="status.home"[^>]*href="/id/"') {
        $html = $html -replace '(<a href=")/(" class="hover:text-white transition" data-i18n="status.home")', '<a href="/id/" class="hover:text-white transition" data-i18n="status.home"'
    }
    return $html
}

$statusEn = Apply-LocaleDict $statusTpl $en @('hero.', 'feat.', 'dl.', 'nav.')
$statusEn = Inject-SeoStatus $statusEn 'en' 'https://alienai.id/status' 'https://alienai.id/status' 'https://alienai.id/id/status' 'System Status — Alien AI' 'Live uptime for Alien AI core services.'
Write-Utf8NoBom (Join-Path $web 'status.html') $statusEn

$statusId = Apply-LocaleDict $statusTpl $id @('hero.', 'feat.', 'dl.', 'nav.')
$statusId = Inject-SeoStatus $statusId 'id' 'https://alienai.id/id/status' 'https://alienai.id/status' 'https://alienai.id/id/status' 'Status Sistem — Alien AI' 'Status dan uptime layanan inti Alien AI.'
$statusId = Fix-IdNavLinks $statusId
Write-Utf8NoBom (Join-Path $web 'id\status.html') $statusId

$homeId = Fix-IdNavLinks $homeId
Write-Utf8NoBom (Join-Path $web 'id\index.html') $homeId

Write-Host 'Synced index.html, id/index.html, status.html, id/status.html from locale JSON.'
