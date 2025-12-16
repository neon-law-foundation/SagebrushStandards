# Format Markdown

## Usage

```txt
/format-markdown
```

Format markdown files or those ending in `.md` with these steps.

1. Run `markdownlint-cli2 --fix "**/*.md"` to auto-fix markdown issues.
2. Fix any remaining issues except for `MD013` line length issues.
3. Re-run `markdownlint-cli2 "**/*.md"` to ensure all non-line length issues
  are fixed. Confirm with the developer if
   you are unsure how to fix an issue.
4. Note all of the `MD013` line length issues.
5. Use the Task tool to launch the `markdown-formatter` agent to fix all
  line-length issues. The agent will
   intelligently reflow text to stay within 120 characters while preserving code
   blocks, tables, links, and document
   structure.
6. Confirm that all markdown files are formatted correctly by running
  `markdownlint-cli2 "**/*.md"`. **MANDATORY** this
   must exit 0.
