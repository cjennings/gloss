;;; test-gloss-fetch--multi-source-walks-registry.el --- Registry walk tests -*- lexical-binding: t -*-

;; SPDX-License-Identifier: GPL-3.0-or-later

;;; Commentary:
;; `gloss-fetch--sources' is an alist (source-symbol → fetcher fn).
;; `gloss-fetch-sources' is the user-facing defcustom that orders the
;; walk.  Each fetcher returns a per-source result plist.  The walker
;; aggregates results across all configured sources.

;;; Code:

(require 'ert)
(require 'cl-lib)
(require 'gloss-fetch)

(ert-deftest test-gloss-fetch-collect-walks-registry-in-defcustom-order ()
  "Normal: walker visits each source in `gloss-fetch-sources' order, gathers a result per source."
  (let* ((calls nil)
         (gloss-fetch--sources
          `((alpha . ,(lambda (term)
                        (push 'alpha calls)
                        (list :source 'alpha :status :ok :defs
                              (list (list :source 'alpha :text (concat "A:" term))))))
            (beta . ,(lambda (term)
                       (push 'beta calls)
                       (list :source 'beta :status :no-defs
                             :reason (concat "no entry for " term))))))
         (gloss-fetch-sources '(alpha beta))
         (per-source (gloss-fetch--collect "x")))
    (should (equal (reverse calls) '(alpha beta)))
    (should (= 2 (length per-source)))
    (should (eq 'alpha (plist-get (nth 0 per-source) :source)))
    (should (eq 'beta  (plist-get (nth 1 per-source) :source)))))

(ert-deftest test-gloss-fetch-rollup-mixes-no-defs-and-failed ()
  "Boundary: a mix of :no-defs and :server-error rolls up with both lists populated."
  (let* ((gloss-fetch--sources
          `((alpha . ,(lambda (_term)
                        (list :source 'alpha :status :no-defs :reason "404")))
            (beta . ,(lambda (_term)
                       (list :source 'beta :status :server-error :reason "HTTP 503")))))
         (gloss-fetch-sources '(alpha beta))
         (result (gloss-fetch-definitions "x")))
    (should (eq (car result) :empty))
    (should (member 'alpha (plist-get result :no-defs)))
    (should (member 'beta (plist-get result :failed)))))

(ert-deftest test-gloss-fetch-rollup-any-ok-yields-ok ()
  "Boundary: if any source returns :ok with defs, the rollup is (:ok DEFS)."
  (let* ((gloss-fetch--sources
          `((alpha . ,(lambda (_term)
                        (list :source 'alpha :status :no-defs :reason "404")))
            (beta . ,(lambda (_term)
                       (list :source 'beta :status :ok :defs
                             (list (list :source 'beta :text "got it")))))))
         (gloss-fetch-sources '(alpha beta))
         (result (gloss-fetch-definitions "x")))
    (should (eq (car result) :ok))
    (should (= 1 (length (plist-get result :ok))))
    (should (equal "got it" (plist-get (car (plist-get result :ok)) :text)))))

(ert-deftest test-gloss-fetch-collect-skips-source-not-in-defcustom ()
  "Error: a source registered in `gloss-fetch--sources' but not in `gloss-fetch-sources' is skipped."
  (let* ((called nil)
         (gloss-fetch--sources
          `((alpha . ,(lambda (_term)
                        (setq called t)
                        (list :source 'alpha :status :ok :defs
                              (list (list :source 'alpha :text "x")))))))
         (gloss-fetch-sources '()) ; empty — skip everything
         (per-source (gloss-fetch--collect "x")))
    (should-not called)
    (should (null per-source))))

(ert-deftest test-gloss-fetch-collect-skips-unknown-source-symbol ()
  "Error: a symbol in `gloss-fetch-sources' with no registered fetcher is silently skipped."
  (let* ((gloss-fetch--sources
          `((alpha . ,(lambda (_term)
                        (list :source 'alpha :status :ok :defs
                              (list (list :source 'alpha :text "x")))))))
         (gloss-fetch-sources '(zeta alpha))
         (per-source (gloss-fetch--collect "x")))
    (should (= 1 (length per-source)))
    (should (eq 'alpha (plist-get (car per-source) :source)))))

(provide 'test-gloss-fetch--multi-source-walks-registry)
;;; test-gloss-fetch--multi-source-walks-registry.el ends here
