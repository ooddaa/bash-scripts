#!/bin/bash

# Script to find all .tool-versions files from current directory
# and print their contents with paths, highlighting specified tool versions
# Usage: ./find-tool-versions.sh [tool_name] [--down]
#   [tool_name] - Tool to highlight (default: nodejs)
#   --down      - Search in all subdirectories instead of going up to HOME

# Color codes for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
TOOL_TO_HIGHLIGHT="nodejs"
SEARCH_DOWN=false

for arg in "$@"; do
  if [[ "$arg" == "--down" ]]; then
    SEARCH_DOWN=true
  elif [[ "$arg" != --* ]]; then
    TOOL_TO_HIGHLIGHT="$arg"
  fi
done

if [[ "$SEARCH_DOWN" == true ]]; then
  echo -e "${BLUE}Searching for .tool-versions files in current directory and all subdirectories...${NC}"
else
  echo -e "${BLUE}Searching for .tool-versions files from current directory up to $HOME...${NC}"
fi
echo -e "${BLUE}Highlighting entries for: ${YELLOW}${TOOL_TO_HIGHLIGHT}${NC}\n"

# Start from current directory
current_dir=$(pwd)

# Function to check file and print its contents if it exists
check_and_print_file() {
  local dir="$1"
  local file_path="$dir/.tool-versions"

  if [ -f "$file_path" ]; then
    echo -e "${GREEN}Found .tool-versions at:${NC} $dir"
    echo -e "${YELLOW}Contents:${NC}"

    # Print file contents with specified tool highlighted
    while IFS= read -r line; do
      if [[ $line == ${TOOL_TO_HIGHLIGHT}* ]]; then
        echo -e "  ${YELLOW}$line${NC}"
      else
        echo "  $line"
      fi
    done <"$file_path"
    echo ""
    return 0
  fi
  return 1
}

# Function to generate find exclusion patterns from .gitignore
generate_exclusions() {
  local exclusions=()

  # Always exclude node_modules and dist
  exclusions+=("-not -path '*/node_modules/*'")
  exclusions+=("-not -path '*/dist/*'")

  # Read .gitignore if it exists
  if [ -f ".gitignore" ]; then
    while IFS= read -r line; do
      # Skip empty lines and comments
      if [[ -n "$line" && ! "$line" =~ ^# ]]; then
        # Remove leading and trailing slashes
        pattern=$(echo "$line" | sed 's|^/||; s|/$||')
        # Skip if empty after processing
        if [[ -n "$pattern" ]]; then
          # Convert gitignore pattern to find pattern
          exclusions+=("-not -path '*/$pattern/*'")
        fi
      fi
    done <".gitignore"
  fi

  echo "${exclusions[@]}"
}

# Perform search based on direction flag
if [[ "$SEARCH_DOWN" == true ]]; then
  # Get exclusion patterns
  EXCLUSIONS=$(generate_exclusions)

  # Search down - find all .tool-versions files in current directory and subdirectories
  # Use eval to properly handle the exclusion arguments
  FIND_CMD="find \"$(pwd)\" -name \".tool-versions\" -type f $EXCLUSIONS 2>/dev/null"
  while IFS= read -r file_path; do
    dir=$(dirname "$file_path")
    check_and_print_file "$dir"
  done < <(eval "$FIND_CMD")
else
  # Search up - check current directory and its parents up to HOME
  while [[ "$current_dir" == $HOME* || "$current_dir" == "$HOME" ]]; do
    check_and_print_file "$current_dir"

    # Break if we've reached HOME
    if [[ "$current_dir" == "$HOME" ]]; then
      break
    fi

    # Go up one directory
    current_dir=$(dirname "$current_dir")
  done
fi

echo -e "${BLUE}Search completed.${NC}"
