# NPower

Status: concept
Proposed plugin id: `npower`
Suggested name: `NPower`

## Goal

Create a single power-management panel for laptop-specific controls, power policy visibility, charge thresholds, and suspend/session power actions.

## Why It Fits This System

This machine already uses multiple separate power-related mechanisms:

- `powerprofilesctl`
- `ppp-auto-profile`
- `stasis`
- battery threshold logic
- session lock / suspend flows

The system is already opinionated. `npower` would make that state visible and actionable from one place.

## Merge Sources

Primary inspiration:

- `battery-threshold`
- `battery-actions`
- `ideapad-battery-health` (only as a model for hardware-specific sections)
- `update-count` (for command abstraction patterns)

## Core UI

### Bar Widget

A compact power icon only:

- AC: plug icon / balanced accent
- Battery: battery icon + severity color by level
- Power saver: muted blue/gray
- Performance: stronger accent

Left click:

- opens panel

Right click:

- cycles power profile

## Panel Layout

### Overview Strip

- power source: AC / battery
- battery percent
- active power profile
- idle inhibitor state

### Power Profile Section

- set: power-saver / balanced / performance
- show whether `ppp-auto-profile` is active
- allow temporary manual override lock

### Charging Section

- threshold slider (where supported)
- conservation mode toggle (hardware-specific if supported)

### Session Actions

- lock
- suspend
- lock and suspend
- idle inhibit toggle

### Advanced State

- current CPU governor/profile snapshot
- optional `stasis` state summary
- optional thermal summary if data is cheap to collect

## IPC Surface

Suggested commands:

- `plugin:npower togglePanel`
- `plugin:npower cycleProfile`
- `plugin:npower setProfile <mode>`
- `plugin:npower setThreshold <value>`
- `plugin:npower toggleConservation`
- `plugin:npower toggleIdleInhibit`
- `plugin:npower lock`
- `plugin:npower suspend`
- `plugin:npower lockAndSuspend`

## Dependencies

Baseline:

- `powerprofilesctl`
- `systemctl`
- `loginctl` (optional)

Optional integrations:

- local threshold helper scripts
- `stasisctl`
- `osc-system`

## Implementation Notes

- Split hardware support into capability probes instead of assumptions
- Treat unsupported battery controls as hidden sections, not errors
- Keep the bar widget state-driven and cheap

## Phases

1. Build profile + session actions
2. Add battery source and percent state
3. Add threshold control capability detection
4. Add advanced system summary integration
