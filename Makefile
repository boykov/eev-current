# Makefile for GNU eev.
# Copyright (C) 2004,2005,2010 Free Software Foundation, Inc.
#
# This file is part of GNU eev.
#
# GNU eev is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 2, or (at your option) any
# later version.
#
# GNU eev is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with GNU eev; see the file COPYING. If not, write to the Free
# Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
# 02111-1307, USA.

# �.tarball�		(to "tarball")
# �.htmlize.el�		(to "htmlize.el")

# (find-eev "examples/eev-tests.e" "test-install-beth")

# (find-node "(make)Automatic")
# (find-node "(make)Makefile Contents" "`#'")
# (find-node "(make)Echoing")

EEVDIR = $(PWD)
EEVTMPDIR = $(PWD)/tmp
EEVRCDIR = $(EEVDIR)/rcfiles
CHANGE = $(EEVRCDIR)/change

default:
	@echo "There's nothing to make."
	@echo "Patching of initialization files is now done by eev-rctool."
	@echo "Read the INSTALL file."

clean preinstall uninstall install:
	@echo Installation and uninstallation of the patches for eev in
	@echo rcfiles is now done by eev-rctool. Read the INSTALL file.
	@false

# (find-eev "rcfiles/change")
# (find-eev "rcfiles/change" "clean")

#cleantmp:
#	cd -rm -fv *.aux *.log *.dvi *.ps ee.eeg ee.gdb ee.tex

# �tarball�  (to ".tarball")
# (find-fline ".files")
# (find-angg ".zshrc" "eev-current")
#
/tmp/eev-current.tar.gz:
	(TZ=GMT date; date) > VERSION
	tar -cvzf $@ $$(cat .files)


# (find-angg "bin/emacs-default")
# CVSEMACS = $(HOME)/bigsrc/emacs/src/emacs
# CVSEMACS = $(HOME)/bin/emacs-default
CVSEMACS = emacs


# �htmlize.el�  (to ".htmlize.el")
# (find-eev "htmlize-eev.el" "htmlize.el")
# http://www.emacswiki.org/emacs/Htmlize
# http://www.emacswiki.org/emacs/download/htmlize.el
# cp -v $(S)/http/fly.srk.fer.hr/~hniksic/emacs/htmlize.el . || \
# wget     http://fly.srk.fer.hr/~hniksic/emacs/htmlize.el
#
htmlize.el:
	cp -v $(S)/http/www.emacswiki.org/emacs/download/htmlize.el . || \
	wget     http://www.emacswiki.org/emacs/download/htmlize.el

# (find-eeshell-here "make htmls")
# (find-eev "htmlize-all.el")
#
htmls: htmlize.el
	$(CVSEMACS) -fg bisque -bg black -fn fixed -Q -l htmlize-all.el



#  Local Variables:
#  coding:               raw-text-unix
#  ee-anchor-format:     "�%s�"
#  End:
