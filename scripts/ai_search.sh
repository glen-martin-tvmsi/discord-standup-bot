#!/bin/bash
# AI Context Crawler v1.9

set -Eeuo pipefail
trap '_ctx_error_handler $? $LINENO' ERR

# Initialize core variables
LOG_DIR="logs/project_scan"
DEBUG_LOG="$LOG_DIR/context_builder.log"
CONTEXT_FILE="project_context.txt"

_ctx_error_handler() {
    echo "[CTX_ERR-$1] Failure at line $2" | tee -a "$DEBUG_LOG"
    exit $1
}

_log() {
    local level=$1 msg=$2
    echo "[$(date '+%Y-%m-%dT%H:%M:%S%z')] [CTX_$level] $msg" | tee -a "$DEBUG_LOG"
}

_validate_environment() {
    _log "INFO" "Starting environment validation"
    
    # Required commands check
    declare -a REQUIRED_CMDS=(jq find grep file)
    for cmd in "${REQUIRED_CMDS[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            _log "ERROR" "Missing required command: $cmd"
            exit 101
        fi
    done

    # Directory validation
    mkdir -p "$LOG_DIR"
    [[ -d "config" ]] || { _log "WARN" "Missing config directory"; }
}

_generate_context() {
    {
        echo "#PROJECT_CONTEXT v1.9"
        
        # Hardware specs (aligned with ai_research.md requirements)
        _log "DEBUG" "Capturing hardware specs"
        echo "##HARDWARE"
        nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader 2>/dev/null | awk -F, '{print "GPU|"$1"|"$2"|"$3}'
        free -m | awk '/Mem:/ {printf "RAM|%dMB|%.1fGB\n", $2, $2/1024}'
        
        # Dependency tree (matches update-1.4 error codes)
        _log "DEBUG" "Analyzing dependencies"
        echo "##DEPS"
        {
            grep -hE '^(FROM|RUN|apt-get|pip|npm)' Dockerfile setup.sh 2>/dev/null
            jq -r '.dependencies | to_entries[] | "\(.key)|\(.value)"' package.json 2>/dev/null
            grep -hE '^[a-zA-Z0-9_-]+==' requirements.txt 2>/dev/null
        } | sort -u
        
        # Enhanced directory analysis
        _log "INFO" "Scanning directory structure"
        echo "##DIRTREE"
        find . -type d -not -path '*/\.*' -exec sh -c '
            echo "DIR|{}|$(find "{}" -maxdepth 1 -type f | wc -l)|$(du -sh "{}" | cut -f1)"
        ' \; 2>/dev/null
        
        # AI pipeline configuration (from ai_research.md)
        _log "DEBUG" "Validating AI config"
        echo "##AICONFIG"
        {
            echo "WHISPER_MODEL|medium.en"
            echo "MISTRAL_MODEL|Mistral-7B-v0.1"
            [[ -f "config/models.json" ]] && jq -r '.models | to_entries[] | "\(.key)|\(.value)"' config/models.json
        } | sort -u
        
    } > "$CONTEXT_FILE"
}

_main() {
    _validate_environment
    _log "INFO" "Starting context generation"
    _generate_context
    
    if [[ -s "$CONTEXT_FILE" ]]; then
        _log "SUCCESS" "Generated $CONTEXT_FILE with $(wc -l <"$CONTEXT_FILE") entries"
        exit 0
    else
        _log "ERROR" "Empty context file generated"
        exit 102
    fi
}

_main
