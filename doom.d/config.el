;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets.

;; Doom exposes five (optional) variables for controlling fonts in Doom. Here
;; are the three important ones:
;;
;; + `doom-font'
;; + `doom-variable-pitch-font'
;; + `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;;
;; They all accept either a font-spec, font string ("Input Mono-12"), or xlfd
;; font string. You generally only need these two:
;; (setq doom-font (font-spec :family "monospace" :size 12 :weight 'semi-light)
;;       doom-variable-pitch-font (font-spec :family "sans" :size 13))

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-lantern)
(setq doom-font (font-spec :family "Iosevka" :size 26))
(setq doom-big-font (font-spec :family "Iosevka" :size 42))
(setq doom-variable-pitch-font (font-spec :family "Iosevka" :size 20))

;; (push "~/nix-configs/.doom.d/themes/emacs-material-ocean" custom-theme-load-path)
;; (push "~/nix-configs/.doom.d/themes/emacs-material-ocean" load-path)
;; (load-theme 'material-ocean t)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-enable-github-support t
      org-enable-reveal-js-support t
      org-enable-org-journal-support t
      org-enable-trello-support t
      org-projectile-file "~/org/TODOs.org"
      org-agenda-files '("~/org" "~/org/todos" "~/org/roam/daily")
      org-directory "~/org/")

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)


;; Here are some additional functions/macros that could help you configure Doom:
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.
(setq user-full-name "Gabriela Moreira")
;; (load-file "~/.emacs.d/private/local/tla-mode/tla-mode.el")
;; (load-file "~/.emacs.d/private/local/tla+-mode/tla+-mode.el")
;; (load-file "~/.emacs.d/private/local/tokens.el")
;; (load-file "~/.emacs.d/private/local/literature.el")
;; (load-file "~/.emacs.d/private/local/ob-haskell.el")
;; (load-file "~/.emacs.d/private/local/ob-go.el")
;; (add-to-list 'load-path "~/.emacs.d/private" "~/.emacs.d/tla-tools")

(setq mouse-wheel-scroll-amount '(4))
(setq mouse-wheel-progressive-speed nil)

(server-start)
(require 'org-tempo)
;; (setq org-bullets-bullet-list '("› "))
;; (add-hook 'org-mode-hook 'org-bullets-mode)

;; (setq org-gcal-recurring-events-mode 'nested)
;; (setq org-gcal-remove-api-cancelled-events t)
(setq org-agenda-time-grid (quote ((daily today require-timed)
                                   (700
                                    800
                                    900
                                    1100
                                    1200
                                    1300
                                    1400
                                    1500
                                    1600
                                    1700
                                    1800
                                    1900
                                    2000
                                    2100
                                    2200
                                    2300)
                                   "......"
                                   "-----------------------------------------------------"
                                   )))

(add-to-list 'auto-mode-alist '("\\.trello$" . org-mode))
(add-hook 'org-mode-hook
          (lambda ()
            (let ((filename (buffer-file-name (current-buffer))))
              (when (and filename (string= "trello" (file-name-extension filename)))
                (org-trello-mode)))))
;; (use-package org-gcal :ensure t)

(add-to-list 'org-babel-load-languages '(ledger . t))
(with-eval-after-load 'ox-latex
  (setq org-latex-inputenc-alist '(("utf8" . "utf8x")))
  (add-to-list 'org-latex-classes
               '("acm"
                 "\\documentclass[sigconf]{acmart}"
                 ("\\section{%s}" . "\\section*{%s}")
                 ("\\subsection{%s}" . "\\subsection*{%s}")
                 ("\\subsubsection{%s}" . "\\subsubsection*{%s}")
                 ("\\paragraph{%s}" . "\\paragraph*{%s}")
                 ("\\subparagraph{%s}" . "\\subparagraph*{%s}")))
  (add-to-list 'org-latex-classes
               '("springer"
                 "\\documentclass[runningheads]{llncs}"
                 ("\\section{%s}" . "\\section*{%s}")
                 ("\\subsection{%s}" . "\\subsection*{%s}")
                 ("\\subsubsection{%s}" . "\\subsubsection*{%s}")
                 ("\\paragraph{%s}" . "\\paragraph*{%s}")
                 ("\\subparagraph{%s}" . "\\subparagraph*{%s}")))
  (add-to-list 'org-latex-classes
               '("einfart"
                 "\\documentclass{einfart}"
                 ("\\section{%s}" . "\\section*{%s}")
                 ("\\subsection{%s}" . "\\subsection*{%s}")
                 ("\\subsubsection{%s}" . "\\subsubsection*{%s}")
                 ("\\paragraph{%s}" . "\\paragraph*{%s}")
                 ("\\subparagraph{%s}" . "\\subparagraph*{%s}")))
  (add-to-list 'org-latex-classes
               '("abntex2"
                 "\\documentclass[12pt, openright, oneside, a4paper, chapter=TITLE, section=TITLE, english]{abntex2}"
                 ("\\chapter{%s}" . "\\chapter*{%s}")
                 ("\\section{%s}" . "\\section*{%s}")
                 ("\\subsection{%s}" . "\\subsection*{%s}")
                 ("\\subsubsection{%s}" . "\\subsubsection*{%s}")
                 ("\\subsubsubsection{%s}" . "\\subsubsubsection*{%s}")
                 ("\\subsubsubsubsection{%s}" . "\\subsubsubsubsection*{%s}")
                 ("\\paragraph{%s}" . "\\paragraph*{%s}")
                 ("\\subparagraph{%s}" . "\\subparagraph*{%s}"))))

(add-to-list 'org-file-apps
             '("\\.pdf\\'" . emacs))

(eval-after-load "org-present"
  '(progn
     (add-hook 'org-present-mode-hook
               (lambda ()
                 (org-present-big)
                 (org-present-hide-cursor)
                 (visual-line-mode)
                 (org-present-read-only)))
     (add-hook 'org-present-mode-quit-hook
               (lambda ()
                 (org-present-small)
                 (visual-line-mode)
                 (org-present-show-cursor)
                 (org-present-read-write)))))

(custom-set-faces '(flycheck-duplicate ((t (:underline '(:style line)))))
                  '(flycheck-incorrect ((t (:underline '(:style line)))))
                  '(flycheck-error ((t (:underline '(:style line)))))
                  '(flycheck-warning ((t (:underline '(:style line)))))
                  '(flycheck-info ((t (:background nil :foreground nil :underline '(:style line))))))

(defun json-delete-value ()
  "Delete the sexp at point."
  (interactive)
  (let ((syntax (syntax-ppss)) symbol)
    (cond
     ((nth 4 syntax) nil)               ; inside a comment
     ((nth 3 syntax)                    ; inside a string
      (goto-char (nth 8 syntax))
      (when (save-excursion (forward-sexp) (skip-chars-forward "[:space:]") (eq (char-after) ?:))
        ;; sexp is an object key, so we nullify the entire object
        (goto-char (nth 1 syntax)))
      (kill-sexp))
     ((setq symbol (bounds-of-thing-at-point 'symbol))
      (cond
       ((looking-at-p "null"))
       ((save-excursion (skip-chars-backward "[0-9.]") (looking-at json-mode-number-re))
        -region (match-beginning 0) (match-end 0)))
      (t (kill-region (car symbol) (cdr symbol)))))
    ((< 0 (nth 0 syntax))
     (goto-char (nth 1 syntax))
     (kill-sexp))
    (t nil)))

(use-package! pinentry
  :init (setq epg-pinentry-mode `loopback)
  (pinentry-start))


(with-eval-after-load 'evil
  (scroll-on-jump-advice-add evil-undo)
  (scroll-on-jump-advice-add evil-redo)
  (scroll-on-jump-advice-add evil-jump-item)
  (scroll-on-jump-advice-add evil-jump-forward)
  (scroll-on-jump-advice-add evil-jump-backward)
  (scroll-on-jump-advice-add evil-ex-search-next)
  (scroll-on-jump-advice-add evil-ex-search-previous)
  (scroll-on-jump-advice-add evil-forward-paragraph)
  (scroll-on-jump-advice-add evil-backward-paragraph))

(with-eval-after-load 'goto-chg
  (scroll-on-jump-advice-add goto-last-change)
  (scroll-on-jump-advice-add goto-last-change-reverse))

(global-set-key (kbd "<269025093>") "λ")
(map! :leader
      (:prefix ("a" . "custom")
       :desc "Find definition" "d" #'xref-find-definitions-other-window
       :desc "Open spec" "s" #'projectile-find-implementation-or-test-other-window
       :desc "Yank relative path" "y" #'(lambda () (interactive) (kill-new (file-relative-name buffer-file-name (projectile-project-root))))
       :desc "Delete JSON value" "k" #'json-delete-value
       :desc "Cite with org-ref" "c" #'org-ref-insert-link
       :desc "Zoom transient state" "z" #'+hydra/text-zoom/body
       :desc "BibTeX transient state" "b" #'org-ref-bibtex-hydra/body
       :desc "Org preset" "p" #'org-present))

(setq doom-unreal-buffer-functions '(minibufferp))

(setq go-projectile-tools
      '((gocode    . "github.com/mdempsky/gocode")
        (golint    . "golang.org/x/lint/golint")
        (godef     . "github.com/rogpeppe/godef")
        (errcheck  . "github.com/kisielk/errcheck")
        (godoc     . "golang.org/x/tools/cmd/godoc")
        (gogetdoc  . "github.com/zmb3/gogetdoc")
        (goimports . "golang.org/x/tools/cmd/goimports")
        (gorename  . "golang.org/x/tools/cmd/gorename")
        (gomvpkg   . "golang.org/x/tools/cmd/gomvpkg")
        (guru      . "golang.org/x/tools/cmd/guru")))

(defun my-go-mode-hook ()
                                        ; Use goimports instead of go-fmt
  (setq gofmt-command "goimports")
                                        ; Call Gofmt before saving
  (add-hook 'before-save-hook 'gofmt-before-save)
                                        ; Customize compile command to run go build
  (if (not (string-match "go" compile-command))
      (set (make-local-variable 'compile-command)
           "go build -v && go test -v && go vet"))
                                        ; Godef jump key binding
  (local-set-key (kbd "M-.") 'godef-jump)
  (local-set-key (kbd "M-*") 'pop-tag-mark)
  )
(add-hook 'go-mode-hook 'my-go-mode-hook)

;; (require 'tla-mode)
;; (use-package tla-mode :mode "\.tla$")
;; (use-package tla-tools :mode "\.tla$")
;; (require 'tla+-mode)
;; (setq tla+-tlatools-path "$HOME/tla2tools.jar")

(defun my-dnd-func (event)
  (interactive "e")
  (goto-char (nth 1 (event-start event)))
  (x-focus-frame nil)
  (let* ((payload (car (last event)))
         (type (car payload))
         (fname (cadr payload))
         (img-regexp "\\(png\\|jp[e]?g\\)\\>"))
    (cond
     ;; insert image link
     ((and  (eq 'drag-n-drop (car event))
            (eq 'file type)
            (string-match img-regexp fname))
      (insert (format "[[%s]]" fname))
      (org-display-inline-images t t))
     ;; insert image link with caption
     ((and  (eq 'C-drag-n-drop (car event))
            (eq 'file type)
            (string-match img-regexp fname))
      (insert "#+ATTR_ORG: :width 300\n")
      (insert (concat  "#+CAPTION: " (read-input "Caption: ") "\n"))
      (insert (format "[[%s]]" fname))
      (org-display-inline-images t t))
     ;; C-drag-n-drop to open a file
     ((and  (eq 'C-drag-n-drop (car event))
            (eq 'file type))
      (find-file fname))
     ((and (eq 'M-drag-n-drop (car event))
           (eq 'file type))
      (insert (format "[[attachfile:%s]]" fname)))
     ;; regular drag and drop on file
     ((eq 'file type)
      (insert (format "[[%s]]\n" fname)))
     (t
      (error "I am not equipped for dnd on %s" payload)))))


(define-key org-mode-map (kbd "<drag-n-drop>") 'my-dnd-func)
(define-key org-mode-map (kbd "<C-drag-n-drop>") 'my-dnd-func)
(define-key org-mode-map (kbd "<M-drag-n-drop>") 'my-dnd-func)

(add-to-list 'org-babel-tangle-lang-exts '("tla"))
(defconst org-babel-header-args:tla '(module . :any)
  "TLA-specific header arguments.")

(defun org-babel-execute:tla (body params)
  "Converts TLA block to TeX using tla2tex"
  (let* ((base-name (concat (file-name-directory buffer-file-name) "exported-org-files/" (file-name-base buffer-file-name) "-tla-tex"))
         (tla-file (concat base-name ".tla"))
         (my-tex-file (concat base-name ".tex"))
         (command (concat "tlatex" " -latexCommand pdflatex " (org-babel-process-file-name tla-file)))
         (module (string= "yes" (cdr (assq :module params))))
         (figure (not (string= "no" (cdr (assq :figure params)))))
         (caption (cdr (assq :caption params)))
         (label (cdr (assq :label params)))
         (preserve-indentp org-src-preserve-indentation)
         indentation)
    (with-temp-file tla-file
      (if module
          (insert body)
        (insert (format "----------------------------- MODULE OB -----------------------------\n%s\n=============================================================================" body)))
      (write-file tla-file)
      (org-babel-eval command ""))
    (with-temp-buffer
      (insert-file-contents my-tex-file)
      (search-forward "\\bottombar\\")
      (beginning-of-line)
      (if module (progn (forward-line 1) (kill-line 1)) (kill-line 2))
      (goto-char (point-min))
      (search-forward "\n\\tlatex\n")
      (unless module (kill-line 1))
      (setq results (concat
                     (if figure "\\begin{figure}[style=boxed]\\begin{minipage}{\\columnwidth}" "\\medskip")
                     "\\begin{tlatex}\n"
                     (delete-and-extract-region (point) (point-max))
                     "\\end{tlatex}\n"
                     (if figure (format "\\caption{%s}" caption))
                     (if figure (format "\\label{%s}" label))
                     (if figure "\\end{minipage}\\end{figure}" "\\medskip"))))
    (delete-file tla-file)
    (delete-file my-tex-file)
    results))
(provide 'ob-tla)

(fset 'evil-visual-update-x-selection 'ignore)

(setq org_notes "~/MEGA/org/roam"
      deft-directory org_notes
      org-roam-directory org_notes)

(use-package deft
  :commands deft
  :init
  (setq deft-default-extension "org"
        ;; de-couples filename and note title:
        deft-use-filename-as-title nil
        deft-use-filter-string-for-filename t
        ;; disable auto-save
        deft-auto-save-interval -1.0
        ;; converts the filter string into a readable file-name using kebab-case:
        deft-file-naming-rules
        '((noslash . "-")
          (nospace . "-")
          (case-fn . downcase)))
  :config
  (add-to-list 'deft-extensions "tex")
  )

(use-package org-ref
  :config
  (setq
   org-ref-completion-library 'org-ref-ivy-cite
   org-ref-get-pdf-filename-function 'org-ref-get-pdf-filename-helm-bibtex
   org-ref-default-bibliography (list "~/udesc/mestrado/MEP/pbs/acm.bib" "~/udesc/mestrado/MEP/pbs/wos.bib" "~/udesc/mestrado/sblp2021/main.bib")
   org-ref-bibliography-notes org_notes
   org-ref-note-title-format "* TODO %y - %t\n :PROPERTIES:\n  :Custom_ID: %k\n  :NOTER_DOCUMENT: %F\n :ROAM_KEY: cite:%k\n  :AUTHOR: %9a\n  :JOURNAL: %j\n  :YEAR: %y\n  :VOLUME: %v\n  :PAGES: %p\n  :DOI: %D\n  :URL: %U\n :END:\n\n"
   org-ref-notes-directory org_notes
   org-ref-notes-function 'orb-edit-notes
   ))
;; (use-package org-roam
;;   :hook (org-load . org-roam-mode)
;;   :commands (org-roam-buffer-toggle-display
;;              org-roam-find-file
;;              org-roam-graph
;;              org-roam-insert
;;              org-roam-switch-to-buffer
;;              org-roam-dailies-date
;;              org-roam-dailies-today
;;              org-roam-dailies-tomorrow
;;              org-roam-dailies-yesterday)
;;   :preface
;;   ;; Set this to nil so we can later detect whether the user has set a custom
;;   ;; directory for it, and default to `org-directory' if they haven't.
;;   (defvar org-roam-directory nil)
;;   :init
;;   :config
;;   (setq org-roam-directory (expand-file-name (or org-roam-directory "roam")
;;                                              org-directory)
;;         org-roam-verbose nil  ; https://youtu.be/fn4jIlFwuLU
;;         org-roam-buffer-no-delete-other-windows t ; make org-roam buffer sticky
;;         org-roam-completion-system 'default
;;         )

;;   ;; Normally, the org-roam buffer doesn't open until you explicitly call
;;   ;; `org-roam'. If `+org-roam-open-buffer-on-find-file' is non-nil, the
;;   ;; org-roam buffer will be opened for you when you use `org-roam-find-file'
;;   ;; (but not `find-file', to limit the scope of this behavior).
;;   (add-hook 'find-file-hook
;;             (defun +org-roam-open-buffer-maybe-h ()
;;               (and +org-roam-open-buffer-on-find-file
;;                    (memq 'org-roam-buffer--update-maybe post-command-hook)
;;                    (not (window-parameter nil 'window-side)) ; don't proc for popups
;;                    (not (eq 'visible (org-roam-buffer--visibility)))
;;                    (with-current-buffer (window-buffer)
;;                      (org-roam-buffer--get-create)))))

;; Hide the mode line in the org-roam buffer, since it serves no purpose. This
;; makes it easier to distinguish among other org buffers.
;; (add-hook 'org-roam-buffer-prepare-hook #'hide-mode-line-mode))

;; Since the org module lazy loads org-protocol (waits until an org URL is
;; detected), we can safely chain `org-roam-protocol' to it.
(use-package org-roam-protocol
  :after org-protocol)

(use-package company-org-roam
  :after org-roam
  :config
  (set-company-backend! 'org-mode '(company-org-roam company-yasnippet company-dabbrev)))

(use-package org-roam-bibtex
  :after (org-roam)
  :hook (org-roam-mode . org-roam-bibtex-mode)
  :config
  (setq orb-preformat-keywords
        '("=key=" "citekey" "title" "url" "file" "author-or-editor" "keywords"))
  (setq orb-templates
        '(("r" "ref" plain (function org-roam-capture--get-point)
           "" :file-name "${=key=}" :head "#+TITLE: ${=key=}: ${title}
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
" :unnarrowed t)))
  (setq bibtex-completion-notes-template-multiple-files orb-templates))

(setq org-roam-capture-templates
      '(
        ("i" "informal" plain "%?" ;;(file "~/org/roam/work/gabriela/stuff.org")
         :target (file+head "informal/gabriela/%<%Y%m%d%H%M%S>-${slug}.org"
                            "#+title: ${title}\n") :unnarrowed t)
        ("u" "udesc" plain "%?" ;;(file "~/org/roam/work/gabriela/stuff.org")
         :target (file+head "udesc/%<%Y%m%d%H%M%S>-${slug}.org"
                            "#+title: ${title}\n") :unnarrowed t)
        ("p" "personal" plain "%?" ;;(file "~/org/roam/work/gabriela/stuff.org")
         :target (file+head "personal/%<%Y%m%d%H%M%S>-${slug}.org"
                            "#+title: ${title}\n") :unnarrowed t)
        ;; ("b" "research" plain (file "~/Documents/roam/study/templates/research.org")
        ;;  :target (file+head "study/%<%Y%m%d%H%M%S>-${slug}.org"
        ;;                     "#+title: ${title}\n") :unnarrowed t)
        )
      )

(use-package org-noter
  :after (:any org pdf-view)
  :config
  (setq
   ;; The WM can handle splits
   org-noter-notes-window-location 'other-frame
   ;; Please stop opening frames
   org-noter-always-create-frame nil
   ;; I want to see the whole file
   org-noter-hide-other nil
   ;; Everything is relative to the main notes file
   org-noter-notes-search-path (list org_notes)
   )
  )

(add-to-list 'ispell-skip-region-alist '("#\\+begin_src". "#\\+end_src"))
(add-to-list 'ispell-skip-region-alist '("\\begin{algorithm}". "\\end{algorithm}"))

;; Translate *bold* to \textbf in beamer
(defun my-beamer-bold (contents backend info)
  (when (eq backend 'beamer)
    (replace-regexp-in-string "\\`\\\\[A-Za-z0-9]+" "\\\\textbf" contents)))

(add-to-list 'org-export-filter-bold-functions 'my-beamer-bold)

(setq omnisharp-server-executable-path "/nix/store/sfd273zm599d13simay695b3xsmm3l45-omnisharp-roslyn-1.37.8/bin/omnisharp")

(defun dw/org-present-prepare-slide ()
  (org-overview)
  (org-show-entry)
  (org-show-children))

(defun dw/org-present-hook ()
  (setq-local face-remapping-alist '((default (:height 1.5) variable-pitch)
                                     (header-line (:height 4.5) variable-pitch)
                                     (org-document-title (:height 1.75) org-document-title)
                                     (org-code (:height 1.55) org-code)
                                     (org-verbatim (:height 1.55) org-verbatim)
                                     (org-block (:height 1.25) org-block)
                                     (org-block-begin-line (:height 0.7) org-block)))
  (setq header-line-format " ")
  (org-appear-mode -1)
  (org-display-inline-images)
  (dw/org-present-prepare-slide)
  (dw/kill-panel))

(defun dw/org-present-quit-hook ()
  (setq-local face-remapping-alist '((default variable-pitch default)))
  (setq header-line-format nil)
  (org-present-small)
  (org-remove-inline-images)
  (org-appear-mode 1)
  (dw/start-panel))

(defun dw/org-present-prev ()
  (interactive)
  (org-present-prev)
  (dw/org-present-prepare-slide))

(defun dw/org-present-next ()
  (interactive)
  (org-present-next)
  (dw/org-present-prepare-slide)
  (when (fboundp 'live-crafter-add-timestamp)
    (live-crafter-add-timestamp (substring-no-properties (org-get-heading t t t t)))))

(use-package org-present
  :bind (:map org-present-mode-keymap
              ("C-c C-j" . dw/org-present-next)
              ("C-c C-k" . dw/org-present-prev))
  :hook ((org-present-mode . dw/org-present-hook)
         (org-present-mode-quit . dw/org-present-quit-hook)))

(load-file "~/projects/quint/editor-plugins/emacs/quint-mode.el")
(load-file "~/projects/quint/editor-plugins/emacs/lsp-quint.el")
(require 'quint-mode)
(add-to-list 'auto-mode-alist '("\\.qnt" . quint-mode))
(use-package lsp-quint
  :hook (quint-mode . lsp))

(add-hook 'typescript-ts-mode-hook 'prettier-mode)
(add-hook 'typescript-ts-mode-hook 'lsp-mode)

(defun my-haskell-mode-hook ()
  (hindent-mode)
  ;; (add-hook 'before-save-hook 'hindent-reformat-buffer)
  (lsp-deferred)
  )
(add-hook 'haskell-mode-hook 'my-haskell-mode-hook)

;; accept completion from copilot and fallback to company
(use-package! copilot
  :hook (prog-mode . copilot-mode)
  :bind (:map copilot-completion-map
              ("<tab>" . 'copilot-accept-completion)
              ("<backtab>" . 'copilot-accept-completion)
              ("TAB" . 'copilot-accept-completion)
              ("C-TAB" . 'copilot-accept-completion-by-word)
              ("C-<tab>" . 'copilot-accept-completion-by-word)))

(use-package treesit-auto
  :config
  (global-treesit-auto-mode))

(add-to-list 'default-frame-alist '(internal-border-width . 20))
(custom-set-faces
 `(vertical-border ((t (:background nil))))
 `(mode-line ((t (:background nil))))
 `(fringe ((t (:background nil)))))

;; https://robert.kra.hn/posts/rust-emacs-setup/
(use-package rustic
  :ensure
  :bind (:map rustic-mode-map
              ("M-j" . lsp-ui-imenu)
              ("M-?" . lsp-find-references)
              ("C-c C-c l" . flycheck-list-errors)
              ("C-c C-c a" . lsp-execute-code-action)
              ("C-c C-c r" . lsp-rename)
              ("C-c C-c q" . lsp-workspace-restart)
              ("C-c C-c Q" . lsp-workspace-shutdown)
              ("C-c C-c s" . lsp-rust-analyzer-status))
  :config
  ;; uncomment for less flashiness
  ;; (setq lsp-eldoc-hook nil)
  ;; (setq lsp-enable-symbol-highlighting nil)
  ;; (setq lsp-signature-auto-activate nil)

  ;; comment to disable rustfmt on save
  (setq rustic-format-on-save t)
  (add-hook 'rustic-mode-hook 'rk/rustic-mode-hook))

(defun rk/rustic-mode-hook ()
  ;; so that run C-c C-c C-r works without having to confirm, but don't try to
  ;; save rust buffers that are not file visiting. Once
  ;; https://github.com/brotzeit/rustic/issues/253 has been resolved this should
  ;; no longer be necessary.
  (when buffer-file-name
    (setq-local buffer-save-without-query t))
  (add-hook 'before-save-hook 'lsp-format-buffer nil t))
(use-package lsp-mode
  :ensure
  :commands lsp
  :custom
  ;; what to use when checking on-save. "check" is default, I prefer clippy
  (lsp-rust-analyzer-cargo-watch-command "clippy")
  (lsp-eldoc-render-all t)
  (lsp-idle-delay 0.6)
  ;; enable / disable the hints as you prefer:
  (lsp-inlay-hint-enable t)
  ;; These are optional configurations. See https://emacs-lsp.github.io/lsp-mode/page/lsp-rust-analyzer/#lsp-rust-analyzer-display-chaining-hints for a full list
  ;; (lsp-rust-analyzer-display-lifetime-elision-hints-enable "skip_trivial")
  (lsp-rust-analyzer-display-chaining-hints t)
  (lsp-rust-analyzer-display-lifetime-elision-hints-use-parameter-names nil)
  (lsp-rust-analyzer-display-closure-return-type-hints t)
  (lsp-rust-analyzer-display-parameter-hints t)
  (lsp-rust-analyzer-display-reborrow-hints t)
  :config
  (add-hook 'lsp-mode-hook 'lsp-ui-mode))

(use-package lsp-ui
  :ensure
  :commands lsp-ui-mode
  :custom
  (lsp-ui-peek-always-show t)
  (lsp-ui-sideline-show-hover t)
  (lsp-ui-doc-enable t))
(use-package company
  :ensure
  :custom
  (company-idle-delay 0.5) ;; how long to wait until popup
  ;; (company-begin-commands nil) ;; uncomment to disable popup
  :bind
  (:map company-active-map
	("C-n". company-select-next)
	("C-p". company-select-previous)
	("M-<". company-select-first)
	("M->". company-select-last)))

(use-package yasnippet
  :ensure
  :config
  (yas-reload-all)
  (add-hook 'prog-mode-hook 'yas-minor-mode)
  (add-hook 'text-mode-hook 'yas-minor-mode))

;; Export org files to a different directory to avoid mess
(defun org-export-output-file-name-modified (orig-fun extension &optional subtreep pub-dir)
  (unless pub-dir
    (setq pub-dir "exported-org-files")
    (unless (file-directory-p pub-dir)
      (make-directory pub-dir)))
  (apply orig-fun extension subtreep pub-dir nil))
(advice-add 'org-export-output-file-name :around #'org-export-output-file-name-modified)

(setq org-latex-pdf-process '("bash -c 'rm -f %b.log; pdflatex -interaction nonstopmode -output-directory %o %f; while (grep -e \"Rerun .* cross-references\" %o/%b.log > /dev/null); do rm -f %b.log; pdflatex -interaction nonstopmode -output-directory %o %f; done'"))

(setq lsp-completion-provider :capf)
(setq org-cite-export-processors nil);;'((t . (csl "~/MEGA/org/roam/udesc/exported-org-files/abntex2.cls"))))
(setq org-export-allow-bind-keywords t)
(require 'ox-extra)
(ox-extras-activate '(ignore-headlines))

;; https://zzamboni.org/post/beautifying-org-mode-in-emacs/
(setq org-hide-emphasis-markers t)
(font-lock-add-keywords 'org-mode
                        '(("^ *\\([-]\\) "
                           (0 (prog1 () (compose-region (match-beginning 1) (match-end 1) "•"))))))
(use-package org-bullets
  :config
  (add-hook 'org-mode-hook (lambda () (org-bullets-mode 1))))

(let* ((variable-tuple
        (cond ((x-list-fonts "ETBembo")         '(:font "ETBembo"))
              ((x-list-fonts "Iosevka")         '(:font "Iosevka"))
              ((x-list-fonts "Lucida Grande")   '(:font "Lucida Grande"))
              ((x-list-fonts "Verdana")         '(:font "Verdana"))
              ((x-family-fonts "Sans Serif")    '(:family "Sans Serif"))
              (nil (warn "Cannot find a Sans Serif Font.  Install Source Sans Pro."))))
       (base-font-color     (face-foreground 'default nil 'default))
       (headline           `(:inherit default :weight bold :foreground ,base-font-color)))

  (custom-theme-set-faces
   'user
   `(org-level-8 ((t (,@headline ,@variable-tuple))))
   `(org-level-7 ((t (,@headline ,@variable-tuple))))
   `(org-level-6 ((t (,@headline ,@variable-tuple))))
   `(org-level-5 ((t (,@headline ,@variable-tuple))))
   `(org-level-4 ((t (,@headline ,@variable-tuple :height 1.1))))
   `(org-level-3 ((t (,@headline ,@variable-tuple :height 1.25))))
   `(org-level-2 ((t (,@headline ,@variable-tuple :height 1.5))))
   `(org-level-1 ((t (,@headline ,@variable-tuple :height 1.75))))
   `(org-document-title ((t (,@headline ,@variable-tuple :height 2.0 :underline nil))))))

(custom-theme-set-faces
 'user
 '(variable-pitch ((t (:family "ETBembo" :height 190 :weight thin))))
 '(fixed-pitch ((t ( :family "Iosevka" :height 130)))))
(add-hook 'org-mode-hook 'variable-pitch-mode)

(add-hook 'org-mode-hook 'visual-line-mode)

;; (custom-theme-set-faces
;;  'user
;;  '(org-block ((t (:inherit fixed-pitch))))
;;  '(org-code ((t (:inherit (shadow fixed-pitch)))))
;;  '(org-document-info ((t (:foreground "dark orange"))))
;;  '(org-document-info-keyword ((t (:inherit (shadow fixed-pitch)))))
;;  '(org-indent ((t (:inherit (org-hide fixed-pitch)))))
;;  '(org-link ((t (:foreground "royal blue" :underline t))))
;;  '(org-meta-line ((t (:inherit (font-lock-comment-face fixed-pitch)))))
;;  '(org-property-value ((t (:inherit fixed-pitch))) t)
;;  '(org-special-keyword ((t (:inherit (font-lock-comment-face fixed-pitch)))))
;;  '(org-table ((t (:inherit fixed-pitch :foreground "#83a598"))))
;;  '(org-tag ((t (:inherit (shadow fixed-pitch) :weight bold :height 0.8))))
;;  '(org-verbatim ((t (:inherit (shadow fixed-pitch))))))

(add-hook 'org-mode-hook #'org-inline-pdf-mode)
(defun org-include-img-from-pdf (&rest _)
  "Convert pdf files to image files in org-mode bracket links.

    # ()convertfrompdf:t # This is a special comment; tells that the upcoming
                         # link points to the to-be-converted-to file.
    # If you have a foo.pdf that you need to convert to foo.png, use the
    # foo.png file name in the link.
    [[./foo.png]]
"
  (interactive)
  (if (executable-find "convert")
      (save-excursion
        (goto-char (point-min))
        (while (re-search-forward "^[ \t]*#\\s-+()convertfrompdf\\s-*:\\s-*t"
                                  nil :noerror)
          ;; Keep on going to the next line till it finds a line with bracketed
          ;; file link.
          (while (progn
                   (forward-line 1)
                   (not (looking-at org-bracket-link-regexp))))
          ;; Get the sub-group 1 match, the link, from `org-bracket-link-regexp'
          (let ((link (match-string-no-properties 1)))
            (when (stringp link)
              (let* ((imgfile (expand-file-name link))
                     (pdffile (expand-file-name
                               (concat (file-name-sans-extension imgfile)
                                       "." "pdf")))
                     (cmd (concat "convert -density 300 -quality 300 -crop -0-1500 -trim "
                                  pdffile " " imgfile)))
                (when (and (file-readable-p pdffile)
                           (file-newer-than-file-p pdffile imgfile))
                  ;; This block is executed only if pdffile is newer than
                  ;; imgfile or if imgfile does not exist.
                  (shell-command cmd)
                  (message "%s" cmd)))))))
    (user-error "`convert' executable (part of Imagemagick) is not found")))
(defun my/org-include-img-from-pdf-before-save ()
  "Execute `org-include-img-from-pdf' just before saving the file."
  (add-hook 'before-save-hook #'org-include-img-from-pdf nil :local))
(add-hook 'org-mode-hook #'my/org-include-img-from-pdf-before-save)
