;;; test-gloss-fetch--strip-html.el --- HTML strip helper tests -*- lexical-binding: t -*-

;; SPDX-License-Identifier: GPL-3.0-or-later

;;; Commentary:
;; `gloss-fetch--strip-html' converts a fragment of HTML to plain text
;; using `libxml-parse-html-region' (no italic/bold preservation).
;; Returns nil when libxml fails on the fragment so the caller can drop
;; that sense.

;;; Code:

(require 'ert)
(require 'gloss-fetch)

(ert-deftest test-gloss-fetch-strip-html-plain-text-roundtrips ()
  "Normal: a string with no markup comes back unchanged (modulo whitespace)."
  (skip-unless (fboundp 'libxml-parse-html-region))
  (should (equal (gloss-fetch--strip-html "Just plain text.")
                 "Just plain text.")))

(ert-deftest test-gloss-fetch-strip-html-removes-tags ()
  "Normal: anchor and span tags are stripped, leaving inner text."
  (skip-unless (fboundp 'libxml-parse-html-region))
  (let ((stripped (gloss-fetch--strip-html
                   "The <a href=\"/foo\">repetition</a> of a <i>phrase</i>.")))
    (should (string-match-p "repetition" stripped))
    (should (string-match-p "phrase" stripped))
    (should-not (string-match-p "<" stripped))
    (should-not (string-match-p "href" stripped))))

(ert-deftest test-gloss-fetch-strip-html-empty-string-returns-empty ()
  "Boundary: empty input returns an empty string (or nil)."
  (skip-unless (fboundp 'libxml-parse-html-region))
  (let ((result (gloss-fetch--strip-html "")))
    (should (or (null result) (equal result "")))))

(ert-deftest test-gloss-fetch-strip-html-entities-decoded ()
  "Boundary: HTML entities decode to their characters."
  (skip-unless (fboundp 'libxml-parse-html-region))
  (let ((stripped (gloss-fetch--strip-html "Smith &amp; Wesson")))
    (should (string-match-p "&" stripped))
    (should-not (string-match-p "&amp;" stripped))))

(ert-deftest test-gloss-fetch-strip-html-collapses-whitespace ()
  "Boundary: runs of internal whitespace collapse to single spaces; result is trimmed."
  (skip-unless (fboundp 'libxml-parse-html-region))
  (let ((stripped (gloss-fetch--strip-html "  hello   <b>world</b>  ")))
    (should (equal stripped "hello world"))))

(ert-deftest test-gloss-fetch-strip-html-failure-returns-nil ()
  "Error: when libxml-parse-html-region raises, return nil so the caller can drop the sense."
  (skip-unless (fboundp 'libxml-parse-html-region))
  (cl-letf (((symbol-function 'libxml-parse-html-region)
             (lambda (&rest _) (error "libxml exploded"))))
    (should-not (gloss-fetch--strip-html "any input"))))

(provide 'test-gloss-fetch--strip-html)
;;; test-gloss-fetch--strip-html.el ends here
