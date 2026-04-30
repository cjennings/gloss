;;; test-gloss-display--show-entry-smoke.el --- Smoke test for gloss-display-show-entry -*- lexical-binding: t -*-

;; SPDX-License-Identifier: GPL-3.0-or-later

;;; Commentary:
;; Smoke test for `gloss-display-show-entry'.  Exercises the side-buffer
;; setup end to end: buffer creation, content rendering, mode activation,
;; and the read-only invariant.  Per the design and project testing rules,
;; framework primitives like `display-buffer' and major-mode mechanics are
;; not re-tested.

;;; Code:

(require 'ert)
(require 'cl-lib)
(require 'gloss-display)

(defmacro gloss-test--with-display-buffer-mocked (&rest body)
  "Run BODY with `display-buffer' replaced by a no-op.
Avoids opening a real side window during batch tests, while still letting
`gloss-display-show-entry' populate and configure the entry buffer."
  (declare (indent 0) (debug t))
  `(cl-letf (((symbol-function 'display-buffer)
              (lambda (buffer &rest _args) (get-buffer buffer))))
     ,@body))

(ert-deftest test-gloss-display-show-entry-creates-buffer-with-mode-and-content ()
  "Smoke: show-entry creates a named buffer in `gloss-mode' with the entry."
  (gloss-test--with-display-buffer-mocked
    (unwind-protect
        (let ((buf (gloss-display-show-entry
                    "anaphora"
                    "Reference to something earlier in the discourse.")))
          (should (buffer-live-p buf))
          (with-current-buffer buf
            (should (derived-mode-p 'gloss-mode))
            (should buffer-read-only)
            (let ((contents (buffer-substring-no-properties
                             (point-min) (point-max))))
              (should (string-match-p "anaphora" contents))
              (should (string-match-p "Reference to something earlier"
                                      contents)))))
      (when-let ((buf (get-buffer "*gloss: anaphora*")))
        (let ((kill-buffer-query-functions nil))
          (kill-buffer buf))))))

(provide 'test-gloss-display--show-entry-smoke)
;;; test-gloss-display--show-entry-smoke.el ends here
