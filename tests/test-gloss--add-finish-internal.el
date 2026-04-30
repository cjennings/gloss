;;; test-gloss--add-finish-internal.el --- Tests for gloss--add-finish-internal -*- lexical-binding: t -*-

;; SPDX-License-Identifier: GPL-3.0-or-later

;;; Commentary:
;; Tests for the pure save-side helper `gloss--add-finish-internal'.
;; The interactive temp-buffer UI is exercised separately at the smoke
;; level; this file covers the term/body validation and the persistence
;; side effect via a real temp glossary.

;;; Code:

(require 'ert)
(require 'cl-lib)
(require 'gloss)
(require 'testutil-gloss)

(ert-deftest test-gloss-add-finish-internal-saves-with-manual-source ()
  "Normal: a fresh term + body is saved with source `manual'.
Display is the caller's responsibility, not this function's."
  (gloss-test--with-missing-glossary
    (let ((saved (gloss--add-finish-internal "newterm" "A new definition.")))
      (should saved)
      (should (equal (plist-get saved :body) "A new definition."))
      (should (eq (plist-get saved :source) 'manual))
      (should (equal (gloss-core-lookup "newterm") saved)))))

(ert-deftest test-gloss-add-finish-internal-empty-term-raises ()
  "Error: empty TERM raises `user-error'."
  (gloss-test--with-missing-glossary
    (should-error (gloss--add-finish-internal "" "Body.")
                  :type 'user-error)
    (should-error (gloss--add-finish-internal "   " "Body.")
                  :type 'user-error)))

(ert-deftest test-gloss-add-finish-internal-empty-body-raises ()
  "Error: empty BODY raises `user-error'."
  (gloss-test--with-missing-glossary
    (should-error (gloss--add-finish-internal "term" "")
                  :type 'user-error)
    (should-error (gloss--add-finish-internal "term" "   \n  ")
                  :type 'user-error)))

(ert-deftest test-gloss-add-finish-internal-trims-body-whitespace ()
  "Boundary: leading/trailing whitespace in BODY is trimmed before save."
  (gloss-test--with-missing-glossary
    (gloss--add-finish-internal "term" "  Body content.\n\n")
    (let ((saved (gloss-core-lookup "term")))
      (should (equal (plist-get saved :body) "Body content.")))))

(provide 'test-gloss--add-finish-internal)
;;; test-gloss--add-finish-internal.el ends here
