;;; test-gloss-display--format-candidate.el --- Tests for gloss-display--format-candidate -*- lexical-binding: t -*-

;; SPDX-License-Identifier: GPL-3.0-or-later

;;; Commentary:
;; Tests for the pure helper `gloss-display--format-candidate' covering
;; Normal/Boundary/Error cases.  The helper takes a definition plist
;; (:source SYM :text STRING) and returns a single-line "[source] text"
;; row suitable for display in `completing-read'.

;;; Code:

(require 'ert)
(require 'gloss-display)

(ert-deftest test-gloss-display-format-candidate-normal-short-text ()
  "Normal: short text formats as \"[source] text\" with no truncation."
  (let ((result (gloss-display--format-candidate
                 '(:source wiktionary :text "Hello world."))))
    (should (equal result "[wiktionary] Hello world."))))

(ert-deftest test-gloss-display-format-candidate-normal-different-source ()
  "Normal: source symbol is rendered as its name inside brackets."
  (let ((result (gloss-display--format-candidate
                 '(:source dictionary-api :text "Some text."))))
    (should (string-prefix-p "[dictionary-api] " result))))

(ert-deftest test-gloss-display-format-candidate-boundary-empty-text ()
  "Boundary: empty text yields the prefix only."
  (let ((result (gloss-display--format-candidate
                 '(:source wiktionary :text ""))))
    (should (equal result "[wiktionary] "))))

(ert-deftest test-gloss-display-format-candidate-boundary-single-char-text ()
  "Boundary: one-character text is preserved verbatim."
  (let ((result (gloss-display--format-candidate
                 '(:source wiktionary :text "a"))))
    (should (equal result "[wiktionary] a"))))

(ert-deftest test-gloss-display-format-candidate-boundary-unicode-text ()
  "Boundary: unicode characters in text are preserved."
  (let ((result (gloss-display--format-candidate
                 '(:source wiktionary :text "café — naïve résumé"))))
    (should (equal result "[wiktionary] café — naïve résumé"))))

(ert-deftest test-gloss-display-format-candidate-boundary-long-text-truncated ()
  "Boundary: text longer than the cap is truncated with an ellipsis."
  (let* ((long-text (make-string 200 ?x))
         (result (gloss-display--format-candidate
                  (list :source 'wiktionary :text long-text))))
    (should (<= (length result) gloss-display--candidate-max-length))
    (should (string-suffix-p "..." result))
    (should (string-prefix-p "[wiktionary] " result))))

(ert-deftest test-gloss-display-format-candidate-boundary-text-at-cap-not-truncated ()
  "Boundary: text that fits exactly at the cap is not truncated."
  (let* ((prefix-len (length "[wiktionary] "))
         (text (make-string (- gloss-display--candidate-max-length prefix-len) ?y))
         (result (gloss-display--format-candidate
                  (list :source 'wiktionary :text text))))
    (should (= (length result) gloss-display--candidate-max-length))
    (should-not (string-suffix-p "..." result))))

(ert-deftest test-gloss-display-format-candidate-boundary-missing-source ()
  "Boundary: missing :source falls back to the literal \"unknown\" tag."
  (let ((result (gloss-display--format-candidate
                 '(:text "Some text."))))
    (should (string-prefix-p "[unknown] " result))
    (should (string-suffix-p "Some text." result))))

(ert-deftest test-gloss-display-format-candidate-boundary-newlines-collapsed ()
  "Boundary: embedded newlines are collapsed to spaces (single-line row)."
  (let ((result (gloss-display--format-candidate
                 '(:source wiktionary :text "First line.\nSecond line."))))
    (should-not (string-match-p "\n" result))
    (should (string-match-p "First line. Second line." result))))

(ert-deftest test-gloss-display-format-candidate-error-non-list-input ()
  "Error: passing a non-list raises `wrong-type-argument'."
  (should-error (gloss-display--format-candidate "not a plist")
                :type 'wrong-type-argument))

(provide 'test-gloss-display--format-candidate)
;;; test-gloss-display--format-candidate.el ends here
