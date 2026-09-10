{ codex }:

codex.overrideAttrs (oldAttrs: {
  patches = (oldAttrs.patches or [ ]) ++ [ ./status-line.patch ];
})
