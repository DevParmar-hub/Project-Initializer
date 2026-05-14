# dev-arch (Development Environment Architect)

I got tired of setting up the same folders and files every time I started a project. 
This tool does it for me.

## What it does

Scaffolds a project, sets up Git, creates a GitHub repo, and optionally adds Tailwind — 
one command instead of ten.

## Install

You need WSL if you're on Windows. Then:

```bash
curl -o ~/.local/bin/dev-arch https://raw.githubusercontent.com/DevParmar-hub/dev-arch/main/dev-arch.sh
chmod +x ~/.local/bin/dev-arch
```

## Usage

```bash
dev-arch <project_name> -t <type> [options]
```

## Project types

| Flag | What you get |
|------|-------------|
| `-t python` | src/, tests/, main.py, requirements.txt |
| `-t web` | index.html, style.css, script.js |
| `-t react` | React + Vite |
| `-t node` | Express + MongoDB + project structure |
| `-t fullstack` | React frontend + Node backend |

## Options

| Flag | What it does |
|------|-------------|
| `-g` | Init a local Git repo |
| `-G` | Create a GitHub repo and push |
| `--private` | Make the GitHub repo private |
| `-tw` | Add Tailwind CSS (React only) |
| `--full` | Boilerplate code instead of empty files (Node only) |

## Config

Don't want to type the same flags every time:

```bash
dev-arch --init-config
```

Opens a config file at `~/.devarchrc`. Set your defaults there.

## Requirements

- WSL (Windows) or Linux/Mac
- Node.js + npm (for React/Node projects)
- GitHub CLI — `gh auth login` (for `-G` flag)

## Help

```bash
dev-arch --help
```
