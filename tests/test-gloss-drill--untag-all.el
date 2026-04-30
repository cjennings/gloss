;;; test-gloss-drill--untag-all.el --- Tests for gloss-drill-untag-all -*- lexical-binding: t -*-

;; SPDX-License-Identifier: GPL-3.0-or-later

;;; Commentary:
;; Tests for `gloss-drill-untag-all' covering Normal (export then untag),
;; Boundary (untag when nothing was tagged), and the no-org-drill-needed
;; case (untag must work without `org-drill' installed, since the user
;; might want to remove tags after uninstalling).

;;; Code:

(require 'ert)
(require 'gloss-drill)
(require 'testutil-gloss)
(require 'testutil-gloss-drill)

(defun gloss-test--no-drill-tags-or-properties-p ()
  "Return non-nil when no top-level entry carries :drill: or DRILL_CARD_TYPE.
Reads the file fresh from disk."
  (with-current-buffer (find-file-noselect gloss-file)
    (revert-buffer t t t)
    (let ((dirty nil))
      (org-map-entries
       (lambda ()
         (when (= 1 (org-current-level))
           (when (or (member "drill" (org-get-tags nil t))
                     (org-entry-get nil "DRILL_CARD_TYPE"))
             (setq dirty t)))))
      (not dirty))))

(ert-deftest test-gloss-drill-untag-all-removes-tag-and-property ()
  "Normal: untag-all removes :drill: and :DRILL_CARD_TYPE: from every entry."
  (gloss-test--with-temp-glossary gloss-test--sample-content
    (gloss-test--with-org-drill-feature
      (gloss-drill-export-all)
      (gloss-drill-untag-all)
      (should (gloss-test--no-drill-tags-or-properties-p)))))

(ert-deftest test-gloss-drill-untag-all-no-op-when-nothing-tagged ()
  "Boundary: untag-all on never-tagged entries is a no-op, no error."
  (gloss-test--with-temp-glossary gloss-test--sample-content
    (gloss-drill-untag-all)
    (should (gloss-test--no-drill-tags-or-properties-p))))

(ert-deftest test-gloss-drill-untag-all-works-without-org-drill-installed ()
  "Boundary: untag-all does NOT require org-drill to be installed."
  (gloss-test--with-temp-glossary gloss-test--sample-content
    (gloss-test--with-org-drill-feature
      (gloss-drill-export-all))
    (gloss-test--without-org-drill-feature
      (gloss-drill-untag-all)
      (should (gloss-test--no-drill-tags-or-properties-p)))))

(provide 'test-gloss-drill--untag-all)
;;; test-gloss-drill--untag-all.el ends here
