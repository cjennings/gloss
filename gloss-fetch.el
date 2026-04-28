;;; gloss-fetch.el --- Online definition fetcher for gloss -*- lexical-binding: t -*-

;; Copyright (C) 2026 Craig Jennings
;; Author: Craig Jennings <c@cjennings.net>
;; SPDX-License-Identifier: GPL-3.0-or-later

;;; Commentary:

;; Network layer for `gloss'.  Walks a registry of online sources
;; (`gloss-fetch--sources') in the order specified by the user-facing
;; `gloss-fetch-sources' defcustom; aggregates per-source results into
;; a single response shape.
;;
;; Public API:
;;   `gloss-fetch-definitions' TERM
;;     -> (:ok DEFS)                                ; any source returned >=1 def
;;        | (:empty :no-defs (SYM ...) :failed (SYM ...))
;;
;; Each definition is a plist:
;;   (:source SYM :text "Reference to ...")
;;
;; Per-source internal status taxonomy:
;;   :ok :defs (...)   :no-defs   :unreachable   :server-error   :rate-limited
;;
;; libxml is treated as a precondition (probed once at first fetch);
;; absent libxml disables online fetch package-wide for the session.
;;
;; See `docs/design/gloss.org' for the full design.

;;; Code:

(require 'json)
(require 'subr-x)
(require 'url)

(defcustom gloss-fetch-sources '(wiktionary)
  "Ordered list of source symbols consulted by `gloss-fetch-definitions'.
Each symbol must be a key in `gloss-fetch--sources'.  Symbols not
registered there are silently skipped (forward-compat for v2+ sources)."
  :type '(repeat symbol)
  :group 'gloss)

(defcustom gloss-fetch-timeout 5
  "Seconds before a single online fetch is treated as unreachable."
  :type 'integer
  :group 'gloss)

(defconst gloss-fetch--wiktionary-url
  "https://en.wiktionary.org/api/rest_v1/page/definition/%s"
  "URL template for the Wiktionary REST definition endpoint.
The `%s' placeholder receives the URL-encoded term.")

(defvar gloss-fetch--libxml-checked nil
  "Non-nil once the libxml availability probe has run for this session.")

(defvar gloss-fetch--libxml-disabled nil
  "Non-nil when libxml was probed and found absent.
While non-nil, every call to `gloss-fetch-definitions' signals
`user-error' rather than touching the network.")

(defun gloss-fetch--debug (fmt &rest args)
  "Append a formatted line to *gloss-debug* when `gloss-debug' is non-nil.
FMT and ARGS are passed to `format'."
  (when (and (boundp 'gloss-debug) gloss-debug)
    (with-current-buffer (get-buffer-create "*gloss-debug*")
      (goto-char (point-max))
      (insert (format-time-string "%Y-%m-%d %H:%M:%S "))
      (insert (apply #'format fmt args))
      (insert "\n"))))

(defun gloss-fetch--libxml-available-p ()
  "Return non-nil when `libxml-parse-html-region' is bound and functional."
  (and (fboundp 'libxml-parse-html-region)
       (with-temp-buffer
         (insert "<p>x</p>")
         (condition-case _err
             (and (libxml-parse-html-region (point-min) (point-max)) t)
           (error nil)))))

(defun gloss-fetch--ensure-libxml ()
  "Probe libxml on first call; disable online fetching for the session if absent.
Signals `user-error' when libxml is unavailable."
  (unless gloss-fetch--libxml-checked
    (setq gloss-fetch--libxml-checked t)
    (unless (gloss-fetch--libxml-available-p)
      (setq gloss-fetch--libxml-disabled t)))
  (when gloss-fetch--libxml-disabled
    (user-error
     "Online fetch requires Emacs built with libxml2; manual add still works")))

(defun gloss-fetch--strip-html (html)
  "Return plain-text contents of HTML, with whitespace collapsed and trimmed.
Returns nil if `libxml-parse-html-region' raises an error so the caller
can drop that sense.  Empty input returns the empty string."
  (when (stringp html)
    (if (string-empty-p html)
        ""
      (condition-case err
          (with-temp-buffer
            (insert html)
            (let* ((tree (libxml-parse-html-region (point-min) (point-max)))
                   (text (gloss-fetch--dom-text tree)))
              (gloss-fetch--collapse-whitespace text)))
        (error
         (gloss-fetch--debug "[fetch] strip-html error: %s"
                             (error-message-string err))
         nil)))))

(defun gloss-fetch--dom-text (node)
  "Return the concatenated text content of NODE, an `libxml' DOM node."
  (cond
   ((null node) "")
   ((stringp node) node)
   ((listp node)
    ;; Node shape: (TAG ATTRS . CHILDREN).  Skip TAG and ATTRS.
    (mapconcat #'gloss-fetch--dom-text (cddr node) ""))
   (t "")))

(defun gloss-fetch--collapse-whitespace (s)
  "Collapse runs of whitespace in S to single spaces and trim."
  (string-trim
   (replace-regexp-in-string "[ \t\n\r]+" " " s)))

(defun gloss-fetch--http-status (buf)
  "Return the HTTP status code as an integer from response buffer BUF, or nil."
  (with-current-buffer buf
    (save-excursion
      (goto-char (point-min))
      (when (re-search-forward "^HTTP/[0-9.]+[ \t]+\\([0-9]+\\)" nil t)
        (string-to-number (match-string 1))))))

(defun gloss-fetch--http-body (buf)
  "Return the body of response buffer BUF as a UTF-8 decoded string.
The body is everything after the first blank line (end of headers)."
  (with-current-buffer buf
    (save-excursion
      (goto-char (point-min))
      (if (re-search-forward "^\r?$" nil t)
          (let ((raw (buffer-substring-no-properties (1+ (point)) (point-max))))
            (decode-coding-string raw 'utf-8))
        ""))))

(defun gloss-fetch--url-encode (term)
  "Return TERM URL-encoded for use as a Wiktionary REST path segment."
  (url-hexify-string term))

(defun gloss-fetch--retrieve (url)
  "GET URL synchronously honoring `gloss-fetch-timeout'.
Returns the response buffer on success.  Returns the symbol
`:unreachable' when the call returns nil (timeout) or signals an
error (DNS, connection refused)."
  (condition-case err
      (let ((url-request-method "GET")
            (buf (url-retrieve-synchronously url t t gloss-fetch-timeout)))
        (or buf :unreachable))
    (error
     (gloss-fetch--debug "[fetch] retrieve error: %s"
                         (error-message-string err))
     :unreachable)))

(defun gloss-fetch--classify-status (code)
  "Map an HTTP status CODE to a per-source status symbol."
  (cond
   ((null code) :server-error)
   ((and (>= code 200) (< code 300)) :ok)
   ((= code 404) :no-defs)
   ((= code 429) :rate-limited)
   ((and (>= code 500) (< code 600)) :server-error)
   (t :server-error)))

(defun gloss-fetch--parse-json (body)
  "Parse JSON BODY into a plist-shaped value.
Returns the parsed object or signals an error if BODY is malformed."
  (let ((json-object-type 'alist)
        (json-array-type 'list)
        (json-key-type 'string)
        (json-false nil)
        (json-null nil))
    (json-read-from-string body)))

(defun gloss-fetch--wiktionary-extract-defs (parsed)
  "Return a list of definition plists from PARSED Wiktionary JSON.
Only English (`en') entries contribute.  Each yielded plist has
:source `wiktionary' and :text (HTML-stripped, whitespace-collapsed).
Empty stripped strings and senses where strip fails are dropped."
  (let ((english (cdr (assoc "en" parsed)))
        (defs nil))
    (dolist (section english)
      (let ((senses (cdr (assoc "definitions" section))))
        (dolist (sense senses)
          (let* ((html (cdr (assoc "definition" sense)))
                 (text (and (stringp html)
                            (gloss-fetch--strip-html html))))
            (when (and text (not (string-empty-p text)))
              (push (list :source 'wiktionary :text text) defs))))))
    (nreverse defs)))

(defun gloss-fetch--fetch-wiktionary (term)
  "Fetch TERM from Wiktionary; return a per-source result plist.
The returned plist has :source `wiktionary', :status, and either
:defs (on :ok) or :reason (on every other status)."
  (let* ((url (format gloss-fetch--wiktionary-url
                      (gloss-fetch--url-encode term)))
         (buf-or-status (gloss-fetch--retrieve url)))
    (cond
     ((eq buf-or-status :unreachable)
      (list :source 'wiktionary :status :unreachable
            :reason (format "timeout (%ss) or unreachable" gloss-fetch-timeout)))
     (t
      (unwind-protect
          (let* ((code (gloss-fetch--http-status buf-or-status))
                 (status (gloss-fetch--classify-status code)))
            (gloss-fetch--debug "[fetch:wiktionary] GET %s -> %S" url code)
            (cond
             ((eq status :ok)
              (gloss-fetch--wiktionary-build-ok-result buf-or-status code))
             (t
              (list :source 'wiktionary :status status
                    :reason (format "HTTP %s" code)))))
        (when (buffer-live-p buf-or-status)
          (kill-buffer buf-or-status)))))))

(defun gloss-fetch--wiktionary-build-ok-result (buf code)
  "Inspect a 200 response BUF and return a per-source result plist.
CODE is the HTTP status (passed through to :reason on failure paths)."
  (let ((body (gloss-fetch--http-body buf)))
    (condition-case err
        (let* ((parsed (gloss-fetch--parse-json body))
               (defs (gloss-fetch--wiktionary-extract-defs parsed)))
          (if defs
              (list :source 'wiktionary :status :ok :defs defs)
            (list :source 'wiktionary :status :no-defs
                  :reason (format "HTTP %s, no English senses" code))))
      (error
       (list :source 'wiktionary :status :server-error
             :reason (format "malformed JSON: %s"
                             (error-message-string err)))))))

(defvar gloss-fetch--sources
  `((wiktionary . ,#'gloss-fetch--fetch-wiktionary))
  "Alist mapping source symbol to a fetcher function.
Each fetcher accepts TERM and returns a per-source result plist of the
shape (:source SYM :status STATUS [:defs DEFS] [:reason STRING]).")

(defun gloss-fetch--collect (term)
  "Walk every entry of `gloss-fetch-sources' that maps to a fetcher.
Return the per-source results in walk order.  Symbols not registered
in `gloss-fetch--sources' are silently skipped."
  (let (results)
    (dolist (sym gloss-fetch-sources)
      (let ((fetcher (cdr (assq sym gloss-fetch--sources))))
        (when fetcher
          (push (funcall fetcher term) results))))
    (nreverse results)))

(defun gloss-fetch--rollup (per-source)
  "Roll up PER-SOURCE results into the user-facing response shape.
Returns (:ok DEFS) when any source returned :ok with non-empty :defs.
Otherwise returns (:empty :no-defs (...) :failed (...))."
  (let (ok-defs no-defs failed)
    (dolist (entry per-source)
      (let ((sym (plist-get entry :source))
            (status (plist-get entry :status)))
        (cond
         ((and (eq status :ok) (plist-get entry :defs))
          (setq ok-defs (append ok-defs (plist-get entry :defs))))
         ((eq status :no-defs)
          (push sym no-defs))
         ((memq status '(:unreachable :server-error :rate-limited))
          (push sym failed)))))
    (if ok-defs
        (list :ok ok-defs)
      (list :empty
            :no-defs (nreverse no-defs)
            :failed (nreverse failed)))))

(defun gloss-fetch-definitions (term)
  "Fetch candidate definitions for TERM from each source in `gloss-fetch-sources'.
Returns (:ok DEFS) when any source returns at least one definition,
otherwise (:empty :no-defs (SYM ...) :failed (SYM ...)).  Signals
`user-error' the first time it runs in a session without libxml, and
on every subsequent call in that session."
  (gloss-fetch--ensure-libxml)
  (gloss-fetch--rollup (gloss-fetch--collect term)))

(provide 'gloss-fetch)
;;; gloss-fetch.el ends here
