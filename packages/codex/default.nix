# Deliberately unpinned: this package follows whatever nixpkgs-unstable ships
# for codex, unlike the version-pinned dcg/tirith/gcx. The agent CLI tracks
# nixpkgs; re-pin here only deliberately, never silently.
{ codex }:

codex.overrideAttrs (oldAttrs: {
  patches = (oldAttrs.patches or [ ]) ++ [ ./status-line.patch ];
})
