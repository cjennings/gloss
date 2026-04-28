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
;; Pure helper (full N/B/E test coverage):
;;   `gloss-display--format-candidate' PLIST -> "[source] text..."
;;
;; `gloss-mode' is derived from `special-mode': `q' quits the window.
;;
;; See `docs/design/gloss.org' for the full design.

;;; Code:

;; Implementation pending.  Track via todo.org.

(provide 'gloss-display)
;;; gloss-display.el ends here
