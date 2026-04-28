;;; test-gloss-fetch--definitions-404-returns-no-defs.el --- 404 path -*- lexical-binding: t -*-

;; SPDX-License-Identifier: GPL-3.0-or-later

;;; Commentary:
;; HTTP 404 from a source maps to :no-defs.  When every source returns
;; :no-defs, the user-facing rollup is :empty with the source listed
;; under :no-defs and nothing under :failed.

;;; Code:

(require 'ert)
(require 'cl-lib)
(require 'gloss-fetch)
(require 'testutil-gloss-fetch)

(ert-deftest test-gloss-fetch-definitions-404-rolls-up-to-empty-no-defs ()
  "Normal: a 404 from the only source rolls up to (:empty :no-defs (wiktionary) :failed nil)."
  (gloss-fetch-test--with-mocked-url
      (lambda (_url)
        (gloss-fetch-test--status-response "HTTP/1.1 404 Not Found"
                                           "{\"detail\":\"Page not found\"}"))
    (let ((result (gloss-fetch-definitions "asdf-not-a-word")))
      (should (eq (car result) :empty))
      (should (member 'wiktionary (plist-get result :no-defs)))
      (should-not (plist-get result :failed)))))

(ert-deftest test-gloss-fetch-definitions-200-empty-rolls-up-to-empty-no-defs ()
  "Boundary: a 200 with an empty JSON object also maps to :no-defs."
  (gloss-fetch-test--with-mocked-url
      (lambda (_url) (gloss-fetch-test--ok-response "{}"))
    (let ((result (gloss-fetch-definitions "term")))
      (should (eq (car result) :empty))
      (should (member 'wiktionary (plist-get result :no-defs)))
      (should-not (plist-get result :failed)))))

(ert-deftest test-gloss-fetch-definitions-200-no-english-rolls-up-to-no-defs ()
  "Boundary: a 200 response with only non-English keys maps to :no-defs."
  ;; v1 ignores everything but the en key per the design doc.
  (let ((body "{\"fr\":[{\"partOfSpeech\":\"Noun\",\"language\":\"French\",\"definitions\":[{\"definition\":\"Un mot.\"}]}]}"))
    (gloss-fetch-test--with-mocked-url
        (lambda (_url) (gloss-fetch-test--ok-response body))
      (let ((result (gloss-fetch-definitions "term")))
        (should (eq (car result) :empty))
        (should (member 'wiktionary (plist-get result :no-defs)))))))

(provide 'test-gloss-fetch--definitions-404-returns-no-defs)
;;; test-gloss-fetch--definitions-404-returns-no-defs.el ends here
