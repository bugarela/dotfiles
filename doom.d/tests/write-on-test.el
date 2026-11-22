;;; write-on-test.el --- Write On tests -*- lexical-binding: t; -*-
(require 'ert)
(require 'write-on)
(require 'ox-ascii)
(require 'ox-html)

(defmacro write-on-test-buffer (text &rest body)
  (declare (indent 1))
  `(with-temp-buffer
     (org-mode)
     (insert ,text)
     (goto-char (point-min))
     (write-on-mode 1)
     ,@body))

(ert-deftest write-on-roundtrip-and-export ()
  (write-on-test-buffer "The cache is fast.\n"
    (search-forward "fast")
    (backward-word)
    (write-on-add "quick")
    (let ((saved (buffer-string)))
      (erase-buffer)
      (insert saved)
      (goto-char (point-min))
      (search-forward "[[write-on:")
      (let* ((target (write-on--target))
             (variants (write-on--variants (plist-get target :id))))
        (should (equal variants '("fast" "quick")))
        (write-on--apply target "fast" variants))
      (should (string-match-p "The cache is fast\\." (org-export-as 'ascii nil nil t)))
      (let ((html (org-export-as 'html nil nil t)))
        (should (string-match-p "The cache is fast\\." html))
        (should-not (string-match-p "WRITE_ON\\|write-on:\\|quick" html))))))

(ert-deftest write-on-stale-target-is-never-replaced ()
  (write-on-test-buffer "fast cache"
    (let ((target (write-on--target)))
      (delete-char 1)
      (insert "p")
      (should-error (write-on--apply target "quick" '("quick")) :type 'user-error)
      (should (equal (buffer-string) "past cache")))))

(ert-deftest write-on-markers-follow-unrelated-edits ()
  (write-on-test-buffer "The fast cache"
    (search-forward "fast")
    (backward-word)
    (let ((target (write-on--target)))
      (goto-char (point-min))
      (insert "Note: ")
      (should (write-on--valid-target-p target))
      (write-on--apply target "quick" '("quick"))
      (should (string-prefix-p "Note: The [[write-on:" (buffer-string))))))

(ert-deftest write-on-manual-description-edits-are-preserved ()
  (write-on-test-buffer "fast cache"
    (write-on-add "quick")
    (search-forward "][quick")
    (replace-match "][rapid" t t)
    (backward-char)
    (let ((target (write-on--target)))
      (write-on--apply target "swift" (write-on--variants (plist-get target :id))))
    (should (equal (write-on--variants (plist-get (write-on--target) :id))
                   '("rapid" "fast" "quick" "swift")))))

(ert-deftest write-on-flatten-preserves-visible-prose ()
  (write-on-test-buffer "fast cache"
    (write-on-add "quick")
    (write-on-flatten)
    (should (string-prefix-p "quick cache" (buffer-string)))
    (should-not (string-match-p "\\[\\[write-on:" (buffer-string)))))

(ert-deftest write-on-apply-is-undoable ()
  (write-on-test-buffer "fast cache"
    (buffer-enable-undo)
    (setq buffer-undo-list nil)
    (write-on-add "quick")
    (undo-boundary)
    (undo)
    (should (equal (buffer-string) "fast cache"))))

(ert-deftest write-on-strict-model-output ()
  (should (equal (write-on--parse "[\"quick\",\"swift\",\"quick\"]") '("quick" "swift")))
  (dolist (bad '("null" "[]" "{}" "[1]" "[\"\"]" "[\"[[file:x]]\"]"
                 "```json\n[\"quick\"]\n```"))
    (should-error (write-on--parse bad))))

(ert-deftest write-on-cancel-does-not-open-panel ()
  (write-on-test-buffer "fast cache"
    (let ((write-on-command '("sh" "-c" "read line; sleep 30")))
      (write-on-generate)
      (should (process-live-p write-on--process))
      (write-on-cancel)
      (should-not write-on--process)
      (should-not write-on--timer))))

(ert-deftest write-on-generation-is-local-with-remote-source ()
  (write-on-test-buffer "fast cache"
    (let ((write-on-command '("sh" "-c" "read line; printf '[\"quick\",\"swift\"]'"))
          (default-directory "/ssh:unreachable:/tmp/")
          shown)
      (cl-letf (((symbol-function 'write-on--show)
                 (lambda (target variants) (setq shown (list target variants)))))
        (write-on-generate)
        (let ((deadline (+ (float-time) 5)))
          (while (and write-on--process (< (float-time) deadline))
            (accept-process-output nil 0.02)))
        (should-not write-on--process)
        (should (equal (cadr shown) '((:text "quick" :origin "ai") (:text "swift" :origin "ai"))))
        (should (equal (buffer-string) "fast cache"))
        (should-not write-on--timer)))))

(ert-deftest write-on-stash-is-not-exported ()
  (write-on-test-buffer "Keep this.\n\nCut this.\n"
    (search-forward "Cut this.")
    (set-mark (- (point) 9))
    (setq transient-mark-mode t mark-active t)
    (write-on-stash)
    (should (string-match-p "COMMENT Overflow" (buffer-string)))
    (should-not (string-match-p "Cut this" (org-export-as 'ascii nil nil t)))))

(ert-deftest write-on-refuses-nested-links-and-source-blocks ()
  (dolist (text '("[[https://example.com][fast]]" "#+begin_src text\nfast\n#+end_src"))
    (write-on-test-buffer text
      (search-forward "fast")
      (set-mark (- (point) 4))
      (setq transient-mark-mode t mark-active t)
      (should-error (write-on--target) :type 'user-error))))

(ert-deftest write-on-wrapped-original-can-be-restored ()
  (write-on-test-buffer "The cache\nis fast."
    (set-mark (point-max))
    (setq transient-mark-mode t mark-active t)
    (write-on-add "The cache is quick.")
    (deactivate-mark)
    (let* ((target (write-on--target))
           (variants (write-on--variants (plist-get target :id))))
      (write-on--apply target (car variants) variants))
    (should (string-match-p "The cache\nis fast\\." (buffer-string)))))

(ert-deftest write-on-panel-can-be-used-repeatedly ()
  (write-on-test-buffer "fast cache"
    (let ((source (current-buffer)))
      (unwind-protect
          (progn
            (write-on--show (write-on--target) '("quick" "swift"))
            (with-current-buffer "*Write On*"
              (goto-char (point-min))
              (search-forward "quick")
              (button-activate (button-at (1- (point)))))
            (with-current-buffer "*Write On*"
              (goto-char (point-min))
              (search-forward "swift")
              (button-activate (button-at (1- (point)))))
            (with-current-buffer source
              (should (equal (buffer-string) "swift cache")))
            (with-current-buffer "*Write On*" (write-on-panel-accept))
            (with-current-buffer source
              (should (string-match-p "\\]\\[swift\\]\\]" (buffer-string)))))
        (when (get-buffer "*Write On*") (kill-buffer "*Write On*"))))))

(ert-deftest write-on-async-stale-response-is-discarded ()
  (write-on-test-buffer "fast cache"
    (let ((write-on-command '("sh" "-c" "read line; printf '[\"quick\"]'"))
          shown)
      (cl-letf (((symbol-function 'write-on--show) (lambda (&rest _) (setq shown t))))
        (write-on-generate)
        (delete-char 1)
        (let ((deadline (+ (float-time) 5)))
          (while (and write-on--process (< (float-time) deadline))
            (accept-process-output nil 0.02)))
        (should-not write-on--process)
        (should-not shown)
        (should (equal (buffer-string) "ast cache"))))))

(defmacro write-on-test-panel (text entries &rest body)
  (declare (indent 2))
  `(write-on-test-buffer ,text
     (let ((source (current-buffer)))
       (save-window-excursion
         (unwind-protect
             (progn
               (write-on--show (write-on--target) ,entries)
               (with-current-buffer "*Write On*" ,@body))
           (when (get-buffer "*Write On*") (kill-buffer "*Write On*")))))))

(ert-deftest write-on-keyboard-previews-and-cancel-restores ()
  (write-on-test-panel "fast cache" '("quick" "swift")
    (should (eq (key-binding (kbd "j")) #'write-on-panel-next))
    (should (eq (key-binding (kbd "a")) #'write-on-panel-add))
    (write-on-panel-next)
    (with-current-buffer source (should (equal (buffer-string) "quick cache")))
    (write-on-panel-next)
    (with-current-buffer source (should (equal (buffer-string) "swift cache")))
    (write-on-panel-next)
    (with-current-buffer source (should (equal (buffer-string) "fast cache")))
    (write-on-panel-previous)
    (with-current-buffer source (should (equal (buffer-string) "swift cache")))
    (write-on-panel-cancel)
    (with-current-buffer source (should (equal (buffer-string) "fast cache")))))

(ert-deftest write-on-panel-add-persists-authorship ()
  (write-on-test-panel "fast cache" '((:text "quick" :origin "ai"))
    (write-on-panel-next)
    (should (string-match-p "\\[AI\\]" (buffer-string)))
    (write-on-panel-add "speedy")
    (should (string-match-p "\\[Mine\\]" (buffer-string)))
    (with-current-buffer source (should (equal (buffer-string) "speedy cache")))
    (write-on-panel-accept)
    (with-current-buffer source
      (goto-char (point-min))
      (let* ((target (write-on--target))
             (entries (write-on--entries (plist-get target :id))))
        (should (member '(:text "speedy" :origin "mine") entries))
        (should (member '(:text "quick" :origin "ai") entries))
        (should (member '(:text "fast" :origin "original") entries))
        (let ((saved (buffer-string)))
          (erase-buffer)
          (insert saved)
          (goto-char (point-min))
          (should (equal entries (write-on--entries (plist-get (write-on--target) :id)))))))))

(ert-deftest write-on-preview-save-is-guarded ()
  (write-on-test-panel "fast cache" '("quick")
    (write-on-panel-next)
    (with-current-buffer source
      (should-error (write-on--guard-save) :type 'user-error))
    (write-on-panel-cancel)
    (with-current-buffer source
      (should-not (memq #'write-on--guard-save before-save-hook)))))

(ert-deftest write-on-cancel-preserves-unrelated-edits ()
  (write-on-test-panel "fast cache" '("quick" "swift")
    (write-on-panel-next)
    (with-current-buffer source
      (goto-char (point-max))
      (insert " today"))
    (write-on-panel-next)
    (write-on-panel-cancel)
    (with-current-buffer source
      (should (equal (buffer-string) "fast cache today"))
      (should (buffer-modified-p)))))

(ert-deftest write-on-cancel-does-not-clobber-a-manual-edit ()
  (write-on-test-panel "fast cache" '("quick")
    (write-on-panel-next)
    (with-current-buffer source
      (goto-char (point-min))
      (delete-char 1)
      (insert "Q"))
    (should-error (write-on-panel-next) :type 'user-error)
    (write-on-panel-cancel)
    (with-current-buffer source
      (should (equal (buffer-string) "Quick cache")))))

(ert-deftest write-on-cancel-restores-clean-buffer-state ()
  (write-on-test-buffer "fast cache"
    (set-buffer-modified-p nil)
    (let ((source (current-buffer)))
      (save-window-excursion
        (unwind-protect
            (progn
              (write-on--show (write-on--target) '("quick"))
              (with-current-buffer "*Write On*"
                (write-on-panel-next)
                (write-on-panel-cancel))
              (with-current-buffer source
                (should-not (buffer-modified-p))))
          (when (get-buffer "*Write On*") (kill-buffer "*Write On*")))))))

(ert-deftest write-on-killing-panel-restores-source ()
  (write-on-test-panel "fast cache" '("quick")
    (write-on-panel-next)
    (kill-buffer "*Write On*")
    (with-current-buffer source
      (should (equal (buffer-string) "fast cache")))))

(ert-deftest write-on-existing-choice-cancel-preserves-metadata ()
  (write-on-test-buffer "fast cache"
    (write-on-add "quick")
    (let ((before (buffer-string))
          (source (current-buffer)))
      (save-window-excursion
        (unwind-protect
            (progn
              (write-on-choose)
              (with-current-buffer "*Write On*"
                (write-on-panel-next)
                (write-on-panel-cancel))
              (with-current-buffer source
                (should (equal before (buffer-string)))))
          (when (get-buffer "*Write On*") (kill-buffer "*Write On*")))))))

(ert-deftest write-on-legacy-metadata-is-unattributed ()
  (write-on-test-buffer "[[write-on:legacy][fast]]\n\n#+WRITE_ON: legacy [\"fast\",\"quick\"]\n"
    (should (equal (write-on--entries "legacy")
                   '((:text "fast" :origin "unknown") (:text "quick" :origin "unknown"))))))

;;; write-on-test.el ends here

