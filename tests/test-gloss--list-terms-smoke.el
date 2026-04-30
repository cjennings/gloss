;;; test-gloss--list-terms-smoke.el --- Smoke tests for gloss-list-terms -*- lexical-binding: t -*-

;; SPDX-License-Identifier: GPL-3.0-or-later

;;; Commentary:
;; Smoke tests for `gloss-list-terms'.  Uses `completing-read' on the
;; cached term list and dispatches to the lookup flow with the chosen
;; term.

;;; Code:

(require 'ert)
(require 'cl-lib)
(require 'gloss)
(require 'testutil-gloss)

(ert-deftest test-gloss-list-terms-empty-glossary-raises ()
  "Error: list-terms on an empty glossary raises `user-error' mentioning empty."
  (gloss-test--with-temp-glossary "#+TITLE: Glossary\n"
    (let ((err (should-error (gloss-list-terms) :type 'user-error)))
      (should (string-match-p "empty" (error-message-string err))))))

(ert-deftest test-gloss-list-terms-dispatches-chosen-to-lookup ()
  "Smoke: list-terms passes the chosen term to `gloss--lookup-flow'."
  (gloss-test--with-temp-glossary gloss-test--sample-content
    (let (looked-up)
      (cl-letf (((symbol-function 'completing-read)
                 (lambda (&rest _) "anaphora"))
                ((symbol-function 'gloss--lookup-flow)
                 (lambda (term &optional _) (setq looked-up term) :show)))
        (gloss-list-terms)
        (should (equal looked-up "anaphora"))))))

(provide 'test-gloss--list-terms-smoke)
;;; test-gloss--list-terms-smoke.el ends here
