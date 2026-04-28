;;; test-gloss-core--invalidate-on-mtime.el --- Tests for cache mtime invalidation -*- lexical-binding: t -*-

;; SPDX-License-Identifier: GPL-3.0-or-later

;;; Commentary:
;; Tests that the cache reloads when `gloss-file' is edited out-of-band.

;;; Code:

(require 'ert)
(require 'gloss-core)
(require 'testutil-gloss)

(ert-deftest test-gloss-core-invalidate-on-mtime-new-content-detected ()
  "Normal: out-of-band edit + later lookup sees the new content."
  (gloss-test--with-temp-glossary gloss-test--sample-content
    ;; Prime cache.
    (should (gloss-core-lookup "anaphora"))
    ;; Append a new entry directly to disk.
    (with-temp-buffer
      (insert-file-contents gloss-file)
      (goto-char (point-max))
      (insert "\n* hapax\n:PROPERTIES:\n:SOURCE:   manual\n:ADDED:    2026-04-28\n:END:\nA word used only once in a corpus.\n")
      (write-region (point-min) (point-max) gloss-file))
    ;; Force mtime change to be visible (1-second granularity on some FSes).
    (set-file-times gloss-file (time-add (current-time) 5))
    ;; Lookup detects the mtime change and reloads.
    (let ((entry (gloss-core-lookup "hapax")))
      (should entry)
      (should (string-match-p "used only once" (plist-get entry :body))))))

(ert-deftest test-gloss-core-invalidate-on-mtime-unchanged-uses-cache ()
  "Boundary: unchanged mtime — two consecutive lookups both succeed."
  (gloss-test--with-temp-glossary gloss-test--sample-content
    (should (gloss-core-lookup "anaphora"))
    (should (gloss-core-lookup "anaphora"))))

(ert-deftest test-gloss-core-invalidate-on-mtime-deleted-file-clears-cache ()
  "Error: file deleted out-of-band — subsequent lookup returns nil."
  (gloss-test--with-temp-glossary gloss-test--sample-content
    (should (gloss-core-lookup "anaphora"))
    (when-let ((buf (find-buffer-visiting gloss-file)))
      (with-current-buffer buf (set-buffer-modified-p nil))
      (kill-buffer buf))
    (delete-file gloss-file)
    (should-not (gloss-core-lookup "anaphora"))))

(provide 'test-gloss-core--invalidate-on-mtime)
;;; test-gloss-core--invalidate-on-mtime.el ends here
