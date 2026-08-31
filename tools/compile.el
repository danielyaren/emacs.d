;;; compile.el --- Byte-compile the packages in lib/ -*- lexical-binding: t; -*-
;;; Commentary:

;; Copyright (C) 2021 Daniel Yaren

;; Author: Daniel Yaren

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;; Meant to be run from the repository root through `make compile'.  Set the
;; FORCE environment variable to recompile files whose byte-code is current.

;;; Code:

(require 'bytecomp)
(require 'lisp-mnt)

(defconst compile-lib-dirs
  '("lib/compat"
    "lib/dash"
    "lib/s"
    "lib/llama"
    "lib/cond-let"
    "lib/spinner"
    "lib/transient/lisp"
    "lib/with-editor/lisp"
    "lib/emacs-request"
    "lib/emacs-async"
    "lib/wgrep"
    "lib/avy"
    "lib/ace-window"
    "lib/vertico"
    "lib/marginalia"
    "lib/orderless"
    "lib/consult"
    "lib/corfu"
    "lib/corfu/extensions"
    "lib/magit/lisp"
    "lib/deft"
    "lib/git-auto-commit-mode")
  "Directories to compile, ordered so macros are compiled before their users.
Mirrors the `:load-path' entries used by `use-package' in init.el.")

(defun compile-directories ()
  "Return the existing directories among `compile-lib-dirs'."
  (let (dirs)
    (dolist (dir compile-lib-dirs (nreverse dirs))
      (let ((full (expand-file-name dir)))
        (if (file-directory-p full)
            (push full dirs)
          (message "Skipping missing %s, run: git submodule update --init --recursive"
                   dir))))))

(defun compile-requirements (file)
  "Return the `Package-Requires' entries declared by FILE."
  (with-temp-buffer
    (insert-file-contents file)
    (let ((header (lm-header-multiline "package-requires")))
      (when header
        (ignore-errors (read (mapconcat #'identity header " ")))))))

(defun compile-emacs-requirement (files)
  "Return the highest Emacs version any of FILES asks for.
A package is written against one Emacs version, so the whole directory is
left alone when this one is too new: only some of its files spell the
requirement out, the rest would fail with confusing errors."
  (let ((required "0"))
    (dolist (file files required)
      (dolist (requirement (compile-requirements file))
        (let ((version (cadr requirement)))
          (when (and (eq (car requirement) 'emacs)
                     (stringp version)
                     (version< required version))
            (setq required version)))))))

(defun compile-skip-reason (file)
  "Return a string telling why FILE cannot be compiled here, or nil."
  (let ((reason (when (string-match-p "-\\(?:sub\\)?tests?\\.el\\'" file)
                  "is a test file")))
    (dolist (requirement (compile-requirements file) reason)
      (let ((package (format "%s" (car requirement))))
        (unless (or (equal package "emacs") (locate-library package))
          (setq reason (format "needs the %s package" package)))))))

(defun compile-stale-p (file)
  "Return non-nil when the byte-code of FILE is missing or out of date."
  (let ((dest (byte-compile-dest-file file)))
    (or (not (file-exists-p dest))
        (file-newer-than-file-p file dest))))

(defun compile-plan (dirs force)
  "Return the files of DIRS that should be compiled, reporting the others.
With FORCE, files whose byte-code is already current are included too.
The whole plan is made before anything is compiled: loading a package as
a side effect of compiling another one can change how the headers read."
  (let (plan)
    (dolist (dir dirs (nreverse plan))
      (let* ((files (directory-files dir t "\\`[^.].*\\.el\\'"))
             (required (compile-emacs-requirement files)))
        (if (version< emacs-version required)
            (message "Skipping %s, it needs Emacs %s" (file-relative-name dir) required)
          (dolist (file files)
            (let ((reason (compile-skip-reason file)))
              (cond (reason
                     (message "Skipping %s, it %s" (file-relative-name file) reason))
                    ((or force (compile-stale-p file))
                     (push file plan))))))))))

(defun compile-lib ()
  "Byte-compile every package directory in `compile-lib-dirs'."
  (let ((dirs (compile-directories))
        (compiled 0)
        (failed 0))
    ;; Ahead of the built-in directories, as `use-package' does in init.el:
    ;; several of these packages also ship with Emacs, in an older version.
    (setq load-path (append dirs load-path))
    (dolist (file (compile-plan dirs (getenv "FORCE")))
      (pcase (byte-compile-file file)
        ('t (setq compiled (1+ compiled)))
        ('no-byte-compile nil)
        (_ (setq failed (1+ failed))
           (message "Failed to compile %s" (file-relative-name file)))))
    (message "Byte-compiled %d file(s), %d failure(s)" compiled failed)
    (kill-emacs (if (zerop failed) 0 1))))

(compile-lib)

;;; compile.el ends here
