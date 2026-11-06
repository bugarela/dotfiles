# Home Manager substitutes these tokens and loads this in interactive shells.
# Herdr already manages tabs/panes; keep Zellij automatic only elsewhere.
if test "$TERM" != dumb; and test -z "$HC_TERMINAL_ID"; and test "$TERM_PROGRAM" != herdr
    set -lx ZELLIJ_AUTO_ATTACH @autoAttach@
    set -lx ZELLIJ_AUTO_EXIT @autoExit@
    eval (@zellij@ setup --generate-auto-start fish | string collect)
end
