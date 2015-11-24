;; eev-sshot.el - hyperlinks to series of screenshots (and tools to take shots)
;; Author:  Eduardo Ochs <eduardoochs@gmail.com>
;; License: GPL (headers missing at the moment! Sorry...)
;; Version: 2006oct02
;; (First version: 2006sep30)
;; Author home page: <http://angg.twu.net/>
;; IRC: I'm "edrx" at freenode, channels #emacs and #eev.
;; URLs for this file:
;;   <http://angg.twu.net/eev-current/eev-sshot.el>
;;   <http://angg.twu.net/eev-current/eev-sshot.el.html>
;; Examples of output (in html flipbook format):
;;   <http://angg.twu.net/flipbooks/eesteps.html>
;;   <http://angg.twu.net/flipbooks/ee-glyph.html>
;;
;; This file contains functions for:
;; (1) taking series of (numbered) screenshots in Emacs,
;; (2) producing an HTML "flipbook interface" for viewing them,
;; (3) a minor mode for viewing screenshot series inside Emacs,
;; (4) hyperlinking to a specific screenshot in a series.
;;
;; WARNING: (1) is tricky to run - it requires a prepared Fvwm that
;; reacts to commands sent by FvwmCommand. Finding the geometry of a
;; window, including the window's borders and title bar - that are
;; added by the window manager - is something that depends on the WM,
;; and I've been using Fvwm since the dawn of times and I know
;; practically nothing about other WMs...

;; (Old stuff that I'm rewriting...)
;;
;; The "take screenshots" part requires fvwm with eev support to get
;; the geometry of the Emacs window window (`sshot-save-geom-fvwm'),
;; and ImageMagick to generate the pngs; you can bypass the dependency
;; on fvwm if you have other ways to write the geometry of the region
;; to take screenshots of to the file /tmp/sshot.geom. See:
;;   <http://angg.twu.net/eev-current/eev-langs.el.html#eefvwm>
;; Note: if you find other ways to get the geometry please tell me!!!
;;
;; The "view screenshots" part requires just a graphical Emacs.
;; Navigation through the screenshots in sshot-view-mode is done with
;; the keys <left> and <right>. This is better than watching passively
;; the animations in <http://angg.twu.net/eev-current/anim/> because:
;;   (1) png screenshots can be viewed inside Emacs,
;;   (2) they doesn't require a browser and a Flash plugin,
;;   (3) you can "move forward and backward in time" though them,
;;   (4) you can spend as much or as little time as you wish in each
;;       screenshot,
;;   (5) you can create hyperlinks to specific shots with `find-sshot'.
;;
;; The "html flipbooks" part generates HTML pages like these:
;;   <http://angg.twu.net/flipbooks/eesteps.html>
;;   <http://angg.twu.net/flipbooks/ee-glyph.html>
;; You won't need to run it unless you are creating your own series of
;; screenshots - but for that you will need fvwm, etc.
;;
;; Note: compare this with the "stepper" functions of eev:
;;   <http://angg.twu.net/eev-current/eev-steps.el.html>
;; the functions there can be thought as hyperlinks to _performing_
;; series of steps; the functions here implement hyperlinks to the
;; _expected result_ of performing series of steps.

;; script to removes duplicates:
;;   <http://angg.twu.net/bin/sshot-uniq.lua.html>
;;   <http://angg.twu.net/.emacs.html#sshot>


;; The style of this file is reminiscent of my Forth roots.


;; Save the desired geometry in "/tmp/sshot.geom".
;; WARNING: this depends on Fvwm and is not supposed to be easy to run! 
;;
(defvar sshot-geom-file    "/tmp/sshot.geom") ; don't change this
(defvar sshot-fname-prefix "/tmp/sshot/test") ; "test_001.png", "_002.png"...
(defvar sshot-next         1)		      ; next screenshot to save

(defun sshot-save-fvwm-script ()
  (write-region "Current Exec sh -c \
                 'echo $[w.width]x$[w.height]+$[w.x]+$[w.y] > /tmp/sshot.geom'"
		nil "/tmp/sshot.geom.fvwm"))
(defun sshot-save-tcl-script  ()
  (write-region "bind . <Key-q> {
                   puts [exec FvwmCommand {read /tmp/sshot.geom.fvwm}]; exit
                 }" nil "/tmp/sshot.geom.tcl"))
(defun sshot-save-geom-fvwm   () (sshot-save-fvwm-script) (find-sh0
                                  "FvwmCommand 'read /tmp/sshot.geom.fvwm'"))
(defun sshot-save-geom-tcl    () (sshot-save-fvwm-script)
                                 (sshot-save-tcl-script)
				 (find-sh0 "wish /tmp/sshot.geom.tcl"))
(defun sshot-force-geom (geom) (write-region geom nil "/tmp/sshot.geom"))
(defun sshot-save-geom  () (sshot-save-geom-fvwm))    ; redefine this if needed
(defun sshot-geom       () (ee-no-trailing-nl (ee-read-file sshot-geom-file)))


;; Take a screenshot.
;; Depends on "import", from ImageMagick.
;;
(defun sshot-n-to-fname (n) (format "%s_%03d.png" sshot-fname-prefix n))
(defun sshot-fname-next () (sshot-n-to-fname sshot-next))
(defun sshot-import-cmd ()
  (format "import -window root -crop %s %s" (sshot-geom) (sshot-fname-next)))
(defun sshot-import     () (find-sh0 (sshot-import-cmd)))
(defun sshot-next++     () (setq sshot-next (1+ sshot-next)))
(defun sshot-dir        () (file-name-directory sshot-fname-prefix))
(defun sshot-mkdir      () (make-directory (file-name-directory (sshot-dir)) t))
(defun sshot-fname-*png () (concat sshot-fname-prefix "*.png"))
(defun sshot-rm-v-shots () (find-sh0 (format "rm -v %s" (sshot-fname-*png))))
(defun sshot-next=1     () (setq sshot-next 1))
(defun sshot-cursor     () (blink-cursor-mode 0))
(defun sshot-blink      () (blink-cursor-mode 1))
(defun sshot-init (prefix) (interactive) (setq sshot-fname-prefix prefix)
                           (sshot-rm-v-shots) (sshot-mkdir) (sshot-next=1)
			   (sshot-cursor))
(defun sshot-take       () (interactive) (sshot-import) (sshot-next++))


;; Discard the last screenshot taken if it's a duplicate.
;;
(defun sshot-read-file   (f) (with-temp-buffer
			       (insert-file-contents-literally f)
			       (buffer-string)))
(defun sshot-read-file-n (n) (sshot-read-file (sshot-n-to-fname n)))
(defun sshot-equal-prev  () (and (> sshot-next 2)
				 (equal (sshot-read-file-n (- sshot-next 1))
					(sshot-read-file-n (- sshot-next 2)))))
(defun sshot-remove      () (setq sshot-next (- sshot-next 1))
                            (delete-file (sshot-n-to-fname sshot-next)))
(defun sshot-remove*     () (while (sshot-equal-prev) (sshot-remove)))
(defun sshot-take-unique () (interactive) (sshot-take) (sshot-remove*))


;; Produce an html "flipbook interface" for the current series of screenshots.
;; Example of output: <http://angg.twu.net/flipbooks/eesteps.html>
;;
(defun sshot-aname      (n) (format "<a name=\"%03d\"></a>" n))
(defun sshot-imgsrc     (pr n) (format "<img src=\"%s_%03d.png\">" pr n))
(defun sshot-prev-text  (n) (format                   "&larr;%03d"       n))
(defun sshot-prev-href  (n) (format "<a href=\"#%03d\">&larr;%03d</a>" n n))
(defun sshot-this-href  (n) (format "<a href=\"#%03d\">%03d</a>" n n))
(defun sshot-next-text  (n) (format                   "%03d&rarr;"       n))
(defun sshot-next-href  (n) (format "<a href=\"#%03d\">%03d&rarr;</a>" n n))
(defun sshot-image-html (prefix max n) (format "%s\n%s<br>\n%s %s %s<br>\n"
       (sshot-aname n)
       (sshot-imgsrc prefix n)
       (if (<= n 1)   (sshot-prev-text (- n 1)) (sshot-prev-href (- n 1)))
       (sshot-this-href n)
       (if (>= n max) (sshot-next-text (+ n 1)) (sshot-next-href (+ n 1)))))
(defun sshot-images-html (prefix max) (mapconcat
			    (lambda (n) (sshot-image-html prefix max n))
			    (number-sequence 1 max)
			    "<br>\n\n"))
(defun sshot-html-wrap   (title body tail)
          (format "<html>\n%s\n%s</html>\n"
           (format "<head>\n<title>%s</title>\n</head>" title)
           (format "<body bgcolor=\"#4C4C4C\">\n\n%s\n%s\n</body>" body tail)))
(defun sshot-mkstr (s n) (mapconcat (lambda (n) s) (number-sequence 1 n) ""))
(defun sshot-html-3      (title prefix max) (sshot-html-wrap title
                                             (sshot-images-html prefix max)
					     (sshot-mkstr "<br>\n" 40)))
(defun sshot-stem       () (file-name-nondirectory sshot-fname-prefix))
(defun sshot-fname-html () (format "%s.html" sshot-fname-prefix))
(defun sshot-title-html () (format "flipbook: %s" (sshot-stem)))
(defun sshot-html-0     () (sshot-html-3 (sshot-title-html) (sshot-stem)
					 (- sshot-next 1)))
(defun sshot-write-html () (write-region (sshot-html-0) nil (sshot-fname-html)))
(defun sshot-take+      () (interactive) (sshot-take-unique) (sshot-write-html))

;; (global-set-key (kbd "<print>") 'sshot-take)
;; (global-set-key (kbd "<print>") 'sshot-take-unique)
;; (global-set-key (kbd "<print>") 'sshot-take+)

;; fvwm-sshot:
;; (find-man "1 fvwm" "Key [(window)] Keyname Context Modifiers Function")
;; (find-man "1 fvwm" "Modifiers is any combination")
;; (eefvwm0 "Key Print A N   Exec gnudoit '(sshot-take+)'")
;; (eefvwm0 "Key Print A N   -")




;; This is how I produced a certain series of screenshots.
;; You are not expected to understand all of this!!!
;; Preparation: 
;;   (eval-buffer)
;;   (set-frame-size (selected-frame) 80 25)
;;   (sshot-save-geom-fvwm)
;;   (recenter 12)
;;   (sshot-init "/tmp/sshot/eesteps")
;; Now we get into the states that are to be "photographed".
;; The keys here are M-e, then 10*<down>, C-e, etc, etc,
;; with <print>s at the right places.
;;   (find-efunctiondescr 'eesteps)
;;   (sshot-blink)
;;   (sshot-write-html)
;; Here's how to view that series of screenshots inside Emacs:
;;   (find-fline (sshot-dir))
;;   (find-fline "/tmp/sshot/")
;;   (find-sshot "/tmp/sshot/eesteps" 1)
;;
;; And here's how to download one such series of screenshots
;; (instead of producing it locally):
;;   mkdir -p /tmp/flipbooks/
;;   cd       /tmp/flipbooks/
;;   wget http://angg.twu.net/flipbooks/eesteps.tgz
;;   tar -xvzf eesteps.tgz
;; Now to view it:
;;   (find-sshot "/tmp/flipbooks/eesteps" 1)
;;
(defvar sshot-view-mode-map (make-sparse-keymap))
(define-key sshot-view-mode-map (kbd "<left>")  'sshot-open-prev)
(define-key sshot-view-mode-map (kbd "<right>") 'sshot-open-next)
(define-key sshot-view-mode-map (kbd "q")       'sshot-bury-all)
(define-minor-mode sshot-view-mode
  "Navigate through screenshots with <left> and <right>."
  nil " sshot-view" sshot-view-mode-map)

(defvar sshot-this          nil)	; like sshot-next
(defvar sshot-view-prefix   nil)	; like sshot-fname-prefix
(make-variable-buffer-local 'sshot-this)
(make-variable-buffer-local 'sshot-view-prefix)

(defun sshot-message    () "sshot-view-mode - navigate with <left>, <right>, q")
(defun sshot-pn-to-fname (p n) (format "%s_%03d.png" p n))
(defun sshot-exists-p    (p n) (file-exists-p (sshot-pn-to-fname p n)))
(defun sshot-not-found   (p n) (error "Not found: %s" (sshot-pn-to-fname p n)))
(defun sshot-assert      (p n) (or (sshot-exists-p p n) (sshot-not-found p n)))
(defun sshot-open        (p n) (sshot-assert p n)
                               (find-file (sshot-pn-to-fname p n))
			       (sshot-view-mode 1)
			       (setq sshot-view-prefix p sshot-this n)
			       (message (sshot-message)))
(defun sshot-open-prev      () (interactive)
                               (sshot-open sshot-view-prefix (- sshot-this 1)))
(defun sshot-open-next      () (interactive)
                               (sshot-open sshot-view-prefix (+ sshot-this 1)))
(defun sshot-bury-all       () (interactive) (let ((p sshot-view-prefix))
			        (if p (while (equal p sshot-view-prefix)
				        (bury-buffer)))))
(defun find-sshot        (p n) (sshot-open p n) (sshot-message))






(provide 'eev-sshot)
