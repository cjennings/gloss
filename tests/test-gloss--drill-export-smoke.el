;;; test-gloss--drill-export-smoke.el --- Smoke test for gloss-drill-export -*- lexical-binding: t -*-

;; SPDX-License-Identifier: GPL-3.0-or-later

;;; Commentary:
;; Smoke test confirming `gloss-drill-export' is a thin wrapper around
;; `gloss-drill-export-all' and runs end-to-end against a real glossary.

;;; Code:

(require 'ert)
(require 'gloss)
(require 'testutil-gloss)
(require 'testutil-gloss-drill)

(ert-deftest test-gloss-drill-export-tags-every-entry ()
  "Smoke: drill-export delegates and tags every entry with :drill:."
  (gloss-test--with-temp-glossary gloss-test--sample-content
    (gloss-test--with-org-drill-feature
      (gloss-drill-export)
      (with-current-buffer (find-file-noselect gloss-file)
        (revert-buffer t t t)
        (let ((tagged 0))
          (org-map-entries
           (lambda ()
             (when (and (= 1 (org-current-level))
                        (member "drill" (org-get-tags nil t)))
               (setq tagged (1+ tagged)))))
          (should (= tagged 2)))))))

(provide 'test-gloss--drill-export-smoke)
;;; test-gloss--drill-export-smoke.el ends here
