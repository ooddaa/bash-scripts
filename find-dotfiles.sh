#!/bin/bash

# Script to find specific dotfiles from current directory
# either up the filesystem or down through subdirectories
# Usage: ./find-dotfiles.sh [dotfile_name] [--down]
#   [dotfile_name] - Dotfile to search for (default: .tool-versions)
#   --down         - Search in all subdirectories instead of going up to HOME

# Color codes for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
DOTFILE=".tool-versions"
SEARCH_DOWN=false

for arg in "$@"; do
  if [[ "$arg" == "--down" ]]; then
    SEARCH_DOWN=true
  elif [[ "$arg" != --* ]]; then
    # Remove any leading dot if provided
    if [[ "$arg" == .* ]]; then
      DOTFILE="$arg"
    else
      DOTFILE=".$arg"
    fi
  fi
done

if [[ "$SEARCH_DOWN" == true ]]; then
  echo -e "${BLUE}Searching for ${YELLOW}${DOTFILE}${BLUE} files in current directory and all subdirectories...${NC}"
else
  echo -e "${BLUE}Searching for ${YELLOW}${DOTFILE}${BLUE} files from current directory up to $HOME...${NC}"
fi

# Start from current directory
current_dir=$(pwd)

# Function to check file and print its path if it exists
check_and_print_file() {
  local dir="$1"
  local file_path="$dir/$DOTFILE"
  
  if [ -f "$file_path" ]; then
    echo -e "${GREEN}Found $DOTFILE at:${NC} $file_path"
    return 0
  fi
  return 1
}

# Function to generate find exclusion patterns from .gitignore
generate_exclusions() {
  local exclusions=()
  
  # Always exclude common directories to improve performance
  exclusions+=("-not -path '*/node_modules/*'")
  exclusions+=("-not -path '*/dist/*'")
  exclusions+=("-not -path '*/.git/*'")
  
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
    done < ".gitignore"
  fi
  
  echo "${exclusions[@]}"
}

# Track if we found any files
found_any=false

# Perform search based on direction flag
if [[ "$SEARCH_DOWN" == true ]]; then
  # Get exclusion patterns
  EXCLUSIONS=$(generate_exclusions)
  
  # Search down - find all specified dotfiles in current directory and subdirectories
  # Use eval to properly handle the exclusion arguments
  FIND_CMD="find \"$(pwd)\" -name \"$DOTFILE\" -type f $EXCLUSIONS 2>/dev/null"
  
  while IFS= read -r file_path; do
    echo -e "${GREEN}Found $DOTFILE at:${NC} $file_path"
    found_any=true
  done < <(eval "$FIND_CMD")
else
  # Search up - check current directory and its parents up to HOME
  while [[ "$current_dir" == $HOME* || "$current_dir" == "$HOME" ]]; do
    if check_and_print_file "$current_dir"; then
      found_any=true
    fi
    
    # Break if we've reached HOME
    if [[ "$current_dir" == "$HOME" ]]; then
      break
    fi
    
    # Go up one directory
    current_dir=$(dirname "$current_dir")
  done
fi

if [[ "$found_any" == false ]]; then
  echo -e "${YELLOW}No $DOTFILE files found.${NC}"
fi

echo -e "${BLUE}Search completed.${NC}"
