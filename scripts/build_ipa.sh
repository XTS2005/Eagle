#!/bin/bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build"
DERIVED_DATA="$BUILD_DIR/DerivedData"
PRODUCT_NAME="Eagle"

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

PAYLOAD_DIR="$BUILD_DIR/Payload"
PACKAGED_APP="$PAYLOAD_DIR/$PRODUCT_NAME.app"
mkdir -p "$PAYLOAD_DIR"
cp -R "$BUILT_APP" "$PACKAGED_APP"

codesign --remove-signature "$PACKAGED_APP" 2>/dev/null || true
ldid -S"$PROJECT_ROOT/Config/lara.entitlements" "$PACKAGED_APP/$PRODUCT_NAME"

(cd "$BUILD_DIR" && /usr/bin/zip -qry "$PRODUCT_NAME.ipa" Payload)

echo "Eagle IPA: $BUILD_DIR/$PRODUCT_NAME.ipa"
