;;; test-gloss-fetch--definitions-timeout-returns-unreachable.el --- timeout path -*- lexical-binding: t -*-

;; SPDX-License-Identifier: GPL-3.0-or-later

;;; Commentary:
;; A timeout (or any other transport-level failure) makes
;; `url-retrieve-synchronously' return nil; the source maps to
;; :unreachable, which joins :failed at the rollup.

;;; Code:

(require 'ert)
(require 'cl-lib)
(require 'gloss-fetch)
(require 'testutil-gloss-fetch)

(ert-deftest test-gloss-fetch-definitions-timeout-rolls-up-to-failed ()
  "Normal: nil from url-retrieve-synchronously rolls up to :failed."
  (gloss-fetch-test--with-mocked-url
      (lambda (_url) nil)
    (let ((result (gloss-fetch-definitions "anaphora")))
      (should-not (plist-get result :defs))
      (should (member 'wiktionary (plist-get result :failed)))
      (should-not (plist-get result :no-defs)))))

(ert-deftest test-gloss-fetch-definitions-timeout-marks-source-unreachable ()
  "Boundary: per-source status is :unreachable, distinct from :server-error."
  (gloss-fetch-test--with-mocked-url
      (lambda (_url) nil)
    (let* ((per-source (gloss-fetch--collect "anaphora"))
           (entry (car per-source)))
      (should (eq (plist-get entry :source) 'wiktionary))
      (should (eq (plist-get entry :status) :unreachable)))))

(ert-deftest test-gloss-fetch-definitions-error-signal-marks-source-unreachable ()
  "Error: a signaled error inside url-retrieve-synchronously also yields :unreachable."
  (gloss-fetch-test--with-mocked-url
      (lambda (_url) (error "Connection refused"))
    (let* ((per-source (gloss-fetch--collect "anaphora"))
           (entry (car per-source)))
      (should (eq (plist-get entry :status) :unreachable)))))

(provide 'test-gloss-fetch--definitions-timeout-returns-unreachable)
;;; test-gloss-fetch--definitions-timeout-returns-unreachable.el ends here
