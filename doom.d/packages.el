;; -*- no-byte-compile: t; -*-
;;; $DOOMDIR/packages.el

;; To install a package with Doom you must declare them here and run 'doom sync'
;; on the command line, then restart Emacs for the changes to take effect -- or
;; use 'M-x doom/reload'.


;; To install SOME-PACKAGE from MELPA, ELPA or emacsmirror:
                                        ;(package! some-package)
(package! pinentry)
;; (package! ivy-posframe)
(package! company-org-roam)
(package! org-roam-bibtex :recipe (:host github :repo "org-roam/org-roam-bibtex"))
(package! org-present)
(package! org-bullets)
(package! org-ref)
(package! org-download)
(package! org-special-block-extras)
(package! sqlformat)
(package! goto-last-change)
(package! popup-kill-ring)
(package! git-link)
(package! kubernetes)
(package! flymake-shellcheck)
(package! polymode)
(package! web-mode)
(package! fish-mode)
(package! go-projectile)
(package! mvn)
(package! maven-test-mode)
(package! org-d20)
(package! flx)
(package! hlint-refactor)
(package! hindent)
(package! autothemer)

(package! prettier)
(package! treesit-auto)

(package! scroll-on-jump)
(package! ob-mermaid)
(package! ox-gfm)
(package! sidebar :recipe (:host github :repo "sebastiencs/sidebar.el"))

(package! tla-mode :recipe (:host github :repo "valschneider/tla-mode"))
;; (package! tla-tools :recipe (:host github :repo "mrc/tla-tools"))
;; (package! tla+-mode :recipe (:host nil :type git :repo "https://git.sdf.org/bch/tlamode"))

;; Workaround from https://github.com/hlissner/doom-emacs/issues/5667
(package! gitconfig-mode
  :recipe (:host github :repo "magit/git-modes"
           :files ("gitconfig-mode.el")))
(package! gitignore-mode
  :recipe (:host github :repo "magit/git-modes"
           :files ("gitignore-mode.el")))
;; (package! pymupdf-mode :recipe (:host github :repo "dalanicolai/pymupdf-mode.el"))

(package! copilot
  :recipe (:host github :repo "zerolfx/copilot.el" :files ("*.el" "dist")))

(package! ox-html-stable-ids
  :recipe (:host github :repo "jeffkreeftmeijer/ox-html-stable-ids.el"))

(package! org-inline-pdf
  :recipe (:host github :repo "shg/org-inline-pdf.el" :files ("*.el")))

;; https://github.com/doomemacs/doomemacs/issues/7568
(unpin! apheleia)
;; To install a package directly from a remote git repo, you must specify a
;; `:recipe'. You'll find documentation on what `:recipe' accepts here:
;; https://github.com/raxod502/straight.el#the-recipe-format
                                        ;(package! another-package
                                        ;  :recipe (:host github :repo "username/repo"))

;; If the package you are trying to install does not contain a PACKAGENAME.el
;; file, or is located in a subdirectory of the repo, you'll need to specify
;; `:files' in the `:recipe':
                                        ;(package! this-package
                                        ;  :recipe (:host github :repo "username/repo"
                                        ;           :files ("some-file.el" "src/lisp/*.el")))

;; If you'd like to disable a package included with Doom, you can do so here
;; with the `:disable' property:
                                        ;(package! builtin-package :disable t)

;; You can override the recipe of a built in package without having to specify
;; all the properties for `:recipe'. These will inherit the rest of its recipe
;; from Doom or MELPA/ELPA/Emacsmirror:
                                        ;(package! builtin-package :recipe (:nonrecursive t))
                                        ;(package! builtin-package-2 :recipe (:repo "myfork/package"))

;; Specify a `:branch' to install a package from a particular branch or tag.
;; This is required for some packages whose default branch isn't 'master' (which
;; our package manager can't deal with; see raxod502/straight.el#279)
                                        ;(package! builtin-package :recipe (:branch "develop"))

;; Use `:pin' to specify a particular commit to install.
                                        ;(package! builtin-package :pin "1a2b3c4d5e")


;; Doom's packages are pinned to a specific commit and updated from release to
;; release. The `unpin!' macro allows you to unpin single packages...
                                        ;(unpin! pinned-package)
;; ...or multiple packages
                                        ;(unpin! pinned-package another-pinned-package)
;; ...Or *all* packages (NOT RECOMMENDED; will likely break things)
                                        ;(unpin! t)
