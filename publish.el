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
      ;; blog posts to be './blog', the absolute path provided in ENTRY is
      ;; incorrect. It lacks 'blog' directory because Emacs thinks it is running
      ;; in the project's root. Therefore, we have to re-include 'blog/' into
      ;; the path.
      ;;
      ;; Example:
      ;; If the initial ENTRY holds "/home/marek/src/felsoci.sk/post.org",
      ;; transform it to "/home/marek/src/felsoci.sk/blog/post.org".
      ((fixed-entry
        (concat
         (file-name-directory entry) "blog/" (file-name-nondirectory entry))))
    ;; Return a formatted string. Each '%s' shall be replaced by the remaining
    ;; function arguments as it is the case for the 'printf' function in C.
    (format "
@@html:<h2 class=\"post-title\">@@
[[file:%s][%s]]
@@html:</h2><span class=\"post-metadata\">@@
Published on %s by %s
@@html:</span>@@

%s

@@html:
<form action=\"@@%s@@html:.html\" method=\"POST\">
  <button type=\"submit\">Read more</button>
</form>
@@
"
            entry
            (org-publish-find-title entry project)
            (format-time-string "%d/%m/%Y"
                                (org-publish-find-date entry project))
            (substring
             (format "%s"
                     (org-publish-find-property entry :author project)) 1 -1)
            (get-post-synopsis fixed-entry)
            ;; We need to strip the '.org' extension because the link is not
            ;; converted into a HTML link during the export as we do not use a
            ;; standard Org-formatted link such as '[[target][text]]'.
            (file-name-sans-extension entry))))

(defun format-blog-sitemap (title posts)
  "Generate customized sitemap TITLE of POSTS returned by `format-blog-item'."
  (concat
   ;; Print the sitemap document's title.
   "#+TITLE: " title "\n\n"
   ;; Concatenate all the posts from POSTS into a single string to be saved to
   ;; the sitemap document.
   (mapconcat
    ;; For each post, print the latter followed by a newline character.
    (lambda (post)
      (format "%s\n" (car post)))
    ;; POSTS is a nested list having the following form:
    ;;
    ;; - "unordered"
    ;; - <list of possibly nested posts>
    ;; - <list of possibly nested posts>
    ;; - ...
    ;;
    ;; Therefore, we have to transform it into a simple list containing only the
    ;; leading elements of the nested post lists. To achieve this, we apply a
    ;; sequence filter on POSTS. We strip the "unordered" string from the
    ;; beginning using `cdr'. We apply `car' as a filter on the lists of nested
    ;; posts which shall make `seq-filter' return only the leading elements of
    ;; the latter.
    (seq-filter #'car (cdr posts))
    ;; Each post shall be separated using another newline character in the final
    ;; string containing all the posts from POSTS.
    "\n@@html:<hr class=\"post-separator\">@@")))

(defun add-suffix-to-html-title (suffix html-files)
  "A post-processing export function to append a string SUFFIX to the string
enclosed in '<title>' and '</title>' tags in each one of the HTML files in the
input list HTML-FILES."
  ;; Iterate over each file in HTML-FILES.
  (while (setq html-file (pop html-files))
    (with-temp-buffer
      ;; Read the content of the current HTML file.
      (insert-file-contents html-file)
      ;; Move the cursor to the end.
      (goto-char (point-max))
      ;; Backward search for the closing '</title>' tag and place the cursor at
      ;; the beginning of the match.
      (re-search-backward "<\\/title>")
      ;; Append the string in SUFFIX immediately after the last character of the
      ;; original document's title (see the Org keyword '#+TITLE').
      (insert suffix)
      ;; Save the updated buffer to the same file.
      (write-region 1 (point-max) html-file))))

(defun add-suffix-to-html-title-for-pages (plist)
  "A wrapper for the post-processing function 'add-suffix-to-html-title' to be
used when exporting static pages. It appends the string ' - Marek Felšöci's
personal website' to HTML page titles.

PLIST holds the project's property list."
  ;; Call the function 'add-suffix-to-html-title' on all the HTML files in the
  ;; publishing directory of static pages (the project's root).
  (add-suffix-to-html-title
   " - Marek Felšöci's personal website"
   (directory-files
    (plist-get plist :publishing-directory) t "\\.html$")))

(defun add-suffix-to-html-title-for-blog-posts (plist)
  "A wrapper for the post-processing function 'add-suffix-to-html-title' to be
used when exporting blog posts. It appends the string ' - Marek Felšöci's blog'
to HTML page titles.

PLIST holds the project's property list."
  ;; Call the function 'add-suffix-to-html-title' on all the HTML files in the
  ;; publishing directory of blog posts ('blog' directory under the projet's
  ;; root).
  (add-suffix-to-html-title
   " - Marek Felšöci's blog"
   (directory-files
    (plist-get plist :publishing-directory) t "\\.html$")))

;; Force publishing of unchanged files to make sure all the pages get published.
(setq org-publish-use-timestamps-flag nil)

;; Override the default LaTeX publishing command.
(setq org-latex-pdf-process (list "latexmk --shell-escape -f -pdf %f"))

;; Set static HTML header and footer files globally for the whole project.
(setq org-html-preamble (org-file-contents "./shared/header.html"))
(setq org-html-postamble (org-file-contents "./shared/footer.html"))

;; Define project components to export.
(setq org-publish-project-alist
      (list
       (list "blog" ;; Blog posts
             :base-directory "./blog"
             :base-extension "org"
             :publishing-directory "/var/www/html/blog"
             :publishing-function '(org-html-publish-to-html)
             :completion-function '(add-suffix-to-html-title-for-blog-posts)
             :htmllized-source t

             :with-author t
             :with-creator t
             :with-date t

             :headline-level 4
             :section-numbers nil
             :with-toc nil

             :html-head-extra "<link rel=\"stylesheet\" type=\"text/css\"
href=\"../styles/custom.css\">"
             :html-head nil
             :html-head-include-default-style nil
             :html-head-include-scripts nil

             :auto-sitemap t
             :sitemap-filename "posts.org"
             :sitemap-title "Posts"
             :sitemap-function 'format-blog-sitemap
             :sitemap-format-entry 'format-blog-item
             :sitemap-sort-files 'anti-chronologically)
        (list "pages" ;; Static pages
              :base-directory "."
              :base-extension "org"
              :publishing-directory "/var/www/html"
              :exclude (regexp-opt '("blog"))
              :publishing-function '(org-html-publish-to-html)
              :completion-function '(add-suffix-to-html-title-for-pages)
              :htmllized-source t

              :with-author t
              :with-creator t
              :with-date t

              :headline-level 4
              :section-numbers nil
              :with-toc nil

              :html-head-extra "<link rel=\"stylesheet\" type=\"text/css\"
href=\"styles/custom.css\">"
              :html-head nil
              :html-head-include-default-style nil
              :html-head-include-scripts nil)
        (list "cv" ;; LaTeX-typeset curriculum vitae
              :base-directory "./cv"
              :base-extension "org"
              :publishing-directory "/var/www/html/cv"
              :publishing-function '(org-latex-publish-to-pdf))
        (list "styles" ;; Cascade style sheets (CSS)
              :base-directory "./styles"
              :base-extension ".*"
              :recursive t
              :publishing-directory "/var/www/html/styles"
              :publishing-function '(org-publish-attachment))
        (list "images" ;; Images and figures
              :base-directory "./images"
              :base-extension ".*"
              :publishing-directory "/var/www/html/images"
              :publishing-function '(org-publish-attachment))
        (list "felsoci.sk" ;; Name of the project
              :components '("blog" "pages" "styles" "images"))))
