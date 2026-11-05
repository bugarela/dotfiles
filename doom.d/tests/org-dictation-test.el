;;; org-dictation-test.el --- Voice comment tests -*- lexical-binding: t; -*-
(require 'ert)
(require 'org)
(require 'org-dictation)

(ert-deftest org-dictation-inserts-at-marker-not-current-point ()
  (with-temp-buffer
    (org-mode)
    (insert "First passage.\nSecond passage.\n")
    (goto-char (point-min))
    (let ((process (make-pipe-process :name "voice-test" :noquery t)))
      (unwind-protect
          (progn
            (process-put process 'dictation-marker (copy-marker (line-end-position)))
            (goto-char (point-max))
            (my/org-dictation--insert process "Why this?\nPlease simplify.")
            (should (equal (buffer-string)
                           "First passage.\n# ? Why this? Please simplify.\n\nSecond passage.\n")))
        (delete-process process)))))

(ert-deftest dictation-plain-text-inserts-at-exact-point-in-any-mode ()
  (dolist (mode '(text-mode emacs-lisp-mode org-mode))
    (with-temp-buffer
      (funcall mode)
      (insert "Before  after")
      (goto-char 8)
      (let ((process (make-pipe-process :name "plain-voice-test" :noquery t)))
        (unwind-protect
            (progn
              (process-put process 'dictation-marker (copy-marker (point)))
              (process-put process 'dictation-plain-text t)
              (my/org-dictation--insert process "spoken words")
              (should (equal (buffer-string) "Before spoken words after"))
              (should (= (point) (+ 8 (length "spoken words")))))
          (delete-process process))))))

(ert-deftest dictation-plain-keeps-moved-point-and-saved-target ()
  (with-temp-buffer
    (text-mode)
    (insert "first\nsecond")
    (goto-char 3)
    (let ((process (make-pipe-process :name "plain-marker-test" :noquery t)))
      (unwind-protect
          (progn
            (process-put process 'dictation-marker (copy-marker (point)))
            (process-put process 'dictation-plain-text t)
            (goto-char (point-max))
            (my/org-dictation--insert process "WORD")
            (should (equal (buffer-string) "fiWORDrst\nsecond"))
            (should (= (point) (point-max))))
        (delete-process process)))))

(ert-deftest dictation-generic-toggle-works-in-non-org-buffers ()
  (let ((my/org-dictation-process nil)
        (my/org-dictation-command
         '("python3" "-u" "-c"
           "import json,sys; print(json.dumps({'event':'recording'})); sys.stdin.readline(); print(json.dumps({'event':'text','text':'Dictated text'}))")))
    (with-temp-buffer
      (text-mode)
      (insert "Note: ")
      (unwind-protect
          (progn
            (my/dictation-toggle)
            (org-dictation-test--wait
             (lambda () (eq (process-get my/org-dictation-process 'dictation-state) 'recording)))
            (my/dictation-toggle)
            (org-dictation-test--wait (lambda () (null my/org-dictation-process)))
            (should (equal (buffer-string) "Note: Dictated text")))
        (my/org-dictation-cancel)))))

(ert-deftest dictation-generic-rejects-read-only ()
  (let ((my/org-dictation-process nil))
    (with-temp-buffer
      (setq buffer-read-only t)
      (should-error (my/dictation-toggle) :type 'user-error))))

(ert-deftest org-dictation-decodes-split-json ()
  (let ((process (make-pipe-process :name "voice-json-test" :noquery t)))
    (unwind-protect
        (progn
          (my/org-dictation--filter process "{\"event\":\"text\",\"te")
          (should-not (process-get process 'dictation-text))
          (my/org-dictation--filter process "xt\":\"Why?\"}\n")
          (should (equal (process-get process 'dictation-text) "Why?")))
      (delete-process process))))

(ert-deftest org-dictation-rejects-non-org-and-source-blocks ()
  (let ((my/org-dictation-process nil))
    (with-temp-buffer
      (should-error (my/org-dictation-toggle) :type 'user-error)
      (org-mode)
      (insert "#+begin_src text\nexample\n#+end_src\n")
      (goto-char (point-min))
      (forward-line 1)
      (should-error (my/org-dictation-toggle) :type 'user-error))))

(defun org-dictation-test--wait (predicate)
  (let ((deadline (+ (float-time) 5)))
    (while (and (not (funcall predicate)) (< (float-time) deadline))
      (accept-process-output nil 0.05))
    (should (funcall predicate))))

(ert-deftest org-dictation-toggle-end-to-end-with-fake-backend ()
  (let ((my/org-dictation-process nil)
        (my/org-dictation-command
         '("python3" "-u" "-c"
           "import json,sys; print(json.dumps({'event':'recording'})); sys.stdin.readline(); print(json.dumps({'event':'text','text':'Please clarify.'}))")))
    (with-temp-buffer
      (org-mode)
      (insert "A decision.")
      (unwind-protect
          (progn
            (my/org-dictation-toggle)
            (org-dictation-test--wait
             (lambda () (eq (process-get my/org-dictation-process 'dictation-state) 'recording)))
            (my/org-dictation-toggle)
            (org-dictation-test--wait (lambda () (null my/org-dictation-process)))
            (should (equal (buffer-string) "A decision.\n# ? Please clarify.\n")))
        (my/org-dictation-cancel)))))

(ert-deftest org-dictation-killing-target-cancels-capture ()
  (let ((my/org-dictation-process nil)
        (my/org-dictation-command
         '("python3" "-u" "-c"
           "import json,time; print(json.dumps({'event':'recording'})); time.sleep(30)"))
        (buffer (generate-new-buffer " *voice-target*")))
    (unwind-protect
        (progn
          (with-current-buffer buffer
            (org-mode)
            (my/org-dictation-toggle))
          (org-dictation-test--wait
           (lambda () (eq (process-get my/org-dictation-process 'dictation-state) 'recording)))
          (kill-buffer buffer)
          (org-dictation-test--wait (lambda () (null my/org-dictation-process))))
      (my/org-dictation-cancel)
      (when (buffer-live-p buffer) (kill-buffer buffer)))))

(ert-deftest org-dictation-cancel-inserts-nothing ()
  (let ((my/org-dictation-process nil)
        (my/org-dictation-command
         '("python3" "-u" "-c"
           "import json,time; print(json.dumps({'event':'recording'})); time.sleep(30)")))
    (with-temp-buffer
      (org-mode)
      (insert "Keep this unchanged.")
      (unwind-protect
          (progn
            (my/org-dictation-toggle)
            (org-dictation-test--wait
             (lambda () (eq (process-get my/org-dictation-process 'dictation-state) 'recording)))
            (my/org-dictation-cancel)
            (org-dictation-test--wait (lambda () (null my/org-dictation-process)))
            (should (equal (buffer-string) "Keep this unchanged.")))
        (my/org-dictation-cancel)))))
