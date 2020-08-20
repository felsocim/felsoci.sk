(require 'org) ;; Org mode support
(require 'ox-html) ;; HTML export backend
(require 'ox-publish) ;; publishing functions
(require 'htmlize) ;; source code block export to HTML
(require 'org-ref) ;; bibliography support

;; Declare the extra HTML header entry for the custom style sheet.
(setq custom-css
      "<link rel=\"stylesheet\" href=\"../styles/custom.css\"")

(defun get-custom-header-or-footer (target)
  "If the value of TARGET is 'header' the function shall import the custom HTML
header file located in the 'shared' folder. If the value of TARGET is 'footer'
the footer file shall be imported."
  (with-temp-buffer
    ;; Load the HTML file.
    (insert-file-contents (concat "shared/" target ".html"))
    ;; Return the file buffer as a string.
    (buffer-string)))

(defun get-post-synopsis (blog-post)
  "Parse the synopsis from a BLOG-POST and return it as a string. The synopsis
text must be enclosed between the #+BEGIN_SYNOPSIS and #+END_SYNOPSIS tags."
  (with-temp-buffer
    (insert-file-contents blog-post) ;; Load the Org file.
    (goto-char (point-min)) ;; Move the cursor to the beginning of the buffer.
    (let ;; Use markers to select the area in the buffer between the first and
         ;; the last character of the synopsis.
        ((beg (+1 (re-search-forward "^#\\+BEGIN_SYNOPSIS$")))
         (end (progn
                (re-search-forward "^#\\+END_SYNOPSIS$")
                ;; We place the cursor before the first character of the closing
                ;; tag of the synopsis text to include its last character in the
                ;; selected area.
                (match-beginning 0))))
      ;; Return the selected area of the file buffer as a string.
      (buffer-substring beg end))))
