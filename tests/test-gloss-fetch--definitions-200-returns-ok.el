;;; test-gloss-fetch--definitions-200-returns-ok.el --- 200 path tests -*- lexical-binding: t -*-

;; SPDX-License-Identifier: GPL-3.0-or-later

;;; Commentary:
;; Normal/Boundary cases: a 200 response with valid JSON returns
;; (:ok DEFS) and each def is a plist with :source and :text.  Uses the
;; captured Wiktionary fixtures replayed through a mocked
;; `url-retrieve-synchronously'.

;;; Code:

(require 'ert)
(require 'cl-lib)
(require 'gloss-fetch)
(require 'testutil-gloss)
(require 'testutil-gloss-fetch)

(ert-deftest test-gloss-fetch-definitions-200-anaphora-returns-ok ()
  "Normal: anaphora fixture (single English sense) returns (:ok DEFS)."
  (let ((body (gloss-test--load-wiktionary-fixture "anaphora")))
    (gloss-fetch-test--with-mocked-url
        (lambda (_url) (gloss-fetch-test--ok-response body))
      (let* ((result (gloss-fetch-definitions "anaphora"))
             (defs (plist-get result :ok)))
        (should (eq (car result) :ok))
        (should (consp defs))
        (should (>= (length defs) 1))
        (let ((first (car defs)))
          (should (eq (plist-get first :source) 'wiktionary))
          (should (stringp (plist-get first :text)))
          (should (> (length (plist-get first :text)) 0))
          ;; HTML stripped — no angle brackets in the text.
          (should-not (string-match-p "<" (plist-get first :text))))))))

(ert-deftest test-gloss-fetch-definitions-200-sbir-returns-multiple-senses ()
  "Boundary: SBIR fixture has multiple senses; all returned as separate plists."
  (let ((body (gloss-test--load-wiktionary-fixture "SBIR")))
    (gloss-fetch-test--with-mocked-url
        (lambda (_url) (gloss-fetch-test--ok-response body))
      (let* ((result (gloss-fetch-definitions "SBIR"))
             (defs (plist-get result :ok)))
        (should (eq (car result) :ok))
        (should (>= (length defs) 1))
        (dolist (d defs)
          (should (eq (plist-get d :source) 'wiktionary))
          (should (stringp (plist-get d :text))))))))

(ert-deftest test-gloss-fetch-definitions-200-encodes-spaces-in-url ()
  "Boundary: a multi-word term URL-encodes the space."
  (let ((seen-url nil)
        (body "{}"))
    (gloss-fetch-test--with-mocked-url
        (lambda (url)
          (setq seen-url url)
          (gloss-fetch-test--ok-response body))
      (gloss-fetch-definitions "hapax legomenon"))
    (should seen-url)
    (should (string-match-p "hapax%20legomenon\\|hapax_legomenon" seen-url))))

(provide 'test-gloss-fetch--definitions-200-returns-ok)
;;; test-gloss-fetch--definitions-200-returns-ok.el ends here
