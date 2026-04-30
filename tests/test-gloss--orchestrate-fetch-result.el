;;; test-gloss--orchestrate-fetch-result.el --- Tests for gloss--orchestrate-fetch-result -*- lexical-binding: t -*-

;; SPDX-License-Identifier: GPL-3.0-or-later

;;; Commentary:
;; Tests for the pure pattern-matcher `gloss--orchestrate-fetch-result'.
;; It maps a `gloss-fetch-definitions' result plist to a decision
;; symbol that the lookup flow then dispatches on.  Full N/B/E
;; coverage on the full decision matrix.

;;; Code:

(require 'ert)
(require 'gloss)

(ert-deftest test-gloss-orchestrate-fetch-result-single-def-returns-auto-save ()
  "Normal: exactly one definition returns :auto-save."
  (let ((result '(:defs ((:source wiktionary :text "Only sense."))
                  :no-defs nil
                  :failed nil)))
    (should (eq (gloss--orchestrate-fetch-result result) :auto-save))))

(ert-deftest test-gloss-orchestrate-fetch-result-multi-def-returns-pick ()
  "Normal: more than one definition returns :pick."
  (let ((result '(:defs ((:source wiktionary :text "First.")
                         (:source wiktionary :text "Second.")
                         (:source wiktionary :text "Third."))
                  :no-defs nil
                  :failed nil)))
    (should (eq (gloss--orchestrate-fetch-result result) :pick))))

(ert-deftest test-gloss-orchestrate-fetch-result-two-defs-returns-pick ()
  "Boundary: exactly two definitions returns :pick (above the >1 threshold)."
  (let ((result '(:defs ((:source wiktionary :text "A.")
                         (:source wiktionary :text "B."))
                  :no-defs nil
                  :failed nil)))
    (should (eq (gloss--orchestrate-fetch-result result) :pick))))

(ert-deftest test-gloss-orchestrate-fetch-result-only-no-defs-returns-error-no-defs ()
  "Boundary: no defs and only :no-defs sources returns :error-no-defs."
  (let ((result '(:defs nil
                  :no-defs (wiktionary)
                  :failed nil)))
    (should (eq (gloss--orchestrate-fetch-result result) :error-no-defs))))

(ert-deftest test-gloss-orchestrate-fetch-result-only-failed-returns-error-failed ()
  "Boundary: no defs and only :failed sources returns :error-failed."
  (let ((result '(:defs nil
                  :no-defs nil
                  :failed (wiktionary))))
    (should (eq (gloss--orchestrate-fetch-result result) :error-failed))))

(ert-deftest test-gloss-orchestrate-fetch-result-mixed-no-defs-and-failed-returns-error-mixed ()
  "Boundary: no defs but BOTH :no-defs and :failed populated returns :error-mixed."
  (let ((result '(:defs nil
                  :no-defs (wiktionary)
                  :failed (dictionary-api))))
    (should (eq (gloss--orchestrate-fetch-result result) :error-mixed))))

(ert-deftest test-gloss-orchestrate-fetch-result-all-empty-returns-error-no-defs ()
  "Error: degenerate result with all three keys empty returns :error-no-defs."
  (let ((result '(:defs nil :no-defs nil :failed nil)))
    (should (eq (gloss--orchestrate-fetch-result result) :error-no-defs))))

(provide 'test-gloss--orchestrate-fetch-result)
;;; test-gloss--orchestrate-fetch-result.el ends here
