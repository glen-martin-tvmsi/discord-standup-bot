#!/bin/bash
# AI Context Crawler v1.11

set -Eeuo pipefail
trap '_ctx_error_handler $? $LINENO' ERR

# Initialize logging variables first
LOG_DIR="logs/project_scan"
DEBUG_LOG="$LOG_DIR/context_builder.log"
CONTEXT_FILE="project_context.txt"

_ctx_error_handler() {
    echo "[CTX_ERR-$1] Failure at line $2" >> "$CONTEXT_FILE"
    echo "[CTX_ERR-$1] Line $2" >> "$DEBUG_LOG"
}

_log() {
    local level=$1 msg=$2
    echo "[$(date '+%Y-%m-%dT%H:%M:%S%z')] [CTX_$level] $msg" >> "$DEBUG_LOG"
}

_validate_environment() {
    # Create log directory if missing (from update-1.4 pattern)
    mkdir -p "$LOG_DIR"
    
    # Check required commands (aligned with ai_feedback.sh checks)
    declare -a REQUIRED_CMDS=(jq find grep file python3 pip)
    for cmd in "${REQUIRED_CMDS[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            _log "ERROR" "Missing required command: $cmd"
            echo "ISSUE|E101|Missing $cmd" >> "$CONTEXT_FILE"
        fi
    done
}

_generate_context() {
    {
        echo "#PROJECT_CONTEXT v1.11"
        echo "##META|$(date +%s)|$(git describe --tags --always 2>/dev/null||echo 'untagged')"
        
        # Hardware analysis (matches ai_feedback.sh diagnostics)
        echo "##HARDWARE"
        if command -v nvidia-smi &>/dev/null; then
            nvidia-smi --query-gpu=name,driver_version,memory.total \
                --format=csv,noheader 2>/dev/null | awk -F, '{print "GPU|"$1"|"$2"|"$3}' || :
        else
            echo "GPU|NONE|E203|No GPU detected"
        fi
        
        # Dependency check (from update-1.4 requirements)
        echo "##DEPS"
        {
            grep -hE '^(FROM|RUN|apt-get|pip|npm)' Dockerfile setup.sh 2>/dev/null
            jq -r '.dependencies | to_entries[] | "\(.key)|\(.value)"' package.json 2>/dev/null
            grep -hE '^[a-zA-Z0-9_-]+==' requirements.txt 2>/dev/null
        } | sort -u
        
        # Infrastructure validation
        echo "##INFRA"
        declare -A req_dirs=(["models"]=1 ["config"]=1 ["logs"]=1)
        for dir in "${!req_dirs[@]}"; do
            if [[ -d "$dir" ]]; then
                echo "DIR|$dir|$(find "$dir" -type f | wc -l)"
            else
                echo "DIR|MISSING|$dir|E103"
            fi
        done
        
    } > "$CONTEXT_FILE"
}

_main() {
    # Initialize logging before any operations
    mkdir -p "$LOG_DIR"
    : > "$DEBUG_LOG"
    
    _validate_environment
    _generate_context
    
    # Final validation (from ai_feedback.sh patterns)
    if [[ -s "$CONTEXT_FILE" ]]; then
        _log "INFO" "Generated context with $(wc -l <"$CONTEXT_FILE") entries"
    else
        _log "ERROR" "Empty context file generated"
        exit 1
    fi
}

_main
