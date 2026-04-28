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
;; See `docs/design/gloss.org' for the full design.

;;; Code:

;; Implementation pending.  Track via todo.org.

(provide 'gloss-core)
;;; gloss-core.el ends here
