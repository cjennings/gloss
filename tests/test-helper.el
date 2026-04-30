;;; test-helper.el --- Test setup for ert-runner -*- lexical-binding: t -*-

;; SPDX-License-Identifier: GPL-3.0-or-later

;;; Commentary:

;; Loaded automatically by ert-runner before test files.  Adds the
;; tests/ directory to `load-path' so `(require \\='testutil-gloss)' and
;; sibling testutil files resolve.

;;; Code:

(let ((tests-dir (file-name-directory (or load-file-name buffer-file-name))))
  (add-to-list 'load-path tests-dir))

(provide 'test-helper)
;;; test-helper.el ends here
