;;; test-gloss--edit-smoke.el --- Smoke tests for gloss-edit -*- lexical-binding: t -*-

;; SPDX-License-Identifier: GPL-3.0-or-later

;;; Commentary:
;; Smoke tests for `gloss-edit'.  Switches to the source buffer and
;; positions point at the heading; installs a buffer-local
;; `after-save-hook' so cache refresh follows hand edits.

;;; Code:

(require 'ert)
(require 'gloss)
(require 'testutil-gloss)

(ert-deftest test-gloss-edit-known-term-positions-at-heading ()
  "Smoke: edit on a known term puts point at its heading line."
  (gloss-test--with-temp-glossary gloss-test--sample-content
    (save-window-excursion
      (gloss-edit "anaphora")
      (should (looking-at-p "^\\* anaphora")))))

(ert-deftest test-gloss-edit-installs-buffer-local-cache-refresh-hook ()
  "Smoke: edit installs `gloss--after-save-refresh-cache' buffer-locally."
  (gloss-test--with-temp-glossary gloss-test--sample-content
    (save-window-excursion
      (gloss-edit "anaphora")
      (should (memq 'gloss--after-save-refresh-cache after-save-hook))
      (should (local-variable-p 'after-save-hook)))))

(ert-deftest test-gloss-edit-unknown-term-raises ()
  "Error: edit on a non-existent term raises `user-error' naming the term."
  (gloss-test--with-temp-glossary gloss-test--sample-content
    (let ((err (should-error (gloss-edit "no-such-term") :type 'user-error)))
      (should (string-match-p "no-such-term" (error-message-string err))))))

(provide 'test-gloss--edit-smoke)
;;; test-gloss--edit-smoke.el ends here
