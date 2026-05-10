;;; init.el --- This is where emacs starts.
;;; -*- lexical-binding: t; -*-
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

;;; Code:

;; The emacs directory.
(defvar emacs-dir
  (eval-when-compile (file-truename user-emacs-directory))
  "The path to the .emacs.d directory. Must end with a slash.")


;; In noninteractive sessions, prioritize non-byte-compiled source files to
;; prevent the use of stale byte-code. Otherwise, it saves us a little IO time
;; to skip the mtime checks on every *.elc file we load.
(setq load-prefer-newer noninteractive)

;; Make apropos omnipotent.
(defvar apropos-do-all t)

;; Org-dir for notes.
(defvar org-dir nil)

;; Don't make a second case-insensitive pass over `auto-mode-alist'.
(setq auto-mode-case-fold nil)

;; Disable bidirectional text rendering for a modest performance boost. Of
;; course, this renders Emacs unable to detect/display right-to-left languages
;; (sorry!), but for us left-to-right language speakers/writers, it's a boon.
(setq-default bidi-paragraph-direction 'left-to-right)
(setq bidi-inhibit-bpa t)

;; Don't ping things that look like domain names.
(setq ffap-machine-p-known 'reject)

;; Resolve symlinks when opening files, so that any operations are conducted
;; from the file's true directory (like `find-file').
(setq find-file-visit-truename t)

;; Compilation mode tweaks.
(setq compilation-always-kill t
      compilation-ask-about-save nil)

;; Try to keep things organised.
(setq backup-directory-alist '(("." . "~/.emacs-saves")))
(setq save-place-file "~/.emacs-save-place")
(save-place-mode 1)

(with-eval-after-load 'dired
  (setq dired-listing-switches "-alh"
        dired-recursive-copies 'always
        dired-recursive-deletes 'always)
  (add-hook 'dired-mode-hook 'auto-revert-mode))

(with-eval-after-load 'dired-x
  (setq dired-omit-extensions nil))

;; Modern editor behavior.
(delete-selection-mode 1)

;; Middle-click paste at location.
(setq mouse-yank-at-point t)

;; Automatically update a buffer.
(global-auto-revert-mode 1)

;; Eliminate duplicates in the kill ring. That is, if you kill the
;; same thing twice, you won't have to use M-y twice to get past it
;; to older entries in the kill ring.
(setq kill-do-not-save-duplicates t)

;; Some editing visuals.
(setq blink-matching-paren nil
      visible-cursor nil
      x-stretch-cursor nil)

;; Smoother scrolling.
(setq scroll-margin 1
      scroll-step 1
      scroll-conservatively 10000
      scroll-preserve-screen-position 1)

;; Nicer line spacing.
(setq-default line-spacing 3)

;; Whether to add a newline.
(setq mode-require-final-newline nil)

;; Obviously
(setq-default sentence-end-double-space nil)

;; Matching pairs!
(show-paren-mode 1)

;; Indentation
(setq-default tab-width 2
              js-indent-level 2
              tab-always-indent t
              indent-tabs-mode nil
              fill-column 80)

(setq-default sentence-end-double-space nil
              delete-trailing-lines nil
              require-final-newline t
              tabify-regexp "^\t* [ \t]+")

;; Mode to trigger indentation.
(electric-indent-mode +1)

;; Insert matching delimiters.
(electric-pair-mode +1)

;; Subword mode.
(global-subword-mode 1)

;; When the lines in a buffer are so long that performance could suffer to an unacceptable degree,
;; we say “so long” to the buffer’s major mode
(global-so-long-mode +1)

;; More performant rapid scrolling over unfontified regions.
(setq fast-but-imprecise-scrolling t)

(with-eval-after-load 'eshell
  (setq eshell-scroll-to-bottom-on-input 'all
        eshell-scroll-to-bottom-on-output 'all
        eshell-buffer-shorthand t
        eshell-kill-processes-on-exit t
        eshell-hist-ignoredups t
        eshell-input-filter (lambda (input) (not (string-match-p "\\`\\s-+" input)))
        eshell-glob-case-insensitive t
        eshell-error-if-no-glob t
        eshell-where-to-jump 'begin
        eshell-review-quick-commands nil
        eshell-smart-spaces-goes-to-end t)
  (add-hook 'eshell-preoutput-filter-functions 'ansi-color-filter-apply)
  (add-hook 'eshell-preoutput-filter-functions 'ansi-color-apply))

(defun eshell/clear ()
  "Clear the eshell buffer."
  (interactive)
  (let ((inhibit-read-only t))
    (erase-buffer)))

(defun eshell/mini-eshell ()
  "Open a mini-eshell in a small window at the bottom of the current window."
  (interactive)
  (quarter-window-vertically)
  (other-window 1)
  (eshell))

(defun eshell/other-frame ()
  "Open eshell in another frame."
  (interactive)
  (with-selected-frame (make-frame)
    (eshell)))

(defun open-emacs-dir ()
  "Open the emacs.d directory."
  (interactive)
  (find-file emacs-dir))

(defun rename-this-file-and-buffer (new-name)
  "Renames both current buffer and file it's visiting to NEW-NAME."
  (interactive "sNew name: ")
  (let ((name (buffer-name))
        (filename (buffer-file-name)))
    (unless filename
      (error "Buffer '%s' is not visiting a file!" name))
    (progn
      (when (file-exists-p filename)
        (rename-file filename new-name 1))
      (set-visited-file-name new-name)
      (rename-buffer new-name))))

(defun delete-this-file ()
  "Delete the current file, and kill the buffer."
  (interactive)
  (unless (buffer-file-name)
    (error "No file is currently being edited"))
  (when (yes-or-no-p (format "Really delete '%s'?"
                             (file-name-nondirectory buffer-file-name)))
    (delete-file (buffer-file-name))
    (kill-buffer (current-buffer))))

(defun browse-file-directory ()
  "Open the current file's directory however the OS would."
  (interactive)
  (if default-directory
      (browse-url-of-file (expand-file-name default-directory))
    (error "No `default-directory' to open")))

(defun kill-region-or-backward-word ()
  "Backword or kill the region set."
  (interactive)
  (if (region-active-p)
      (kill-region (region-beginning) (region-end))
    (backward-kill-word 1)))

(defun smarter-move-beginning-of-line (arg)
  "Move point back to indentation of beginning of line.
Move point to the first non-whitespace character on this line.
If point is already there, move to the beginning of the line.
Effectively toggle between the first non-whitespace character and
the beginning of the line.
If ARG is not nil or 1, move forward ARG - 1 lines first.  If
point reaches the beginning or end of the buffer, stop there."
  (interactive "^p")
  (setq arg (or arg 1))

  ;; Move lines first
  (when (/= arg 1)
    (let ((line-move-visual nil))
      (forward-line (1- arg))))

  (let ((orig-point (point)))
    (back-to-indentation)
    (when (= orig-point (point))
      (move-beginning-of-line 1))))

(defun quarter-window-vertically ()
  "Split the current window, leaving a quarter-height window at the bottom.
Point stays in the upper window."
  (split-window-below (- (/ (window-total-height) 4))))

(defun crm-indicator (args)
  (cons (format "[CRM%s] %s"
                (replace-regexp-in-string
                 "\\`\\[.*?]\\*\\|\\[.*?]\\*\\'" ""
                 crm-separator)
                (car args))
        (cdr args)))

(advice-add #'completing-read-multiple :filter-args #'crm-indicator)

(setq enable-recursive-minibuffers t
      minibuffer-prompt-properties
      '(read-only t cursor-intangible t face minibuffer-prompt))

(add-hook 'minibuffer-setup-hook #'cursor-intangible-mode)

;; Font size
(global-set-key (kbd "C-+") 'text-scale-increase)
(global-set-key (kbd "C--") 'text-scale-decrease)

;; Switch window.
(global-set-key (kbd "M-o") 'other-window)

;; Start eshell or switch to it if it's active.
(global-set-key (kbd "C-x m") 'eshell)

;; Start a new eshell even if one is active.
(global-set-key (kbd "C-x M") (lambda () (interactive) (eshell t)))

;; Open a small eshell.
(global-set-key (kbd "C-x 9") 'eshell/mini-eshell)

;; Open eshell in a new frame.
(global-set-key (kbd "C-x !") 'eshell/other-frame)

;; Cycle through buffers
(global-set-key (kbd "<C-tab>") 'bury-buffer)

;; Jump to Dired buffer corresponding to current buffer.
(global-set-key (kbd "C-x C-j") 'dired-jump)

;; Compilation mode.
(global-set-key (kbd "C-x c") 'compile)

;; Open Emacs directory.
(global-set-key (kbd "C-x ?") 'open-emacs-dir)

;; Open folder in a file browser.
(global-set-key (kbd "C-x /") 'browse-file-directory)

;; Killing text.
(global-set-key (kbd "C-w") 'kill-region-or-backward-word)

;; remap C-a to `smarter-move-beginning-of-line'
(global-set-key [remap move-beginning-of-line] 'smarter-move-beginning-of-line)

;; Profiler.
(global-set-key (kbd "C-x p r") 'profiler-report)
(global-set-key (kbd "C-x p s") 'profiler-start)
(global-set-key (kbd "C-x p t") 'profiler-stop)

;; Speedbar
(global-set-key (kbd "C-x S") 'speedbar)

;; Unbind arrow keys.
(global-unset-key (kbd "<left>"))
(global-unset-key (kbd "<right>"))
(global-unset-key (kbd "<up>"))
(global-unset-key (kbd "<down>"))

;; Unbind key to minimize.
(global-unset-key "\C-z")
(global-unset-key "\C-x\C-z")

(with-eval-after-load 'org
  (setq org-log-done t
        org-startup-with-inline-images t
        org-startup-indented t
        org-pretty-entities t
        org-hide-emphasis-markers t
        org-fontify-whole-heading-line t
        org-fontify-done-headline t
        org-fontify-quote-and-verse-blocks t
        org-image-actual-width nil
        org-startup-folded nil
        org-todo-keyword-faces
        '(("TODO" . org-warning)
          ("STARTED" . "yellow")
          ("CANCELLED" . (:foreground "blue" :weight bold)))))

(add-hook 'org-mode-hook
          (lambda ()
            (variable-pitch-mode 1)
            (visual-line-mode 1)))

;; Colorize compilation.
(add-hook 'compilation-filter-hook 'ansi-color-compilation-filter)

;; Display the bare minimum at startup.
(setq inhibit-startup-message t
      inhibit-startup-echo-area-message user-login-name
      inhibit-default-init t
      initial-major-mode 'fundamental-mode
      initial-scratch-message nil)

(fset #'display-startup-echo-area-message #'ignore)

;; Enable y/n answers
(setq use-short-answers t)

;; Disable the warning "X and Y are the same file". It's fine to ignore this
;; warning as it will redirect you to the existing buffer anyway.
(setq find-file-suppress-same-file-warnings t)

;; Make Emacs flash instead of beeping an error.
(setq visible-bell t)

;; Emacs "updates" its ui more often than it needs to, so we slow it down
;; slightly, from 0.5s:
(setq idle-update-delay 1)

;; How much time should elapse before command characters echo
(setq echo-keystrokes 0.02)

;; Resize windows/frames in units of pixels
(setq window-resize-pixelwise t
      frame-resize-pixelwise t)

;; Window Divider widths.
(setq window-divider-default-places t
      window-divider-default-bottom-width 1
      window-divider-default-right-width 1)

;; Empty the frame title.
(setq-default frame-title-format "%f")

;; Reduce rendering/line scan work for Emacs by not rendering cursors or regions
;; in non-focused windows.
(setq-default cursor-in-non-selected-windows nil)
(setq highlight-nonselected-windows nil)

;; Remove command line options that aren't relevant to our current OS; that
;; means less to process at startup.
(unless (eq system-type 'darwin) (setq command-line-ns-option-alist nil))
(unless (eq system-type 'gnu/linux) (setq command-line-x-option-alist nil))

(defun setup-frame-and-fonts (width height left top default-font fixed-font variable-font)
  "Set the initial/default frame size+position and the main font faces."
  (let ((frame-options `((width . ,width)
                         (height . ,height)
                         (left . ,left)
                         (top . ,top))))
    (setq initial-frame-alist frame-options
          default-frame-alist frame-options))
  (set-face-attribute 'default nil :font default-font)
  (set-face-attribute 'fixed-pitch nil :font fixed-font)
  (set-face-attribute 'variable-pitch nil :font variable-font))

;; Windows specific settings.
(when (eq system-type 'windows-nt)
  (setup-frame-and-fonts 180 40 50 50
                         "Cascadia Code-12.0"
                         "Cascadia Code-12.0"
                         "Constantia-16.0")
  (setq w32-get-true-file-attributes nil
        inhibit-compacting-font-caches t
        abbreviated-home-dir "\\`'"))

;; macOS specific settings.
(when (eq system-type 'darwin)
  (setup-frame-and-fonts 200 50 100 50
                         "Monaco-12.0"
                         "Monaco-12.0"
                         "Helvetica Neue-14.0")
  (menu-bar-mode +1)
  (when (fboundp 'set-fontset-font)
    (set-fontset-font t 'unicode "Apple Color Emoji" nil 'prepend))
  (setq org-dir "~/Repos/slipbox"))

(use-package s
  :load-path "lib/s"
  :defer)

(use-package dash
  :load-path "lib/dash"
  :defer)

(use-package request
  :load-path "lib/emacs-request"
  :defer)

(use-package wgrep
  :load-path "lib/wgrep"
  :defer)

(use-package compat
  :load-path "lib/compat"
  :defer)

(use-package cond-let
  :load-path "lib/cond-let"
  :defer)

(use-package llama
  :load-path "lib/llama"
  :defer)

(use-package transient
  :load-path "lib/transient/lisp"
  :defer)

(use-package with-editor
  :load-path "lib/with-editor/lisp"
  :defer)

(use-package spinner
  :load-path "lib/spinner"
  :defer)

(use-package which-key
  :hook (emacs-startup . which-key-mode))

(use-package async
  :load-path "lib/emacs-async"
  :defer
  :hook (dired-mode . dired-async-mode)
  :init (autoload 'dired-async-mode "dired-async.el" nil t))

(use-package avy
  :load-path "lib/avy"
  :config (setq avy-timeout-seconds 0.3)
  :bind (("C-:" . avy-goto-char-timer)
         ("M-g w" . avy-goto-word-1)
         ("M-g M-l" . avy-goto-line)))

(use-package ace-window
  :load-path "lib/ace-window"
  :commands ace-swap-window
  :config (setq aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l))
  :bind ("C-x o" . ace-window))

(use-package magit
  :load-path "lib/magit/lisp"
  :bind (("C-x g" . magit-status)
         ("C-x M-g" . magit-dispatch)))

(use-package emacs-lisp-mode
  :no-require t
  :bind (:map emacs-lisp-mode-map
              ("C-c C-b" . eval-buffer)
              ("C-c C-c" . eval-defun)
              ("C-c C-e" . ielm)))

(when (file-directory-p org-dir)
  (use-package deft
    :load-path "lib/deft"
    :bind (("C-c n d" . deft)
           ("C-c n f" . deft-find-file))
    :init (setq deft-text-mode 'org-mode
                deft-extensions '("org")
                deft-recursive t
                deft-use-filter-string-for-filename t
                deft-directory org-dir))
  (use-package git-auto-commit-mode
    :load-path "lib/git-auto-commit-mode"
    :config (setq gac-automatically-push-p t
                  gac-automatically-add-new-files-p t
                  gac-debounce-interval 10)))

;; Restore the values we deferred in early-init.el for startup speed.
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (expt 2 24)
                  file-name-handler-alist my/file-name-handler-alist)))

;;; init.el ends here
