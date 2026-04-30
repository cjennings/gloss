;;; testutil-gloss-drill.el --- Shared test fixtures for gloss-drill -*- lexical-binding: t -*-

;; SPDX-License-Identifier: GPL-3.0-or-later

;;; Commentary:

;; Fixtures used across `gloss-drill' test files.  Provides:
;;   - `gloss-test--with-org-drill-feature' macro to register `org-drill'
;;     as a feature for the duration of BODY (without actually loading it).

;;; Code:

(defmacro gloss-test--with-org-drill-feature (&rest body)
  "Run BODY with `org-drill' provided as a feature.
Restores the prior feature state on exit so tests can both assert
\"org-drill present\" and \"org-drill absent\" behaviour without leaking
state across the suite."
  (declare (indent 0) (debug t))
  `(let ((had-org-drill (featurep 'org-drill)))
     (unwind-protect
         (progn
           (provide 'org-drill)
           ,@body)
       (unless had-org-drill
         (setq features (delq 'org-drill features))))))

(defmacro gloss-test--without-org-drill-feature (&rest body)
  "Run BODY with `org-drill' un-registered as a feature.
Restores the prior feature state on exit."
  (declare (indent 0) (debug t))
  `(let ((had-org-drill (featurep 'org-drill)))
     (unwind-protect
         (progn
           (setq features (delq 'org-drill features))
           ,@body)
       (when had-org-drill
         (provide 'org-drill)))))

(provide 'testutil-gloss-drill)
;;; testutil-gloss-drill.el ends here
