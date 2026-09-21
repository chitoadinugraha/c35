# Regenerate Dart protobuf (requires protoc + protoc_plugin on PATH)
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$protoRoot = Join-Path $root "_\schemas\proto"
$out = Join-Path $root "clients\app\lib\c\pb"
$dartPluginBin = Join-Path $env:LOCALAPPDATA "Pub\Cache\bin"
if (Test-Path $dartPluginBin) { $env:PATH = "$dartPluginBin;$env:PATH" }
New-Item -ItemType Directory -Force -Path $out | Out-Null
protoc -I $protoRoot --dart_out=$out (Join-Path $protoRoot "c35\*.proto")
