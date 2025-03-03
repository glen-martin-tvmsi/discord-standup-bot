#!/bin/bash
# updates/update-1.7.sh - AI Context Builder v1.7

set -Eeuo pipefail
trap 'echo "Update failed! Check logs/update-1.7.log" >&2' ERR

VERSION="1.7"
SEARCH_SCRIPT="scripts/ai_search.sh"
CONTEXT_FILE="project_context.txt"
LOG_DIR="logs"

# Create directory structure if missing
mkdir -p "$LOG_DIR"

{
echo "Creating AI context builder v$VERSION..."
cat > "$SEARCH_SCRIPT" <<'EOL'
#!/bin/bash
# AI Context Crawler v1.7

set -o pipefail

scan_project() {
  echo "#PROJECT_CONTEXT v1.7"
  echo "##META|$(date +%s)|$(git rev-parse --short HEAD 2>/dev/null||echo 'no_vcs')"
  
  # Directory structure analysis
  echo "##DIRTREE"
  find . -type d -not -path '*/\.*' | sed 's|^\./||' | sort | while read -r dir; do
    count=$(find "$dir" -maxdepth 1 -type f | wc -l)
    echo "DIR|$dir|$count"
  done
  
  # Dependency analysis
  echo "##DEPS"
  {
    grep -hE '^(FROM|RUN|apt-get|pip|npm)' Dockerfile setup.sh 2>/dev/null || true
    grep -hPo '"([A-Za-z0-9_-]+)":\s*"[^"]+"' package.json 2>/dev/null || true
    grep -hE '^[a-zA-Z0-9_-]+==' requirements.txt 2>/dev/null || true
  } | sort -u
  
  # Script analysis
  echo "##SCRIPTS"
  find scripts/ -type f -executable | while read -r script; do
    {
      echo "SCRIPT|$script"
      grep -m1 '# Description:' "$script" || echo "DESC|No description"
      grep -m1 'VERSION=' "$script" | cut -d'"' -f2 || echo "VER|unknown"
      grep -E '^log_message|^echo' "$script" | wc -l | awk '{print "LOG|"$1}'
    } | paste -sd '|'
  done
  
  # Configuration analysis
  echo "##CONFIG"
  find config/ -type f -exec file {} \; | while read -r line; do
    file=$(echo "$line" | cut -d: -f1)
    type=$(echo "$line" | cut -d: -f2- | xargs)
    echo "CFG|$file|$type"
  done
  
  # Test infrastructure
  echo "##TESTS"
  find tests/ -type f -name 'test_*.py' | wc -l | awk '{print "PYTEST|"$1}'
  grep -hrE 'def test_' tests/ 2>/dev/null | wc -l | awk '{print "CASES|"$1}'
  
  # Error patterns
  echo "##ERRORS"
  grep -hrE 'ERROR|WARN|FAIL' logs/* 2>/dev/null | head -n 100 || true
  
  # Build artifacts
  echo "##ARTIFACTS"
  find . -type f \( -name '*.pyc' -o -name '*.log' -o -name '*.csv' \) | wc -l | awk '{print "BUILD_OUT|"$1}'

} > project_context.txt
EOL

# Add documentation
cat >> README.md <<'EOL'

## AI Context Builder (v1.7+)

Generate project snapshot
bash scripts/ai_search.sh

Output format:
#PROJECT_CONTEXT v1.7
##META|<unix_ts>|<git_sha>
##DIRTREE
DIR|<path>|<file_count>
##DEPS
<dependency_line>
##SCRIPTS
SCRIPT|<path>|<desc>|<version>|<log_lines>
##CONFIG
CFG|<file>|<type>
##TESTS
PYTEST|<count>
CASES|<count>
##ERRORS
<error_line>
##ARTIFACTS
BUILD_OUT|<count>

text

EOL

# Set permissions
chmod +x "$SEARCH_SCRIPT"

# Commit changes
git add "$SEARCH_SCRIPT" README.md
git commit -m "System v$VERSION - AI Context Builder" \
          -m "- Automated project analysis script" \
          -m "- Machine-readable context format" \
          -m "- Dependency/configuration mapping"

echo "Update v$VERSION applied successfully!"
echo "AI context file will be generated at: project_context.txt"
} > "$LOG_DIR/update-1.7.log" 2>&1