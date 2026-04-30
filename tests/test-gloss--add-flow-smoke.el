;;; test-gloss--add-flow-smoke.el --- Smoke tests for the gloss-add interactive flow -*- lexical-binding: t -*-

;; SPDX-License-Identifier: GPL-3.0-or-later

;;; Commentary:
;; Smoke tests for the `gloss-add' interactive flow.  The buffer pops
;; up in the side-window slot with a read-only header (term +
;; underline + blank line) and an editable body region beneath it.
;; `gloss-add-finish' reads the body region, saves, and shows the
;; rendered entry in the same side slot.  `gloss-add-abort' kills the
;; buffer and closes the side window.

;;; Code:

(require 'ert)
(require 'cl-lib)
(require 'gloss)
(require 'testutil-gloss)

(defmacro gloss-test--with-add-display-mocks (&rest body)
  "Run BODY with `pop-to-buffer' replaced by a no-op that keeps the
buffer current, and `gloss-display-show-entry' / `delete-window' as
capturing no-ops."
  (declare (indent 0) (debug t))
  `(cl-letf (((symbol-function 'pop-to-buffer)
              (lambda (buf &rest _) (set-buffer buf) (current-buffer)))
             ((symbol-function 'get-buffer-window)
              (lambda (&rest _) nil))
             ((symbol-function 'gloss-display-show-entry)
              (lambda (_ _) nil)))
     ,@body))

(ert-deftest test-gloss-add-opens-buffer-with-read-only-header ()
  "Smoke: gloss-add buffer renders the header read-only and exposes a
live `gloss-add--body-start' marker pointing past the header."
  (gloss-test--with-missing-glossary
    (gloss-test--with-add-display-mocks
      (gloss-add "newterm")
      (let ((buf (get-buffer "*gloss-add: newterm*")))
        (unwind-protect
            (with-current-buffer buf
              (should (eq major-mode 'gloss-add-mode))
              (should (equal gloss-add--term "newterm"))
              (should (markerp gloss-add--body-start))
              ;; Header content is the rendered entry with empty body.
              (let ((header (buffer-substring-no-properties
                             (point-min) gloss-add--body-start)))
                (should (string-match-p "^newterm\n=+\n\n" header)))
              ;; Header range is read-only.
              (should (get-text-property (point-min) 'read-only))
              ;; Body-start position is NOT read-only (rear-nonsticky).
              (should-not (get-text-property gloss-add--body-start 'read-only))
              ;; Editing the header raises text-read-only.
              (should-error (let ((inhibit-read-only nil))
                              (goto-char (point-min))
                              (insert "x"))
                            :type 'text-read-only))
          (when (buffer-live-p buf)
            (let ((kill-buffer-query-functions nil))
              (kill-buffer buf))))))))

(ert-deftest test-gloss-add-empty-term-raises-and-opens-no-buffer ()
  "Error: empty term raises `user-error' and never opens an add buffer."
  (gloss-test--with-missing-glossary
    (gloss-test--with-add-display-mocks
      (should-error (gloss-add "") :type 'user-error)
      (should-error (gloss-add "   ") :type 'user-error)
      (should-not (get-buffer "*gloss-add: *"))
      (should-not (get-buffer "*gloss-add:    *")))))

(ert-deftest test-gloss-add-finish-reads-body-saves-without-showing ()
  "Smoke: finish reads body from after the header, saves, kills the
buffer, and does NOT pop a side display.  Add is a save-and-return
flow (org-capture style); only `gloss-lookup' shows the side entry."
  (gloss-test--with-missing-glossary
    (let (show-called)
      (cl-letf (((symbol-function 'pop-to-buffer)
                 (lambda (buf &rest _) (set-buffer buf)))
                ((symbol-function 'gloss-display-show-entry)
                 (lambda (_ _) (setq show-called t))))
        (gloss-add "term")
        (with-current-buffer (get-buffer "*gloss-add: term*")
          (goto-char (point-max))
          (let ((inhibit-read-only nil))
            (insert "Definition body."))
          (gloss-add-finish))
        (should-not (get-buffer "*gloss-add: term*"))
        (let ((saved (gloss-core-lookup "term")))
          (should saved)
          (should (equal (plist-get saved :body) "Definition body.")))
        (should-not show-called)))))

(ert-deftest test-gloss-add-abort-kills-buffer-without-save ()
  "Smoke: abort kills the buffer with no save and no show.
The window-cleanup path (`delete-window' on the side window) only runs
when the buffer is actually displayed; in batch mode it isn't, so we
verify the save and show side effects rather than the window state."
  (gloss-test--with-missing-glossary
    (let (show-called)
      (cl-letf (((symbol-function 'pop-to-buffer)
                 (lambda (buf &rest _) (set-buffer buf)))
                ((symbol-function 'gloss-display-show-entry)
                 (lambda (_ _) (setq show-called t))))
        (gloss-add "term")
        (with-current-buffer (get-buffer "*gloss-add: term*")
          (goto-char (point-max))
          (let ((inhibit-read-only nil))
            (insert "Body the user typed but abandoned."))
          (gloss-add-abort))
        (should-not (get-buffer "*gloss-add: term*"))
        (should-not (gloss-core-lookup "term"))
        (should-not show-called)))))

(provide 'test-gloss--add-flow-smoke)
;;; test-gloss--add-flow-smoke.el ends here
