#!/bin/sh
# Create minimal fn-main stubs for Cargo workspace members not built in this image.
set -eu
root="${WORKSPACE_ROOT:-/app/servers}"
for pkg in "$@"; do
  mkdir -p "${root}/${pkg}/src"
  printf '%s\n' 'fn main() {}' > "${root}/${pkg}/src/main.rs"
done
