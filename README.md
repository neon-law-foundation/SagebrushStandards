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

### `standards pdf <file>`

Converts a standard Markdown file to PDF format. The command validates the file
first (same as `standards lint`), strips the YAML frontmatter, and generates a
PDF with:

- Standard American letter size (8.5 x 11 inches)
- 1-inch margins on all sides
- Professional typography

The PDF is created in the same directory as the input file with a `.pdf`
extension.

```bash
# Convert a standard to PDF
standards pdf nevada.md

# Output: nevada.pdf (in the same directory)
```

**Requirements:**

- Input file must be a valid standard with YAML frontmatter
- All lines must be ≤120 characters
- Must have a `title` field in frontmatter
- Requires `pandoc` to be installed: `brew install pandoc`

**Note:** If validation fails, the command will display detailed error messages
and refuse to generate the PDF until issues are fixed.

## Development

Run tests:

```bash
swift test
```

Build the project:

```bash
swift build
```
