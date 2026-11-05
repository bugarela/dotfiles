;;; org-dictation.el --- Local dictation and Org voice comments -*- lexical-binding: t; -*-

(require 'cl-lib)
(require 'json)
(require 'subr-x)

(defgroup my/org-dictation nil "Local Whisper dictation." :group 'editing)
(defcustom my/org-dictation-command '("note-taker" "--dictate")
  "Command for the JSON-lines dictation backend."
  :type '(repeat string))

(defvar my/org-dictation-process nil)
(defvar my/org-dictation-status "")
(add-to-list 'global-mode-string 'my/org-dictation-status t)

(defun my/org-dictation--status (process state label)
  (process-put process 'dictation-state state)
  (setq my/org-dictation-status label)
  (force-mode-line-update t))

(defun my/org-dictation--event (process event)
  (pcase (alist-get 'event event)
    ("loading"
     (my/org-dictation--status process 'loading " [Voice: loading]"))
    ("recording"
     (my/org-dictation--status process 'recording " [Voice: RECORDING]")
     (message "Dictation: speak now; F8 to stop, Shift+F8 to cancel"))
    ("transcribing"
     (my/org-dictation--status process 'transcribing " [Voice: transcribing]"))
    ("text" (process-put process 'dictation-text (alist-get 'text event)))))

(defun my/org-dictation--filter (process chunk)
  "Decode JSON lines even when process output splits a message."
  (let ((pending (concat (process-get process 'dictation-pending) chunk)))
    (while (string-match "\n" pending)
      (let ((line (substring pending 0 (match-beginning 0))))
        (setq pending (substring pending (match-end 0)))
        (unless (string-empty-p line)
          (condition-case err
              (my/org-dictation--event
               process (json-parse-string line :object-type 'alist))
            (error
             (process-put process 'dictation-error
                          (format "Invalid backend output: %s" (error-message-string err))))))))
    (process-put process 'dictation-pending pending)))

(defun my/org-dictation--recover (comment)
  "Keep COMMENT available if its original destination is no longer editable."
  (with-current-buffer (get-buffer-create "*Voice dictation recovery*")
    (goto-char (point-max))
    (unless (bolp) (insert "\n"))
    (insert comment)
    (unless (bolp) (insert "\n")))
  (display-buffer "*Voice dictation recovery*")
  (message "Transcription preserved in *Voice dictation recovery*"))

(defun my/org-dictation--insert (process text)
  (let* ((marker (process-get process 'dictation-marker))
         (buffer (and marker (marker-buffer marker)))
         (plain (process-get process 'dictation-plain-text))
         (normalized (string-trim (replace-regexp-in-string "[[:space:]]+" " " text)))
         (comment (if plain normalized (concat "# ? " normalized "\n"))))
    (if (not (buffer-live-p buffer))
        (my/org-dictation--recover comment)
      (condition-case nil
          (with-current-buffer buffer
            (let ((follow (and plain (= (point) marker))) end)
              (save-excursion
                (goto-char marker)
                (unless plain (end-of-line))
                (undo-boundary)
                (atomic-change-group
                  (unless (or plain (bolp)) (insert "\n"))
                  (insert comment)
                  (setq end (point)))
                (undo-boundary))
              (when follow (goto-char end)))
            (message "Dictation inserted in %s (not auto-saved)" (buffer-name)))
        (error (my/org-dictation--recover comment))))))

(defun my/org-dictation--sentinel (process _event)
  (when (memq (process-status process) '(exit signal))
    (unwind-protect
        (cond
         ((process-get process 'dictation-cancelled)
          (message "Dictation cancelled"))
         ((or (/= (process-exit-status process) 0)
              (process-get process 'dictation-error))
          (message "Dictation failed: %s; see *Org dictation errors*"
                   (or (process-get process 'dictation-error)
                       (format "backend exit %s" (process-exit-status process)))))
         ((not (stringp (process-get process 'dictation-text)))
          (message "Dictation failed: backend returned no transcription"))
         ((string-empty-p (string-trim (process-get process 'dictation-text)))
          (message "No speech detected; nothing inserted"))
         (t (my/org-dictation--insert process (process-get process 'dictation-text))))
      (when-let* ((marker (process-get process 'dictation-marker)))
        (set-marker marker nil))
      (when (eq process my/org-dictation-process)
        (setq my/org-dictation-process nil
              my/org-dictation-status "")
        (force-mode-line-update t)))))

(defun my/org-dictation--cancel-for-buffer ()
  "Stop capture when its destination buffer is killed."
  (when (and (process-live-p my/org-dictation-process)
             (eq (current-buffer)
                 (marker-buffer
                  (process-get my/org-dictation-process 'dictation-marker))))
    (my/org-dictation-cancel)))

;;;###autoload
(defun my/dictation-toggle (&optional org-comment)
  "Start/stop plain dictation in any editable buffer.
Insert at the saved point (or region end), without replacing selected text.
With ORG-COMMENT non-nil, insert an Org review comment after the saved line.
Wait for RECORDING before speaking; toggle again to stop and transcribe."
  (interactive)
  (if (process-live-p my/org-dictation-process)
      (pcase (process-get my/org-dictation-process 'dictation-state)
        ('recording
         (my/org-dictation--status my/org-dictation-process 'transcribing
                                   " [Voice: transcribing]")
         (process-send-string my/org-dictation-process "stop\n"))
        (_ (user-error "Voice is loading/transcribing; use the cancel command to discard")))
    (when buffer-read-only (user-error "This buffer is read-only"))
    (when org-comment
      (unless (derived-mode-p 'org-mode)
        (user-error "Start voice comments in an Org buffer"))
      (when (org-in-src-block-p)
        (user-error "Move outside the source block before adding a voice comment")))
    (unless (executable-find (car my/org-dictation-command))
      (user-error "Dictation backend not found: %s" (car my/org-dictation-command)))
    (let ((marker (copy-marker
                   (save-excursion
                     (when (use-region-p) (goto-char (region-end)))
                     (if org-comment (line-end-position) (point)))))
          ;; Always capture locally, even while editing a file through TRAMP.
          (default-directory (expand-file-name "~/")))
      (condition-case err
          (let ((process
                 (make-process :name "org-dictation"
                               :command my/org-dictation-command
                               :connection-type 'pipe :coding 'utf-8-unix
                               :noquery t :stderr "*Org dictation errors*"
                               :filter #'my/org-dictation--filter
                               :sentinel #'my/org-dictation--sentinel)))
            (setq my/org-dictation-process process)
            (process-put process 'dictation-marker marker)
            (process-put process 'dictation-plain-text (not org-comment))
            (add-hook 'kill-buffer-hook #'my/org-dictation--cancel-for-buffer nil t)
            (my/org-dictation--status process 'loading " [Voice: loading]")
            (message "Loading Whisper; wait for the RECORDING indicator"))
        (error (set-marker marker nil)
               (signal (car err) (cdr err)))))))

;;;###autoload
(defun my/org-dictation-toggle ()
  "Start/stop dictation of an Org review comment after the current passage."
  (interactive)
  (my/dictation-toggle t))

;;;###autoload
(defun my/org-dictation-cancel ()
  "Discard current dictation and stop its microphone capture."
  (interactive)
  (when (process-live-p my/org-dictation-process)
    (process-put my/org-dictation-process 'dictation-cancelled t)
    (my/org-dictation--status my/org-dictation-process 'cancelling " [Voice: cancelling]")
    ;; Signal only Python. Its finally block stops and reaps ffmpeg.
    (signal-process my/org-dictation-process 'SIGTERM)))

(add-hook 'kill-emacs-hook #'my/org-dictation-cancel)
(provide 'org-dictation)
;;; org-dictation.el ends here
