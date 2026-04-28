;;; test-gloss-core--corrupt-file-preserves-cache.el --- Tests for corrupt-file resilience -*- lexical-binding: t -*-

;; SPDX-License-Identifier: GPL-3.0-or-later

;;; Commentary:
;; Tests that a parser failure during cache reload does not destroy the
;; existing cache; previously-cached lookups still succeed and the user
;; sees an informative message.

;;; Code:

(require 'cl-lib)
(require 'ert)
(require 'gloss-core)
(require 'testutil-gloss)

(ert-deftest test-gloss-core-corrupt-file-preserves-existing-cache ()
  "Error: parser failure during reload preserves the existing cache."
  (gloss-test--with-temp-glossary gloss-test--sample-content
    ;; Prime cache.
    (should (gloss-core-lookup "anaphora"))
    ;; Force mtime change to trigger a reload attempt.
    (set-file-times gloss-file (time-add (current-time) 5))
    ;; Mock the parse helper to fail.
    (cl-letf (((symbol-function 'gloss-core--parse-file-into-cache)
               (lambda () (error "simulated parse failure"))))
      (let ((inhibit-message t))
        ;; Lookup must not propagate the error; cached entry remains findable.
        (should (gloss-core-lookup "anaphora"))))))

(provide 'test-gloss-core--corrupt-file-preserves-cache)
;;; test-gloss-core--corrupt-file-preserves-cache.el ends here
