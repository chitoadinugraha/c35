from pathlib import Path
p = Path(r"D:/c35/dev_browser.ps1")
t = p.read_text(encoding="utf-8")
if "RtpVideo" not in t:
    t = t.replace("[switch]$SctpScreen,", "[switch]$SctpScreen,\n    [switch]$RtpVideo,")
old = "if ($SctpScreen) { $env:C35_BROWSER_SCTP_SCREEN = '1' }"
new = """if ($RtpVideo) {
    $env:C35_BROWSER_SCTP_SCREEN = '0'
} elseif ($SctpScreen -or -not $env:C35_BROWSER_SCTP_SCREEN) {
    $env:C35_BROWSER_SCTP_SCREEN = '1'
}"""
if old in t:
    t = t.replace(old, new)
p.write_text(t, encoding="utf-8", newline="\n")
print("ok")