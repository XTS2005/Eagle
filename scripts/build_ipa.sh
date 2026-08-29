#!/bin/bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build"
DERIVED_DATA="$BUILD_DIR/DerivedData"
PRODUCT_NAME="Eagle"
STAGING_DIR="$(mktemp -d "${TMPDIR:-/private/tmp}/eagle-ipa.XXXXXX")"
VERIFY_MATRIX_SCRIPT="$PROJECT_ROOT/scripts/verify_prepare_matrices.sh"

cleanup() {
  rm -rf "$STAGING_DIR"
}
trap cleanup EXIT

mkdir -p "$BUILD_DIR"
rm -rf "$DERIVED_DATA"
rm -f "$BUILD_DIR/xcodebuild.log" "$BUILD_DIR/$PRODUCT_NAME.ipa"

if [ ! -x "$VERIFY_MATRIX_SCRIPT" ]; then
  echo "ERROR: compatibility verifier is missing or not executable: $VERIFY_MATRIX_SCRIPT" >&2
  exit 1
fi

"$VERIFY_MATRIX_SCRIPT"

echo "Building Eagle release..."
xcodebuild \
  -project "$PROJECT_ROOT/lara.xcodeproj" \
  -scheme lara \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -derivedDataPath "$DERIVED_DATA" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  build 2>&1 | tee "$BUILD_DIR/xcodebuild.log"

BUILT_APP="$DERIVED_DATA/Build/Products/Release-iphoneos/$PRODUCT_NAME.app"
if [ ! -d "$BUILT_APP" ]; then
  echo "ERROR: expected app was not produced at $BUILT_APP" >&2
  exit 1
fi

PAYLOAD_DIR="$STAGING_DIR/Payload"
PACKAGED_APP="$PAYLOAD_DIR/$PRODUCT_NAME.app"
mkdir -p "$PAYLOAD_DIR"
cp -R -X "$BUILT_APP" "$PACKAGED_APP"

# File-provider workspaces can attach Finder metadata to copied bundles. Those
# attributes are not part of Eagle and can make downstream signing fail.
xattr -cr "$PACKAGED_APP" 2>/dev/null || true

codesign --remove-signature "$PACKAGED_APP" 2>/dev/null || true

# CODE_SIGNING_ALLOWED=NO deliberately leaves embedded Mach-O files unsigned.
# A direct device install then fails in dyld before Eagle can launch. Sign and
# verify every embedded executable before signing the main binary and zipping
# the payload. Sideloading tools may replace these ad-hoc signatures later.
EMBEDDED_BINARIES=(
  "$PACKAGED_APP/Frameworks/libgrabkernel2.dylib"
  "$PACKAGED_APP/Frameworks/libxpf.dylib"
)

for binary in "${EMBEDDED_BINARIES[@]}"; do
  if [ ! -f "$binary" ]; then
    echo "ERROR: expected embedded binary was not produced: $binary" >&2
    exit 1
  fi
  codesign --remove-signature "$binary" 2>/dev/null || true
  codesign --force --sign - --timestamp=none "$binary"
  codesign --verify --strict --verbose=2 "$binary"
done

codesign \
  --force \
  --sign - \
  --entitlements "$PROJECT_ROOT/Config/lara.entitlements" \
  --generate-entitlement-der \
  --timestamp=none \
  "$PACKAGED_APP"
codesign --verify --deep --strict --verbose=2 "$PACKAGED_APP"

(cd "$STAGING_DIR" && /usr/bin/zip -qryX "$BUILD_DIR/$PRODUCT_NAME.ipa" Payload)

echo "Eagle IPA: $BUILD_DIR/$PRODUCT_NAME.ipa"
