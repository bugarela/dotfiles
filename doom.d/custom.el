(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(LaTeX-command "xelatex")
 '(ansi-color-names-vector
   ["#1d1f21" "#EDD26C" "#4F2E6E" "#71539F" "#AB7793" "#6F5494" "#D351AE" "#A3C6DA"])
 '(bibtex-completion-bibliography
   '("~/udesc/mestrado/MEP/pbs/acm.bib" "~/udesc/mestrado/MEP/pbs/wos.bib" "~/projects/masters-dissertation/dissertation.bib"))
 '(bibtex-completion-library-path '("~/udesc/mestrado/MEP/pbs/pdfs"))
 '(bibtex-completion-notes-global-mode nil)
 '(bibtex-completion-notes-path "~/org/roam")
 '(bibtex-completion-notes-template-multiple-files
   "#+TITLE: ${=key=}: ${title}
#+ROAM_KEY: ${ref}
#+ROAM_TAGS:
Time-stamp: <>
- tags :: ${keywords}

* ${title}
  :PROPERTIES:
  :Custom_ID: ${=key=}
  :URL: ${url}
  :AUTHOR: ${author-or-editor}
  :NOTER_DOCUMENT: ~/udesc/mestrado/MEP/pbs/pdfs/${=key=}.pdf
  :NOTER_PAGE:
  :END:


")
 '(css-indent-offset 2)
 '(custom-safe-themes
   '("76b4632612953d1a8976d983c4fdf5c3af92d216e2f87ce2b0726a1f37606158" "e7ba99d0f4c93b9c5ca0a3f795c155fa29361927cadb99cfce301caf96055dfd" "f4876796ef5ee9c82b125a096a590c9891cec31320569fc6ff602ff99ed73dca" default))
 '(fci-rule-color "#427FA3")
 '(flyspell-persistent-highlight nil)
 '(indent-tabs-mode nil)
 '(ispell-local-dictionary-alist '(("pt_BR" "" "" "" nil nil "~tex" iso-8859-10)))
 '(jdee-db-active-breakpoint-face-colors (cons "#0e000f" "#AB7793"))
 '(jdee-db-requested-breakpoint-face-colors (cons "#0e000f" "#4F2E6E"))
 '(jdee-db-spec-breakpoint-face-colors (cons "#0e000f" "#376A88"))
 '(js-indent-level 2)
 '(langtool-bin "languagetool-commandline")
 '(objed-cursor-color "#EDD26C")
 '(org-latex-compiler "xelatex")
 '(org-latex-hyperref-template nil)
 '(org-roam-capture-immediate-template
   '("d" "default" plain #'org-roam-capture--get-point "%?" :file-name "${slug}" :head "#+title: ${title}
" :unnarrowed t :immediate-finish t))
 '(org-startup-folded 'content)
 '(package-selected-packages
   '(maven-test-mode mvn go-projectile org-caldav org-gcal protobuf-mode fish-mode web-mode modus-themes php-mode polymode helm-bibtex org-roam-bibtex twilight-bright-theme twilight-theme ox-hugo zoom-window zoom undo-tree sqlformat smooth-scrolling popup-kill-ring org-special-block-extras org-re-reveal-ref org-download languagetool jazz-theme ivy-spotify ivy-posframe ivy-bibtex imenu-list ibuffer-sidebar goto-last-change git-link flymake-shellcheck dired-sidebar counsel-spotify badger-theme avk-emacs-themes abyss-theme))
 '(pdf-latex-command "xelatex")
 '(pdf-view-midnight-colors (cons "#A3C6DA" "#130416"))
 '(rustic-ansi-faces
   ["#130416" "#EDD26C" "#4F2E6E" "#71539F" "#AB7793" "#6F5494" "#D351AE" "#A3C6DA"])
 '(sqlformat-command 'pgformatter)
 '(tla+-tlatools-path "/home/gabriela/tla2tools.jar")
 '(vc-annotate-background "#130416")
 '(vc-annotate-color-map
   (list
    (cons 20 "#4F2E6E")
    (cons 40 "#5a3a7e")
    (cons 60 "#65468e")
    (cons 80 "#71539F")
    (cons 100 "#856896")
    (cons 120 "#9a7d8e")
    (cons 140 "#AF9386")
    (cons 160 "#997e8a")
    (cons 180 "#84698f")
    (cons 200 "#6F5494")
    (cons 220 "#997e86")
    (cons 240 "#c3a879")
    (cons 260 "#EDD26C")
    (cons 280 "#bfb872")
    (cons 300 "#929e79")
    (cons 320 "#648381")
    (cons 340 "#427FA3")
    (cons 360 "#427FA3")))
 '(vc-annotate-very-old-color nil)
 '(warning-suppress-types
   '(((defvaralias losing-value helm-bibtex-bibliography))
     ((defvaralias losing-value helm-bibtex-library-path))
     ((defvaralias losing-value helm-bibtex-library-path))
     (:warning)))
 '(web-mode-attr-indent-offset 2)
 '(web-mode-css-indent-offset 2))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(elixir-atom-face ((t (:foreground "blue"))))
 '(flycheck-duplicate ((t (:underline '(:style line)))))
 '(flycheck-error ((t (:underline '(:style line)))))
 '(flycheck-incorrect ((t (:underline '(:style line)))))
 '(flycheck-info ((t (:background nil :foreground nil :underline '(:style line)))))
 '(flycheck-warning ((t (:underline '(:style line)))))
 '(flyspell-duplicate ((t (:underline nil))))
 '(fringe ((t (:background "#323334"))))
 '(markdown-code-face ((t (:background "#000000"))))
 '(org-level-1 ((t (:inherit org-tree-slide-heading-level-1))))
 '(org-level-2 ((t (:inherit org-tree-slide-heading-level-2))))
 '(org-level-3 ((t (:inherit org-tree-slide-heading-level-3))))
 '(org-level-4 ((t (:inherit org-tree-slide-heading-level-4)))))
(put 'customize-variable 'disabled nil)
(put 'customize-group 'disabled nil)
(put 'customize-face 'disabled nil)
