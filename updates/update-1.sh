#!/bin/bash
# updates/update-1.0.sh - Certified Atomic Update v1.0

set -Eeuo pipefail
trap 'error_handler $?' ERR

# Configuration
APPROVED_VERSION="1.0"
VERSION_FILE=".project_version"
COMMIT_MSG="[Bot Certified Update] v1.0 - Initial Release"

error_handler() {
    echo "‼️ Critical error ($1) - Rolling back changes"
    git restore --staged .
    git clean -fd
    exit 1
}

initialize_version_control() {
    # Create version file if missing
    if [[ ! -f "$VERSION_FILE" ]]; then
        echo "$APPROVED_VERSION" > "$VERSION_FILE"
        git add "$VERSION_FILE"
        git commit -m "chore: Initialize version tracking"
    fi

    # Track updates directory
    if [[ ! -d "updates" ]]; then
        mkdir -p updates
        git add updates/
        git commit -m "chore: Create updates directory" || true
    fi
}

verify_approval() {
    CURRENT_VERSION=$(cat "$VERSION_FILE" 2>/dev/null || echo "0")
    if [[ "$CURRENT_VERSION" != "$APPROVED_VERSION" ]]; then
        echo "❌ Version mismatch:"
        echo "Approved: $APPROVED_VERSION | Current: $CURRENT_VERSION"
        echo "Update $VERSION_FILE to proceed"
        exit 1
    fi
}

apply_changes() {
    # Create/update voice recorder implementation
    mkdir -p src/bot_handlers
    cat > src/bot_handlers/voice_recorder.py <<'PY'
import discord
from discord.ext import commands
import datetime

class VoiceRecorder(commands.Cog):
    def __init__(self, bot):
        self.bot = bot
        
    @commands.Cog.listener()
    async def on_voice_state_update(self, member, before, after):
        if before.channel != after.channel:
            print(f"{datetime.datetime.now()} - {member} changed voice channels")

async def setup(bot):
    await bot.add_cog(VoiceRecorder(bot))
PY

    # Stage all changes including this script
    git add -A
}

commit_and_push() {
    if ! git diff --cached --quiet; then
        git commit -m "$COMMIT_MSG" \
                  -m "Changes include:" \
                  -m "- Initial voice state tracking" \
                  -m "- Version control system" \
                  -m "- Atomic update infrastructure"
        
        git push origin main
        echo "✅ Certified update v1.0 successfully deployed"
    else
        echo "✅ No changes required - system up-to-date"
    fi
}

# Execution Flow
initialize_version_control
verify_approval
apply_changes
commit_and_push
