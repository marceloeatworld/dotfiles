#!/usr/bin/env bash
set -euo pipefail

# Install/update Cloudflare skill for Claude Code (and optionally OpenCode)
# Usage: install-cloudflare-skill.sh [--with-opencode]

REPO_URL="https://github.com/dmmulroy/cloudflare-skill.git"
SKILL_NAME="cloudflare"

with_opencode=false
[[ "${1:-}" == "--with-opencode" ]] && with_opencode=true

echo "Installing/updating Cloudflare skill..."

# Create temp directory
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

# Clone repo
echo "Fetching latest from GitHub..."
git clone --depth 1 --quiet "$REPO_URL" "$tmp_dir"

# Claude Code paths
claude_skill="$HOME/.claude/skills"
claude_cmd="$HOME/.claude/commands"

# Install for Claude Code
echo "Installing for Claude Code..."
mkdir -p "$claude_skill" "$claude_cmd"
rm -rf "${claude_skill}/${SKILL_NAME}"
cp -r "${tmp_dir}/skills/${SKILL_NAME}" "${claude_skill}/"
cp "${tmp_dir}/command/${SKILL_NAME}.md" "${claude_cmd}/"
echo "  -> ${claude_skill}/${SKILL_NAME}/"

# Install for OpenCode (optional)
if $with_opencode; then
  opencode_skill="$HOME/.config/opencode/skill"
  opencode_cmd="$HOME/.config/opencode/command"

  echo "Installing for OpenCode..."
  mkdir -p "$opencode_skill" "$opencode_cmd"
  rm -rf "${opencode_skill}/${SKILL_NAME}"
  cp -r "${tmp_dir}/skills/${SKILL_NAME}" "${opencode_skill}/"
  cp "${tmp_dir}/command/${SKILL_NAME}.md" "${opencode_cmd}/"
  echo "  -> ${opencode_skill}/${SKILL_NAME}/"
fi

echo "Done!"
