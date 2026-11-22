;;; write-on-edit-test.el --- Capture-style alternatives -*- lexical-binding: t; -*-
(require 'ert)
(require 'write-on)
(require 'org-dictation)

(defmacro write-on-edit-test-panel (&rest body)
  (declare (indent 0))
  `(save-window-excursion
     (with-temp-buffer
       (org-mode)
       (write-on-mode 1)
       (insert "The system is useful. Other prose stays.\n")
       (goto-char (point-min))
       (set-mark (+ (point-min) (length "The system is useful.")))
       (setq transient-mark-mode t mark-active t)
       (let ((source (current-buffer)))
         (unwind-protect
             (progn
               (write-on--show (write-on--target)
                               '((:text "A clearer system." :origin "ai")))
               (with-current-buffer "*Write On*" ,@body))
           (when (get-buffer "*Write On draft*") (kill-buffer "*Write On draft*"))
           (when (get-buffer "*Write On*") (kill-buffer "*Write On*")))))))

(defun write-on-edit-test--replace-draft (text)
  (with-current-buffer "*Write On draft*"
    (erase-buffer)
    (insert text)))

(defun write-on-edit-test--wait (source)
  (let ((deadline (+ (float-time) 5)))
    (while (and (buffer-local-value 'write-on--process source) (< (float-time) deadline))
      (accept-process-output nil 0.02))
    (should-not (buffer-local-value 'write-on--process source))))

(ert-deftest write-on-editor-is-seeded-from-highlighted-option ()
  (write-on-edit-test-panel
    (write-on-panel-next)
    (let ((org-mode-hook (list (lambda () (write-on-mode 1)))))
      (cl-letf (((symbol-function 'read-string) (lambda (&rest _) (ert-fail "No minibuffer editor"))))
        (call-interactively #'write-on-panel-add)))
    (with-current-buffer "*Write On draft*"
      (should (derived-mode-p 'org-mode))
      (should-not write-on-mode)
      (should (equal (buffer-string) "A clearer system."))
      (should (= (point) (point-max))))
    (write-on-edit-test--replace-draft "An unfinished personal version.")
    (with-current-buffer "*Write On draft*" (write-on-edit-cancel))
    (should-not (get-buffer "*Write On draft*"))
    (with-current-buffer source
      (should (equal (buffer-string) "A clearer system. Other prose stays.\n"))
      (should-not write-on--process))))

(ert-deftest write-on-editor-source-command-does-not-read-minibuffer ()
  (save-window-excursion
    (with-temp-buffer
      (org-mode)
      (insert "Useful prose.")
      (goto-char (point-min))
      (unwind-protect
          (progn
            (cl-letf (((symbol-function 'read-string) (lambda (&rest _) (ert-fail "No minibuffer editor"))))
              (call-interactively #'write-on-add))
            (with-current-buffer "*Write On draft*"
              (should (equal (buffer-string) "Useful"))))
        (when (get-buffer "*Write On draft*") (kill-buffer "*Write On draft*"))
        (when (get-buffer "*Write On*") (kill-buffer "*Write On*"))))))

(ert-deftest write-on-editor-finish-generates-from-author-draft ()
  (write-on-edit-test-panel
    (let ((write-on-command
           '("python3" "-u" "-c"
             "import json,sys; p=sys.stdin.read(); d=json.loads(p.split('Source material: ',1)[1]); assert d['author_draft']=='The author added a reason.'; assert d['selection']==d['author_draft']; assert d['original_selection']=='The system is useful.'; print(json.dumps(['A developed explanation of the reason.','A different organization of the idea.']))")))
      (write-on-panel-add)
      (write-on-edit-test--replace-draft "The author added\n\na reason.\n")
      (with-current-buffer "*Write On draft*" (write-on-edit-finish))
      (should-not (get-buffer "*Write On draft*"))
      (write-on-edit-test--wait source)
      (with-current-buffer source
        (should (equal (buffer-string) "The author added a reason. Other prose stays.\n")))
      (with-current-buffer "*Write On*"
        (should (= (length (plist-get write-on--session :entries)) 5))
        (should (equal (plist-get (nth (plist-get write-on--session :index)
                                       (plist-get write-on--session :entries)) :origin) "mine"))
        (should (member '(:text "A developed explanation of the reason." :origin "ai")
                        (plist-get write-on--session :entries)))
        (write-on-panel-accept))
      (with-current-buffer source
        (goto-char (point-min))
        (should (member '(:text "The author added a reason." :origin "mine")
                        (write-on--entries (plist-get (write-on--target) :id))))))))

(ert-deftest write-on-editor-allows-browsing-while-ai-is-working ()
  (write-on-edit-test-panel
    (let ((write-on-command '("python3" "-u" "-c"
                              "import sys,time; sys.stdin.read(); time.sleep(.1); print('[\"A new explanation.\"]')")))
      (write-on-panel-add)
      (write-on-edit-test--replace-draft "My expanded version.")
      (with-current-buffer "*Write On draft*" (write-on-edit-finish))
      (with-current-buffer "*Write On*" (write-on-panel-previous))
      (write-on-edit-test--wait source)
      (with-current-buffer source
        (should (equal (buffer-string) "A clearer system. Other prose stays.\n")))
      (with-current-buffer "*Write On*"
        (should (member '(:text "A new explanation." :origin "ai")
                        (plist-get write-on--session :entries)))
        (should (member '(:text "My expanded version." :origin "mine")
                        (plist-get write-on--session :entries)))))))

(ert-deftest write-on-editor-closing-panel-cancels-followup-generation ()
  (dolist (action '(write-on-panel-accept write-on-panel-cancel))
    (write-on-edit-test-panel
      (let ((write-on-command '("python3" "-u" "-c"
                                "import sys,time; sys.stdin.read(); time.sleep(30)")))
        (write-on-panel-add)
        (write-on-edit-test--replace-draft "My version.")
        (with-current-buffer "*Write On draft*" (write-on-edit-finish))
        (should (process-live-p (buffer-local-value 'write-on--process source)))
        (with-current-buffer "*Write On*"
          (funcall action)
          (should-not write-on--session))
        (should-not (buffer-local-value 'write-on--process source))
        (accept-process-output nil 0.02)
        (with-current-buffer "*Write On*" (should-not write-on--session))))))

(ert-deftest write-on-editor-stale-source-preserves-editable-draft ()
  (write-on-edit-test-panel
    (write-on-panel-add)
    (write-on-edit-test--replace-draft "My version remains available.")
    (with-current-buffer source
      (goto-char (point-min))
      (delete-char 1))
    (with-current-buffer "*Write On draft*"
      (should-error (write-on-edit-finish) :type 'user-error)
      (should (equal (buffer-string) "My version remains available.")))
    (with-current-buffer source
      (should (string-prefix-p "he system" (buffer-string)))
      (should-not write-on--process))))

(ert-deftest write-on-editor-invalid-draft-is-not-discarded ()
  (write-on-edit-test-panel
    (write-on-panel-add)
    (write-on-edit-test--replace-draft "[An unfinished note]")
    (with-current-buffer "*Write On draft*"
      (should-error (write-on-edit-finish) :type 'user-error)
      (should (equal (buffer-string) "[An unfinished note]")))
    (with-current-buffer source
      (should (string-prefix-p "The system is useful." (buffer-string)))
      (should-not write-on--process))))

(ert-deftest write-on-editor-does-not-overwrite-an-existing-draft ()
  (write-on-edit-test-panel
    (write-on-panel-add)
    (write-on-edit-test--replace-draft "Keep my unfinished writing.")
    (with-current-buffer "*Write On*"
      (write-on-panel-next)
      (write-on-panel-add))
    (with-current-buffer "*Write On draft*"
      (should (equal (buffer-string) "Keep my unfinished writing.")))))

(ert-deftest write-on-editor-ai-failure-keeps-mine-version ()
  (write-on-edit-test-panel
    (let ((write-on-command '("python3" "-u" "-c"
                              "import sys; sys.stdin.read(); sys.exit(1)")))
      (write-on-panel-add)
      (write-on-edit-test--replace-draft "My own explanation.")
      (with-current-buffer "*Write On draft*" (write-on-edit-finish))
      (write-on-edit-test--wait source)
      (with-current-buffer source
        (should (equal (buffer-string) "My own explanation. Other prose stays.\n")))
      (with-current-buffer "*Write On*"
        (should (member '(:text "My own explanation." :origin "mine")
                        (plist-get write-on--session :entries)))))))

(ert-deftest write-on-editor-dictation-is-plain-text-not-a-rewrite ()
  (write-on-edit-test-panel
    (write-on-panel-add)
    (let ((my/org-dictation-process nil) called)
      (with-current-buffer "*Write On draft*"
        (goto-char (point-min))
        (set-mark (point-max))
        (setq transient-mark-mode t mark-active t)
        (cl-letf (((symbol-function 'my/dictation-toggle)
                   (lambda (&optional comment receiver)
                     (setq called t)
                     (should-not comment)
                     (should-not receiver))))
          (write-on-dictation-toggle)))
      (should called))))

(ert-deftest write-on-prompts-request-substantive-explanations ()
  (with-temp-buffer
    (org-mode)
    (insert "The cache is cleared.")
    (goto-char (point-min))
    (set-mark (point-max))
    (setq transient-mark-mode t mark-active t)
    (let ((prompt (write-on--prompt
                   (write-on--target)
                   "The [[write-on:x][cache]] contains expired entries."
                   "Explain the mechanism and why this matters." t)))
      (should (string-match-p "exactly one" prompt))
      (should (string-match-p "multiple sentences" prompt))
      (should (string-match-p "A synonym substitution is not an explanation" prompt))
      (should (string-match-p "Incorporate the author's added context" prompt))
      (should (string-match-p "Explain the mechanism and why this matters" prompt))
      (should-not (string-match-p "\\[\\[write-on:" prompt)))))

;;; write-on-edit-test.el ends here
