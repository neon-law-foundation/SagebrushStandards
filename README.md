# Sagebrush Standards

Questionnaires, Workflows, and Templates together to create computable
contracts.

## Installation

```bash
./install.sh
```

This installs the `standards` CLI to `~/.local/bin/standards`.

Make sure `~/.local/bin` is in your PATH:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

## Commands

### `standards lint <directory> [--fix]`

Validates that all Markdown files (except README.md) have lines ≤120 characters.

```bash
# Check current directory
standards lint .

# Check specific directory
standards lint ShookFamily/Estate

# Auto-fix violations
standards lint . --fix
```

**Note:** README.md files are excluded from linting.

### `standards voice <directory>`

Checks Markdown files (except README.md) for active voice and tone compliance
according to the writing guidelines in
CLAUDE.md.

```bash
# Check current directory
standards voice .

# Check specific directory
standards voice ShookFamily/Estate
```

**Note:** README.md files are excluded from voice checking.

### `standards setup`

Creates the `~/Standards` directory structure and fetches all projects from the
Sagebrush API.

```bash
standards setup
```

### `standards sync`

Syncs all projects in `~/Standards` by running `git pull` on existing
repositories.

```bash
standards sync
```

## Development

Run tests:

```bash
swift test
```

Build the project:

```bash
swift build
```
