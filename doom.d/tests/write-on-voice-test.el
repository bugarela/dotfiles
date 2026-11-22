;;; write-on-voice-test.el --- Selected prose voice instructions -*- lexical-binding: t; -*-
(require 'ert)
(require 'org-dictation)
(require 'write-on)

(defconst write-on-voice-test--backend
  '("python3" "-u" "-c"
    "import json,sys; print(json.dumps({'event':'recording'})); sys.stdin.readline(); print(json.dumps({'event':'text','text':'Make it more concrete.'}))"))

(defun write-on-voice-test--wait (predicate)
  (let ((deadline (+ (float-time) 5)))
    (while (and (not (funcall predicate)) (< (float-time) deadline))
      (accept-process-output nil 0.02))
    (should (funcall predicate))))

(defmacro write-on-voice-test-buffer (&rest body)
  (declare (indent 0))
  `(let ((my/org-dictation-process nil)
         (my/org-dictation-command write-on-voice-test--backend)
         (write-on-command
          '("python3" "-u" "-c"
            "import json,sys; p=sys.stdin.read(); assert 'Make it more concrete.' in p; assert 'exactly one' in p; assert 'The system is good.' in p; print(json.dumps(['The system completes each job in two seconds.']))")))
     (save-window-excursion
       (with-temp-buffer
         (org-mode)
         (write-on-mode 1)
         (insert "The system is good. Other text stays.\n")
         (goto-char (point-min))
         (set-mark (+ (point-min) (length "The system is good.")))
         (setq transient-mark-mode t mark-active t)
         (let ((source (current-buffer)))
           (unwind-protect
               (progn ,@body)
             (my/org-dictation-cancel)
             (when (process-live-p my/org-dictation-process)
               (write-on-voice-test--wait (lambda () (null my/org-dictation-process))))
             (with-current-buffer source (write-on-cancel))
             (when (get-buffer "*Write On*") (kill-buffer "*Write On*"))
             (when (get-buffer "*Voice dictation recovery*")
               (kill-buffer "*Voice dictation recovery*"))))))))

(ert-deftest write-on-voice-end-to-end-previews-one-ai-alternative ()
  (write-on-voice-test-buffer
    (write-on-dictation-toggle)
    (write-on-voice-test--wait
     (lambda () (eq (process-get my/org-dictation-process 'dictation-state) 'recording)))
    ;; Stopping from a different buffer must still rewrite the captured selection.
    (with-temp-buffer (text-mode) (write-on-dictation-toggle))
    (write-on-voice-test--wait
     (lambda () (and (not my/org-dictation-process)
                     (not (buffer-local-value 'write-on--process source))
                     (get-buffer "*Write On*"))))
    (with-current-buffer source
      (should (equal (buffer-string)
                     "The system completes each job in two seconds. Other text stays.\n"))
      (should-not (string-match-p "Make it more concrete" (buffer-string))))
    (with-current-buffer "*Write On*"
      (should (= (length (plist-get write-on--session :entries)) 2))
      (should (equal (plist-get (nth (plist-get write-on--session :index)
                                     (plist-get write-on--session :entries)) :origin) "ai"))
      (write-on-panel-accept))
    (with-current-buffer source
      (goto-char (point-min))
      (should (member '(:text "The system completes each job in two seconds." :origin "ai")
                      (write-on--entries (plist-get (write-on--target) :id)))))))

(ert-deftest write-on-voice-without-selection-is-plain-dictation ()
  (write-on-voice-test-buffer
    (deactivate-mark)
    (write-on-dictation-toggle)
    (write-on-voice-test--wait
     (lambda () (eq (process-get my/org-dictation-process 'dictation-state) 'recording)))
    (write-on-dictation-toggle)
    (write-on-voice-test--wait (lambda () (null my/org-dictation-process)))
    (should (string-prefix-p "Make it more concrete.The system" (buffer-string)))
    (should-not write-on--process)))

(ert-deftest write-on-voice-cancel-does-not-send-an-instruction ()
  (write-on-voice-test-buffer
    (let (called)
      (cl-letf (((symbol-function 'write-on-generate) (lambda (&rest _) (setq called t))))
        (write-on-dictation-toggle)
        (write-on-voice-test--wait
         (lambda () (eq (process-get my/org-dictation-process 'dictation-state) 'recording)))
        (my/org-dictation-cancel)
        (write-on-voice-test--wait (lambda () (null my/org-dictation-process)))
        (should-not called)
        (should (equal (buffer-string) "The system is good. Other text stays.\n"))))))

(ert-deftest write-on-voice-stale-selection-recovers-instruction ()
  (write-on-voice-test-buffer
    (let (called)
      (cl-letf (((symbol-function 'write-on-generate) (lambda (&rest _) (setq called t))))
        (write-on-dictation-toggle)
        (write-on-voice-test--wait
         (lambda () (eq (process-get my/org-dictation-process 'dictation-state) 'recording)))
        (delete-char 1)
        (deactivate-mark)
        (write-on-dictation-toggle)
        (write-on-voice-test--wait (lambda () (null my/org-dictation-process)))
        (should-not called)
        (should (string-prefix-p "he system" (buffer-string)))
        (with-current-buffer "*Voice dictation recovery*"
          (should (string-match-p "Make it more concrete" (buffer-string))))))))

(ert-deftest write-on-voice-tracks-selection-through-unrelated-edits ()
  (write-on-voice-test-buffer
    (write-on-dictation-toggle)
    (write-on-voice-test--wait
     (lambda () (eq (process-get my/org-dictation-process 'dictation-state) 'recording)))
    (goto-char (point-min))
    (insert "Introduction.\n\n")
    (deactivate-mark)
    (write-on-dictation-toggle)
    (write-on-voice-test--wait
     (lambda () (and (not my/org-dictation-process)
                     (not (buffer-local-value 'write-on--process source))
                     (get-buffer "*Write On*"))))
    (with-current-buffer "*Write On*" (write-on-panel-cancel))
    (with-current-buffer source
      (should (equal (buffer-string) "Introduction.\n\nThe system is good. Other text stays.\n")))))

(ert-deftest write-on-selected-visible-alternative-targets-whole-link ()
  (with-temp-buffer
    (org-mode)
    (insert "[[write-on:example][The system is good.]] Other prose.\n")
    (goto-char (point-min))
    (search-forward "][")
    (set-mark (point))
    (search-forward "The system is good.")
    (setq transient-mark-mode t mark-active t)
    (let ((target (write-on--target)))
      (should (equal (plist-get target :text) "The system is good."))
      (should (equal (plist-get target :id) "example"))
      (should (equal (plist-get target :raw) "[[write-on:example][The system is good.]]")))))

(ert-deftest write-on-voice-refines-an-uncommitted-preview ()
  (write-on-voice-test-buffer
    (let ((write-on-command '("python3" "-u" "-c"
                              "import sys; sys.stdin.read(); print('[\"A concrete benefit.\"]')")))
      (write-on--show (write-on--target) '((:text "The system is excellent." :origin "ai")))
      (with-current-buffer "*Write On*" (write-on-panel-next))
      (with-current-buffer source
        (goto-char (point-min))
        (set-mark (+ (point-min) (length "The system is excellent.")))
        (setq transient-mark-mode t mark-active t)
        (write-on-dictation-toggle))
      (write-on-voice-test--wait
       (lambda () (eq (process-get my/org-dictation-process 'dictation-state) 'recording)))
      (write-on-dictation-toggle)
      (write-on-voice-test--wait
       (lambda () (and (not my/org-dictation-process)
                       (not (buffer-local-value 'write-on--process source)))))
      (with-current-buffer source
        (should (equal (buffer-string) "A concrete benefit. Other text stays.\n")))
      (with-current-buffer "*Write On*"
        (should (= (length (plist-get write-on--session :entries)) 3))
        (write-on-panel-cancel))
      (with-current-buffer source
        (should (equal (buffer-string) "The system is good. Other text stays.\n"))))))

(ert-deftest write-on-voice-model-failure-recovers-instruction ()
  (write-on-voice-test-buffer
    (let ((write-on-command '("python3" "-u" "-c"
                              "import sys; sys.stdin.read(); print('not JSON')")))
      (write-on-dictation-toggle)
      (write-on-voice-test--wait
       (lambda () (eq (process-get my/org-dictation-process 'dictation-state) 'recording)))
      (write-on-dictation-toggle)
      (write-on-voice-test--wait
       (lambda () (and (not my/org-dictation-process)
                       (not (buffer-local-value 'write-on--process source)))))
      (with-current-buffer source
        (should (equal (buffer-string) "The system is good. Other text stays.\n")))
      (with-current-buffer "*Voice dictation recovery*"
        (should (string-match-p "Make it more concrete" (buffer-string)))))))

;;; write-on-voice-test.el ends here
