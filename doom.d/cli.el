;;; cli.el -*- lexical-binding: t; -*-

;; Emacs 31.1's loaddefs-gen loads a package's files with `load-suffixes' bound
;; to (".el") to find its autoloaded macros. On Nix, Emacs's own lisp ships as
;; .el.gz, so the first nested `require' of a built-in library pulls in
;; jka-compr.el.gz, which needs jka-compr to decompress itself: "Recursive
;; load". The macros then stay unexpanded and the autoloads file errors (e.g.
;; majutsu's `transient-define-prefix'). Loading jka-compr up front avoids it.
(require 'jka-compr)
