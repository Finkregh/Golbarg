;; golbarg.el
;;
;; Emacs support for Golbarg blogs.
;;
;; To use, just put this file somewhere in the load path and
;; (require 'golbarg)

(require 'markdown-mode)
(require 'yaml-mode)

(defvar golbarg-posts-dir nil
  "Golbarg posts directory.")

(defvar golbarg-drafts-dir nil
  "Golbarg drafts directory.")

(defvar golbarg-post-ext ""
  "Golbarg posts files extension.")

(defvar golbarg-post-template "title: %s\ndate: %s\ntags: []\n---\n\n"
  "Template for Golbarg posts.")

(defvar golbarg-header-face 'golbarg-header-face
  "Face for Golbarg posts headers.")

(defface golbarg-header-face
  '((t (:background "gray85")))
  "Face for Golbarg posts headers.")

(defun golbarg-slug (title)
  "Turn a post title into a slug."
  (downcase (replace-regexp-in-string "[^A-Za-z0-9]+" "-" title)))

(defun golbarg-new-draft (title)
  "Create a draft for a new Golbarg post."
  (interactive "MPost title: \n")
  (let* ((date (if (interactive-p)
		   (org-read-date nil nil nil "Post date: ")
		 (format-time-string "%Y-%m-%d")))
	 (fn (expand-file-name (concat date "-" (golbarg-slug title) golbarg-post-ext) golbarg-drafts-dir))
	 (buf (create-file-buffer fn)))
    (set-buffer buf)
    (set-visited-file-name fn)
    (insert (format golbarg-post-template title date))
    (switch-to-buffer buf)
    (golbarg-mode)))

(define-derived-mode golbarg-mode markdown-mode "Golbarg"
  "Major mode for Golbarg blog posts."
  (set (make-local-variable 'font-lock-fontify-region-function) 'golbarg-fontify-region)
  (set (make-local-variable 'golbarg-overlay) (make-overlay (point-min) (golbarg-header-end)))
  (overlay-put golbarg-overlay 'face 'golbarg-header-face)
)

(defun golbarg-header-end ()
  "Get the point of the end of a Golbarg post header."
  (save-excursion
    (goto-char (point-min))
    (re-search-forward "^--+\n" nil t)))

(defun golbarg-fontify-region (beg end loudly)
  "Fontify a region, using YAML font-lock parameters in the header."
  (let ((hdr-end (golbarg-header-end)))
    ;; Update header overlay
    (if (not (= hdr-end (overlay-end golbarg-overlay)))
	(move-overlay golbarg-overlay (point-min) hdr-end))
    ;; Check how to fontify the region
    (cond ((> beg hdr-end) ;; Region is after the header
	   (font-lock-default-fontify-region beg end loudly))
	  ((>= hdr-end end) ;; Region is inside the header
	   (golbarg-fontify-region-as-yaml beg end loudly))
	  (t ;; Header end is inside the region...
	   (golbarg-fontify-region-as-yaml beg hdr-end loudly)
	   (font-lock-default-fontify-region (1+ hdr-end) end loudly)))))

(defun golbarg-fontify-region-as-yaml (beg end loudly)
  (let ((font-lock-syntactic-keywords yaml-font-lock-syntactic-keywords)
	(font-lock-keywords yaml-font-lock-keywords))
    (message (concat "From " (int-to-string beg) " to " (int-to-string end)))
    (font-lock-default-fontify-region beg end loudly)))


(provide 'golbarg)