;;; doom-bugarela-theme.el --- Custom Doom theme with bugarela color palette -*- lexical-binding: t; no-byte-compile: t -*-
;;
;; Palette from dotfiles/home-manager/common.nix
;;
;;; Commentary:
;;; Code:

(require 'doom-themes)

(defgroup doom-bugarela-theme nil
  "Options for the `doom-bugarela' theme."
  :group 'doom-themes)

(defcustom doom-bugarela-padded-modeline doom-themes-padded-modeline
  "If non-nil, adds padding to the mode-line.
Can be an integer to determine the exact padding."
  :group 'doom-bugarela-theme
  :type '(choice integer boolean))

;;
(def-doom-theme doom-bugarela
  "A dark theme using the bugarela color palette (purple/teal accents)."

  ;; name          default    256        16
  ((bg           '("#3b224c" "#3b224c" "black"))        ;; main bg
   (bg-alt       '("#281733" "#281733" "black"))        ;; black from palette
   (base0        '("#281733" "#281733" "black"))
   (base1        '("#2d1b3d" "#2d1b3d" "brightblack"))
   (base2        '("#352248" "#352248" "brightblack"))
   (base3        '("#3b224c" "#3b224c" "brightblack"))
   (base4        '("#4a2d5c" "#4a2d5c" "brightblack"))
   (base5        '("#5A3D6E" "#5A3D6E" "brightblack"))  ;; bgFade
   (base6        '("#8b7a9e" "#8b7a9e" "brightblack"))
   (base7        '("#b5a8c4" "#b5a8c4" "brightblack"))
   (base8        '("#f0f0f0" "#f0f0f0" "white"))        ;; white from palette

   (region       '("#5A3D6E" "#5A3D6E" "brightblack"))  ;; bgFade
   (fg           '("#CECECE" "#CECECE" "brightwhite"))   ;; main fg
   (fg-alt       '("#b5a8c4" "#b5a8c4" "white"))

   (grey         base5)

   ;; Palette accent colors
   (red          '("#D678B5" "#D678B5" "red"))
   (orange       '("#D678B5" "#D678B5" "brightred"))     ;; red from palette
   (green        '("#7FC9AB" "#7FC9AB" "green"))
   (teal         '("#7FC9AB" "#7FC9AB" "brightgreen"))
   (yellow       '("#E3C0A8" "#E3C0A8" "yellow"))
   (blue         '("#70bad1" "#70bad1" "blue"))
   (dark-blue    '("#5a9bb5" "#5a9bb5" "brightblue"))
   (magenta      '("#C78DFC" "#C78DFC" "magenta"))
   (violet       '("#a586ba" "#a586ba" "brightmagenta")) ;; cursor
   (cyan         '("#23acdd" "#23acdd" "cyan"))
   (dark-cyan    '("#1e8fbc" "#1e8fbc" "brightcyan"))

   ;; face categories -- required for all themes
   (highlight      violet)
   (vertical-bar   base0)
   (line-highlight (doom-darken base5 0.2))
   (selection      region)
   (builtin        magenta)
   (comments       base6)
   (doc-comments   (doom-lighten comments 0.2))
   (constants      orange)
   (functions      blue)
   (keywords       magenta)
   (methods        red)
   (operators      cyan)
   (type           yellow)
   (strings        green)
   (variables      fg-alt)
   (numbers        orange)
   (error          red)
   (warning        yellow)
   (success        green)
   (vc-modified    blue)
   (vc-added       teal)
   (vc-deleted     red)

   ;; modeline
   (modeline-bg     (doom-darken base2 0.1))
   (modeline-bg-alt (doom-darken bg 0.1))
   (modeline-fg     base8)
   (modeline-fg-alt comments)

   (-modeline-pad
    (when doom-bugarela-padded-modeline
      (if (integerp doom-bugarela-padded-modeline) doom-bugarela-padded-modeline 4))))

  ;;;; Base theme face overrides
  ((font-lock-keyword-face :foreground keywords)
   (font-lock-comment-face :foreground comments)
   (font-lock-doc-face :foreground doc-comments)
   (hl-line :background line-highlight)
   (lazy-highlight :background base5 :foreground fg)
   ((line-number &override) :foreground base5 :background (doom-darken bg 0.06))
   ((line-number-current-line &override) :foreground fg :background line-highlight)
   (mode-line
    :background modeline-bg :foreground modeline-fg
    :box (if -modeline-pad `(:line-width ,-modeline-pad :color ,modeline-bg)))
   (mode-line-inactive
    :background modeline-bg-alt :foreground modeline-fg-alt
    :box (if -modeline-pad `(:line-width ,-modeline-pad :color ,modeline-bg-alt)))
   (tooltip :background base0 :foreground fg)

   ;;;; doom-modeline
   (doom-modeline-buffer-file       :foreground base7)
   (doom-modeline-buffer-path       :foreground blue)
   (doom-modeline-buffer-modified   :inherit 'bold :foreground yellow)
   (doom-modeline-buffer-major-mode :inherit 'doom-modeline-buffer-path)
   (doom-modeline-project-dir       :foreground teal)
   (doom-modeline-evil-normal-state :foreground cyan)
   (doom-modeline-evil-insert-state :foreground blue)

   ;;;; ivy
   (ivy-current-match :background region :foreground fg)
   (ivy-minibuffer-match-face-1 :foreground comments)
   (ivy-minibuffer-match-face-2 :foreground magenta)
   (ivy-minibuffer-match-face-3 :foreground blue)
   (ivy-minibuffer-match-face-4 :foreground green)

   ;;;; org
   ((outline-1 &override) :foreground blue)
   ((outline-2 &override) :foreground cyan)
   ((outline-3 &override) :foreground green)
   ((outline-4 &override) :foreground yellow)
   ((outline-5 &override) :foreground magenta)
   ((outline-6 &override) :foreground red)
   ((org-block &override) :background base2)
   ((org-block-background &override) :background base2)
   ((org-block-begin-line &override) :background base2 :foreground base6)

   ;;;; hl-todo
   (hl-todo :foreground yellow :weight 'bold)
   (org-todo :foreground yellow :weight 'bold)
   (org-done :foreground green)

   ;;;; magit
   (magit-section-heading :foreground blue)
   (magit-branch-local :foreground teal)
   (magit-branch-remote :foreground green)
   (magit-diff-added :foreground vc-added)
   (magit-diff-removed :foreground vc-deleted)
   (magit-diff-modified :foreground vc-modified)

   ;;;; nav-flash
   (nav-flash-face :background region)

   ;;;; rainbow-delimiters
   (rainbow-delimiters-depth-1-face :foreground magenta)
   (rainbow-delimiters-depth-2-face :foreground blue)
   (rainbow-delimiters-depth-3-face :foreground green)
   (rainbow-delimiters-depth-4-face :foreground yellow)
   (rainbow-delimiters-depth-5-face :foreground cyan)
   (rainbow-delimiters-depth-6-face :foreground red)
   (rainbow-delimiters-depth-7-face :foreground violet)
   (rainbow-delimiters-depth-8-face :foreground orange)

   ;;;; which-key
   (which-key-command-description-face :foreground fg)
   (which-key-group-description-face :foreground magenta)
   (which-key-key-face :foreground cyan)
   (which-key-local-map-description-face :foreground blue)))

;;; doom-bugarela-theme.el ends here
