;;; test-gloss--reload-smoke.el --- Smoke test for gloss-reload -*- lexical-binding: t -*-

;; SPDX-License-Identifier: GPL-3.0-or-later

;;; Commentary:
;; Smoke test for `gloss-reload'.  Clears the in-memory cache, then the
;; next lookup repopulates from disk (handled by core's mtime path).

;;; Code:

(require 'ert)
(require 'gloss)
(require 'testutil-gloss)

(ert-deftest test-gloss-reload-resets-and-repopulates-cache ()
  "Smoke: reload clears the cache and the next lookup re-reads from disk."
  (gloss-test--with-temp-glossary gloss-test--sample-content
    (gloss-core-lookup "anaphora")
    (should gloss-core--cache)
    (gloss-reload)
    (should (gloss-core-lookup "anaphora"))))

(provide 'test-gloss--reload-smoke)
;;; test-gloss--reload-smoke.el ends here
