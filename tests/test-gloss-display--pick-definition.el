;;; test-gloss-display--pick-definition.el --- Tests for gloss-display-pick-definition -*- lexical-binding: t -*-

;; SPDX-License-Identifier: GPL-3.0-or-later

;;; Commentary:
;; Tests for `gloss-display-pick-definition' covering Normal/Boundary/Error
;; cases.  The picker mocks `completing-read' at the boundary; the function
;; under test is responsible for building the alist of formatted-string ->
;; plist and mapping the user's choice back to the chosen plist.

;;; Code:

(require 'ert)
(require 'cl-lib)
(require 'gloss-display)

(defmacro gloss-test--with-completing-read (return-value &rest body)
  "Run BODY with `completing-read' mocked to return RETURN-VALUE.
If RETURN-VALUE is the symbol `quit', simulate the user pressing C-g
by signalling `quit' inside the mock."
  (declare (indent 1) (debug t))
  `(cl-letf (((symbol-function 'completing-read)
              (lambda (&rest _args)
                ,(if (eq return-value 'quit)
                     '(signal 'quit nil)
                   return-value))))
     ,@body))

(ert-deftest test-gloss-display-pick-definition-normal-pick-first-of-three ()
  "Normal: choosing the first row returns the first definition plist."
  (let* ((def1 '(:source wiktionary :text "First sense."))
         (def2 '(:source wiktionary :text "Second sense."))
         (def3 '(:source wiktionary :text "Third sense."))
         (defs (list def1 def2 def3))
         (chosen-row (gloss-display--format-candidate def1)))
    (gloss-test--with-completing-read chosen-row
      (should (equal (gloss-display-pick-definition "term" defs) def1)))))

(ert-deftest test-gloss-display-pick-definition-normal-pick-middle-of-three ()
  "Normal: choosing the middle row returns the middle definition plist."
  (let* ((def1 '(:source wiktionary :text "First sense."))
         (def2 '(:source wiktionary :text "Second sense."))
         (def3 '(:source wiktionary :text "Third sense."))
         (defs (list def1 def2 def3))
         (chosen-row (gloss-display--format-candidate def2)))
    (gloss-test--with-completing-read chosen-row
      (should (equal (gloss-display-pick-definition "term" defs) def2)))))

(ert-deftest test-gloss-display-pick-definition-boundary-single-definition ()
  "Boundary: a single-definition list still returns that plist."
  (let* ((def '(:source wiktionary :text "Only sense."))
         (chosen-row (gloss-display--format-candidate def)))
    (gloss-test--with-completing-read chosen-row
      (should (equal (gloss-display-pick-definition "term" (list def))
                     def)))))

(ert-deftest test-gloss-display-pick-definition-boundary-empty-list ()
  "Boundary: an empty definition list returns nil without prompting."
  (let ((completing-read-called nil))
    (cl-letf (((symbol-function 'completing-read)
               (lambda (&rest _args)
                 (setq completing-read-called t) "")))
      (should-not (gloss-display-pick-definition "term" nil))
      (should-not completing-read-called))))

(ert-deftest test-gloss-display-pick-definition-error-quit-returns-nil ()
  "Error: C-g during the picker (quit signal) returns nil, not propagate."
  (let ((def '(:source wiktionary :text "Only sense.")))
    (gloss-test--with-completing-read quit
      (should-not (gloss-display-pick-definition "term" (list def))))))

(ert-deftest test-gloss-display-pick-definition-prompt-mentions-term ()
  "Normal: the completing-read prompt names the term being disambiguated."
  (let* ((captured-prompt nil)
         (def '(:source wiktionary :text "Only sense."))
         (chosen-row (gloss-display--format-candidate def)))
    (cl-letf (((symbol-function 'completing-read)
               (lambda (prompt &rest _args)
                 (setq captured-prompt prompt)
                 chosen-row)))
      (gloss-display-pick-definition "anaphora" (list def))
      (should (string-match-p "anaphora" captured-prompt)))))

(provide 'test-gloss-display--pick-definition)
;;; test-gloss-display--pick-definition.el ends here
