## {{prTitle}}

### Work Summary

| Commit | Description |
|--------|-------------|
{{#commits}}
| `{{hash}}` | {{message}} |
{{/commits}}

### Changed Files

{{#files}}
- `{{path}}` — {{description}}
{{/files}}

### Implementation Details

{{implementationDetails}}

### Checklist

- [ ] base/compare branch confirmed
- [ ] Build success (`bun run build`)
- [ ] Type check passed (`tsc --noEmit`)
- [ ] No `console.log` in production code
- [ ] `.env.example` updated if needed

### Review Guide

| Priority | Action | Scope |
|----------|--------|-------|
| **P1** | Request Changes | Feature bugs, security issues |
| **P2** | Comment | Style/structure improvement suggestions |
| **P3** | Approve | Minor opinions |
