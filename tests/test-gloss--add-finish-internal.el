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

(ert-deftest test-gloss-add-finish-internal-saves-and-shows ()
  "Normal: a fresh term + body is saved with source `manual' and shown."
  (gloss-test--with-missing-glossary
    (let (shown)
      (cl-letf (((symbol-function 'gloss-display-show-entry)
                 (lambda (term body) (setq shown (list term body)))))
        (gloss--add-finish-internal "newterm" "A new definition.")
        (let ((saved (gloss-core-lookup "newterm")))
          (should saved)
          (should (equal (plist-get saved :body) "A new definition."))
          (should (eq (plist-get saved :source) 'manual)))
        (should (equal shown '("newterm" "A new definition.")))))))

(ert-deftest test-gloss-add-finish-internal-empty-term-raises ()
  "Error: empty TERM raises `user-error'."
  (gloss-test--with-missing-glossary
    (cl-letf (((symbol-function 'gloss-display-show-entry)
               (lambda (_ _) nil)))
      (should-error (gloss--add-finish-internal "" "Body.")
                    :type 'user-error)
      (should-error (gloss--add-finish-internal "   " "Body.")
                    :type 'user-error))))

(ert-deftest test-gloss-add-finish-internal-empty-body-raises ()
  "Error: empty BODY raises `user-error'."
  (gloss-test--with-missing-glossary
    (cl-letf (((symbol-function 'gloss-display-show-entry)
               (lambda (_ _) nil)))
      (should-error (gloss--add-finish-internal "term" "")
                    :type 'user-error)
      (should-error (gloss--add-finish-internal "term" "   \n  ")
                    :type 'user-error))))

(ert-deftest test-gloss-add-finish-internal-trims-body-whitespace ()
  "Boundary: leading/trailing whitespace in BODY is trimmed before save."
  (gloss-test--with-missing-glossary
    (cl-letf (((symbol-function 'gloss-display-show-entry)
               (lambda (_ _) nil)))
      (gloss--add-finish-internal "term" "  Body content.\n\n")
      (let ((saved (gloss-core-lookup "term")))
        (should (equal (plist-get saved :body) "Body content."))))))

(provide 'test-gloss--add-finish-internal)
;;; test-gloss--add-finish-internal.el ends here
