publish: tangle
	guix time-machine -C .guix/channels.scm -- shell --pure --preserve=ORG_OUTPUT_PATH -m .guix/manifest.scm -- emacs --batch --no-init-file --eval '(setq org-confirm-babel-evaluate nil)' --load publish.el --funcall org-publish-all

tangle: blog/creating-websites-and-blogging-in-org-mode.org
	guix shell --pure emacs emacs-org -- emacs --batch -l org --eval '(org-babel-tangle-file "blog/creating-websites-and-blogging-in-org-mode.org")'
