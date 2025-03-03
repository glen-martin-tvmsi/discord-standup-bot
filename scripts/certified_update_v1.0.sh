#!/bin/bash
# scripts/certified_update_v1.0.sh - Atomic Project Update v1.0

set -Eeuo pipefail
trap 'handle_error $?' ERR

VERSION="1.0"
VERSION_FILE=".project_version"

handle_error() {
  echo "‼️ Update failed - resetting changes"
  git reset --hard HEAD@{1}
  exit 1
}

verify_approval() {
  [[ "$(cat "$VERSION_FILE")" == "$VERSION" ]] || {
      echo "❌ Version mismatch: Expected $VERSION"
      exit 1
  }
}

apply_update() {
  git add -A
  git commit -m "[System] Certified Update v$VERSION" \
            -m "Changes:" \
            -m "- Base voice recording system" \
            -m "- Atomic update framework" \
            -m "- Version control foundation"
  git push origin main
}

verify_approval
apply_update
echo "✅ Certified update v$VERSION completed"
