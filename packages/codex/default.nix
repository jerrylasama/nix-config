# Deliberately unpinned: this package follows whatever nixpkgs-unstable ships
# for codex, unlike the version-pinned dcg/tirith/gcx. The agent CLI tracks
# nixpkgs; re-pin here only deliberately, never silently.
# Passthrough: the status line is configured via tui.status_line in
# aspects/agents.nix using upstream-supported items, so no source patch (and
# no Rust rebuild) is needed.
{ codex }:

codex
