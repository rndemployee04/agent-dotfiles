#!/usr/bin/env bash
# ==============================================================================
# Agent Dotfiles Setup & Continuous Updater Script
# ==============================================================================
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$DOTFILES_DIR/skills"
AGENTS_DIR="$DOTFILES_DIR/agents"
RULES_DIR="$DOTFILES_DIR/rules"
MCP_DIR="$DOTFILES_DIR/mcp"

# ------------------------------------------------------------------------------
# Colors & Formatting
# ------------------------------------------------------------------------------
if [ -t 1 ]; then
    BOLD='\033[1m'
    DIM='\033[2m'
    CYAN='\033[0;36m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    MAGENTA='\033[0;35m'
    RED='\033[0;31m'
    NC='\033[0m' # No Color
else
    BOLD=''
    DIM=''
    CYAN=''
    GREEN=''
    YELLOW=''
    BLUE=''
    MAGENTA=''
    RED=''
    NC=''
fi

# ------------------------------------------------------------------------------
# CLI Flag Handling
# ------------------------------------------------------------------------------
AUTO_CONFIRM=0
for arg in "$@"; do
    case "$arg" in
        -y|--yes)
            AUTO_CONFIRM=1
            ;;
        -h|--help)
            echo "Usage: ./setup.sh [-y|--yes]"
            echo "  -y, --yes    Skip interactive confirmation and run automatically"
            exit 0
            ;;
    esac
done

# ------------------------------------------------------------------------------
# Welcome Banner & Pre-Flight Notice
# ------------------------------------------------------------------------------
echo -e "${BOLD}${CYAN}==================================================================${NC}"
echo -e "${BOLD}${CYAN}   🚀 Agent Dotfiles Universal Setup & Continuous Updater         ${NC}"
echo -e "${BOLD}${CYAN}==================================================================${NC}"
echo -e "${DIM}Repository Path: $DOTFILES_DIR${NC}"
echo ""
echo -e "${BOLD}${YELLOW}⚠️  PRE-FLIGHT NOTICES (When re-running on an existing setup):${NC}"
echo -e "  ${DIM}1.${NC} ${BOLD}Upstream Skills:${NC} Folders matching ${CYAN}mattpocock/skills${NC} are updated."
echo -e "     ${DIM}Custom skills are safely preserved.${NC}"
echo -e "  ${DIM}2.${NC} ${BOLD}Active Sessions:${NC} Restart any running ${CYAN}agy${NC} or ${CYAN}claude${NC} sessions"
echo -e "     after this script finishes so they reload tools and configs."
echo -e "  ${DIM}3.${NC} ${BOLD}Secrets:${NC} Ensure ${CYAN}GITHUB_TOKEN${NC} is exported in your shell profile."
echo -e "${BOLD}${CYAN}------------------------------------------------------------------${NC}"

# Interactive Confirmation
if [ "$AUTO_CONFIRM" -eq 0 ] && [ -t 0 ]; then
    echo -e -n "${BOLD}${MAGENTA}⚡ Proceed with setup and update? [Y/n]: ${NC}"
    read -r response
    response="${response:-y}"
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Aborted by user.${NC}"
        exit 0
    fi
fi

# Ensure directories exist
mkdir -p "$SKILLS_DIR" "$AGENTS_DIR" "$RULES_DIR" "$MCP_DIR"

# ------------------------------------------------------------------------------
# 1. Update Upstream Matt Pocock Skills
# ------------------------------------------------------------------------------
echo ""
echo -e "${BOLD}${BLUE}[1/5] 📦 Updating skills from upstream...${NC}"

if command -v curl >/dev/null 2>&1 && command -v tar >/dev/null 2>&1; then
    TMP_SKILLS=$(mktemp -d)
    echo -e "  ${CYAN}•${NC} Fetching latest archive from ${DIM}github.com/mattpocock/skills${NC}..."
    if curl -sL "https://github.com/mattpocock/skills/archive/refs/heads/main.tar.gz" -o "$TMP_SKILLS/skills.tar.gz"; then
        tar -xzf "$TMP_SKILLS/skills.tar.gz" -C "$TMP_SKILLS"
        find "$TMP_SKILLS" -name "SKILL.md" | while read -r skill_file; do
            skill_source_dir="$(dirname "$skill_file")"
            skill_name="$(basename "$skill_source_dir")"
            rm -rf "$SKILLS_DIR/$skill_name"
            cp -r "$skill_source_dir" "$SKILLS_DIR/$skill_name"
        done
        echo -e "  ${GREEN}✓${NC} Successfully synced all upstream Matt Pocock skills"
    else
        echo -e "  ${YELLOW}!${NC} Upstream fetch skipped or offline. Preserved existing skills."
    fi
    rm -rf "$TMP_SKILLS"
fi

SKILL_COUNT=$(find "$SKILLS_DIR" -mindepth 1 -maxdepth 1 -type d | wc -l)
echo -e "  ${GREEN}✓${NC} Active skills in dotfiles: ${BOLD}${CYAN}$SKILL_COUNT${NC}"

# ------------------------------------------------------------------------------
# 2. Update Third-Party MCP Server Packages
# ------------------------------------------------------------------------------
echo ""
echo -e "${BOLD}${BLUE}[2/5] 🔌 Checking third-party MCP servers...${NC}"
if command -v npm >/dev/null 2>&1; then
    echo -e "  ${CYAN}•${NC} Checking Context7 MCP package..."
    C7_VER=$(npm view @upstash/context7-mcp version 2>/dev/null || echo "latest")
    echo -e "    ${GREEN}✓${NC} Context7 latest version: ${BOLD}$C7_VER${NC}"

    echo -e "  ${CYAN}•${NC} Checking GitHub MCP package..."
    GH_VER=$(npm view @modelcontextprotocol/server-github version 2>/dev/null || echo "latest")
    echo -e "    ${GREEN}✓${NC} GitHub MCP latest version: ${BOLD}$GH_VER${NC}"
fi

# ------------------------------------------------------------------------------
# 3. Check CLI Tool Updates
# ------------------------------------------------------------------------------
echo ""
echo -e "${BOLD}${BLUE}[3/5] 🛠️  Checking CLI tool updates...${NC}"
if command -v agy >/dev/null 2>&1; then
    echo -e "  ${CYAN}•${NC} Checking Antigravity CLI (${BOLD}agy${NC})..."
    agy update 2>/dev/null || true
else
    echo -e "  ${DIM}agy CLI not found in PATH; skipping CLI update check.${NC}"
fi

# ------------------------------------------------------------------------------
# 4. Link & Configure Claude Code CLI (~/.claude)
# ------------------------------------------------------------------------------
echo ""
echo -e "${BOLD}${BLUE}[4/5] 🧠 Linking Claude Code CLI (~/.claude)...${NC}"
mkdir -p "$HOME/.claude"

# Claude Skills
if [ -d "$HOME/.claude/skills" ] && [ ! -L "$HOME/.claude/skills" ]; then
    echo -e "  ${YELLOW}!${NC} Backing up existing ~/.claude/skills to ~/.claude/skills.bak..."
    mv "$HOME/.claude/skills" "$HOME/.claude/skills.bak"
fi
ln -sfn "$SKILLS_DIR" "$HOME/.claude/skills"
echo -e "  ${GREEN}✓${NC} ~/.claude/skills ${DIM}->${NC} $SKILLS_DIR"

# Claude Agents
rm -rf "$HOME/.claude/agents"
mkdir -p "$HOME/.claude/agents"
for agent_dir in "$AGENTS_DIR"/*; do
    if [ -d "$agent_dir" ] && [ -f "$agent_dir/agent.md" ]; then
        name="$(basename "$agent_dir")"
        ln -sfn "$agent_dir/agent.md" "$HOME/.claude/agents/${name}.md"
    fi
done
echo -e "  ${GREEN}✓${NC} ~/.claude/agents/*.md ${DIM}->${NC} individual agent specs"

# Claude Global Rule
if [ -f "$RULES_DIR/AGENTS.md" ]; then
    ln -sfn "$RULES_DIR/AGENTS.md" "$HOME/.claude/CLAUDE.md"
    echo -e "  ${GREEN}✓${NC} ~/.claude/CLAUDE.md ${DIM}->${NC} $RULES_DIR/AGENTS.md"
fi

# Claude MCP Servers
if [ -f "$MCP_DIR/mcp_config.json" ] && [ -f "$HOME/.claude.json" ]; then
    python3 -c "
import json
with open('$MCP_DIR/mcp_config.json') as f:
    hub_mcp = json.load(f)
with open('$HOME/.claude.json') as f:
    claude_cfg = json.load(f)
if 'mcpServers' not in claude_cfg:
    claude_cfg['mcpServers'] = {}
claude_cfg['mcpServers'].update(hub_mcp.get('mcpServers', {}))
with open('$HOME/.claude.json', 'w') as f:
    json.dump(claude_cfg, f, indent=2)
"
    echo -e "  ${GREEN}✓${NC} ~/.claude.json ${DIM}->${NC} merged Context7 & GitHub MCP servers"
fi

# ------------------------------------------------------------------------------
# 5. Link & Configure Antigravity CLI / IDE (~/.gemini/config)
# ------------------------------------------------------------------------------
echo ""
echo -e "${BOLD}${BLUE}[5/5] 🌌 Linking Antigravity CLI / IDE (~/.gemini/config)...${NC}"
mkdir -p "$HOME/.gemini/config"

# Antigravity Skills
if [ -d "$HOME/.gemini/config/skills" ] && [ ! -L "$HOME/.gemini/config/skills" ]; then
    echo -e "  ${YELLOW}!${NC} Backing up ~/.gemini/config/skills to ~/.gemini/config/skills.bak..."
    mv "$HOME/.gemini/config/skills" "$HOME/.gemini/config/skills.bak"
fi
ln -sfn "$SKILLS_DIR" "$HOME/.gemini/config/skills"
echo -e "  ${GREEN}✓${NC} ~/.gemini/config/skills ${DIM}->${NC} $SKILLS_DIR"

# Antigravity Agents (~/.gemini/config/agents/{agent_name}/agent.md)
rm -rf "$HOME/.gemini/config/agents"
ln -sfn "$AGENTS_DIR" "$HOME/.gemini/config/agents"
echo -e "  ${GREEN}✓${NC} ~/.gemini/config/agents ${DIM}->${NC} $AGENTS_DIR"

# Antigravity MCP Servers
if [ -f "$MCP_DIR/mcp_config.json" ]; then
    ln -sfn "$MCP_DIR/mcp_config.json" "$HOME/.gemini/config/mcp_config.json"
    echo -e "  ${GREEN}✓${NC} ~/.gemini/config/mcp_config.json ${DIM}->${NC} $MCP_DIR/mcp_config.json"
fi

# Antigravity Global Rule
if [ -f "$RULES_DIR/AGENTS.md" ]; then
    ln -sfn "$RULES_DIR/AGENTS.md" "$HOME/.gemini/GEMINI.md"
    echo -e "  ${GREEN}✓${NC} ~/.gemini/GEMINI.md ${DIM}->${NC} $RULES_DIR/AGENTS.md"
fi

# ------------------------------------------------------------------------------
# Summary & Verification Card
# ------------------------------------------------------------------------------
echo ""
echo -e "${BOLD}${GREEN}==================================================================${NC}"
echo -e "${BOLD}${GREEN}  ✨ Setup & Update Complete! Everything is in sync:${NC}"
echo -e "     ${BOLD}• Active Skills:${NC}      ${CYAN}$SKILL_COUNT skills${NC} (Matt Pocock + custom)"
echo -e "     ${BOLD}• Swarm Agents:${NC}       ${CYAN}$(find "$AGENTS_DIR" -name "agent.md" | wc -l) agents${NC} (planner, implementer, tester, reviewer)"
echo -e "     ${BOLD}• MCP Servers:${NC}        ${CYAN}Context7${NC} (live docs), ${CYAN}GitHub${NC} (guardrailed)"
echo -e "     ${BOLD}• Rules Active:${NC}       ${CYAN}AGENTS.md${NC} (Local-First Grounding)"
echo -e "${BOLD}${GREEN}==================================================================${NC}"
