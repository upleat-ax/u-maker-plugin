# failure-handling — Human Verification + Failure Triage (Steps 7+8)

Detailed protocols for when a browser step fails or requires human-in-the-loop confirmation. Load when implementing Steps 7 and 8 of the main workflow.

## Step 7: Human Verification (only when flow requires it)

Pause for confirmation when the journey crosses an external boundary:

| Flow | Question |
|------|----------|
| OAuth | "Please sign in with {provider} and confirm the redirect returned to the app." |
| Payments | "Complete the sandbox purchase and confirm order appears in dashboard." |
| Email | "Check inbox for `{subject}` and confirm content." |
| SMS | "Confirm receipt of the verification code." |
| External APIs | "Confirm the {service} integration responded successfully." |

Use `AskUserQuestion`:

```
Human Verification Needed
This scenario requires {flow}. Please:
1. {Action}
2. {Verify}

Did it work correctly?
  Yes — continue testing
  No  — describe the issue
```

## Step 8: Handle Failures

When a step fails (assertion, navigation, timeout):

1. Capture an error screenshot:
   ```
   browser_take_screenshot  path: .u-maker/.state/screenshots/errors/{YYYY-MM-DD}-{slug}.png  fullPage: true
   ```
2. Collect console + network evidence:
   ```
   browser_console_messages
   browser_network_requests
   ```
3. Ask the caller via `AskUserQuestion`:
   ```
   Test Failed: {route}
   Issue: {description}
   Console errors: {n}

   How to proceed?
     Fix now  — investigate and patch
     Create todo — defer via /u-gatekeeping todo with priority p1
     Skip     — record as skipped, continue
   ```
4. Per choice:
   - **Fix now** → debug → propose patch → re-run Step 6 for that route only
   - **Create todo** → append to `.u-maker/.state/todos.json` with `priority=p1`, `source=u-tools-browser`, `route={route}`
   - **Skip** → mark result `skipped` and continue
