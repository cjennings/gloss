;;; test-gloss-fetch--definitions-429-returns-rate-limited.el --- 429 path -*- lexical-binding: t -*-

;; SPDX-License-Identifier: GPL-3.0-or-later

;;; Commentary:
;; HTTP 429 is its own per-source status (`:rate-limited'), separated
;; from `:server-error' so the v2 user-facing wording can call it out
;; distinctly.  At the rollup it joins :failed.

;;; Code:

(require 'ert)
(require 'cl-lib)
(require 'gloss-fetch)
(require 'testutil-gloss-fetch)

(ert-deftest test-gloss-fetch-definitions-429-rolls-up-to-failed ()
  "Normal: HTTP 429 maps the source to :rate-limited, which joins :failed."
  (gloss-fetch-test--with-mocked-url
      (lambda (_url)
        (gloss-fetch-test--status-response "HTTP/1.1 429 Too Many Requests" ""))
    (let ((result (gloss-fetch-definitions "anaphora")))
      (should (eq (car result) :empty))
      (should (member 'wiktionary (plist-get (cdr result) :failed)))
      (should-not (plist-get (cdr result) :no-defs)))))

(ert-deftest test-gloss-fetch-definitions-429-tracked-separately-internally ()
  "Boundary: per-source status taxonomy distinguishes :rate-limited from :server-error.

Verifies the internal walker exposes the per-source result so the
debug log can carry the right tag.  Calls
`gloss-fetch--collect' (the internal entry point that returns the
per-source result list) and inspects the :status field."
  (gloss-fetch-test--with-mocked-url
      (lambda (_url)
        (gloss-fetch-test--status-response "HTTP/1.1 429 Too Many Requests" ""))
    (let* ((per-source (gloss-fetch--collect "anaphora"))
           (entry (car per-source)))
      (should (eq (plist-get entry :source) 'wiktionary))
      (should (eq (plist-get entry :status) :rate-limited)))))

(provide 'test-gloss-fetch--definitions-429-returns-rate-limited)
;;; test-gloss-fetch--definitions-429-returns-rate-limited.el ends here
