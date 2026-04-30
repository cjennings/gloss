;;; test-gloss-drill--export-all-no-orgdrill-installed.el --- Error tests for missing org-drill -*- lexical-binding: t -*-

;; SPDX-License-Identifier: GPL-3.0-or-later

;;; Commentary:
;; Tests for `gloss-drill-export-all' covering the Error case where
;; `org-drill' is not installed.  The function must raise `user-error'
;; with an install hint and must not touch `gloss-file'.

;;; Code:

(require 'ert)
(require 'gloss-drill)
(require 'testutil-gloss)
(require 'testutil-gloss-drill)

(ert-deftest test-gloss-drill-export-all-without-org-drill-raises-user-error ()
  "Error: missing `org-drill' raises `user-error' with an install hint."
  (gloss-test--with-temp-glossary gloss-test--sample-content
    (gloss-test--without-org-drill-feature
      (let ((err (should-error (gloss-drill-export-all) :type 'user-error)))
        (should (string-match-p "org-drill" (error-message-string err)))))))

(ert-deftest test-gloss-drill-export-all-without-org-drill-leaves-file-untouched ()
  "Error: missing `org-drill' must not modify the glossary file."
  (gloss-test--with-temp-glossary gloss-test--sample-content
    (gloss-test--without-org-drill-feature
      (let ((before (with-temp-buffer
                      (insert-file-contents gloss-file)
                      (buffer-string))))
        (ignore-errors (gloss-drill-export-all))
        (let ((after (with-temp-buffer
                       (insert-file-contents gloss-file)
                       (buffer-string))))
          (should (equal before after)))))))

(provide 'test-gloss-drill--export-all-no-orgdrill-installed)
;;; test-gloss-drill--export-all-no-orgdrill-installed.el ends here
