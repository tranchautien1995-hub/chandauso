#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ "$(uname -s)" != Darwin ]]; then
  echo "Cần macOS với Xcode để tạo IPA." >&2
  exit 1
fi
mkdir -p build
xcrun swiftc -target "$(uname -m)-apple-macosx13.0" Shared/BlockingRules.swift Tests/main.swift -o build/rules-tests
build/rules-tests
xcodebuild -project ChanDauSo.xcodeproj -scheme ChanDauSo \
  -configuration Release -sdk iphoneos -destination 'generic/platform=iOS' \
  -derivedDataPath build/DerivedData CODE_SIGNING_ALLOWED=NO ARCHS=arm64 build

# A fresh staging directory avoids accidentally packaging stale products.
stage="$(mktemp -d "$PWD/build/staging.XXXXXX")"
mkdir -p "$stage/Payload"
cp -R build/DerivedData/Build/Products/Release-iphoneos/ChanDauSo.app "$stage/Payload/"
app="$stage/Payload/ChanDauSo.app"
extension="$app/PlugIns/ChanDauSoDirectory.appex"
test -f "$extension/ChanDauSoDirectory"

# Sign nested code before the host. TrollStore reapplies its own install signature.
# Apple tools only: no downloaded signing binary or Apple Developer account required.
if [[ -d "$app/Frameworks" ]]; then
  while IFS= read -r -d '' dylib; do
    codesign --force --sign - --timestamp=none "$dylib"
  done < <(find "$app/Frameworks" -maxdepth 1 \( -name '*.dylib' -o -name '*.framework' \) -print0)
fi
codesign --force --sign - --timestamp=none --entitlements Extension/Entitlements.plist "$extension"
codesign --force --sign - --timestamp=none --entitlements App/Entitlements.plist "$app"
codesign --verify --deep --strict "$app"
codesign -d --entitlements :- "$extension"
codesign -d --entitlements :- "$app"
ditto -c -k --keepParent "$stage/Payload" "$stage/ChanDauSo.ipa"
mv -f "$stage/ChanDauSo.ipa" build/ChanDauSo.ipa
echo "IPA: $PWD/build/ChanDauSo.ipa"
