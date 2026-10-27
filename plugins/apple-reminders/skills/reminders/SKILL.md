---
name: reminders
description: Read and manage the user's Apple Reminders on macOS — list reminder lists, show open reminders, add a reminder, or mark one complete. Use when the user mentions Reminders, their to-do list in Reminders, or asks to be reminded of something on their Mac.
---

# Apple Reminders

Talk to the Reminders app through AppleScript with `osascript`.

## Permissions

The first call triggers a macOS Automation prompt asking to let the terminal app (or Claude) control Reminders. If a command fails with error `-1743` ("Not authorized to send Apple events"), tell the user to allow it under System Settings → Privacy & Security → Automation, then try again. Don't retry in a loop.

## Operations

List all reminder lists:

```bash
osascript -e 'tell application "Reminders" to get name of every list'
```

Show open reminders in a list:

```bash
osascript -e 'tell application "Reminders" to get name of (every reminder of list "LIST" whose completed is false)'
```

Add a reminder:

```bash
osascript -e 'tell application "Reminders" to make new reminder in list "LIST" with properties {name:"TITLE", body:"NOTES"}'
```

Mark a reminder complete:

```bash
osascript -e 'tell application "Reminders" to set completed of (first reminder of list "LIST" whose name is "TITLE") to true'
```

## Notes

- Escape double quotes and backslashes in user-supplied names before putting them into the script.
- If the user doesn't name a list, use the default list: `default list` in AppleScript.
- Confirm with the user before completing or deleting reminders that match more than one item.
