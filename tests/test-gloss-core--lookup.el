;;; test-gloss-core--lookup.el --- Tests for gloss-core-lookup -*- lexical-binding: t -*-

;; SPDX-License-Identifier: GPL-3.0-or-later

;;; Commentary:
;; Tests for `gloss-core-lookup' covering Normal/Boundary/Error cases.

;;; Code:

(require 'ert)
(require 'gloss-core)
(require 'testutil-gloss)

(ert-deftest test-gloss-core-lookup-existing-term-returns-entry ()
  "Normal: lookup of saved term returns entry plist with all fields."
  (gloss-test--with-temp-glossary gloss-test--sample-content
    (let ((entry (gloss-core-lookup "anaphora")))
      (should entry)
      (should (equal (plist-get entry :term) "anaphora"))
      (should (string-match-p "Reference to something earlier"
                              (plist-get entry :body)))
      (should (eq (plist-get entry :source) 'wiktionary))
      (should (equal (plist-get entry :added) "2026-04-28")))))

(ert-deftest test-gloss-core-lookup-includes-marker ()
  "Normal: lookup result includes a :marker field at the heading."
  (gloss-test--with-temp-glossary gloss-test--sample-content
    (let* ((entry (gloss-core-lookup "anaphora"))
           (marker (plist-get entry :marker)))
      (should (markerp marker))
      (with-current-buffer (marker-buffer marker)
        (goto-char marker)
        (should (looking-at-p "^\\* anaphora"))))))

(ert-deftest test-gloss-core-lookup-missing-term-returns-nil ()
  "Normal: lookup of unsaved term returns nil."
  (gloss-test--with-temp-glossary gloss-test--sample-content
    (should-not (gloss-core-lookup "nonexistent-term"))))

(ert-deftest test-gloss-core-lookup-empty-string-returns-nil ()
  "Boundary: lookup of empty string returns nil, not an error."
  (gloss-test--with-temp-glossary gloss-test--sample-content
    (should-not (gloss-core-lookup ""))))

(ert-deftest test-gloss-core-lookup-nil-returns-nil ()
  "Boundary: lookup of nil returns nil, not an error."
  (gloss-test--with-temp-glossary gloss-test--sample-content
    (should-not (gloss-core-lookup nil))))

(ert-deftest test-gloss-core-lookup-case-sensitive ()
  "Boundary: lookup is case-sensitive — \"Anaphora\" misses \"anaphora\"."
  (gloss-test--with-temp-glossary gloss-test--sample-content
    (should-not (gloss-core-lookup "Anaphora"))))

(ert-deftest test-gloss-core-lookup-empty-glossary-file-returns-nil ()
  "Error: lookup against empty file returns nil."
  (gloss-test--with-temp-glossary "#+TITLE: Glossary\n"
    (should-not (gloss-core-lookup "anything"))))

(ert-deftest test-gloss-core-lookup-missing-file-returns-nil ()
  "Error: lookup before any save returns nil (file does not exist)."
  (let ((gloss-file (concat temporary-file-directory "gloss-nonexistent-"
                            (number-to-string (random 100000)) ".org")))
    (unwind-protect
        (progn
          (gloss-core--cache-reset)
          (should-not (file-exists-p gloss-file))
          (should-not (gloss-core-lookup "anything")))
      (gloss-core--cache-reset)
      (when (file-exists-p gloss-file) (delete-file gloss-file)))))

(provide 'test-gloss-core--lookup)
;;; test-gloss-core--lookup.el ends here
