;;; gloss-display.el --- Side-buffer UI for gloss -*- lexical-binding: t -*-

;; Copyright (C) 2026 Craig Jennings
;; Author: Craig Jennings <c@cjennings.net>
;; SPDX-License-Identifier: GPL-3.0-or-later

;;; Commentary:

;; UI layer for `gloss'.  Defines the side buffer's major mode and
;; renders entries; also owns the picker shown when an online fetch
;; returns multiple candidate definitions.
;;
;; Public API:
;;   `gloss-display-show-entry' TERM BODY
;;   `gloss-display-pick-definition' TERM DEFINITIONS -> chosen plist
;;
;; Pure helpers (full N/B/E test coverage):
;;   `gloss-display--format-candidate' PLIST -> "[source] text..."
;;   `gloss-display--render-entry' TERM BODY -> rendered string
;;
;; `gloss-mode' is derived from `special-mode': `q' quits the window.
;;
;; See `docs/design/gloss.org' for the full design.

;;; Code:

(defconst gloss-display--candidate-max-length 80
  "Maximum total length of a formatted candidate row.
Rows longer than this are truncated and end in an ellipsis.")

(defconst gloss-display--buffer-name-format "*gloss: %s*"
  "Format string for the side buffer name.  Single %s receives the term.")

(defconst gloss-display--side-window-alist
  '((display-buffer-in-side-window)
    (side . right)
    (window-width . 0.4))
  "Display action used by `gloss-display-show-entry'.")

(define-derived-mode gloss-mode special-mode "Gloss"
  "Major mode for the gloss side buffer.

\\{gloss-mode-map}"
  (setq-local truncate-lines nil))

(defun gloss-display--format-candidate (plist)
  "Format definition PLIST as a single-line `completing-read' row.
Return \"[source] text\".  Embedded newlines and runs of whitespace
collapse to a single space.  When the row would exceed
`gloss-display--candidate-max-length', the text portion is truncated
and the row ends in \"...\".  A missing :source falls back to the
literal tag \"unknown\"."
  (unless (listp plist)
    (signal 'wrong-type-argument (list 'listp plist)))
  (let* ((source (or (plist-get plist :source) 'unknown))
         (text (or (plist-get plist :text) ""))
         (single-line (replace-regexp-in-string "[ \t\n]+" " " text))
         (prefix (format "[%s] " source))
         (room (- gloss-display--candidate-max-length (length prefix))))
    (if (<= (length single-line) room)
        (concat prefix single-line)
      (concat prefix (substring single-line 0 (max 0 (- room 3))) "..."))))

(defun gloss-display--render-entry (term body)
  "Return the rendered string for TERM and BODY.
The format is the term, an underline of `=' matching the term length,
a blank line, then the body verbatim."
  (format "%s\n%s\n\n%s" term (make-string (length term) ?=) body))

(defun gloss-display-pick-definition (term definitions)
  "Prompt the user to pick one of DEFINITIONS for TERM.
DEFINITIONS is a list of plists shaped (:source SYM :text STRING).
Return the chosen plist, or nil if DEFINITIONS is empty or the user
cancelled with \\[keyboard-quit]."
  (when definitions
    (let* ((alist (mapcar (lambda (def)
                            (cons (gloss-display--format-candidate def) def))
                          definitions))
           (prompt (format "Pick definition for %s: " term))
           (choice (condition-case nil
                       (completing-read prompt alist nil t)
                     (quit nil))))
      (and choice (cdr (assoc choice alist))))))

(defun gloss-display-show-entry (term body)
  "Display TERM's BODY in the gloss side buffer and return the buffer."
  (let ((buf (get-buffer-create
              (format gloss-display--buffer-name-format term))))
    (with-current-buffer buf
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert (gloss-display--render-entry term body))
        (goto-char (point-min)))
      (unless (derived-mode-p 'gloss-mode)
        (gloss-mode)))
    (display-buffer buf gloss-display--side-window-alist)
    buf))

(provide 'gloss-display)
;;; gloss-display.el ends here
