#!/bin/bash
# updates/update-1.8.sh - Enhanced Context Builder v1.8

set -Eeuo pipefail
trap '_error_handler $LINENO' ERR

VERSION="1.8"
CONTEXT_SCRIPT="scripts/ai_search.sh"
CONTEXT_FILE="project_context.txt"
LOG_DIR="logs/project_scan"
DEBUG_LOG="$LOG_DIR/context_builder.log"

_error_handler() {
    local line=$1
    echo "[ERR] Update failed at line $line - Check $DEBUG_LOG" >&2
    exit 1
}

_create_context_script() {
    cat > "$CONTEXT_SCRIPT" <<'EOL'
#!/bin/bash
# AI Context Crawler v1.8

set -Eeuo pipefail
trap 'echo "[CTX_ERR] $BASH_COMMAND failed at line $LINENO" >&2' ERR

scan_project() {
  echo "#PROJECT_CONTEXT v1.8"
  echo "##META|$(date +%s)|$(git describe --tags --always 2>/dev/null||echo 'untagged')"
  
  # Enhanced directory analysis with size metrics
  echo "##DIRTREE"
  find . -type d -not -path '*/\.*' -exec sh -c '
    echo "DIR|{}|$(find "{}" -maxdepth 1 -type f | wc -l)|$(du -sh "{}" | cut -f1)"
  ' \; 2>/dev/null
  
  # Hardware-aware dependency scan
  echo "##DEPS"
  {
    nvidia-smi --query-gpu=name,driver_version --format=csv,noheader 2>/dev/null || echo "GPU|N/A"
    free -m | awk '/Mem:/ {printf "RAM|%dMB|%.1fGB\n", $2, $2/1024}'
    grep -hE '^(FROM|RUN|apt-get|pip|npm)' Dockerfile setup.sh 2>/dev/null
    jq -r '.dependencies | to_entries[] | "\(.key)|\(.value)"' package.json 2>/dev/null
    grep -hE '^[a-zA-Z0-9_-]+==' requirements.txt 2>/dev/null
  } | sort -u
  
  # Script analysis with execution patterns
  echo "##SCRIPTS"
  find scripts/ -type f -executable | while read -r script; do
    {
      echo "SCRIPT|$script"
      grep -m1 '# Version:' "$script" | cut -d':' -f2 | xargs
      grep -Ec 'log_message|echo' "$script"
      grep -q 'nvidia-smi' "$script" && echo "GPU|1" || echo "GPU|0"
    } | paste -sd '|'
  done
  
  # Configuration validation with JSON linting
  echo "##CONFIG"
  find config/ -type f | while read -r file; do
    {
      echo "CFG|$file|$(file -b --mime-type "$file")"
      [[ "$file" == *.json ]] && jq . "$file" >/dev/null 2>&1 && echo "JSON|VALID" || echo "JSON|INVALID"
    } | paste -sd '|'
  done
  
  # Test infrastructure analysis
  echo "##TESTS"
  {
    find tests/ -type f -name 'test_*.py' | wc -l
    grep -hrE 'def test_' tests/ 2>/dev/null | wc -l
    coverage report --fail-under=80 2>/dev/null | awk '/TOTAL/ {print $4}'
  } | awk 'NR==1 {print "PYTEST|"$0} NR==2 {print "CASES|"$0} NR==3 {print "COVERAGE|"$0}'
  
  # Enhanced error pattern detection with codes
  echo "##ERRORS"
  grep -hrE 'E[0-9]{3}|WARN|FAIL|CRITICAL' logs/* 2>/dev/null | head -n100 | awk '
    /E[0-9]{3}/ {print "CODED_ERR|"$0; next}
    /WARN/ {print "WARNING|"$0; next}
    {print "GENERIC_ERR|"$0}
  '
  
  # Build artifact analysis with hashes
  echo "##ARTIFACTS"
  find . -type f \( -name '*.pyc' -o -name '*.log' -o -name '*.csv' \) -exec sh -c '
    echo "ARTIFACT|{}|$(du -h "{}" | cut -f1)|$(md5sum "{}" | cut -d" " -f1)"
  ' \; 2>/dev/null
}

_main() {
  mkdir -p "$LOG_DIR"
  exec &> >(tee -a "$DEBUG_LOG")
  
  echo "[CTX_INFO] Starting project context scan v1.8"
  scan_project > "$CONTEXT_FILE"
  
  if [[ -s "$CONTEXT_FILE" ]]; then
    echo "[CTX_SUCCESS] Generated $CONTEXT_FILE with $(wc -l <"$CONTEXT_FILE") entries"
    exit 0
  else
    echo "[CTX_ERR] Failed to create context file" >&2
    exit 1
  fi
}

_main
EOL
}

_update_documentation() {
    cat >> README.md <<'EOL'

## AI Context Builder v1.8+

### Machine-Readable Format
#PROJECT_CONTEXT v1.8
##META|<unix_ts>|<git_ref>
##DIRTREE
DIR|<path>|<file_count>|<size>
##DEPS
<type>|<name>|<version>
##SCRIPTS
SCRIPT|<path>|<version>|<log_count>|<gpu_usage>
##CONFIG
CFG|<path>|<mime_type>|<validation>
##TESTS
PYTEST|<count>|<cases>|<coverage>
##ERRORS
<type>|<message>
##ARTIFACTS
ARTIFACT|<path>|<size>|<md5>
### Usage
Generate context (outputs to project_context.txt)
./scripts/ai_search.sh

Validate context format
file project_context.txt | grep 'ASCII text'

text

### Monitoring
Watch context generation
tail -f logs/project_scan/context_builder.log

Verify artifact integrity
md5sum project_context.txt

text
EOL
}

# Main update sequence
mkdir -p "$LOG_DIR"
{
echo "[UPDATE] Starting v$VERSION deployment"
_create_context_script
chmod +x "$CONTEXT_SCRIPT"
_update_documentation

# Validate components
[[ -x "$CONTEXT_SCRIPT" ]] || { echo "[UPDATE_ERR] Missing executable permissions"; exit 1; }
[[ -f "README.md" ]] || { echo "[UPDATE_ERR] Missing README"; exit 1; }

# Commit changes
git add -A
git commit -m "System v$VERSION - Enhanced Context" \
          -m "- Hardware-aware scanning" \
          -m "- Artifact fingerprinting" \
          -m "- Coverage tracking" \
          -m "- JSON validation"

echo "[UPDATE_SUCCESS] v$VERSION installed"
echo "Next: Generate context with './scripts/ai_search.sh'"
} > "$DEBUG_LOG" 2>&1