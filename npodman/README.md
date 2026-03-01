# NPodman

![npodman preview](preview.png)

A compact Noctalia plugin for Podman.

## What it does

- shows Podman health and running container counts in the bar
- opens a panel for containers, images, and pods
- supports common actions:
  - start / stop / restart containers
  - remove containers
  - remove images
  - start / stop / remove pods

## Requirements

- `podman`
- permission to manage Podman resources from your user session

## Notes

- The panel refresh interval is configurable from plugin settings.
- This plugin is designed for local Podman workflows, not remote Podman hosts.
