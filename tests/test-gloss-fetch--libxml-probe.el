;;; test-gloss-fetch--libxml-probe.el --- libxml availability probe tests -*- lexical-binding: t -*-

;; SPDX-License-Identifier: GPL-3.0-or-later

;;; Commentary:
;; libxml is a precondition for online fetch.  First call probes once;
;; absent libxml triggers a one-shot `user-error' and disables online
;; fetch package-wide for the session.  Subsequent attempts in the same
;; session also signal `user-error'.

;;; Code:

(require 'ert)
(require 'cl-lib)
(require 'gloss-fetch)
(require 'testutil-gloss-fetch)

(ert-deftest test-gloss-fetch-libxml-absent-signals-user-error ()
  "Error: with libxml unavailable, the first fetch signals user-error and disables online."
  (let ((gloss-fetch--libxml-disabled nil)
        (gloss-fetch--libxml-checked nil))
    (cl-letf (((symbol-function 'gloss-fetch--libxml-available-p)
               (lambda () nil)))
      (should-error (gloss-fetch-definitions "anything") :type 'user-error)
      ;; Subsequent attempts also signal — no auto-recovery in the same session.
      (should-error (gloss-fetch-definitions "again") :type 'user-error))))

(ert-deftest test-gloss-fetch-libxml-error-mentions-libxml2 ()
  "Error: the user-error message names libxml2 so the user can act."
  (let ((gloss-fetch--libxml-disabled nil)
        (gloss-fetch--libxml-checked nil))
    (cl-letf (((symbol-function 'gloss-fetch--libxml-available-p)
               (lambda () nil)))
      (let ((err (should-error (gloss-fetch-definitions "x") :type 'user-error)))
        (should (string-match-p "libxml2" (error-message-string err)))))))

(ert-deftest test-gloss-fetch-libxml-probe-runs-only-once ()
  "Boundary: the libxml availability probe is invoked at most once per session."
  (let ((probe-calls 0)
        (gloss-fetch--libxml-disabled nil)
        (gloss-fetch--libxml-checked nil))
    (cl-letf (((symbol-function 'gloss-fetch--libxml-available-p)
               (lambda () (cl-incf probe-calls) t)))
      (gloss-fetch-test--with-mocked-url
          (lambda (_url) (gloss-fetch-test--ok-response "{}"))
        (gloss-fetch-definitions "first")
        (gloss-fetch-definitions "second")
        (gloss-fetch-definitions "third"))
      (should (= 1 probe-calls)))))

(ert-deftest test-gloss-fetch-libxml-present-allows-fetch ()
  "Normal: when libxml is available, fetch proceeds normally."
  (let ((gloss-fetch--libxml-disabled nil)
        (gloss-fetch--libxml-checked nil))
    (cl-letf (((symbol-function 'gloss-fetch--libxml-available-p)
               (lambda () t)))
      (gloss-fetch-test--with-mocked-url
          (lambda (_url) (gloss-fetch-test--ok-response "{}"))
        (let ((result (gloss-fetch-definitions "term")))
          (should-not (plist-get result :defs))
          (should (member 'wiktionary (plist-get result :no-defs))))))))

(provide 'test-gloss-fetch--libxml-probe)
;;; test-gloss-fetch--libxml-probe.el ends here
