;;; gloss-core.el --- Data layer for gloss -*- lexical-binding: t -*-

;; Copyright (C) 2026 Craig Jennings
;; Author: Craig Jennings <c@cjennings.net>
;; SPDX-License-Identifier: GPL-3.0-or-later

;;; Commentary:

;; Storage and lookup primitives for `gloss'.  Owns the in-memory
;; cache (a hash table keyed by term) and the org file I/O.
;;
;; Public API:
;;   `gloss-core-lookup' TERM            -> entry plist or nil
;;   `gloss-core-save' TERM BODY SOURCE  -> entry plist (saved)
;;   `gloss-core-list'                   -> (TERM ...)
;;   `gloss-core-find-buffer-position' TERM -> marker
;;
;; Entry plist shape:
;;   (:term "anaphora"
;;    :body "Reference to..."
;;    :source wiktionary
;;    :added "2026-04-28"
;;    :marker #<marker at N in gloss.org>)
;;
;; The cache is loaded lazily on the first lookup of the session and
;; refreshed automatically when `gloss-file's mtime advances past the
;; last load time (catching out-of-band edits — other Emacs sessions,
;; git pull, hand edits, sed).  A parse failure during reload preserves
;; the existing cache and surfaces a one-line message; the next lookup
;; will retry.

;;; Code:

(require 'org)
(require 'subr-x)

(defgroup gloss nil
  "Personal glossary with online-sourced definitions."
  :group 'tools
  :prefix "gloss-")

(defcustom gloss-file
  (expand-file-name "gloss.org" (or (bound-and-true-p org-directory)
                                    user-emacs-directory))
  "Path to the glossary org file."
  :type 'file
  :group 'gloss)

(defcustom gloss-debug nil
  "When non-nil, write diagnostic events to *gloss-debug*."
  :type 'boolean
  :group 'gloss)

(defvar gloss-core--cache nil
  "Hash table mapping TERM (string) to entry plist, or nil if cold.")

(defvar gloss-core--cache-mtime nil
  "Mtime of `gloss-file' at last successful cache load, or nil.")

(defun gloss-core--cache-reset ()
  "Reset the in-memory cache.  Used by tests and `gloss-reload'."
  (setq gloss-core--cache nil
        gloss-core--cache-mtime nil))

(defun gloss-core--extract-body ()
  "Extract the body text of the org entry at point.
Point should be on the heading line.  Skips the heading itself, any
planning line, and the properties drawer.  Trims trailing whitespace."
  (save-excursion
    (org-back-to-heading t)
    (forward-line 1)
    (when (looking-at-p "^[ \t]*\\(?:DEADLINE\\|SCHEDULED\\|CLOSED\\):")
      (forward-line 1))
    (when (looking-at-p "^[ \t]*:PROPERTIES:")
      (re-search-forward "^[ \t]*:END:[ \t]*$" nil t)
      (forward-line 1))
    (let ((start (point))
          (end (save-excursion
                 (if (re-search-forward "^\\* " nil t)
                     (line-beginning-position)
                   (point-max)))))
      (string-trim (buffer-substring-no-properties start end)))))

(defun gloss-core--parse-file-into-cache ()
  "Read `gloss-file' and return a fresh cache populated from its entries.
Each entry plist has :term, :body, :source, :added, :marker."
  (let ((cache (make-hash-table :test 'equal))
        (buf (find-file-noselect gloss-file)))
    (with-current-buffer buf
      ;; Pick up out-of-band changes (other Emacs sessions, git pull,
      ;; manual edits, sed) before parsing.
      (unless (verify-visited-file-modtime buf)
        (revert-buffer t t t))
      (unless (derived-mode-p 'org-mode)
        (let ((org-mode-hook nil))
          (org-mode)))
      (save-excursion
        (goto-char (point-min))
        (org-map-entries
         (lambda ()
           (when (= 1 (org-current-level))
             (let* ((term (substring-no-properties
                           (org-get-heading t t t t)))
                    (heading-marker (point-marker))
                    (source (org-entry-get nil "SOURCE"))
                    (added (org-entry-get nil "ADDED"))
                    (body (gloss-core--extract-body)))
               (puthash term
                        (list :term term
                              :body body
                              :source (and source (intern source))
                              :added added
                              :marker heading-marker)
                        cache)))))))
    cache))

(defun gloss-core--cache-ensure ()
  "Ensure the cache reflects current `gloss-file' contents.
On parse failure, preserve the existing cache and surface a message."
  (cond
   ((not (file-exists-p gloss-file))
    (gloss-core--cache-reset))
   (t
    (let ((mtime (file-attribute-modification-time
                  (file-attributes gloss-file))))
      (when (or (null gloss-core--cache)
                (null gloss-core--cache-mtime)
                (time-less-p gloss-core--cache-mtime mtime))
        (condition-case err
            (let ((new-cache (gloss-core--parse-file-into-cache)))
              (setq gloss-core--cache new-cache
                    gloss-core--cache-mtime mtime))
          (error
           (message "gloss: glossary file appears corrupt (%s); cache not refreshed"
                    (error-message-string err)))))))))

(defun gloss-core--cache-ensure-or-init ()
  "Ensure the cache is loaded.  Create `gloss-file' if missing."
  (unless (file-exists-p gloss-file)
    (let ((dir (file-name-directory gloss-file)))
      (when (and dir (not (file-exists-p dir)))
        (make-directory dir t)))
    (with-temp-file gloss-file
      (insert "#+TITLE: Glossary\n#+STARTUP: showall\n\n")))
  (gloss-core--cache-ensure)
  (unless gloss-core--cache
    (setq gloss-core--cache (make-hash-table :test 'equal)
          gloss-core--cache-mtime (file-attribute-modification-time
                                   (file-attributes gloss-file)))))

(defun gloss-core--find-insertion-point (term)
  "Return the buffer position where TERM should be inserted alphabetically.
Compares case-insensitively against existing top-level headings.  Returns
`point-max' if all existing headings sort before TERM."
  (save-excursion
    (goto-char (point-min))
    (let ((target-down (downcase term))
          (insert-point nil))
      (while (and (not insert-point)
                  (re-search-forward "^\\* \\(.*\\)$" nil t))
        (when (string-greaterp (downcase (match-string-no-properties 1))
                               target-down)
          (setq insert-point (match-beginning 0))))
      (or insert-point (point-max)))))

(defun gloss-core--format-entry (term body source added)
  "Return the org-formatted text for an entry.  Always ends with a blank line."
  (format "* %s\n:PROPERTIES:\n:SOURCE:   %s\n:ADDED:    %s\n:END:\n%s\n\n"
          term
          (if source (symbol-name source) "manual")
          added
          body))

(defun gloss-core--insert-entry (term body source)
  "Insert a new entry into `gloss-file' at the alphabetical position.
Return the entry plist."
  (let ((added (format-time-string "%Y-%m-%d"))
        (buf (find-file-noselect gloss-file)))
    (with-current-buffer buf
      (save-excursion
        (goto-char (gloss-core--find-insertion-point term))
        (insert (gloss-core--format-entry term body source added)))
      (save-buffer))
    (gloss-core--cache-reset)
    (gloss-core--cache-ensure)
    (gethash term gloss-core--cache)))

(defun gloss-core--goto-heading (term)
  "Move point in the current buffer to the start of TERM's heading line."
  (goto-char (point-min))
  (unless (re-search-forward (format "^\\* %s$" (regexp-quote term)) nil t)
    (error "gloss-core: term %S not found in glossary" term))
  (beginning-of-line))

(defun gloss-core--delete-current-entry ()
  "Delete the org entry starting at point through the next heading or EOF.
Point should be on the heading line."
  (let ((start (point))
        (end (save-excursion
               (forward-line 1)
               (if (re-search-forward "^\\* " nil t)
                   (line-beginning-position)
                 (point-max)))))
    (delete-region start end)))

(defun gloss-core--replace-entry (term body source)
  "Replace TERM's existing entry with new BODY and SOURCE.  Updates ADDED to today."
  (let ((added (format-time-string "%Y-%m-%d"))
        (buf (find-file-noselect gloss-file)))
    (with-current-buffer buf
      (save-excursion
        (gloss-core--goto-heading term)
        (gloss-core--delete-current-entry)
        (goto-char (gloss-core--find-insertion-point term))
        (insert (gloss-core--format-entry term body source added)))
      (save-buffer))
    (gloss-core--cache-reset)
    (gloss-core--cache-ensure)
    (gethash term gloss-core--cache)))

(defun gloss-core--append-entry-body (term additional-body _source)
  "Append ADDITIONAL-BODY to TERM's existing entry, separated by a blank line.
The original SOURCE is preserved (the new SOURCE arg is ignored)."
  (let* ((existing (gethash term gloss-core--cache))
         (combined-body (concat (plist-get existing :body)
                                "\n\n"
                                additional-body))
         (combined-source (plist-get existing :source)))
    (gloss-core--replace-entry term combined-body combined-source)))

(defun gloss-core--prompt-collision (term)
  "Prompt the user about a save collision on TERM.
Return one of \\='replace, \\='append, \\='cancel."
  (let ((choice (completing-read
                 (format "Term %S already exists. Action: " term)
                 '("Replace" "Append" "Cancel")
                 nil t nil nil "Cancel")))
    (pcase choice
      ("Replace" 'replace)
      ("Append" 'append)
      (_ 'cancel))))

;;;; Public API

(defun gloss-core-lookup (term)
  "Look up TERM in the glossary.  Return the entry plist or nil."
  (when (and term (stringp term) (not (string-empty-p term)))
    (gloss-core--cache-ensure)
    (and gloss-core--cache (gethash term gloss-core--cache))))

(defun gloss-core-save (term body source &optional collision-action)
  "Save TERM with BODY and SOURCE to the glossary.
COLLISION-ACTION is one of \\='replace, \\='append, \\='cancel.  If TERM
exists and COLLISION-ACTION is nil, prompt the user.  Return the saved
entry plist, or nil on cancel."
  (unless (and term (stringp term)
               (not (string-empty-p (string-trim (or term "")))))
    (user-error "gloss-core-save: term must be a non-empty string"))
  (unless (and body (stringp body)
               (not (string-empty-p (string-trim (or body "")))))
    (user-error "gloss-core-save: body must be a non-empty string"))
  (gloss-core--cache-ensure-or-init)
  (let* ((existing (gethash term gloss-core--cache))
         (action (or collision-action
                     (and existing (gloss-core--prompt-collision term)))))
    (cond
     ((null existing)
      (gloss-core--insert-entry term body source))
     ((eq action 'replace)
      (gloss-core--replace-entry term body source))
     ((eq action 'append)
      (gloss-core--append-entry-body term body source))
     ((eq action 'cancel) nil))))

(defun gloss-core-list ()
  "Return all glossary terms in case-insensitive alphabetical order, or nil."
  (gloss-core--cache-ensure)
  (when gloss-core--cache
    (let (terms)
      (maphash (lambda (k _v) (push k terms)) gloss-core--cache)
      (when terms
        (sort terms (lambda (a b)
                      (string-lessp (downcase a) (downcase b))))))))

(defun gloss-core-find-buffer-position (term)
  "Return a marker at TERM's heading position in `gloss-file', or nil if missing."
  (when-let* ((entry (gloss-core-lookup term))
              (marker (plist-get entry :marker)))
    (if (and (marker-buffer marker)
             (buffer-live-p (marker-buffer marker)))
        marker
      ;; Buffer was killed; force a reload and try once more.
      (gloss-core--cache-reset)
      (when-let ((entry2 (gloss-core-lookup term)))
        (plist-get entry2 :marker)))))

(provide 'gloss-core)
;;; gloss-core.el ends here
