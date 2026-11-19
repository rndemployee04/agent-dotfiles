# Agent Dotfiles (`~/agent-dotfiles`)

A single, portable repository containing AI dotfiles: subagent definitions, skills, engineering rules, and MCP configurations—interoperable across **Antigravity CLI (`agy`)** and **Claude Code CLI (`claude`)**.

---

## Architecture Overview

```
~/agent-dotfiles/
├── agents/                     # Canonical 4-Stage Subagent Pipeline
│   ├── planner/agent.md        # Architecture, requirements & task decomposition
│   ├── implementer/agent.md    # Core code authoring inside isolated Git worktrees
│   ├── tester/agent.md         # Test runner, regression checker & log firewall
│   └── reviewer/agent.md       # Senior diff auditor for standards, security & specs
├── skills/                     # 40 Portable SKILL.md modules (Matt Pocock catalog + custom)
├── rules/
│   └── AGENTS.md               # Production-grade engineering guidelines & GitHub guardrails
├── mcp/
│   └── mcp_config.json         # Lean MCP servers (Context7 + Guardrailed GitHub)
├── setup.sh                    # Universal symlink installer & upstream skills updater
└── README.md                   # Documentation & workflow guide
```

---

## Model Context Protocol (MCP) Configuration

The repo includes two focused, high-leverage MCP servers:

1. **Context7 (`@upstash/context7-mcp`)**: Real-time framework documentation search (stops API hallucinations).
2. **GitHub (`@modelcontextprotocol/server-github`)**: Inspect issues, check PRs, and create draft PRs.

### GitHub Guardrails

To protect your repositories:

- **Fine-Grained PAT Scoping**:
  - Scope to **selected repositories only**.
  - **Issues**: Read & Write.
  - **Pull Requests**: Read & Write.
  - **Contents**: Read-only (code commits are handled locally via Git worktrees).
  - All administrative and secret permissions: **Disabled**.
- **Agent Rules Enforced in `AGENTS.md`**:
  - Any PR created must be opened as a **Draft** (`draft: true`).
  - Merging PRs or deleting branches/repos is strictly forbidden.
  - Never include credentials, tokens, or `.env` in comments or PRs.

To activate GitHub MCP, export your token in your shell (`~/.bashrc` or `~/.zshrc`):

```bash
export GITHUB_TOKEN="github_pat_..."
```

---

## Path & Discovery Standards

| Component            | Antigravity (`agy` / IDE) Path               | Claude Code CLI Path                   | Dotfiles Source                           |
| :------------------- | :------------------------------------------- | :------------------------------------- | :---------------------------------------- |
| **Global Agents**    | `~/.gemini/config/agents/{name}/agent.md`    | `~/.claude/agents/{name}.md`           | `~/agent-dotfiles/agents/{name}/agent.md` |
| **Workspace Agents** | `<workspace>/.agents/agents/{name}/agent.md` | `<workspace>/.claude/agents/{name}.md` | Local project override                    |
| **Global Skills**    | `~/.gemini/config/skills/{name}/SKILL.md`    | `~/.claude/skills/{name}/SKILL.md`     | `~/agent-dotfiles/skills/{name}/SKILL.md` |
| **Global Rules**     | `~/.gemini/GEMINI.md`                        | `~/.claude/CLAUDE.md`                  | `~/agent-dotfiles/rules/AGENTS.md`        |
| **Global MCP**       | `~/.gemini/config/mcp_config.json`           | `~/.claude.json` (`mcpServers`)        | `~/agent-dotfiles/mcp/mcp_config.json`    |

---

## Quick Start (On Any Machine)

1. **Clone this repository anywhere**:

   ```bash
   git clone <your-private-repo-url> ~/agent-dotfiles
   cd ~/agent-dotfiles
   ```

2. **Run the setup script**:

   ```bash
   ./setup.sh
   ```

3. **Verify in `agy`**:

   ```bash
   agy agents
   # implementer, planner, reviewer, tester

   agy mcp list
   # context7 (enabled), github (enabled)
   ```

---

## ⚠️ Things to Keep in Mind When Re-Running Setup

When running `./setup.sh` on an existing setup:

1. **Upstream Skills Overwrite vs. Custom Skills**:
   - Folders matching upstream `mattpocock/skills` are refreshed to their latest GitHub releases.
   - Any **custom skills** you add (e.g., `skills/laravel-setup/`, `skills/my-tool/`) are **safely preserved**.
   - *Tip*: If you want to modify an upstream skill, rename its folder (e.g., `skills/custom-tdd/`) so updates don't replace your edits.

2. **Active CLI Sessions Do Not Hot-Reload**:
   - If you have an `agy` or `claude` session running in another terminal window while updating, exit (`Ctrl + D`) and relaunch the CLI to load newly added tools and agents.

3. **Secrets & Tokens**:
   - Re-running the script never touches or clears your shell environment variables.
   - Ensure `export GITHUB_TOKEN="github_pat_..."` remains in your `~/.bashrc` or `~/.zshrc`.
