#!/bin/bash
# updates/update-1.15.sh - Linux VSCode Setup v1.15

set -Eeuo pipefail
trap '_handle_error $? $LINENO' ERR

VERSION="1.15"
VSCODE_DIR=".vscode"
WORKSPACE_FILE="discord-standup-bot.code-workspace"
LOG_DIR="logs/vscode"
DEBUG_LOG="$LOG_DIR/update-1.15.log"

_handle_error() {
    echo "[ERR-$1] Update failed at line $2" | tee -a "$DEBUG_LOG"
    exit $1
}

_create_vscode_config() {
    mkdir -p "$VSCODE_DIR"

    # settings.json with Linux-specific paths
    cat > "$VSCODE_DIR/settings.json" <<'EOL'
{
    "python.defaultInterpreterPath": "${workspaceFolder}/.venv/bin/python",
    "python.analysis.extraPaths": ["${workspaceFolder}/src"],
    "files.eol": "\n",
    "editor.tabSize": 4,
    "python.testing.pytestEnabled": true,
    "python.formatting.provider": "black",
    "terminal.integrated.env.linux": {
        "PYTHONPATH": "${workspaceFolder}/src"
    }
}
EOL

    # launch.json for Linux environment
    cat > "$VSCODE_DIR/launch.json" <<'EOL'
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Python: Bot Main",
            "type": "python",
            "request": "launch",
            "program": "${workspaceFolder}/src/bot/main.py",
            "args": ["--env", "development"],
            "console": "integratedTerminal",
            "cwd": "${workspaceFolder}"
        }
    ]
}
EOL

    # extensions.json with Linux recommendations
    cat > "$VSCODE_DIR/extensions.json" <<'EOL'
{
    "recommendations": [
        "ms-python.python",
        "ms-python.vscode-pylance",
        "charliermarsh.ruff",
        "GitHub.copilot"
    ]
}
EOL

    # tasks.json for Linux build system
    cat > "$VSCODE_DIR/tasks.json" <<'EOL'
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "Start Services",
            "type": "shell",
            "command": "bash scripts/start.sh",
            "isBackground": true
        }
    ]
}
EOL
}

_create_workspace_file() {
    cat > "$WORKSPACE_FILE" <<'EOL'
{
    "folders": [
        {
            "path": ".",
            "name": "Discord Standup Bot"
        }
    ],
    "settings": {
        "files.exclude": {
            "**/.git": true,
            "**/.venv": true,
            "**/__pycache__": true
        }
    }
}
EOL
}

_convert_line_endings() {
    # POSIX-compliant CRLF to LF conversion
    find "$VSCODE_DIR" -type f -exec sed -i 's/\r$//' {} \;
    sed -i 's/\r$//' "$WORKSPACE_FILE"
}

_add_gitignore() {
    if ! grep -q ".vscode" .gitignore; then
        cat >> .gitignore <<'EOL'

# VSCode
.vscode/*
!.vscode/settings.json
!.vscode/tasks.json
!.vscode/launch.json
!.vscode/extensions.json
EOL
    fi
}

_update_documentation() {
    cat >> README.md <<'EOL'

## Linux VSCode Setup (v1.15+)

### Configuration Features
- Python virtual environment integration
- Pylance/Ruff language server setup
- Preconfigured debug profiles
- Git-ignored temporary files

### First-Time Setup
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

text

### Recommended Workflow
1. Open workspace: `code discord-standup-bot.code-workspace`
2. Install recommended extensions
3. Select Python interpreter (Ctrl+Shift+P > "Python: Select Interpreter")
4. Start debugging with F5
EOL
}

# Main execution flow
{
    mkdir -p "$LOG_DIR"
    echo "[UPDATE] Starting v$VERSION deployment" | tee -a "$DEBUG_LOG"
    
    _create_vscode_config
    _create_workspace_file
    _add_gitignore
    _update_documentation
    _convert_line_endings
    
    git add -A
    git commit -m "System v$VERSION - Linux VSCode Config" \
              -m "- Cross-platform line endings" \
              -m "- Workspace file setup" \
              -m "- POSIX-compliant CRLF handling" \
              -m "- Development environment docs"

    echo "[SUCCESS] Update v$VERSION completed" | tee -a "$DEBUG_LOG"
}