;;; test-gloss--stats-text.el --- Tests for gloss--stats-text -*- lexical-binding: t -*-

;; SPDX-License-Identifier: GPL-3.0-or-later

;;; Commentary:
;; Tests for the pure helper `gloss--stats-text' which formats a
;; multi-line stats summary. Drill-tagged count walks the org file via
;; the same primitives as `gloss-drill', so this also indirectly
;; exercises that integration.

;;; Code:

(require 'ert)
(require 'gloss)
(require 'testutil-gloss)

(ert-deftest test-gloss-stats-text-empty-glossary-reports-zero ()
  "Boundary: empty glossary file reports zero terms."
  (gloss-test--with-temp-glossary "#+TITLE: Glossary\n#+STARTUP: showall\n"
    (let ((text (gloss--stats-text)))
      (should (string-match-p "Total terms: +0" text))
      (should (string-match-p "Drill-tagged: +0" text)))))

(ert-deftest test-gloss-stats-text-populated-glossary-counts-terms ()
  "Normal: populated glossary reports total terms and source breakdown."
  (gloss-test--with-temp-glossary gloss-test--sample-content
    (let ((text (gloss--stats-text)))
      (should (string-match-p "Total terms: +2" text))
      (should (string-match-p "wiktionary=2" text))
      (should (string-match-p "File size:" text))
      (should (string-match-p "Cache mtime:" text)))))

(ert-deftest test-gloss-stats-text-missing-file-reports-zero-and-never ()
  "Error: missing glossary file reports zero terms and \"never\" mtime."
  (gloss-test--with-missing-glossary
    (let ((text (gloss--stats-text)))
      (should (string-match-p "Total terms: +0" text)))))

(provide 'test-gloss--stats-text)
;;; test-gloss--stats-text.el ends here
