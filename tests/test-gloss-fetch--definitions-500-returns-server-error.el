;;; test-gloss-fetch--definitions-500-returns-server-error.el --- 5xx path -*- lexical-binding: t -*-

;; SPDX-License-Identifier: GPL-3.0-or-later

;;; Commentary:
;; HTTP 5xx, malformed JSON, schema mismatch, and 4xx other than 404/429
;; all roll up to :server-error.  When every source fails this way, the
;; user-facing rollup is :empty with the source listed under :failed.

;;; Code:

(require 'ert)
(require 'cl-lib)
(require 'gloss-fetch)
(require 'testutil-gloss-fetch)

(ert-deftest test-gloss-fetch-definitions-500-rolls-up-to-failed ()
  "Normal: HTTP 500 maps the source to :server-error (in :failed)."
  (gloss-fetch-test--with-mocked-url
      (lambda (_url)
        (gloss-fetch-test--status-response "HTTP/1.1 500 Internal Server Error"
                                           "Server is sad."))
    (let ((result (gloss-fetch-definitions "anaphora")))
      (should (eq (car result) :empty))
      (should (member 'wiktionary (plist-get result :failed)))
      (should-not (plist-get result :no-defs)))))

(ert-deftest test-gloss-fetch-definitions-503-rolls-up-to-failed ()
  "Normal: HTTP 503 maps the source to :server-error (in :failed)."
  (gloss-fetch-test--with-mocked-url
      (lambda (_url)
        (gloss-fetch-test--status-response "HTTP/1.1 503 Service Unavailable" ""))
    (let ((result (gloss-fetch-definitions "anaphora")))
      (should (eq (car result) :empty))
      (should (member 'wiktionary (plist-get result :failed))))))

(ert-deftest test-gloss-fetch-definitions-malformed-json-rolls-up-to-failed ()
  "Boundary: a 200 with non-JSON body also maps to :server-error."
  (gloss-fetch-test--with-mocked-url
      (lambda (_url) (gloss-fetch-test--ok-response "<html>not json</html>"))
    (let ((result (gloss-fetch-definitions "anaphora")))
      (should (eq (car result) :empty))
      (should (member 'wiktionary (plist-get result :failed))))))

(ert-deftest test-gloss-fetch-definitions-400-rolls-up-to-failed ()
  "Error: HTTP 400 (4xx other than 404/429) maps to :server-error (in :failed)."
  (gloss-fetch-test--with-mocked-url
      (lambda (_url)
        (gloss-fetch-test--status-response "HTTP/1.1 400 Bad Request" ""))
    (let ((result (gloss-fetch-definitions "anaphora")))
      (should (eq (car result) :empty))
      (should (member 'wiktionary (plist-get result :failed))))))

(provide 'test-gloss-fetch--definitions-500-returns-server-error)
;;; test-gloss-fetch--definitions-500-returns-server-error.el ends here
