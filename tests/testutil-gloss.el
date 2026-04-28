;;; testutil-gloss.el --- Shared test fixtures for gloss -*- lexical-binding: t -*-

;; SPDX-License-Identifier: GPL-3.0-or-later

;;; Commentary:

;; Fixtures used across gloss test files.  Provides:
;;   - `gloss-test--with-temp-glossary' macro (binds `gloss-file', cleans up).
;;   - `gloss-test--sample-content' two-entry org content.
;;   - `gloss-test--make-temp-glossary-file' for cases that need direct paths.

;;; Code:

(require 'gloss-core)

(defconst gloss-test--sample-content
  "#+TITLE: Glossary
#+STARTUP: showall

* anaphora
:PROPERTIES:
:SOURCE:   wiktionary
:ADDED:    2026-04-28
:END:
Reference to something earlier in the discourse.

* SBIR
:PROPERTIES:
:SOURCE:   wiktionary
:ADDED:    2026-04-27
:END:
Initialism of Small Business Innovation Research.
"
  "Two-entry sample content for tests that need a populated glossary.")

(defun gloss-test--make-temp-glossary-file (&optional initial-content)
  "Create a temp file with INITIAL-CONTENT (or empty) and return its path.
The caller is responsible for cleanup."
  (let ((path (make-temp-file "gloss-test-" nil ".org")))
    (when initial-content
      (with-temp-file path (insert initial-content)))
    path))

(defmacro gloss-test--with-temp-glossary (initial-content &rest body)
  "Bind `gloss-file' to a fresh temp file containing INITIAL-CONTENT.
Reset the in-memory cache before BODY and after.  Clean up file and any
visiting buffer."
  (declare (indent 1) (debug t))
  `(let ((gloss-file (gloss-test--make-temp-glossary-file ,initial-content)))
     (unwind-protect
         (progn
           (gloss-core--cache-reset)
           ,@body)
       (gloss-core--cache-reset)
       (when-let ((buf (find-buffer-visiting gloss-file)))
         (with-current-buffer buf (set-buffer-modified-p nil))
         (kill-buffer buf))
       (when (file-exists-p gloss-file)
         (delete-file gloss-file)))))

(defmacro gloss-test--with-missing-glossary (&rest body)
  "Bind `gloss-file' to a path that does not yet exist; run BODY.
Reset the in-memory cache before BODY and after.  Clean up the file and
any visiting buffer if BODY created them."
  (declare (indent 0) (debug t))
  `(let ((gloss-file (concat temporary-file-directory "gloss-missing-"
                              (number-to-string (random 100000)) ".org")))
     (unwind-protect
         (progn
           (gloss-core--cache-reset)
           ,@body)
       (gloss-core--cache-reset)
       (when-let ((buf (find-buffer-visiting gloss-file)))
         (with-current-buffer buf (set-buffer-modified-p nil))
         (kill-buffer buf))
       (when (file-exists-p gloss-file)
         (delete-file gloss-file)))))

(defconst gloss-test--testutil-dir
  (file-name-directory (or load-file-name buffer-file-name default-directory))
  "Directory of this testutil file; used to locate fixtures.")

(defun gloss-test--load-wiktionary-fixture (name)
  "Return the raw JSON body of fixture `wiktionary-NAME.json' as a string.
NAME is the fixture name without the `wiktionary-' prefix or `.json'
suffix (e.g. \"anaphora\").  Fixtures live in tests/fixtures/ alongside
this file.  Signal `error' with the full path if the file is missing."
  (let ((path (expand-file-name (format "fixtures/wiktionary-%s.json" name)
                                gloss-test--testutil-dir)))
    (unless (file-exists-p path)
      (error "Wiktionary fixture not found: %s" path))
    (with-temp-buffer
      (insert-file-contents path)
      (buffer-string))))

(provide 'testutil-gloss)
;;; testutil-gloss.el ends here
