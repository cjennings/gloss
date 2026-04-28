;;; test-testutil-gloss--load-wiktionary-fixture.el --- Tests for fixture loader -*- lexical-binding: t -*-

;; SPDX-License-Identifier: GPL-3.0-or-later

;;; Commentary:
;; Tests for `gloss-test--load-wiktionary-fixture' covering
;; Normal/Boundary/Error cases.

;;; Code:

(require 'ert)
(require 'testutil-gloss)

(ert-deftest test-testutil-gloss-load-wiktionary-fixture-existing-returns-string ()
  "Normal: an existing fixture loads as a non-empty JSON string."
  (let ((body (gloss-test--load-wiktionary-fixture "anaphora")))
    (should (stringp body))
    (should (> (length body) 0))
    (should (string-prefix-p "{" body))))

(ert-deftest test-testutil-gloss-load-wiktionary-fixture-smallest-fixture-loads ()
  "Boundary: the 404 error-body fixture (smallest) loads as a string."
  (let ((body (gloss-test--load-wiktionary-fixture "404")))
    (should (stringp body))
    (should (> (length body) 0))
    (should (string-match-p "404" body))))

(ert-deftest test-testutil-gloss-load-wiktionary-fixture-missing-raises-error ()
  "Error: a missing fixture signals `error' with the path in the message."
  (let* ((name "does-not-exist-xyzzy")
         (err (should-error (gloss-test--load-wiktionary-fixture name)
                            :type 'error)))
    (should (string-match-p (format "wiktionary-%s\\.json" name)
                            (error-message-string err)))))

(provide 'test-testutil-gloss--load-wiktionary-fixture)
;;; test-testutil-gloss--load-wiktionary-fixture.el ends here
