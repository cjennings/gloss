;;; test-gloss-drill--export-all-tags-untagged.el --- Tests for gloss-drill-export-all on untagged entries -*- lexical-binding: t -*-

;; SPDX-License-Identifier: GPL-3.0-or-later

;;; Commentary:
;; Tests for `gloss-drill-export-all' covering the Normal happy-path
;; (untagged entries gain the tag and property) and the Boundary case of
;; an empty glossary file.  The entry walking uses real `org-element' /
;; `org-map-entries'; only the `org-drill' feature flag is mocked.

;;; Code:

(require 'ert)
(require 'gloss-drill)
(require 'testutil-gloss)
(require 'testutil-gloss-drill)

(defun gloss-test--drill-tagged-count ()
  "Return the number of top-level entries in `gloss-file' tagged :drill:.
Reads the file fresh from disk."
  (with-current-buffer (find-file-noselect gloss-file)
    (revert-buffer t t t)
    (let ((count 0))
      (org-map-entries
       (lambda ()
         (when (and (= 1 (org-current-level))
                    (member "drill" (org-get-tags nil t)))
           (setq count (1+ count)))))
      count)))

(defun gloss-test--drill-card-type-count ()
  "Return the number of top-level entries with :DRILL_CARD_TYPE: twosided'.
Reads the file fresh from disk."
  (with-current-buffer (find-file-noselect gloss-file)
    (revert-buffer t t t)
    (let ((count 0))
      (org-map-entries
       (lambda ()
         (when (and (= 1 (org-current-level))
                    (equal (org-entry-get nil "DRILL_CARD_TYPE") "twosided"))
           (setq count (1+ count)))))
      count)))

(ert-deftest test-gloss-drill-export-all-adds-drill-tag-to-every-entry ()
  "Normal: every untagged entry gains :drill: after export-all."
  (gloss-test--with-temp-glossary gloss-test--sample-content
    (gloss-test--with-org-drill-feature
      (gloss-drill-export-all)
      (should (= (gloss-test--drill-tagged-count) 2)))))

(ert-deftest test-gloss-drill-export-all-sets-drill-card-type-property ()
  "Normal: every entry gains :DRILL_CARD_TYPE: twosided after export-all."
  (gloss-test--with-temp-glossary gloss-test--sample-content
    (gloss-test--with-org-drill-feature
      (gloss-drill-export-all)
      (should (= (gloss-test--drill-card-type-count) 2)))))

(ert-deftest test-gloss-drill-export-all-empty-file-no-op ()
  "Boundary: export-all on an empty glossary file is a no-op, no error."
  (gloss-test--with-temp-glossary "#+TITLE: Glossary\n#+STARTUP: showall\n"
    (gloss-test--with-org-drill-feature
      (gloss-drill-export-all)
      (should (= (gloss-test--drill-tagged-count) 0)))))

(provide 'test-gloss-drill--export-all-tags-untagged)
;;; test-gloss-drill--export-all-tags-untagged.el ends here
