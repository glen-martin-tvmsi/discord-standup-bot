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
