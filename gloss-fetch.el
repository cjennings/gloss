;;; gloss-fetch.el --- Online definition fetcher for gloss -*- lexical-binding: t -*-

;; Copyright (C) 2026 Craig Jennings
;; Author: Craig Jennings <c@cjennings.net>
;; SPDX-License-Identifier: GPL-3.0-or-later

;;; Commentary:

;; Network layer for `gloss'.  Walks a registry of online sources
;; (`gloss-fetch--sources') in the order specified by the user-facing
;; `gloss-fetch-sources' defcustom; aggregates per-source results into
;; a single response shape.
;;
;; Public API:
;;   `gloss-fetch-definitions' TERM
;;     -> (:ok DEFS)                                ; any source returned >=1 def
;;        | (:empty :no-defs (SYM ...) :failed (SYM ...))
;;
;; Each definition is a plist:
;;   (:source SYM :text "Reference to ...")
;;
;; Per-source internal status taxonomy:
;;   :ok :defs (...)   :no-defs   :unreachable   :server-error   :rate-limited
;;
;; libxml is treated as a precondition (probed once at first fetch);
;; absent libxml disables online fetch package-wide for the session.
;;
;; See `docs/design/gloss.org' for the full design.

;;; Code:

;; Implementation pending.  Track via todo.org.

(provide 'gloss-fetch)
;;; gloss-fetch.el ends here
