---
title: "Invalid Standard Example"
# Missing required fields: code and respondant_type
version: "1.0.0"
---

This is an example of a standards file that will fail validation because it is missing required YAML frontmatter fields.

## What's Wrong With This File

1. **Missing `code` field**: Every standard must have a unique identifier
2. **Missing `respondant_type` field**: Must specify "individual", "organization", or "both"
3. The `title` field is present, which is good

## How to Fix It

Add the missing fields to the YAML frontmatter:

```yaml
---
code: EXAMPLE001
title: "Invalid Standard Example"
respondant_type: individual
---
```

This file is intentionally invalid to demonstrate the Standards CLI validation capabilities.
