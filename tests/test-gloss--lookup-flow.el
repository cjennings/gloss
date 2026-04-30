;;; test-gloss--lookup-flow.el --- Tests for gloss--lookup-flow -*- lexical-binding: t -*-

;; SPDX-License-Identifier: GPL-3.0-or-later

;;; Commentary:
;; Tests for the internal `gloss--lookup-flow' that orchestrates
;; cache lookup, online fetch, picker, and persistence.
;;
;; Mocks are at the boundaries: `gloss-fetch-definitions' (network
;; call), `gloss-display-show-entry' / `gloss-display-pick-definition'
;; (UI side effects).  Persistence (`gloss-core-save') is exercised
;; against a real temp glossary so the save side effect is validated
;; end-to-end.

;;; Code:

(require 'ert)
(require 'cl-lib)
(require 'gloss)
(require 'testutil-gloss)

(ert-deftest test-gloss-lookup-flow-cache-hit-shows-cached-and-skips-fetch ()
  "Normal: cache hit shows the cached body, never fetches, returns :show."
  (gloss-test--with-temp-glossary gloss-test--sample-content
    (let (shown)
      (cl-letf (((symbol-function 'gloss-fetch-definitions)
                 (lambda (&rest _) (error "fetch must not be called on cache hit")))
                ((symbol-function 'gloss-display-show-entry)
                 (lambda (term body) (setq shown (list term body)))))
        (should (eq (gloss--lookup-flow "anaphora") :show))
        (should (equal (car shown) "anaphora"))
        (should (string-match-p "Reference to something earlier"
                                (cadr shown)))))))

(ert-deftest test-gloss-lookup-flow-cache-miss-single-def-auto-saves ()
  "Normal: cache miss + 1 def auto-saves, shows entry, returns :auto-save."
  (gloss-test--with-missing-glossary
    (let* ((def '(:source wiktionary :text "The lone definition."))
           (result (list :defs (list def) :no-defs nil :failed nil)))
      (cl-letf (((symbol-function 'gloss-fetch-definitions)
                 (lambda (_) result))
                ((symbol-function 'gloss-display-show-entry)
                 (lambda (_ _) nil)))
        (should (eq (gloss--lookup-flow "newterm") :auto-save))
        (let ((saved (gloss-core-lookup "newterm")))
          (should saved)
          (should (equal (plist-get saved :body) "The lone definition."))
          (should (eq (plist-get saved :source) 'wiktionary)))))))

(ert-deftest test-gloss-lookup-flow-cache-miss-multi-def-picks-and-saves ()
  "Normal: cache miss + multi-def calls picker, saves chosen, returns :pick."
  (gloss-test--with-missing-glossary
    (let* ((d1 '(:source wiktionary :text "First sense."))
           (d2 '(:source wiktionary :text "Second sense."))
           (result (list :defs (list d1 d2) :no-defs nil :failed nil)))
      (cl-letf (((symbol-function 'gloss-fetch-definitions)
                 (lambda (_) result))
                ((symbol-function 'gloss-display-pick-definition)
                 (lambda (_term _defs) d2))
                ((symbol-function 'gloss-display-show-entry)
                 (lambda (_ _) nil)))
        (should (eq (gloss--lookup-flow "API") :pick))
        (let ((saved (gloss-core-lookup "API")))
          (should saved)
          (should (equal (plist-get saved :body) "Second sense.")))))))

(ert-deftest test-gloss-lookup-flow-multi-def-cancelled-leaves-no-save ()
  "Boundary: cancelled picker (returns nil) leaves no save, still returns :pick."
  (gloss-test--with-missing-glossary
    (let* ((d1 '(:source wiktionary :text "A."))
           (d2 '(:source wiktionary :text "B."))
           (result (list :defs (list d1 d2) :no-defs nil :failed nil))
           (show-called nil))
      (cl-letf (((symbol-function 'gloss-fetch-definitions)
                 (lambda (_) result))
                ((symbol-function 'gloss-display-pick-definition)
                 (lambda (_term _defs) nil))
                ((symbol-function 'gloss-display-show-entry)
                 (lambda (_ _) (setq show-called t))))
        (should (eq (gloss--lookup-flow "X") :pick))
        (should-not show-called)
        (should-not (gloss-core-lookup "X"))))))

(ert-deftest test-gloss-lookup-flow-no-defs-returns-error-no-defs ()
  "Error: cache miss + empty result + only :no-defs returns :error-no-defs."
  (gloss-test--with-missing-glossary
    (cl-letf (((symbol-function 'gloss-fetch-definitions)
               (lambda (_)
                 (list :defs nil :no-defs '(wiktionary) :failed nil))))
      (should (eq (gloss--lookup-flow "X") :error-no-defs))
      (should-not (gloss-core-lookup "X")))))

(ert-deftest test-gloss-lookup-flow-force-fetch-bypasses-cache ()
  "Normal: force-fetch arg t skips cache hit and fetches, replacing entry."
  (gloss-test--with-temp-glossary gloss-test--sample-content
    (let* ((fresh '(:source wiktionary :text "Replacement body."))
           (result (list :defs (list fresh) :no-defs nil :failed nil))
           (fetch-called nil))
      (cl-letf (((symbol-function 'gloss-fetch-definitions)
                 (lambda (_) (setq fetch-called t) result))
                ((symbol-function 'gloss-display-show-entry)
                 (lambda (_ _) nil)))
        (should (eq (gloss--lookup-flow "anaphora" t) :auto-save))
        (should fetch-called)
        (let ((entry (gloss-core-lookup "anaphora")))
          (should (equal (plist-get entry :body) "Replacement body.")))))))

(provide 'test-gloss--lookup-flow)
;;; test-gloss--lookup-flow.el ends here
