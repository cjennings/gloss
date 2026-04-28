;;; test-gloss-core--first-call-creates-file.el --- Tests for first-save creates file -*- lexical-binding: t -*-

;; SPDX-License-Identifier: GPL-3.0-or-later

;;; Commentary:
;; Tests that `gloss-core-save' creates `gloss-file' (and any missing
;; parent directory) on first call.

;;; Code:

(require 'ert)
(require 'gloss-core)
(require 'testutil-gloss)

(ert-deftest test-gloss-core-save-creates-file-when-missing ()
  "Normal: first save creates the file with a TITLE header."
  (let ((gloss-file (concat temporary-file-directory "gloss-create-"
                            (number-to-string (random 100000)) ".org")))
    (unwind-protect
        (progn
          (gloss-core--cache-reset)
          (should-not (file-exists-p gloss-file))
          (gloss-core-save "anaphora" "Reference earlier." 'manual)
          (should (file-exists-p gloss-file))
          (let ((content (with-temp-buffer
                           (insert-file-contents gloss-file)
                           (buffer-string))))
            (should (string-match-p "#\\+TITLE:" content))
            (should (string-match-p "^\\* anaphora" content))))
      (gloss-core--cache-reset)
      (when-let ((buf (find-buffer-visiting gloss-file)))
        (with-current-buffer buf (set-buffer-modified-p nil))
        (kill-buffer buf))
      (when (file-exists-p gloss-file) (delete-file gloss-file)))))

(ert-deftest test-gloss-core-save-creates-parent-directory ()
  "Boundary: first save creates missing parent directory."
  (let* ((parent (concat temporary-file-directory "gloss-newdir-"
                         (number-to-string (random 100000))))
         (gloss-file (concat parent "/gloss.org")))
    (unwind-protect
        (progn
          (gloss-core--cache-reset)
          (should-not (file-exists-p parent))
          (gloss-core-save "anaphora" "Reference earlier." 'manual)
          (should (file-exists-p parent))
          (should (file-exists-p gloss-file)))
      (gloss-core--cache-reset)
      (when-let ((buf (find-buffer-visiting gloss-file)))
        (with-current-buffer buf (set-buffer-modified-p nil))
        (kill-buffer buf))
      (when (file-exists-p gloss-file) (delete-file gloss-file))
      (when (file-directory-p parent) (delete-directory parent)))))

(provide 'test-gloss-core--first-call-creates-file)
;;; test-gloss-core--first-call-creates-file.el ends here
