;;; swiper-migemo.el --- Use ivy/counsel/swiper with migemo. -*- lexical-binding: t -*-

;; Copyright (C) 2021 Akira TAMAMORI

;; Author: Akira Tamamori
;; URL: https://github.com/tam17aki/swiper-migemo
;; Version: 1.0
;; Created: Apr 22 2021
;; Package-Requires: ((emacs "27.1") (ivy "0.13.4") (migemo "1.9.2"))

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

;;; Commentary:
;;
;; In the past, many people used avy-migemo to support migemo in swiper, ivy and
;; counsel. However, avy-migemo has not been maintained for a long time, and
;; many attempts have been made to achieve migemo support without using
;; avy-migemo. I decided to write a new minor-mode to make those commands with
;; ivy-based interface compatible with migemo.

;;; Installation:
;;
;; To use this package, add following code to your init file.
;;
;; (require 'swiper-migemo)
;; (global-swiper-migemo-mode +1)
;;
;; In default setting, you can use `swiper' and `swiper-isearch' with migemo.
;; You can also customize swiper-migemo-enable-command which is a list of commands
;; to use migemo-mode.
;;
;; For example, If you want to add `counsel-recentf', add following code in the
;; init file:
;;
;; (add-to-list 'swiper-migemo-enable-command 'counsel-recentf)
;;
;; Furthermore, if you want to use `counsel-rg' with migemo, add following code
;; in the init file:
;;
;; (add-to-list 'swiper-migemo-enable-command 'counsel-rg)
;; (setq migemo-options '("--quiet" "--nonewline" "--emacs"))
;; (migemo-kill)
;; (migemo-init)
;;
;; Note: The above settings must be evaluated before the activataion of this
;; minor-mode. That is,
;;
;; (require 'swiper-migemo)
;; (add-to-list 'swiper-migemo-enable-command 'counsel-recentf)
;; (add-to-list 'swiper-migemo-enable-command 'counsel-rg)
;; (setq migemo-options '("--quiet" "--nonewline" "--emacs"))
;; (migemo-kill)
;; (migemo-init)
;; (global-swiper-migemo-mode +1)
;;
;; You can also toggle this minor-mode by simply invoking `swiper-migemo-mode'
;; via "M-x swiper-migemo-mode".  In this case, never use
;; `global-swiper-migemo-mode' in the init file.

;;; Code:

(require 'ivy)
(require 'swiper)
(require 'migemo)

(defgroup swiper-migemo nil
  "Ivy/Counsel/Swiper with migemo."
  :group 'ivy
  :prefix "swiper-migemo-")

(defcustom swiper-migemo-lighter " SWM" ; Swiper-With-Migemo
  "Lighter for `swiper-migemo-mode'."
  :type '(choice (const :tag "Not displayed." nil)
                 string)
  :group 'swiper-migemo)

(defcustom swiper-migemo-enable-command
  '(swiper swiper-isearch)
  "Commands to use migemo-mode."
  :type 'list
  :group 'swiper-migemo)

(defun swiper-migemo-get-pattern-shyly (word)
  (replace-regexp-in-string
   "\\\\("
   "\\\\(?:"
   (migemo-get-pattern word)))

(defun swiper-migemo--regex-migemo-pattern (word)
  (cond
   ((string-match "\\(.*\\)\\(\\[[^\0]+\\]\\)"  word)
    (concat (swiper-migemo-get-pattern-shyly (match-string 1 word))
            (match-string 2 word)))
   ((string-match "\\`\\\\([^\0]*\\\\)\\'" word)
    (match-string 0 word))
   (t
    (swiper-migemo-get-pattern-shyly word))))

(defun swiper-migemo--regex-migemo (str)
  (when (string-match-p "\\(?:[^\\]\\|^\\)\\\\\\'" str)
    (setq str (substring str 0 -1)))
  (setq str (ivy--trim-trailing-re str))
  (cdr (let ((subs (ivy--split str)))
         (if (= (length subs) 1)
             (cons
              (setq ivy--subexps 0)
              (if (string-match-p "\\`\\.[^.]" (car subs))
                  (concat "\\." (swiper-migemo--regex-migemo-pattern
                                 (substring (car subs) 1)))
                (swiper-migemo--regex-migemo-pattern (car subs))))
           (cons
            (setq ivy--subexps (length subs))
            (replace-regexp-in-string
             "\\.\\*\\??\\\\( "
             "\\( "
             (mapconcat
              (lambda (x)
                (if (string-match-p "\\`\\\\([^?][^\0]*\\\\)\\'" x)
                    x
                  (format "\\(%s\\)" (swiper-migemo--regex-migemo-pattern x))))
              subs
              ".*?")
             nil t))))))

(defun swiper-migemo--regex-migemo-plus (str)
  (cl-letf (((symbol-function 'ivy--regex) #'swiper-migemo--regex-migemo))
    (ivy--regex-plus str)))

(defvar swiper-migemo--search-default-mode-backup nil)
(defvar swiper-migemo--ivy-re-builders-alist-backup nil)

;;;###autoload
(define-minor-mode swiper-migemo-mode
  "Enable migemo under commands with ivy interface."
  :group      'swiper-migemo
  :init-value nil
  :global nil
  :lighter swiper-migemo-lighter
  (if swiper-migemo-mode
      (progn
        ;; enable
        (if (eq swiper-migemo--ivy-re-builders-alist-backup nil)
            (setq swiper-migemo--ivy-re-builders-alist-backup
                  (copy-alist ivy-re-builders-alist)))
        (if (and (eq swiper-migemo--search-default-mode-backup nil)
                 (not (eq search-default-mode nil)))
            (setq swiper-migemo--search-default-mode-backup
                  search-default-mode))
        (mapc (lambda (command)
                (setf (alist-get command ivy-re-builders-alist)
                      #'swiper-migemo--regex-migemo-plus))
              swiper-migemo-enable-command)
        (setq search-default-mode nil))

    ;; disable
    (setq ivy-re-builders-alist
          (copy-alist swiper-migemo--ivy-re-builders-alist-backup))
    (setq search-default-mode swiper-migemo--search-default-mode-backup)))

(defun swiper-migemo--turn-on ()
  (swiper-migemo-mode +1))

;;;###autoload
(define-globalized-minor-mode global-swiper-migemo-mode
  swiper-migemo-mode swiper-migemo--turn-on
  :group 'swiper-migemo)

(provide 'swiper-migemo)

;;; swiper-migemo.el ends here
