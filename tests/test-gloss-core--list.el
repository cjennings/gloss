;;; test-gloss-core--list.el --- Tests for gloss-core-list -*- lexical-binding: t -*-

;; SPDX-License-Identifier: GPL-3.0-or-later

;;; Commentary:
;; Tests for `gloss-core-list' covering Normal/Boundary/Error cases.

;;; Code:

(require 'ert)
(require 'gloss-core)
(require 'testutil-gloss)

(ert-deftest test-gloss-core-list-returns-all-terms-alphabetically ()
  "Normal: list returns all terms in case-insensitive alphabetical order."
  (gloss-test--with-temp-glossary gloss-test--sample-content
    (should (equal (gloss-core-list) '("anaphora" "SBIR")))))

(ert-deftest test-gloss-core-list-empty-glossary-returns-nil ()
  "Boundary: list against an empty file returns nil."
  (gloss-test--with-temp-glossary "#+TITLE: Glossary\n"
    (should-not (gloss-core-list))))

(ert-deftest test-gloss-core-list-missing-file-returns-nil ()
  "Error: list before any save returns nil (file does not exist)."
  (gloss-test--with-missing-glossary
    (should-not (gloss-core-list))))

(provide 'test-gloss-core--list)
;;; test-gloss-core--list.el ends here
