;;; gloss-drill.el --- org-drill export for gloss -*- lexical-binding: t -*-

;; Copyright (C) 2026 Craig Jennings
;; Author: Craig Jennings <c@cjennings.net>
;; SPDX-License-Identifier: GPL-3.0-or-later

;;; Commentary:

;; Spaced-repetition export for `gloss'.  Walks the glossary org file
;; via `org-map-entries' and ensures every term entry carries a `:drill:'
;; tag and a `:DRILL_CARD_TYPE: twosided' property.  `org-drill' then
;; runs unmodified against the file.
;;
;; Public API:
;;   `gloss-drill-export-all'
;;   `gloss-drill-untag-all'
;;
;; Idempotent: running export twice does not double-tag.
;; Checks `(featurep \\='org-drill)' before exporting; raises a helpful
;; user-error if `org-drill' isn't installed.  Untag-all does NOT
;; require `org-drill' — the user might be removing tags after
;; uninstalling.
;;
;; See `docs/design/gloss.org' for the full design.

;;; Code:

(require 'org)
(require 'gloss-core)

(defconst gloss-drill--card-type "twosided"
  "Value written to the :DRILL_CARD_TYPE: property by export-all.")

(defconst gloss-drill--tag "drill"
  "Tag added to every entry by export-all and removed by untag-all.")

(defun gloss-drill--map-entries (fn)
  "Open `gloss-file', call FN at every top-level entry, and save.
FN runs with point at the heading line.  The buffer is saved only if
modified."
  (let ((buf (find-file-noselect gloss-file)))
    (with-current-buffer buf
      (unless (verify-visited-file-modtime buf)
        (revert-buffer t t t))
      (unless (derived-mode-p 'org-mode)
        (let ((org-mode-hook nil))
          (org-mode)))
      (save-excursion
        (org-map-entries
         (lambda ()
           (when (= 1 (org-current-level))
             (funcall fn)))))
      (when (buffer-modified-p)
        (save-buffer)))))

(defun gloss-drill--add-drill-tag-and-property ()
  "Add `:drill:' tag and `DRILL_CARD_TYPE' property at the entry at point."
  (let ((tags (org-get-tags nil t)))
    (unless (member gloss-drill--tag tags)
      (org-set-tags (append tags (list gloss-drill--tag)))))
  (unless (equal (org-entry-get nil "DRILL_CARD_TYPE") gloss-drill--card-type)
    (org-entry-put nil "DRILL_CARD_TYPE" gloss-drill--card-type)))

(defun gloss-drill--remove-drill-tag-and-property ()
  "Remove `:drill:' tag and `DRILL_CARD_TYPE' property at the entry at point."
  (let ((tags (org-get-tags nil t)))
    (when (member gloss-drill--tag tags)
      (org-set-tags (delete gloss-drill--tag tags))))
  (when (org-entry-get nil "DRILL_CARD_TYPE")
    (org-entry-delete nil "DRILL_CARD_TYPE")))

;;;; Public API

(defun gloss-drill-export-all ()
  "Tag every entry in `gloss-file' for `org-drill'.
Adds `:drill:' tag and `DRILL_CARD_TYPE: twosided' property to each
top-level heading.  Idempotent.  Signals `user-error' if `org-drill'
is not installed."
  (interactive)
  (unless (featurep 'org-drill)
    (user-error
     "gloss-drill: `org-drill' is not installed.  Install it with M-x package-install RET org-drill RET"))
  (gloss-drill--map-entries #'gloss-drill--add-drill-tag-and-property))

(defun gloss-drill-untag-all ()
  "Remove the `:drill:' tag and `DRILL_CARD_TYPE' property from every entry.
Does NOT require `org-drill' to be installed."
  (interactive)
  (gloss-drill--map-entries #'gloss-drill--remove-drill-tag-and-property))

(provide 'gloss-drill)
;;; gloss-drill.el ends here
