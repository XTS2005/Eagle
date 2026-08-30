#!/bin/bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEMP_DIR="$(mktemp -d "${TMPDIR:-/private/tmp}/eagle-pointer-guard.XXXXXX")"

cleanup() {
  rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

clang \
  -std=c11 \
  -Wall \
  -Wextra \
  -Werror \
  "$PROJECT_ROOT/scripts/verify_kernel_pointer_guards.c" \
  -o "$TEMP_DIR/verify_kernel_pointer_guards"

"$TEMP_DIR/verify_kernel_pointer_guards"
echo "Kernel pointer guards passed."
