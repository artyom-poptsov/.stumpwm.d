;;; stumpwmrc.lisp -- StumpWM configuration             -*- lisp -*-

(in-package :stumpwm)

;;; Global variables

(defvar *portage-timestamp-file*
  "/usr/portage/metadata/timestamp.chk"
  "Path to the portage timestamp file.")


;;; Load needed services

(defun pgrep (proc-name)
  "pgrep wrapper.  Return PIDs of given process `PROC-NAME', or an
empty string if the does not exist."
  (run-shell-command (concat "pgrep -u " (getenv "USER") " " proc-name) t))

(defun run-daemon (daemon args-string)
  "Start `DAEMON' if it has not been started yet.  Pass `ARGS-STRING'
to the `DAEMON'."
  (and (= (length (pgrep daemon)) 0)
       (run-shell-command (concat daemon " " args-string))))

(run-daemon "unclutter"    "-idle 10 --root &")
(run-daemon "xscreensaver" "-no-splash &")
(run-daemon "urxvtd"       "-q -o -f &")
(run-daemon "emacs"        "--daemon &")

;; TODO: Add tray for stumpwm.
;(run-daemon "trayer"       "--SetDockType false --transparent true --expand false &")


;;; Groups

;; FIXME: Remove "Default" group.
(run-commands "gnew L"
	      "gnew I"
	      "gnew S"
	      "gnew P"
	      "gnew F"			; FS
	      "gnew T"			; Term
	      "gnew W")			; Web


;;; Commands

(defcommand portage/get-last-sync () ()
  (with-open-file (stream *portage-timestamp-file*)
    (read-line stream nil)))

;; from http://en.wikipedia.org/wiki/User:Gwern/.stumpwmrc
(defun cat (&rest strings)
  "A shortcut for (concatenate 'string foo bar)."
  (apply 'concatenate 'string strings))


;;;

(defvar *browser* "firefox-bin")

;; Search the web with ducduckgo.
(defcommand duck (search)
  ((:string "Search in web: "))
  "Search Web with DuckDuckGo"
  (check-type search string)
  (substitute #\+ #\Space search)
  (run-shell-command
   (cat *browser* "'https://duckduckgo.com/?q=" search "'")))


;;; Mode Line

(toggle-mode-line (current-screen) (current-head))

;; FIXME: Check if there are any standard ways of doing that.
(defun get-battery-stat ()
  (run-shell-command
   (concat
   "acpitool -b "
   "| cut -d ':' -f 2 "
   "| awk -F '[,]' '{printf \"%s%s\", $1, $2}' "
   "| sed s/Discharging/\-/ | sed s/Unknown// "
   "| sed s/Full// "
   "| sed s/Charging/+/")
   t))

(setf *screen-mode-line-format*
      (list "%g | %w ^>| "
	    '("^7*" (:eval (get-battery-stat)))
	    " "
	    '("^7*" (:eval (time-format "%k:%M")))))

(setf *mode-line-timeout*      3)
(setf *mode-line-border-width* 0)
(setf *mode-line-pad-y* 0)
(setf *mode-line-pad-x* 0)


;;; Window Appearance

(setf *normal-border-width*  1)
(setf *maxsize-border-width* 0)
(setf *window-border-style* :thin)


;;; Tools

;; Open a new urxvt terminal window.
(define-key *top-map* (kbd "s-RET")
  "exec urxvtc -tr -tint gray60 -fg gray -sh 90 +sb")

;; Start an Emacs client.
(define-key *top-map* (kbd "s-e")
  "exec emacsclient -c")

;; Lock the screen.
(define-key *top-map* (kbd "C-s-l")
  "exec xscreensaver-command --lock")

(define-key *top-map* (kbd "s-d")
  "exec dmenu_run -b")


;;; Window management

(define-key *top-map* (kbd "s-f")
  "fullscreen")

(define-key *top-map* (kbd "s-j")
  "pull-hidden-next")

(define-key *top-map* (kbd "s-k")
  "pull-hidden-previous")


;;; Group Management

(defun number->string (n)
  (format nil "~d" n))

;; Use Awesome style of switching between groups.
(loop with keys = '("!" "@" "#" "$" "%" "^" "&" "*") for i from 1 to 8 do
     (define-key *top-map* (kbd (cat "s-" (nth (- i 1) keys)))
       (cat "gmove " (number->string i))))

;; Use Awesome style of moving windows between groups.
(loop for i from 1 to 8 do
     (define-key *top-map* (kbd (cat "s-" (number->string i)))
       (cat "gselect " (number->string i))))


;;; Hooks

;; Taken from
;; <https://github.com/denlab/stumpwm-config/blob/master/.stumpwmrc.fabrice>
;;
;; display the key sequence in progress
(defun key-press-hook (key key-seq cmd)
  (declare (ignore key))
  (unless (eq *top-map* *resize-map*)
    (let ((*message-window-gravity* :bottom-right)
	  ;; FIXME: It doesn't work.
	  (*timeout-wait*           1))
      (message "Key sequence: ~a" (print-key-seq (reverse key-seq))))
    (when (stringp cmd)
      ;; give 'em time to read it
      ;; FIXME: This causes annoying delay during switching of groups.
      (sleep 0.1))))

(defmacro replace-hook (hook fn)
  `(remove-hook ,hook ,fn)
  `(add-hook ,hook ,fn))

;; Uncomment this if you want to get notification with key sequence in
;; progress.
;(replace-hook *key-press-hook* 'key-press-hook)

;;; stumpwmrc.lisp ends here.
