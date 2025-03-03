#!/bin/bash
# AI Context Crawler v1.10

set -Eeuo pipefail
trap '_ctx_error_handler $? $LINENO' ERR

# Configuration from ai_research.md
MIN_GPU_VRAM=6 # RTX 2060 requirement
MIN_RAM_GB=8
REQUIRED_CMDS=(jq find grep file python3 pip nvidia-smi)
AI_MODELS=("WhisperMedium.en" "Mistral-7B-v0.1")

_ctx_error_handler() {
    echo "[CTX_ERR-$1] Failure at line $2" >> "$CONTEXT_FILE"
}

_log() {
    local level=$1 msg=$2
    echo "[$(date '+%s')] [CTX_$level] $msg" >> "$DEBUG_LOG"
}

_check_deps() {
    {
        echo "##DEPCHECK"
        for cmd in "${REQUIRED_CMDS[@]}"; do
            if command -v "$cmd" &>/dev/null; then
                echo "DEP|PRESENT|$cmd"
            else
                echo "DEP|MISSING|$cmd|E101"
                echo "ISSUE|E101|Missing required command: $cmd"
            fi
        done
        
        # Model validation from system manifest
        echo "##MODELCHECK"
        for model in "${AI_MODELS[@]}"; do
            if [[ -f "models/$model" ]]; then
                echo "MODEL|PRESENT|$model"
            else
                echo "MODEL|MISSING|$model|E301"
                echo "ISSUE|E301|Missing AI model: $model"
            fi
        done
    } >> "$CONTEXT_FILE"
}

_check_hardware() {
    {
        echo "##HARDWARE"
        # GPU check with fallbacks
        if command -v nvidia-smi &>/dev/null; then
            nvidia-smi --query-gpu=name,driver_version,memory.total \
                --format=csv,noheader 2>/dev/null | awk -F, '{
                    split($3, vram, " ");
                    if(vram[1] < '$MIN_GPU_VRAM') 
                        print "ISSUE|E201|Insufficient GPU VRAM: "vram[1]"GB < '$MIN_GPU_VRAM'GB";
                    print "GPU|"$1"|"$2"|"vram[1]"GB"
                }' || echo "GPU|ERROR|E202|Failed to query GPU"
        else
            echo "GPU|NONE|E203|No GPU detected"
            echo "ISSUE|E203|Missing NVIDIA GPU"
        fi

        # RAM check
        local ram_mb=$(free -m | awk '/Mem:/ {print $2}')
        local ram_gb=$((ram_mb / 1024))
        if (( ram_gb < MIN_RAM_GB )); then
            echo "ISSUE|E204|Insufficient RAM: ${ram_gb}GB < ${MIN_RAM_GB}GB"
        fi
        echo "RAM|${ram_mb}MB|${ram_gb}GB"
    } >> "$CONTEXT_FILE"
}

_check_infra() {
    {
        echo "##INFRA"
        # Directory structure from ai_research.md specs
        declare -A req_dirs=(
            ["models"]=2
            ["logs"]=5
            ["config"]=1
        )
        for dir in "${!req_dirs[@]}"; do
            if [[ -d "$dir" ]]; then
                count=$(find "$dir" -type f | wc -l)
                (( count >= ${req_dirs[$dir]} )) || 
                    echo "ISSUE|E102|Incomplete $dir: $count files < ${req_dirs[$dir]}"
                echo "DIR|$dir|$count"
            else
                echo "DIR|MISSING|$dir|E103"
                echo "ISSUE|E103|Missing directory: $dir"
            fi
        done
    } >> "$CONTEXT_FILE"
}

_generate_context() {
    echo "#PROJECT_CONTEXT v1.10" > "$CONTEXT_FILE"
    echo "##META|$(date +%s)|$(git describe --tags --always 2>/dev/null||echo 'untagged')" >> "$CONTEXT_FILE"
    
    _check_deps
    _check_hardware
    _check_infra
    
    # Additional checks from ai_research.md
    {
        echo "##COMPLIANCE"
        grep -q 'AES-256-CBC' config/security.cfg 2>/dev/null && 
            echo "ENCRYPTION|AES-256-CBC" || 
            echo "ENCRYPTION|MISSING|E401"
        
        echo "##PERFORMANCE"
        python3 -c "import torch; print('CUDA|' + str(torch.cuda.is_available()))" 2>/dev/null ||
            echo "CUDA|ERROR|E402"
    } >> "$CONTEXT_FILE"
}

_main() {
    mkdir -p "$LOG_DIR"
    exec &> >(tee -a "$DEBUG_LOG")
    
    _log "INFO" "Starting comprehensive project scan"
    _generate_context
    
    # Final validation from update-1.4 requirements
    if grep -q 'ISSUE|E' "$CONTEXT_FILE"; then
        _log "WARN" "Found $(grep -c 'ISSUE|E' "$CONTEXT_FILE") problems"
    else
        echo "ISSUE|NONE|No critical issues found" >> "$CONTEXT_FILE"
    fi
    
    _log "INFO" "Context generation completed"
    exit 0
}

_main
