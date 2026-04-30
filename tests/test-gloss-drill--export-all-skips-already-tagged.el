;;; test-gloss-drill--export-all-skips-already-tagged.el --- Idempotency tests for gloss-drill-export-all -*- lexical-binding: t -*-

;; SPDX-License-Identifier: GPL-3.0-or-later

;;; Commentary:
;; Tests for `gloss-drill-export-all' covering the Boundary case of
;; running export twice in a row.  Running it on an already-tagged
;; entry must not duplicate the :drill: tag, and the
;; :DRILL_CARD_TYPE: twosided property must remain a single property
;; with the same value.

;;; Code:

(require 'ert)
(require 'gloss-drill)
(require 'testutil-gloss)
(require 'testutil-gloss-drill)

(defun gloss-test--drill-tag-count-on-first-entry ()
  "Return how many times \"drill\" appears in the first entry's tag list.
Reads the file fresh from disk."
  (with-current-buffer (find-file-noselect gloss-file)
    (revert-buffer t t t)
    (let ((count 0))
      (org-map-entries
       (lambda ()
         (when (= 1 (org-current-level))
           (setq count (length (cl-remove-if-not
                                (lambda (tag) (equal tag "drill"))
                                (org-get-tags nil t))))
           (throw 'done nil))))
      count)))

(ert-deftest test-gloss-drill-export-all-idempotent-tag-not-duplicated ()
  "Boundary: running export-all twice does not duplicate the :drill: tag."
  (gloss-test--with-temp-glossary gloss-test--sample-content
    (gloss-test--with-org-drill-feature
      (gloss-drill-export-all)
      (gloss-drill-export-all)
      (catch 'done
        (should (= (gloss-test--drill-tag-count-on-first-entry) 1))))))

(ert-deftest test-gloss-drill-export-all-idempotent-property-unchanged ()
  "Boundary: running export-all twice keeps :DRILL_CARD_TYPE: twosided."
  (gloss-test--with-temp-glossary gloss-test--sample-content
    (gloss-test--with-org-drill-feature
      (gloss-drill-export-all)
      (gloss-drill-export-all)
      (with-current-buffer (find-file-noselect gloss-file)
        (revert-buffer t t t)
        (catch 'done
          (org-map-entries
           (lambda ()
             (when (= 1 (org-current-level))
               (should (equal (org-entry-get nil "DRILL_CARD_TYPE")
                              "twosided"))
               (throw 'done nil)))))))))

(provide 'test-gloss-drill--export-all-skips-already-tagged)
;;; test-gloss-drill--export-all-skips-already-tagged.el ends here
