#!/bin/bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build"
DERIVED_DATA="$BUILD_DIR/DerivedData"
PRODUCT_NAME="Eagle"
STAGING_DIR="$(mktemp -d "${TMPDIR:-/private/tmp}/eagle-ipa.XXXXXX")"

cleanup() {
  rm -rf "$STAGING_DIR"
}
trap cleanup EXIT

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

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

if ! command -v ldid >/dev/null 2>&1; then
  echo "ERROR: ldid is required. Install it with: brew install ldid" >&2
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
ldid -S"$PROJECT_ROOT/Config/lara.entitlements" "$PACKAGED_APP/$PRODUCT_NAME"

(cd "$STAGING_DIR" && /usr/bin/zip -qryX "$BUILD_DIR/$PRODUCT_NAME.ipa" Payload)

echo "Eagle IPA: $BUILD_DIR/$PRODUCT_NAME.ipa"
