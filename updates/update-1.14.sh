#!/bin/bash
# updates/update-1.14.sh - VS Code Configuration Setup v1.14

set -Eeuo pipefail
trap '_handle_error $? $LINENO' ERR

VERSION="1.14"
VSCODE_DIR=".vscode"
CONFIG_FILES=("settings.json" "launch.json" "extensions.json")
LOG_DIR="logs/vscode"
DEBUG_LOG="$LOG_DIR/update-1.14.log"

_handle_error() {
    echo "[ERR-$1] Update failed at line $2" | tee -a "$DEBUG_LOG"
    exit $1
}

_create_vscode_config() {
    mkdir -p "$VSCODE_DIR"

    # settings.json
    cat > "$VSCODE_DIR/settings.json" <<'EOL'
{
    "python.defaultInterpreterPath": "${workspaceFolder}/.venv/Scripts/python.exe",
    "python.analysis.typeCheckingMode": "basic",
    "python.analysis.diagnosticSeverityOverrides": {
        "reportMissingImports": "none",
        "reportUndefinedVariable": "warning"
    },
    "python.formatting.provider": "black",
    "python.linting.enabled": true,
    "python.linting.pylintEnabled": true,
    "python.testing.pytestEnabled": true,
    "files.autoSave": "afterDelay",
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": {
        "source.organizeImports": true
    },
    "terminal.integrated.env.windows": {
        "PYTHONPATH": "${workspaceFolder}/src"
    },
    "ai.codeLens.enabled": true,
    "github.copilot.enable": {
        "*": true
    }
}
EOL

    # launch.json 
    cat > "$VSCODE_DIR/launch.json" <<'EOL'
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Python: Discord Bot",
            "type": "python",
            "request": "launch",
            "program": "${workspaceFolder}/src/bot/main.py",
            "args": ["--production"],
            "console": "integratedTerminal",
            "justMyCode": false,
            "envFile": "${workspaceFolder}/.env",
            "cwd": "${workspaceFolder}",
            "preLaunchTask": "start-services"
        },
        {
            "name": "Python: AI Pipeline",
            "type": "python",
            "request": "launch",
            "module": "pytest",
            "args": ["tests/"],
            "env": {
                "PYTHONPATH": "${workspaceFolder}/src"
            }
        }
    ],
    "compounds": [
        {
            "name": "Full System",
            "configurations": ["Python: Discord Bot", "Python: AI Pipeline"]
        }
    ]
}
EOL

    # extensions.json
    cat > "$VSCODE_DIR/extensions.json" <<'EOL'
{
    "recommendations": [
        "ms-python.python",
        "ms-python.vscode-pylance",
        "ms-toolsai.jupyter",
        "GitHub.copilot",
        "ms-azuretools.vscode-docker",
        "VisualStudioExptTeam.vscodeintellicode",
        "charliermarsh.ruff"
    ]
}
EOL

    # Create AI-specific settings
    cat > "$VSCODE_DIR/ai.json" <<'EOL'
{
    "ai.trace.server": "verbose",
    "ai.experimental.tabCompletion": true,
    "github.copilot.advanced": {
        "debug.overrideEngine": "gpt-4",
        "python.extraPaths": ["${workspaceFolder}/src"]
    }
}
EOL
}

_add_gitignore() {
    if ! grep -q ".vscode/" .gitignore; then
        echo -e "\n# VS Code\n.vscode/*" >> .gitignore
        echo "!.vscode/settings.json" >> .gitignore
        echo "!.vscode/launch.json" >> .gitignore
        echo "!.vscode/extensions.json" >> .gitignore
    fi
}

_update_documentation() {
    cat >> README.md <<'EOL'

## VS Code Configuration (v1.14+)

### Recommended Setup
1. Install [VS Code](https://code.visualstudio.com/)
2. Open the project folder
3. Accept extension recommendations when prompted

### Key Features
- Preconfigured Python environment paths
- Integrated debugging profiles
- AI-assisted development (GitHub Copilot)
- Auto-formatting with Black
- Linting with Pylance/Ruff

### Debugging
- **Discord Bot**: F5 to start with production settings
- **AI Pipeline**: Test runner configuration
- **Full System**: Launch all components

EOL
}

# Main execution flow
{
    mkdir -p "$LOG_DIR"
    echo "[UPDATE] Starting v$VERSION deployment" | tee -a "$DEBUG_LOG"
    
    _create_vscode_config
    _add_gitignore
    _update_documentation
    
    # Convert line endings for Windows compatibility
    find "$VSCODE_DIR" -type f -exec unix2dos {} \;
    
    git add -A
    git commit -m "System v$VERSION - VS Code Config" \
              -m "- AI-optimized editor settings" \
              -m "- Debug configurations for bot" \
              -m "- Git integration rules" \
              -m "- Extension recommendations"
    
    echo "[SUCCESS] Update v$VERSION completed" | tee -a "$DEBUG_LOG"
}
