;;; gloss-drill.el --- org-drill export for gloss -*- lexical-binding: t -*-

;; Copyright (C) 2026 Craig Jennings
;; Author: Craig Jennings <c@cjennings.net>
;; SPDX-License-Identifier: GPL-3.0-or-later

;;; Commentary:

;; Spaced-repetition export for `gloss'.  Walks the glossary org file
;; via `org-element' and ensures every term entry carries a `:drill:'
;; tag and a `:DRILL_CARD_TYPE: twosided' property — `org-drill' then
;; runs unmodified against the file.
;;
;; Public API:
;;   `gloss-drill-export-all'
;;   `gloss-drill-untag-all'
;;
;; Idempotent: running export twice does not double-tag.
;; Checks `(featurep 'org-drill)' before running; raises a helpful
;; user-error if `org-drill' isn't installed.
;;
;; See `docs/design/gloss.org' for the full design.

;;; Code:

;; Implementation pending.  Track via todo.org.

(provide 'gloss-drill)
;;; gloss-drill.el ends here
