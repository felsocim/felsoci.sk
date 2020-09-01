(require 'org) ;; Org mode support
(require 'ox-html) ;; HTML export backend
(require 'ox-publish) ;; publishing functions
(require 'htmlize) ;; source code block export to HTML
(require 'org-ref) ;; bibliography support

(defun get-post-synopsis (blog-post)
  "Parse the synopsis from a BLOG-POST and return it as a string. The synopsis
text must be enclosed between the '#+BEGIN_SYNOPSIS' and '#+END_SYNOPSIS' tags."
  (with-temp-buffer
    (insert-file-contents blog-post) ;; Load the blog post Org file.
    (goto-char (point-min)) ;; Move the cursor to the beginning of the buffer.
    (let
        ;; Use markers to select the area in the buffer between the first and
        ;; the last character of the synopsis.
        ;; To exclude the newlines after the opening and before the closing
        ;; tags, move forward the starting marker by one and move backwards the
        ;; ending marker by one too.
        ((beg (+ 1 (re-search-forward "^#\\+BEGIN_SYNOPSIS$")))
         (end (- (progn
                   (re-search-forward "^#\\+END_SYNOPSIS$")
                   (match-beginning 0)) 1)))
      ;; Return the selected area of the file buffer as a string.
      (buffer-substring beg end))))

(defun format-blog-item (entry style project)
  "Change the formatting of the sitemap item ENTRY belonging to PROJECT. Note
that, ENTRY is an absolute path to the corresponding blog post Org file and the
sitemap style argument STYLE is unused in this implementation."
  (let
      ;; As in 'org-publish-project-alist' below, set the base directory for
      ;; blog posts to be './posts', the absolute path provided in ENTRY is
      ;; incorrect. It lacks 'posts' directory because Emacs thinks it is
      ;; running in the project's root. Therefore, we have to re-include
      ;; 'posts/' into the path.
      ;;
      ;; Example:
      ;; If the initial ENTRY holds "/home/marek/src/felsoci.sk/post.org",
      ;; transform it to "/home/marek/src/felsoci.sk/posts/post.org".
      ((fixed-entry
        (concat
         (file-name-directory entry) "posts/" (file-name-nondirectory entry))))
    ;; Return a formatted string. Each '%s' shall be replaced by the remaining
    ;; function arguments as it is the case for the 'printf' function in C.
    (format "
[[file:%s][%s]]

Published on %s

%s

[[file:%s][Read more]]
"
            entry
            (org-publish-find-title entry project)
            (format-time-string "%d/%m/%Y"
                                (org-publish-find-date entry project))
            (get-post-synopsis fixed-entry)
            entry)))

;; Force publishing of unchanged files to make sure all the pages get published.
(setq org-publish-use-timestamps-flag nil)

;; Set static HTML header and footer files globally for the whole project.
(setq org-html-preamble (org-file-contents "./shared/header.html"))
(setq org-html-postamble (org-file-contents "./shared/footer.html"))

;; Define project components to export.
(setq org-publish-project-alist
      (list
       (list "posts" ;; Blog posts
             :base-directory "./posts"
             :base-extension "org"
             :publishing-directory "./public/posts"
             :publishing-function '(org-html-publish-to-html)
             :htmllized-source t

             :with-author t
             :with-creator t
             :with-date t

             :headline-level 4
             :section-numbers nil
             :with-toc nil

             :html-head-extra "<link rel=\"stylesheet\"
href=\"../styles/custom.css\""
             :html-head nil
             :html-head-include-default-style nil
             :html-head-include-scripts nil
             :html-footnotes-section "<div class=\"footnotes\">%s</div"

             :auto-sitemap t
             :sitemap-filename "contents.org"
             :sitemap-title "Blog"
             :sitemap-format-entry 'format-blog-item
             :sitemap-sort-files 'anti-chronologically)
        (list "pages" ;; Static sites
              :base-directory "."
              :base-extension "org"
              :publishing-directory "./public"
              :exclude (regexp-opt '("posts"))
              :publishing-function '(org-html-publish-to-html)
              :htmllized-source t

              :with-author t
              :with-creator t
              :with-date t

              :headline-level 4
              :section-numbers nil
              :with-toc nil

              :html-head-extra "<link rel=\"stylesheet\"
href=\"../styles/custom.css\""
              :html-head nil
              :html-head-include-default-style nil
              :html-head-include-scripts nil

              :html-footnotes-section "<div class=\"footnotes\">%s</div")
        (list "styles" ;; Cascade style sheets (CSS)
              :base-directory "./styles"
              :base-extension "css"
              :publishing-directory "./public/styles"
              :publishing-function '(org-publish-attachment))
        (list "images" ;; Images and figures
              :base-directory "./images"
              :base-extension ".*"
              :publishing-directory "./public/images"
              :publishing-function '(org-publish-attachment))
        (list "felsoci.sk" ;; Name of the project
              :components '("posts" "pages" "styles" "images"))))
