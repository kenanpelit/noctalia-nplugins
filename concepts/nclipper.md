# NClipper

Status: concept
Proposed plugin id: `nclipper`
Suggested name: `NClipper`

## Goal

Define a cleaner long-term merge strategy between the current `notes` plugin and clipboard-driven capture workflows inspired by `clipper`.

## Why This Should Not Be A Blind Fork

`clipper` is feature-rich, but it solves a broader clipboard problem. The current `notes` plugin is already a focused productivity surface. A direct fork would reintroduce overlap and UI bloat.

The right direction is a selective merge:

- keep `notes` as the durable workspace
- borrow only the high-value capture flows from `clipper`
- avoid building a second full clipboard manager unless it is clearly justified

## Current Base

Existing internal base:

- `notes`

External inspiration:

- `clipper`
- `notes-scratchpad`
- `simple-notes`
- `todo`

## Proposed Scope

### Keep In `notes`

- scratchpad
- durable notes
- active tasks / todos

### Add From `clipper`

- quick capture selected text into scratchpad
- convert clipboard selection directly into note
- pin important notes or tasks
- optional lightweight search across notes and todos
- fast add actions from panel header

### Explicitly Avoid (for now)

- full clipboard history browser
- image preview cards
- rich clipboard type taxonomy
- separate pin-card storage model

## UI Direction

### Header Actions

- New Note
- Quick Capture From Clipboard
- Add Todo From Clipboard
- Search / Filter

### Content Zones

- top: summary cards (already used as tabs)
- notes view: add filter bar and pin support
- active tasks: add quick promote / quick archive
- scratchpad: keep it fast, text-first, zero-friction

## IPC Surface

Suggested additions:

- `plugin:notes quickCapture`
- `plugin:notes addClipboardAsNote`
- `plugin:notes addClipboardAsTodo`
- `plugin:notes search <query>`
- `plugin:notes pinNote <id>`
- `plugin:notes unpinNote <id>`

## Dependencies

- `wl-paste` or equivalent clipboard access command
- optionally `cliphist` if persistent clipboard recall is later added

## Implementation Strategy

Recommended path:

1. Extend `notes`
2. Only create standalone `nclipper` if `notes` becomes too overloaded

This means `nclipper` starts as a design track, not an immediate registry plugin.

## Phases

1. Add clipboard-to-note IPC to `notes`
2. Add pinning model for notes/tasks
3. Add lightweight search/filter
4. Re-evaluate whether a separate plugin is still needed
