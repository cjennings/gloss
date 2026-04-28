;;; test-gloss-core--alphabetical-insert.el --- Tests for alphabetical insert -*- lexical-binding: t -*-

;; SPDX-License-Identifier: GPL-3.0-or-later

;;; Commentary:
;; Tests that `gloss-core-save' inserts new entries at the correct
;; alphabetical position (case-insensitive ordering).

;;; Code:

(require 'ert)
(require 'gloss-core)
(require 'testutil-gloss)

(ert-deftest test-gloss-core-alphabetical-insert-correct-position ()
  "Normal: terms saved out of order land in alphabetical order."
  (gloss-test--with-temp-glossary "#+TITLE: Glossary\n"
    (gloss-core-save "Charlie" "Third." 'manual)
    (gloss-core-save "Alpha" "First." 'manual)
    (gloss-core-save "Bravo" "Second." 'manual)
    (should (equal (gloss-core-list) '("Alpha" "Bravo" "Charlie")))))

(ert-deftest test-gloss-core-alphabetical-insert-case-insensitive-ordering ()
  "Boundary: ordering uses a case-insensitive compare."
  (gloss-test--with-temp-glossary "#+TITLE: Glossary\n"
    (gloss-core-save "banana" "Fruit." 'manual)
    (gloss-core-save "Apple" "Also fruit." 'manual)
    (should (equal (gloss-core-list) '("Apple" "banana")))))

(ert-deftest test-gloss-core-alphabetical-insert-on-disk-matches-list ()
  "Boundary: the on-disk file order matches the list order."
  (gloss-test--with-temp-glossary "#+TITLE: Glossary\n"
    (gloss-core-save "zebra" "Last." 'manual)
    (gloss-core-save "alpha" "First." 'manual)
    (let ((file-content (with-temp-buffer
                          (insert-file-contents gloss-file)
                          (buffer-string))))
      (should (< (string-match "^\\* alpha" file-content)
                 (string-match "^\\* zebra" file-content))))))

(provide 'test-gloss-core--alphabetical-insert)
;;; test-gloss-core--alphabetical-insert.el ends here
