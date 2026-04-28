;;; test-gloss-core--find-buffer-position.el --- Tests for gloss-core-find-buffer-position -*- lexical-binding: t -*-

;; SPDX-License-Identifier: GPL-3.0-or-later

;;; Commentary:
;; Tests for `gloss-core-find-buffer-position' covering N/B/E cases.

;;; Code:

(require 'ert)
(require 'gloss-core)
(require 'testutil-gloss)

(ert-deftest test-gloss-core-find-buffer-position-existing-term-returns-marker ()
  "Normal: returns a marker pointing at the term's heading."
  (gloss-test--with-temp-glossary gloss-test--sample-content
    (let ((marker (gloss-core-find-buffer-position "anaphora")))
      (should (markerp marker))
      (with-current-buffer (marker-buffer marker)
        (goto-char marker)
        (should (looking-at-p "^\\* anaphora"))))))

(ert-deftest test-gloss-core-find-buffer-position-second-term-returns-marker ()
  "Normal: marker for second term points at its heading, not the first."
  (gloss-test--with-temp-glossary gloss-test--sample-content
    (let ((marker (gloss-core-find-buffer-position "SBIR")))
      (should (markerp marker))
      (with-current-buffer (marker-buffer marker)
        (goto-char marker)
        (should (looking-at-p "^\\* SBIR"))))))

(ert-deftest test-gloss-core-find-buffer-position-missing-term-returns-nil ()
  "Boundary: returns nil for a term not in the glossary."
  (gloss-test--with-temp-glossary gloss-test--sample-content
    (should-not (gloss-core-find-buffer-position "nonexistent"))))

(ert-deftest test-gloss-core-find-buffer-position-missing-file-returns-nil ()
  "Error: returns nil when the file does not exist."
  (gloss-test--with-missing-glossary
    (should-not (gloss-core-find-buffer-position "any"))))

(provide 'test-gloss-core--find-buffer-position)
;;; test-gloss-core--find-buffer-position.el ends here
