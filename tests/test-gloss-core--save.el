;;; test-gloss-core--save.el --- Tests for gloss-core-save -*- lexical-binding: t -*-

;; SPDX-License-Identifier: GPL-3.0-or-later

;;; Commentary:
;; Tests for `gloss-core-save' covering Normal/Boundary/Error cases.

;;; Code:

(require 'ert)
(require 'gloss-core)
(require 'testutil-gloss)

(ert-deftest test-gloss-core-save-new-term-returns-entry-plist ()
  "Normal: save new term returns the entry plist with all fields."
  (gloss-test--with-temp-glossary "#+TITLE: Glossary\n"
    (let ((entry (gloss-core-save "anaphora" "Reference to..." 'wiktionary)))
      (should entry)
      (should (equal (plist-get entry :term) "anaphora"))
      (should (equal (plist-get entry :body) "Reference to..."))
      (should (eq (plist-get entry :source) 'wiktionary))
      (should (stringp (plist-get entry :added))))))

(ert-deftest test-gloss-core-save-then-lookup-roundtrip ()
  "Normal: save then lookup returns the matching entry."
  (gloss-test--with-temp-glossary "#+TITLE: Glossary\n"
    (gloss-core-save "anaphora" "Reference to something earlier." 'wiktionary)
    (let ((entry (gloss-core-lookup "anaphora")))
      (should entry)
      (should (equal (plist-get entry :body)
                     "Reference to something earlier.")))))

(ert-deftest test-gloss-core-save-multi-line-body-preserved ()
  "Boundary: save preserves a multi-line body."
  (gloss-test--with-temp-glossary "#+TITLE: Glossary\n"
    (let ((body "First paragraph.\n\nSecond paragraph."))
      (gloss-core-save "term" body 'manual)
      (let ((entry (gloss-core-lookup "term")))
        (should (equal (plist-get entry :body) body))))))

(ert-deftest test-gloss-core-save-empty-body-raises-error ()
  "Error: empty body raises a user-error."
  (gloss-test--with-temp-glossary "#+TITLE: Glossary\n"
    (should-error (gloss-core-save "anaphora" "" 'wiktionary)
                  :type 'user-error)))

(ert-deftest test-gloss-core-save-empty-term-raises-error ()
  "Error: empty term raises a user-error."
  (gloss-test--with-temp-glossary "#+TITLE: Glossary\n"
    (should-error (gloss-core-save "" "Some body" 'wiktionary)
                  :type 'user-error)))

(ert-deftest test-gloss-core-save-collision-replace-overwrites ()
  "Error: collision with action \\='replace overwrites the body and source."
  (gloss-test--with-temp-glossary "#+TITLE: Glossary\n"
    (gloss-core-save "anaphora" "First definition." 'wiktionary)
    (gloss-core-save "anaphora" "Second definition." 'manual 'replace)
    (let ((entry (gloss-core-lookup "anaphora")))
      (should (equal (plist-get entry :body) "Second definition."))
      (should (eq (plist-get entry :source) 'manual)))))

(ert-deftest test-gloss-core-save-collision-append-joins-bodies ()
  "Error: collision with action \\='append concatenates the bodies."
  (gloss-test--with-temp-glossary "#+TITLE: Glossary\n"
    (gloss-core-save "anaphora" "First definition." 'wiktionary)
    (gloss-core-save "anaphora" "Second definition." 'manual 'append)
    (let ((entry (gloss-core-lookup "anaphora")))
      (should (string-match-p "First definition" (plist-get entry :body)))
      (should (string-match-p "Second definition" (plist-get entry :body))))))

(ert-deftest test-gloss-core-save-collision-cancel-leaves-original ()
  "Error: collision with action \\='cancel leaves the original entry."
  (gloss-test--with-temp-glossary "#+TITLE: Glossary\n"
    (gloss-core-save "anaphora" "First definition." 'wiktionary)
    (let ((result (gloss-core-save "anaphora" "Second definition."
                                   'manual 'cancel)))
      (should-not result))
    (let ((entry (gloss-core-lookup "anaphora")))
      (should (equal (plist-get entry :body) "First definition.")))))

(provide 'test-gloss-core--save)
;;; test-gloss-core--save.el ends here
