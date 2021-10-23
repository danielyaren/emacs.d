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

(push (concat emacs-dir "lib/use-package/") load-path)
(push (concat emacs-dir "themes/") custom-theme-load-path)

(eval-when-compile
  (require 'use-package))

;; In noninteractive sessions, prioritize non-byte-compiled source files to
;; prevent the use of stale byte-code. Otherwise, it saves us a little IO time
;; to skip the mtime checks on every *.elc file we load.
(setq-default load-prefer-newer noninteractive)

;; Disable warnings from legacy advice system,
(setq-default ad-redefinition-action 'accept)

;; Make apropos omnipotent.
(defvar apropos-do-all t)

;; Don't make a second case-insensitive pass over `auto-mode-alist'.
(setq-default auto-mode-case-fold nil)

;; Disable bidirectional text rendering for a modest performance boost. Of
;; course, this renders Emacs unable to detect/display right-to-left languages
;; (sorry!), but for us left-to-right language speakers/writers, it's a boon.
(setq-default bidi-display-reordering 'left-to-right)

;; This is consulted on every `require', `load' and various path/io functions.
(setq-default file-name-handler-alist nil)

;; Don't ping things that look like domain names.
(setq-default ffap-machine-p-known 'reject)

;; Resolve symlinks when opening files, so that any operations are conducted
;; from the file's true directory (like `find-file').
(setq-default find-file-visit-truename t)

;; Compilation mode tweaks.
(setq-default compilation-always-kill t
              compilation-ask-about-save nil)

;; Try to keep things organised.
(setq-default backup-directory-alist '(("." . "~/.emacs-saves")))
(setq-default save-place-file "~/.emacs-save-place")
(save-place-mode 1)

(autoload 'dired-jump "dired-x" t)

(with-eval-after-load 'dired
  (setq-default dired-listing-switches "-alh"
                dired-recursive-copies 'always
                dired-recursive-deletes 'always)
  (add-hook 'dired-mode-hook 'auto-revert-mode))

(with-eval-after-load 'dired-x
  (setq-default dired-omit-extensions nil))

;; Modern editor behavior.
(delete-selection-mode 1)

;; Middle-click paste at location.
(setq-default mouse-yank-at-point t)

;; Automatically update a buffer.
(global-auto-revert-mode 1)

;; Eliminate duplicates in the kill ring. That is, if you kill the
;; same thing twice, you won't have to use M-y twice to get past it
;; to older entries in the kill ring.
(setq-default kill-do-not-save-duplicates t)

;; Some editing visuals.
(setq-default blink-matching-paren nil
              visible-cursor nil
              x-stretch-cursor nil)

;; Smoother scrolling.
(setq-default scroll-margin 1
              scroll-step 1
              scroll-conservatively 10000
              scroll-preserve-screen-position 1)

;; Nicer line spacing.
(setq-default line-spacing 3)

;; Whether to add a newline.
(setq-default mode-require-final-newline nil)

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
(global-subword-mode)

;; When the lines in a buffer are so long that performance could suffer to an unacceptable degree,
;; we say “so long” to the buffer’s major mode
(global-so-long-mode +1)

;; More performant rapid scrolling over unfontified regions.
(setq-default fast-but-imprecise-scrolling t)

(with-eval-after-load 'eshell
  (setq-default eshell-scroll-to-bottom-on-input 'all
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
    (kill-this-buffer)))

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
  "Create a new window a quarter size of the current window."
  (split-window-vertically)
  (other-window 1)
  (split-window-vertically)
  (other-window -1)
  (delete-window))

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

;; Toggle Modus themes.
(global-set-key (kbd "C-.") #'theme/toggle)

(with-eval-after-load 'org
  (setq-default org-log-done t
                org-startup-with-inline-images t
                org-startup-indented t
                org-pretty-entities t
                org-hide-emphasis-markers t
                org-fontify-whole-heading-line t
                org-fontify-done-headline t
                org-fontify-quote-and-verse-blocks t
                org-image-actual-width nil
                org-completion-use-ido t
                org-startup-folded "showall"
                org-todo-keyword-faces
                '(("TODO" . org-warning)
                  ("STARTED" . "yellow")
                  ("CANCELLED" . (:foreground "blue" :weight bold)))))

(add-hook 'org-mode-hook
          (lambda ()
            (variable-pitch-mode 1)
            (visual-line-mode 1)))

(load-theme 'modus-vivendi t)

(defun theme/toggle ()
  "Toggle between `modus-operandi' and `modus-vivendi' themes."
  (interactive)
  (if (eq (car custom-enabled-themes) 'modus-operandi)
      (progn
        (disable-theme 'modus-operandi)
        (load-theme 'modus-vivendi t))
    (disable-theme 'modus-vivendi)
    (load-theme 'modus-operandi t)))

;; Colorize compilation.
(when (require 'ansi-color nil t)
  (defun my-colorize-compilation-buffer ()
    (when (eq major-mode 'compilation-mode)
      (ansi-color-apply-on-region compilation-filter-start (point-max))))
  (add-hook 'compilation-filter-hook 'my-colorize-compilation-buffer))

;; Display the bare minimum at startup.
(setq-default inhibit-startup-message t
              inhibit-startup-echo-area-message user-login-name
              inhibit-default-init t
              initial-major-mode 'fundamental-mode
              initial-scratch-message nil)

(fset #'display-startup-echo-area-message #'ignore)

;; Enable y/n answers
(fset 'yes-or-no-p 'y-or-n-p)

;; Disable the warning "X and Y are the same file". It's fine to ignore this
;; warning as it will redirect you to the existing buffer anyway.
(setq-default find-file-suppress-same-file-warnings t)

;; Make Emacs flash instead of beeping an error.
(setq-default visible-bell t)

;; Emacs "updates" its ui more often than it needs to, so we slow it down
;; slightly, from 0.5s:
(setq-default idle-update-delay 1)

;; How much time should elapse before command characters echo
(setq-default echo-keystrokes 0.02)

;; Resize windows/frames in units of pixels
(setq-default window-resize-pixelwise t
      frame-resize-pixelwise t)

;; Window Divider widths.
(setq-default window-divider-default-places t
              window-divider-default-bottom-width 1
              window-divider-default-right-width 1)

;; Empty the frame title.
(setq-default frame-title-format "%f")

;; Reduce rendering/line scan work for Emacs by not rendering cursors or regions
;; in non-focused windows.
(setq-default cursor-in-non-selected-windows nil)
(setq-default highlight-nonselected-windows nil)

;; Remove command line options that aren't relevant to our current OS; that
;; means less to process at startup.
(unless (eq system-type 'darwin) (setq-default command-line-ns-option-alist nil))
(unless (eq system-type 'gnu/linux) (setq-default command-line-x-option-alist nil))

;; Windows specific settings.
(when (eq system-type 'windows-nt)
  (setq-default w32-get-true-file-attributes nil
		            inhibit-compacting-font-caches t
		            abbreviated-home-dir "\\`'")
  (set-face-attribute 'default nil :font "Cascadia Code-10.0")
  (set-face-attribute 'fixed-pitch nil :font "Cascadia Code-10.0")
  (set-face-attribute 'variable-pitch nil :font "Constantia-14.0"))

;; macOS specific settings.
(when (eq system-type 'darwin)
  (menu-bar-mode +1)
  (when (fboundp 'set-fontset-font)
    (set-fontset-font t 'unicode "Apple Color Emoji" nil 'prepend))
  (set-face-attribute 'default nil :font "Monaco-12.0")
  (set-face-attribute 'fixed-pitch nil :font "Monaco-12.0")
  (set-face-attribute 'variable-pitch nil :font "Helvetica Neue-14.0"))

(use-package s
  :defer
  :load-path "lib/s")

(use-package dash
  :defer
  :load-path "lib/dash")

(use-package request
  :defer
  :load-path "lib/emacs-request")

(use-package which-key
  :load-path "lib/which-key"
  :hook (emacs-startup . which-key-mode))

(use-package async
  :load-path "lib/emacs-async"
  :defer
  :hook (dired-mode . dired-async-mode)
  :init (autoload 'dired-async-mode "dired-async.el" nil t))

(use-package avy
  :load-path "lib/avy"
  :config (setq-default avy-timeout-seconds 0.3)
  :bind (("C-:" . avy-goto-char-timer)
         ("M-g w" . avy-goto-word-1)
         ("M-g M-l" . avy-goto-line)))

(use-package ace-window
  :load-path "lib/ace-window"
  :commands ace-swap-window
  :config (setq-default aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l))
  :bind ("C-x o" . ace-window))

(use-package emacs-lisp-mode
  :mode "\\.el\\'"
  :bind (:map emacs-lisp-mode-map
              ("C-c C-b" . eval-buffer)
              ("C-c C-c" . eval-defun)
              ("C-c C-e" . ielm)))

(use-package find-file-in-project
  :load-path "lib/find-file-in-project"
  :config (setq-default ffip-use-rust-fd t)
  :bind (("C-x j" . find-file-in-project)
         ("C-x J" . find-file-in-current-directory)))

;;; init.el ends here
