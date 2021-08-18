;;; doom-bugs-nightly-theme.el
(require 'doom-themes)

;;
(defgroup doom-bugs-nightly-theme nil
  "Options for doom-themes"
  :group 'doom-themes)

(defcustom doom-bugs-nightly-brighter-modeline nil
  "If non-nil, more vivid colors will be used to style the mode-line."
  :group 'doom-bugs-nightly-theme
  :type 'boolean)

(defcustom doom-bugs-nightly-brighter-comments nil
  "If non-nil, comments will be highlighted in more vivid colors."
  :group 'doom-bugs-nightly-theme
  :type 'boolean)

(defcustom doom-bugs-nightly-comment-bg doom-bugs-nightly-brighter-comments
  "If non-nil, comments will have a subtle, darker background. Enhancing their
legibility."
  :group 'doom-bugs-nightly-theme
  :type 'boolean)

(defcustom doom-bugs-nightly-padded-modeline nil
  "If non-nil, adds a 4px padding to the mode-line. Can be an integer to
determine the exact padding."
  :group 'doom-bugs-nightly-theme
  :type '(or integer boolean))

;;
(def-doom-theme doom-bugs-nightly
  "Doom bugs-nightly theme"

  ;; name        default   256       16
  ((bg         '("#030002" nil       nil            ))
   (bg-alt     '("#0d0a0c" nil       nil            ))
   (base0      '("#0e000f" "#121212" "black"        ))
   (base1      '("#0e000f" "#262626" "brightblack"  ))
   (base2      '("#0e000f" "#3A3A3A" "brightblack"  ))
   (base3      '("#2C556D" "#4E4E4E" "brightblack"  ))
   (base4      '("#376A88" "#5F5F87" "brightblack"  ))
   (base5      '("#427FA3" "#5F87AF" "brightblack"  ))
   (base6      '("#5193B9" "#5F87AF" "brightblack"  ))
   (base7      '("#6DA4C4" "#5FAFD7" "brightblack"  ))
   (base8      '("#88B5CF" "#87AFD7" "white"        ))
   (fg-alt     '("#B5D1E1" "#AFD7D7" "brightwhite"  ))
   (fg         '("#A3C6DA" "#AFD7D7" "white"        ))

   (grey       base4)
   (red        '("#EDD26C" "#FFD75F" "red"          ))
   (orange     '("#c46a3d" "#c46a3d" "brightred"    ))
   (yellow     '("#7c2ea6" "#7c2ea6" "yellow"        ))
   (green      '("#51873a" "#51873a" "green"  ))
   (teal       '("#3a4287" "#3a4287" "brightgreen"       ))
   (blue       '("#0d6dd1" "#0d6dd1" "brightblue"   ))
   (dark-blue  '("#031c36" "#031c36" "blue"         ))
   (magenta    '("#8F5976" "#875F87" "magenta"         ))
   (violet     '("#8C73AF" "#875FAF" "brightmagenta"))
   (cyan       '("#a32741" "#a32741" "brightcyan"   ))
   (dark-cyan  '("#2367ad" "#225385" "cyan"         ))

   ;; face categories -- required for all themes
   (highlight      blue)
   (vertical-bar   (doom-lighten bg 0.05))
   (selection      dark-blue)
   (builtin        blue)
   (comments       (if doom-bugs-nightly-brighter-comments dark-cyan base5))
   (doc-comments   (doom-lighten (if doom-bugs-nightly-brighter-comments dark-cyan base5) 0.25))
   (constants      red)
   (functions      blue)
   (keywords       yellow)
   (methods        cyan)
   (operators      yellow)
   (type           blue)
   (strings        orange)
   (variables      cyan)
   (numbers        magenta)
   (region         dark-blue)
   (error          red)
   (warning        cyan)
   (success        green)
   (vc-modified    orange)
   (vc-added       green)
   (vc-deleted     red)

   ;; custom categories
   (hidden     `(,(car bg) "black" "black"))
   (-modeline-bright doom-bugs-nightly-brighter-modeline)
   (-modeline-pad
    (when doom-bugs-nightly-padded-modeline
      (if (integerp doom-bugs-nightly-padded-modeline) doom-bugs-nightly-padded-modeline 4)))

   (modeline-fg     nil)
   (modeline-fg-alt base5)

   (modeline-bg
    (if -modeline-bright
        base3
        `(,(doom-darken (car bg) 0.15) ,@(cdr base0))))
   (modeline-bg-l
    (if -modeline-bright
        base3
        `(,(doom-darken (car bg) 0.1) ,@(cdr base0))))
   (modeline-bg-inactive   (doom-darken bg 0.1))
   (modeline-bg-inactive-l `(,(car bg) ,@(cdr base1))))


  ;; --- extra faces ------------------------
  ((elscreen-tab-other-screen-face :background "#353a42" :foreground "#1e2022")

   ((line-number &override) :foreground fg-alt)
   ((line-number-current-line &override) :foreground fg)
   ((line-number &override) :background (doom-darken bg 0.025))

   (font-lock-comment-face
    :foreground comments
    :background (if doom-bugs-nightly-comment-bg (doom-lighten bg 0.05)))
   (font-lock-doc-face
    :inherit 'font-lock-comment-face
    :foreground doc-comments)

   (doom-modeline-bar :background (if -modeline-bright modeline-bg highlight))

   (mode-line
    :background modeline-bg :foreground modeline-fg
    :box (if -modeline-pad `(:line-width ,-modeline-pad :color ,modeline-bg)))
   (mode-line-inactive
    :background modeline-bg-inactive :foreground modeline-fg-alt
    :box (if -modeline-pad `(:line-width ,-modeline-pad :color ,modeline-bg-inactive)))
   (mode-line-emphasis
    :foreground (if -modeline-bright base8 highlight))
   (mode-line-buffer-id
    :foreground highlight)

   (solaire-mode-line-face
    :inherit 'mode-line
    :background modeline-bg-l
    :box (if -modeline-pad `(:line-width ,-modeline-pad :color ,modeline-bg-l)))
   (solaire-mode-line-inactive-face
    :inherit 'mode-line-inactive
    :background modeline-bg-inactive-l
    :box (if -modeline-pad `(:line-width ,-modeline-pad :color ,modeline-bg-inactive-l)))

   (telephone-line-accent-active
    :inherit 'mode-line
    :background (doom-lighten bg 0.2))
   (telephone-line-accent-inactive
    :inherit 'mode-line
    :background (doom-lighten bg 0.05))
   (telephone-line-evil-emacs
    :inherit 'mode-line
    :background dark-blue)

   ;; --- major-mode faces -------------------
   ;; css-mode / scss-mode
   (css-proprietary-property :foreground orange)
   (css-property             :foreground green)
   (css-selector             :foreground blue)

   ;; markdown-mode
   (markdown-markup-face :foreground base5)
   (markdown-header-face :inherit 'bold :foreground red)
   (markdown-code-face :background (doom-lighten base3 0.05))

   ;; org-mode
   (org-hide :foreground hidden)
   (org-block :background base2)
   (org-block-begin-line :background base2 :foreground comments)
   (solaire-org-hide-face :foreground hidden))

  )

;; --- extra variables ---------------------
;; ()

;;; doom-bugs-nightly-theme.el ends here
