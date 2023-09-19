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
   '("7e377879cbd60c66b88e51fad480b3ab18d60847f31c435f15f5df18bdb18184" "961645c88ac7d89eb13e01005f3710b99ba42dc18661b43eecaf17c978ef5363" "7f3e2839cc6411f236d6d7e65fcae8e78343a7755e407038d6ff8473592b43c6" "1cd1ef3f80fbe5f7eaeabd1678b9942fbacf036ca1c2f899781cc1088ede4400" "8d7b028e7b7843ae00498f68fad28f3c6258eda0650fe7e17bfb017d51d0e2a2" "1d44ec8ec6ec6e6be32f2f73edf398620bb721afeed50f75df6b12ccff0fbb15" "cbdf8c2e1b2b5c15b34ddb5063f1b21514c7169ff20e081d39cf57ffee89bc1e" "76b4632612953d1a8976d983c4fdf5c3af92d216e2f87ce2b0726a1f37606158" "e7ba99d0f4c93b9c5ca0a3f795c155fa29361927cadb99cfce301caf96055dfd" "f4876796ef5ee9c82b125a096a590c9891cec31320569fc6ff602ff99ed73dca" default))
 '(exec-path
   '("/home/gabriela/.emacs.d/bin/" "/nix/store/dzrvibwj2vjwqmc34wk3x1ffsjpp4av7-bash-4.4-p23/bin" "/nix/store/y41s1vcn0irn9ahn9wh62yx2cygs7qjj-coreutils-8.32/bin" "/nix/store/l5wj1yn64d760f19901qw54ags5p9qns-diffutils-3.7/bin" "/nix/store/r0iqzcgaqlb12gd0sqm5ncrn4kx6jg1f-findutils-4.7.0/bin" "/nix/store/k9324hngc23qi9yj54vds6bjv78qvwbw-gnugrep-3.6/bin" "/nix/store/35rvipj6d88692zn39iwcqfxdm92wfsq-gnused-4.8/bin" "/nix/store/nd5c70nkhyad61jsdi3jhqwbyjzmlgyr-ncurses-6.2/bin" "/nix/store/y41s1vcn0irn9ahn9wh62yx2cygs7qjj-coreutils-8.32/bin" "/nix/store/r0iqzcgaqlb12gd0sqm5ncrn4kx6jg1f-findutils-4.7.0/bin" "/nix/store/35rvipj6d88692zn39iwcqfxdm92wfsq-gnused-4.8/bin" "/nix/store/j8pjpaja2ca3zqfx83bjqx6nrw189264-less-563/bin" "/home/gabriela/.cargo/bin" "/usr/local/kubebuilder/bin" "/run/wrappers/bin" "/home/gabriela/.nix-profile/bin" "/etc/profiles/per-user/gabriela/bin" "/nix/var/nix/profiles/default/bin" "/run/current-system/sw/bin" "/home/gabriela/.gvm/gos/go1.13/bin" "/home/gabriela/.gvm/pkgsets/go1.13/global/bin" "/opt/texlive/2020/bin/x86_64-linux" "/home/gabriela/.emacs.d/bin" "/home/gabriela/google-cloud-sdk/bin" "/home/gabriela/.dotnet/tools" "/home/gabriela/.npm/bin" "/nix/store/m1rvj3cb700r70iml7pamini5pp9lr1j-emacs-27.2/libexec/emacs/27.2/x86_64-pc-linux-gnu/" "/nix/store/1ckmg5hzgz77x7kxx7gy42zadbpk4k8v-hindent-5.3.2/bin" "/nix/store/cz0n8fyrw5xjr6xrc9c9kywhbgjvf2ga-ghc-8.10.4-with-packages/bin" "/nix/store/lawnpqd812zq764pjj7rrbv9vx14w56n-haskell-language-server-1.1.0.0/bin"))
 '(exwm-floating-border-color "#292F37")
 '(fci-rule-color "#427FA3")
 '(flyspell-persistent-highlight nil)
 '(highlight-tail-colors ((("#29323c" "#1f2921") . 0) (("#2c3242" "#212928") . 20)))
 '(indent-tabs-mode nil)
 '(ispell-local-dictionary-alist '(("pt_BR" "" "" "" nil nil "~tex" iso-8859-10)))
 '(jdee-db-active-breakpoint-face-colors (cons "#0e000f" "#AB7793"))
 '(jdee-db-requested-breakpoint-face-colors (cons "#0e000f" "#4F2E6E"))
 '(jdee-db-spec-breakpoint-face-colors (cons "#0e000f" "#376A88"))
 '(js-indent-level 2)
 '(langtool-bin "languagetool-commandline")
 '(lsp-client-packages
   '(ccls lsp-actionscript lsp-ada lsp-angular lsp-ansible lsp-awk lsp-astro lsp-bash lsp-beancount lsp-clangd lsp-clojure lsp-cmake lsp-credo lsp-crystal lsp-csharp lsp-css lsp-d lsp-dart lsp-dhall lsp-docker lsp-dockerfile lsp-elm lsp-elixir lsp-emmet lsp-erlang lsp-eslint lsp-fortran lsp-fsharp lsp-gdscript lsp-go lsp-gleam lsp-glsl lsp-graphql lsp-hack lsp-grammarly lsp-groovy lsp-haskell lsp-haxe lsp-idris lsp-java lsp-javascript lsp-json lsp-kotlin lsp-latex lsp-ltex lsp-lua lsp-markdown lsp-marksman lsp-mint lsp-nginx lsp-nim lsp-nix lsp-magik lsp-metals lsp-mssql lsp-ocaml lsp-openscad lsp-pascal lsp-perl lsp-perlnavigator lsp-pls lsp-php lsp-pwsh lsp-pyls lsp-pylsp lsp-pyright lsp-python-ms lsp-purescript lsp-r lsp-racket lsp-remark lsp-ruff-lsp lsp-rf lsp-rust lsp-semgrep lsp-shader lsp-solargraph lsp-sorbet lsp-sourcekit lsp-sonarlint lsp-tailwindcss lsp-tex lsp-terraform lsp-toml lsp-ttcn3 lsp-typeprof lsp-v lsp-vala lsp-verilog lsp-vetur lsp-volar lsp-vhdl lsp-vimscript lsp-xml lsp-yaml lsp-ruby-lsp lsp-ruby-syntax-tree lsp-sqls lsp-svelte lsp-steep lsp-tilt lsp-zig lsp-quint))
 '(lsp-haskell-server-path
   "/nix/store/lawnpqd812zq764pjj7rrbv9vx14w56n-haskell-language-server-1.1.0.0/bin/haskell-language-server-wrapper")
 '(objed-cursor-color "#EDD26C")
 '(org-latex-compiler "xelatex")
 '(org-latex-hyperref-template nil)
 '(org-roam-capture-immediate-template
   '("d" "default" plain #'org-roam-capture--get-point "%?" :file-name "${slug}" :head "#+title: ${title}
" :unnarrowed t :immediate-finish t))
 '(org-startup-folded 'content)
 '(package-selected-packages
   '(autothemer python-black sml-mode jq-format flx-ido org-d20 maven-test-mode mvn go-projectile org-caldav org-gcal protobuf-mode fish-mode web-mode modus-themes php-mode polymode helm-bibtex org-roam-bibtex twilight-bright-theme twilight-theme ox-hugo zoom-window zoom undo-tree sqlformat smooth-scrolling popup-kill-ring org-special-block-extras org-re-reveal-ref org-download languagetool jazz-theme ivy-spotify ivy-posframe ivy-bibtex imenu-list ibuffer-sidebar goto-last-change git-link flymake-shellcheck dired-sidebar counsel-spotify badger-theme avk-emacs-themes abyss-theme))
 '(pdf-latex-command "xelatex")
 '(pdf-view-midnight-colors (cons "#A3C6DA" "#130416"))
 '(prettier-js-command
   "/nix/store/dxyzbxiw1n5s44rzp6f40b48rcfskxvq-prettier-2.8.8/bin/prettier")
 '(rustic-ansi-faces
   ["#130416" "#EDD26C" "#4F2E6E" "#71539F" "#AB7793" "#6F5494" "#D351AE" "#A3C6DA"])
 '(sbt:program-name
   "/nix/store/9qrz057j3vf4cx271by9b8as30sbm2sj-sbt-1.5.3/bin/sbt")
 '(sqlformat-command 'pgformatter)
 '(tide-format-options '(:indentSize 2 :insertSpaceBeforeFunctionParenthesis t))
 '(tide-node-executable
   "/nix/store/yawck8amy1cqr62s0vv6zw94a0hdf5cg-nodejs-16.11.1/bin/node")
 '(tla+-tlatools-path "/home/gabriela/tla2tools.jar")
 '(typescript-indent-level 2)
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
 '(elixir-atom-face ((t (:foreground "rosy brown"))))
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
 '(org-level-4 ((t (:inherit org-tree-slide-heading-level-4))))
 '(ts-fold-replacement-face ((t (:foreground unspecified :box nil :inherit font-lock-comment-face :weight light)))))
(put 'customize-variable 'disabled nil)
(put 'customize-group 'disabled nil)
(put 'customize-face 'disabled nil)
