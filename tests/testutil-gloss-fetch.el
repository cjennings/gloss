;;; testutil-gloss-fetch.el --- Test helpers for gloss-fetch -*- lexical-binding: t -*-

;; SPDX-License-Identifier: GPL-3.0-or-later

;;; Commentary:

;; Helpers for tests that exercise `gloss-fetch'.  The boundary mock is
;; `url-retrieve-synchronously', so these helpers build response buffers
;; in the shape Emacs's url library returns: status line, blank line,
;; body.  The body comes from a JSON fixture loaded via
;; `gloss-test--load-wiktionary-fixture' (provided by testutil-gloss.el
;; on a parallel branch).

;;; Code:

(defun gloss-fetch-test--make-response-buffer (status-line body)
  "Return a fresh buffer containing STATUS-LINE, a blank line, and BODY.
STATUS-LINE is an HTTP status line such as \"HTTP/1.1 200 OK\".  BODY
is the response body as a string.  The buffer is unibyte so that
multibyte handling is exercised end-to-end."
  (let ((buf (generate-new-buffer " *gloss-fetch-test-response*")))
    (with-current-buffer buf
      (set-buffer-multibyte nil)
      (insert status-line "\n")
      (insert "Content-Type: application/json\n")
      (insert "\n")
      (insert (encode-coding-string (or body "") 'utf-8)))
    buf))

(defmacro gloss-fetch-test--with-mocked-url (response-fn &rest body)
  "Run BODY with `url-retrieve-synchronously' replaced by RESPONSE-FN.
RESPONSE-FN takes the URL string and returns either a buffer (the
response) or nil (to simulate timeout / unreachable)."
  (declare (indent 1) (debug t))
  `(cl-letf (((symbol-function 'url-retrieve-synchronously)
              (lambda (url &rest _args) (funcall ,response-fn url))))
     ,@body))

(defun gloss-fetch-test--ok-response (body)
  "Return a 200 OK response buffer with BODY."
  (gloss-fetch-test--make-response-buffer "HTTP/1.1 200 OK" body))

(defun gloss-fetch-test--status-response (status-line &optional body)
  "Return a response buffer with STATUS-LINE and optional BODY (default empty)."
  (gloss-fetch-test--make-response-buffer status-line (or body "")))

(provide 'testutil-gloss-fetch)
;;; testutil-gloss-fetch.el ends here
