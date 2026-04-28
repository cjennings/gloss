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

;;;###autoload
(defun gloss-lookup (term)
  "Look up TERM in the glossary; fetch online on miss."
  (interactive (list (read-string "Glossary lookup: " (thing-at-point 'word t))))
  (ignore term)
  (user-error "gloss-lookup: not yet implemented"))

;;;###autoload
(defun gloss-add (term)
  "Add TERM to the glossary manually."
  (interactive (list (read-string "Add term: ")))
  (ignore term)
  (user-error "gloss-add: not yet implemented"))

;;;###autoload
(defun gloss-edit (term)
  "Open the source org file at TERM's heading."
  (interactive (list (read-string "Edit term: ")))
  (ignore term)
  (user-error "gloss-edit: not yet implemented"))

;;;###autoload
(defun gloss-fetch-online (term)
  "Force online fetch for TERM, bypassing the cache."
  (interactive (list (read-string "Fetch online: ")))
  (ignore term)
  (user-error "gloss-fetch-online: not yet implemented"))

;;;###autoload
(defun gloss-drill-export ()
  "Tag every entry as :drill: for `org-drill'."
  (interactive)
  (user-error "gloss-drill-export: not yet implemented"))

;;;###autoload
(defun gloss-list-terms ()
  "Browse glossary terms via `completing-read'."
  (interactive)
  (user-error "gloss-list-terms: not yet implemented"))

;;;###autoload
(defun gloss-stats ()
  "Summarize the glossary state."
  (interactive)
  (user-error "gloss-stats: not yet implemented"))

;;;###autoload
(defun gloss-reload ()
  "Force reload of the glossary cache from disk."
  (interactive)
  (user-error "gloss-reload: not yet implemented"))

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
