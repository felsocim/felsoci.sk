ORG_OUTPUT_PATH ?= /var/www/html

default: publish

test: publish
	cp -r public/* $(ORG_OUTPUT_PATH)

publish: tangle
	guix time-machine -C .guix/channels.scm -- shell --container -m .guix/manifest.scm -- emacs --batch --quick --eval '(setq org-confirm-babel-evaluate nil)' --load publish.el --funcall org-publish-all

tangle: blog/creating-websites-and-blogging-in-org-mode.org
	guix shell --container git emacs emacs-org -- emacs --batch -l org --eval '(org-babel-tangle-file "blog/creating-websites-and-blogging-in-org-mode.org")'
