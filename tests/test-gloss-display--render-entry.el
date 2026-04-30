;;; test-gloss-display--render-entry.el --- Tests for gloss-display--render-entry -*- lexical-binding: t -*-

;; SPDX-License-Identifier: GPL-3.0-or-later

;;; Commentary:
;; Tests for the pure helper `gloss-display--render-entry' covering
;; Normal/Boundary/Error cases.  The helper takes a TERM and BODY and
;; returns the formatted string that `gloss-display-show-entry' inserts
;; into the side buffer.

;;; Code:

(require 'ert)
(require 'gloss-display)

(ert-deftest test-gloss-display-render-entry-normal-term-and-body ()
  "Normal: render produces the term, an underline, a blank, and the body."
  (let ((result (gloss-display--render-entry
                 "anaphora"
                 "Reference to something earlier in the discourse.")))
    (should (string-match-p "^anaphora\n" result))
    (should (string-match-p "^=+\n" (substring result (length "anaphora\n"))))
    (should (string-match-p "Reference to something earlier" result))))

(ert-deftest test-gloss-display-render-entry-normal-underline-matches-term-length ()
  "Normal: the underline length matches the term length."
  (let* ((term "abc")
         (result (gloss-display--render-entry term "Body."))
         (lines (split-string result "\n")))
    (should (equal (nth 0 lines) term))
    (should (= (length (nth 1 lines)) (length term)))
    (should (string-match-p "^=+$" (nth 1 lines)))))

(ert-deftest test-gloss-display-render-entry-boundary-multi-line-body ()
  "Boundary: a multi-line body is preserved verbatim."
  (let ((result (gloss-display--render-entry
                 "term"
                 "First paragraph.\n\nSecond paragraph.")))
    (should (string-match-p "First paragraph\\." result))
    (should (string-match-p "Second paragraph\\." result))
    (should (string-match-p "First paragraph\\.\n\nSecond paragraph\\." result))))

(ert-deftest test-gloss-display-render-entry-boundary-empty-body ()
  "Boundary: an empty body still renders the term and underline."
  (let ((result (gloss-display--render-entry "lonely" "")))
    (should (string-match-p "^lonely\n=+\n" result))))

(ert-deftest test-gloss-display-render-entry-boundary-unicode-term ()
  "Boundary: unicode characters in the term are preserved."
  (let* ((term "café")
         (result (gloss-display--render-entry term "A coffeehouse.")))
    (should (string-match-p (regexp-quote term) result))
    (should (string-match-p "A coffeehouse\\." result))))

(ert-deftest test-gloss-display-render-entry-boundary-very-long-term ()
  "Boundary: a long term gets a matching long underline."
  (let* ((term (make-string 60 ?z))
         (result (gloss-display--render-entry term "Body."))
         (lines (split-string result "\n")))
    (should (equal (nth 0 lines) term))
    (should (= (length (nth 1 lines)) 60))))

(provide 'test-gloss-display--render-entry)
;;; test-gloss-display--render-entry.el ends here
