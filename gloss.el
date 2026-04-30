;;; gloss.el --- Glossary lookup with online-sourced selection -*- lexical-binding: t -*-

;; Copyright (C) 2026 Craig Jennings

;; Author: Craig Jennings <c@cjennings.net>
;; Created: 28 Apr 2026
;; Version: 0.1.0
;; Package-Requires: ((emacs "27.1") (org "9.3"))
;; Keywords: glossary dictionary terms vocabulary
;; URL: https://github.com/cjennings/gloss

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; gloss — Glossary Lookup with Online-Sourced Selection.
;;
;; A personal Emacs glossary on `C-h g'.  Looks up terms in a single
;; git-tracked org file.  On a local miss, fetches candidate
;; definitions from Wiktionary and prompts the user to pick one to
;; save with provenance.  The same org file feeds `org-drill' for
;; spaced-repetition study.
;;
;; Quick start:
;;   (require 'gloss)
;;   (gloss-install-prefix)            ; binds C-h g
;;
;; Default keys under C-h g:
;;   g  gloss-lookup           lookup term (default: word at point)
;;   a  gloss-add              add term manually
;;   e  gloss-edit             edit term in source file
;;   o  gloss-fetch-online     force online fetch
;;   D  gloss-drill-export     tag entries for org-drill
;;   l  gloss-list-terms       browse glossary
;;   s  gloss-stats            summary
;;   r  gloss-reload           refresh cache
;;   d  gloss-toggle-debug     toggle *gloss-debug*
;;
;; See `docs/design/gloss.org' for the full design.

;;; Code:

(require 'gloss-core)
(require 'gloss-fetch)
(require 'gloss-display)
(require 'gloss-drill)

;; The `gloss' defgroup, `gloss-file', and `gloss-debug' defcustoms live in
;; `gloss-core' so they are defined whenever the data layer is required —
;; tests load `gloss-core' directly without pulling in the orchestration here.

(defvar gloss-prefix-map (make-sparse-keymap)
  "Keymap for `gloss' commands.  Default prefix: C-h g.")

(defun gloss--orchestrate-fetch-result (result)
  "Return decision symbol for RESULT plist from `gloss-fetch-definitions'.
Decision values:
  :auto-save      — exactly one definition.
  :pick           — two or more definitions.
  :error-no-defs  — no defs and only :no-defs sources (or all empty).
  :error-failed   — no defs and only :failed sources.
  :error-mixed    — no defs but BOTH :no-defs and :failed populated."
  (let ((defs (plist-get result :defs))
        (no-defs (plist-get result :no-defs))
        (failed (plist-get result :failed)))
    (cond
     ((= (length defs) 1) :auto-save)
     ((> (length defs) 1) :pick)
     ((and no-defs failed) :error-mixed)
     (failed :error-failed)
     (t :error-no-defs))))

(defun gloss--lookup-flow (term &optional force-fetch)
  "Look up TERM in the glossary.  Fetch online on miss.
If FORCE-FETCH is non-nil, bypass the cache and fetch unconditionally.
Returns a symbol naming the action taken: :show, :auto-save, :pick,
:error-no-defs, :error-failed, or :error-mixed."
  (let ((cached (and (not force-fetch) (gloss-core-lookup term))))
    (if cached
        (progn
          (gloss-display-show-entry term (plist-get cached :body))
          :show)
      (let* ((result (gloss-fetch-definitions term))
             (action (gloss--orchestrate-fetch-result result)))
        (pcase action
          (:auto-save
           (let* ((def (car (plist-get result :defs)))
                  (text (plist-get def :text))
                  (source (plist-get def :source)))
             (gloss-core-save term text source 'replace)
             (gloss-display-show-entry term text)))
          (:pick
           (when-let* ((chosen (gloss-display-pick-definition
                                term (plist-get result :defs)))
                       (text (plist-get chosen :text))
                       (source (plist-get chosen :source)))
             (gloss-core-save term text source 'replace)
             (gloss-display-show-entry term text)))
          (:error-no-defs
           (message "gloss: no definition found for %s" term))
          (:error-failed
           (message "gloss: couldn't reach any source for %s" term))
          (:error-mixed
           (message "gloss: no definition in some sources, others unreachable for %s"
                    term)))
        action))))

;;;###autoload
(defun gloss-lookup (term)
  "Look up TERM in the glossary; fetch online on miss."
  (interactive (list (read-string "Glossary lookup: " (thing-at-point 'word t))))
  (gloss--lookup-flow term))

(defvar gloss-add-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-c") #'gloss-add-finish)
    (define-key map (kbd "C-c C-k") #'gloss-add-abort)
    map)
  "Keymap for `gloss-add-mode'.")

(define-derived-mode gloss-add-mode text-mode "GlossAdd"
  "Major mode for entering a glossary entry's body.

\\{gloss-add-mode-map}"
  (setq header-line-format
        (substitute-command-keys
         "Type the body.  \\[gloss-add-finish] saves; \\[gloss-add-abort] cancels.")))

(defvar-local gloss-add--term nil
  "Term being added in this `gloss-add-mode' buffer.")

(defvar-local gloss-add--body-start nil
  "Marker pointing at the first editable position in `gloss-add-mode'.
Everything before this marker (the rendered header — term + underline
+ blank line) is text-property read-only.")

(defun gloss--add-finish-internal (term body)
  "Validate and save TERM with BODY as a manual entry.
Returns the saved entry plist, or nil if `gloss-core-save' returned nil
(e.g. user cancelled at the collision prompt).  Trims surrounding
whitespace from BODY before saving."
  (when (string-empty-p (string-trim (or term "")))
    (user-error "gloss-add: term cannot be empty"))
  (let ((trimmed (string-trim (or body ""))))
    (when (string-empty-p trimmed)
      (user-error "gloss-add: body cannot be empty"))
    (gloss-core-save term trimmed 'manual)))

(defun gloss--add-cleanup (buf win)
  "Kill BUF and close WIN if it's still live.
Used by both `gloss-add-finish' and `gloss-add-abort' so the layout
returns to its pre-add state."
  (let ((kill-buffer-query-functions nil))
    (kill-buffer buf))
  (when (window-live-p win)
    (delete-window win)))

(defun gloss-add-finish ()
  "Save the current `gloss-add-mode' buffer's body for the recorded term.
Body is everything after the read-only header.  After saving, kills the
add buffer and closes the side window — the user is returned to the
pre-add window layout, with a confirmation message in the echo area."
  (interactive)
  (unless gloss-add--term
    (user-error "gloss-add: no term recorded for this buffer"))
  (let* ((term gloss-add--term)
         (body (buffer-substring-no-properties
                (or gloss-add--body-start (point-min))
                (point-max)))
         (buf (current-buffer))
         (win (get-buffer-window (current-buffer)))
         (saved (gloss--add-finish-internal term body)))
    (gloss--add-cleanup buf win)
    (when saved
      (message "gloss-add: saved %s" term))))

(defun gloss-add-abort ()
  "Abandon the current `gloss-add-mode' buffer without saving.
Kills the add buffer and closes the side window."
  (interactive)
  (gloss--add-cleanup (current-buffer)
                      (get-buffer-window (current-buffer))))

;;;###autoload
(defun gloss-add (term)
  "Add TERM to the glossary manually.
Opens a side-window buffer with TERM rendered as a read-only header
and an editable body region beneath it.  \\[gloss-add-finish] saves
and shows the saved entry; \\[gloss-add-abort] cancels and closes
the side window."
  (interactive (list (read-string "Add term: ")))
  (when (string-empty-p (string-trim (or term "")))
    (user-error "gloss-add: term cannot be empty"))
  (let ((buf (get-buffer-create (format "*gloss-add: %s*" term))))
    (with-current-buffer buf
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert (gloss-display--render-entry term ""))
        (let ((body-start (point-max-marker)))
          (set-marker-insertion-type body-start nil)
          (add-text-properties (point-min) body-start
                               '(read-only "Header is not editable"
                                 front-sticky t
                                 rear-nonsticky t))
          (gloss-add-mode)
          (setq gloss-add--term term)
          (setq gloss-add--body-start body-start)))
      (goto-char (point-max)))
    (pop-to-buffer buf gloss-display--side-window-alist)))

(defun gloss--after-save-refresh-cache ()
  "Buffer-local `after-save-hook' that clears the gloss cache."
  (gloss-core--cache-reset))

;;;###autoload
(defun gloss-edit (term)
  "Open the source org file at TERM's heading.
Installs a buffer-local `after-save-hook' that refreshes the gloss
cache when the file is saved."
  (interactive (list (read-string "Edit term: " (thing-at-point 'word t))))
  (let ((marker (gloss-core-find-buffer-position term)))
    (unless marker
      (user-error "gloss: term not in glossary: %s" term))
    (switch-to-buffer (marker-buffer marker))
    (goto-char marker)
    (when (derived-mode-p 'org-mode)
      (if (fboundp 'org-fold-show-entry)
          (org-fold-show-entry)
        (with-no-warnings (org-show-entry))))
    (add-hook 'after-save-hook #'gloss--after-save-refresh-cache nil t)
    marker))

;;;###autoload
(defun gloss-fetch-online (term)
  "Force online fetch for TERM, bypassing the cache."
  (interactive (list (read-string "Fetch online: " (thing-at-point 'word t))))
  (gloss--lookup-flow term t))

;;;###autoload
(defun gloss-drill-export ()
  "Tag every entry as :drill: for `org-drill'."
  (interactive)
  (gloss-drill-export-all))

;;;###autoload
(defun gloss-list-terms ()
  "Browse glossary terms via `completing-read' and show the chosen one."
  (interactive)
  (let ((terms (gloss-core-list)))
    (unless terms
      (user-error "gloss: glossary is empty"))
    (let ((chosen (completing-read "Term: " terms nil t)))
      (when chosen
        (gloss--lookup-flow chosen)))))

(defun gloss--count-drill-tagged ()
  "Return the number of top-level entries in `gloss-file' tagged :drill:.
Returns 0 if `gloss-file' does not exist."
  (if (and gloss-file (file-exists-p gloss-file))
      (with-current-buffer (find-file-noselect gloss-file)
        (unless (verify-visited-file-modtime (current-buffer))
          (revert-buffer t t t))
        (unless (derived-mode-p 'org-mode)
          (let ((org-mode-hook nil)) (org-mode)))
        (let ((count 0))
          (org-map-entries
           (lambda ()
             (when (and (= 1 (org-current-level))
                        (member "drill" (org-get-tags nil t)))
               (setq count (1+ count)))))
          count))
    0))

(defun gloss--stats-text ()
  "Return a multi-line string summarizing glossary state."
  (gloss-core--cache-ensure-or-init)
  (let* ((terms (gloss-core-list))
         (total (length terms))
         (by-source (make-hash-table :test 'equal))
         (drill-count (gloss--count-drill-tagged))
         (file-size (when (and gloss-file (file-exists-p gloss-file))
                      (file-attribute-size (file-attributes gloss-file))))
         (mtime gloss-core--cache-mtime))
    (dolist (term terms)
      (let* ((entry (gloss-core-lookup term))
             (source (or (plist-get entry :source) 'unknown)))
        (puthash source (1+ (or (gethash source by-source) 0)) by-source)))
    (let (source-pairs)
      (maphash (lambda (k v) (push (cons k v) source-pairs)) by-source)
      (format "Glossary stats:
  Total terms:     %d
  By source:       %s
  Drill-tagged:    %d
  File size:       %s bytes
  Cache mtime:     %s
"
              total
              (if source-pairs
                  (mapconcat (lambda (pair)
                               (format "%s=%d" (car pair) (cdr pair)))
                             source-pairs ", ")
                "(none)")
              drill-count
              (or file-size 0)
              (if mtime
                  (format-time-string "%Y-%m-%d %H:%M:%S" mtime)
                "never")))))

;;;###autoload
(defun gloss-stats ()
  "Show glossary statistics in a side buffer."
  (interactive)
  (let ((buf (get-buffer-create "*gloss-stats*")))
    (with-current-buffer buf
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert (gloss--stats-text)))
      (special-mode)
      (goto-char (point-min)))
    (display-buffer buf)
    buf))

;;;###autoload
(defun gloss-reload ()
  "Force reload of the glossary cache from disk."
  (interactive)
  (gloss-core--cache-reset)
  (gloss-core--cache-ensure)
  (message "gloss: cache reloaded"))

;;;###autoload
(defun gloss-toggle-debug ()
  "Toggle the *gloss-debug* log on or off."
  (interactive)
  (setq gloss-debug (not gloss-debug))
  (message "gloss-debug %s" (if gloss-debug "enabled" "disabled")))

(define-key gloss-prefix-map (kbd "g") #'gloss-lookup)
(define-key gloss-prefix-map (kbd "a") #'gloss-add)
(define-key gloss-prefix-map (kbd "e") #'gloss-edit)
(define-key gloss-prefix-map (kbd "o") #'gloss-fetch-online)
(define-key gloss-prefix-map (kbd "D") #'gloss-drill-export)
(define-key gloss-prefix-map (kbd "l") #'gloss-list-terms)
(define-key gloss-prefix-map (kbd "s") #'gloss-stats)
(define-key gloss-prefix-map (kbd "r") #'gloss-reload)
(define-key gloss-prefix-map (kbd "d") #'gloss-toggle-debug)

;;;###autoload
(defun gloss-install-prefix (&optional key)
  "Install `gloss-prefix-map' on KEY (default \\`g' under `help-map', i.e. C-h g)."
  (interactive)
  (define-key help-map (or key (kbd "g")) gloss-prefix-map))

(provide 'gloss)
;;; gloss.el ends here
