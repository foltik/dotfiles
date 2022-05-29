(doom-load-envvars-file (concat doom-private-dir "env.el"))

(setq doom-modeline-major-mode-icon t)

(defun my/line ()
  (buffer-substring-no-properties
   (line-beginning-position)
   (line-end-position)))

(defun my/line-match-p (regexp)
  (string-match-p regexp (my/line)))

(defun my/insert-mode-p ()
  (eq evil-state 'insert))
(defun my/normal-mode-p ()
  (eq evil-state 'normal))

(defun my/kbd-replace (str)
  "Convert STR into a keyboard macro string by replacing terminal key sequences with GUI keycodes."
  (let ((kbd-regex '(("ESC" . "<escape>")
                     ("DEL" . "<delete>" )
                     ("BS"  . "<backspace>")
                     ("RET" . "<return>")
                     ("SPC" . "<SPC>")
                     ("TAB" . "<tab>"))))
    (my/replace-regexps-in-string str kbd-regex)))

(setq my//kbd-p nil)
(defun my/kbd!-p () (eq my//kbd-p t))

(defun kbd! (str)
  "Execute the key sequence defined by STR like a VIM macro."
  (let ((minibuffer-message-timeout 0))
    (setq my//kbd-p t)
    (execute-kbd-macro (read-kbd-macro (my/kbd-replace str)))
    (setq my//kbd-p nil)))

(defun my/buffer-local-set-key (key fn)
  (let ((mode (intern (format "%s-local-mode"     (buffer-name))))
        (map  (intern (format "%s-local-mode-map" (buffer-name)))))
    (unless (boundp map)
      (set map (make-sparse-keymap))
      (evil-make-overriding-map map 'normal))
    (eval
     `(define-minor-mode ,mode
        "A minor mode for buffer-local keybinds."
        :keymap ,map))
    (eval
     `(define-key ,map ,key #',fn))
    (funcall mode t)))

(defun my/replace-regexps-in-string (str regexps)
  "Replace all pairs of (regex . replacement) defined by REGEXPS in STR."
  (if (null regexps)
      str
    (my/replace-regexps-in-string
     (replace-regexp-in-string (caar regexps) (cdar regexps) str t)
     (cdr regexps))))

(setq auth-sources '("~/.authinfo.gpg"))

(use-package auth-source :commands auth-source-search)

(defmacro my/with-credential (query name &rest body)
  "Evaluates BODY with NAME bound as the secret from AUTH-SOURCES matching criteria QUERY."
  `
  (let* ((entry (nth 0 (auth-source-search ,@query)))
         (,name (when entry
                  (let ((secret (plist-get entry :secret)))
                    (if (functionp secret)
                        (funcall secret)
                      secret)))))
    ,@body))

(setq doom-theme 'doom-catppuccin)

(setq doom-font                (font-spec :family "monospace" :size 13)
      doom-big-font            (font-spec :family "monospace" :size 13)
      doom-variable-pitch-font (font-spec :family "sans-serif" :size 13))

(set-frame-parameter (selected-frame) 'alpha-background 85)
(add-to-list 'default-frame-alist '(alpha-background . 85))

(setq evil-want-fine-undo t)

(defun my/line-numbers-relative ()
  (setq display-line-numbers 'relative))
(defun my/line-numbers-absolute ()
  (setq display-line-numbers 'absolute))
(add-hook 'evil-insert-state-entry-hook #'my/line-numbers-absolute)
(add-hook 'evil-insert-state-exit-hook #'my/line-numbers-relative)

(use-package copilot
  :commands (copilot-complete))

(defun my/copilot-complete ()
  (interactive)
  (copilot-complete)
  (my/hydra-copilot/body)
  (copilot-clear-overlay))

(defhydra my/hydra-copilot ()
  "Copilot"
  ("<return>"  copilot-accept-completion   "Accept" :color blue )
  ("<tab>"     copilot-next-completion     "Next" )
  ("<backtab>" copilot-previous-completion "Prev")
  ("<escape>"  copilot-clear-overlay       "Cancel" :color blue))

(setq doom-scratch-initial-major-mode 'lisp-interaction-mode)

(map! :leader
      "b" nil
      "f" nil
      "h" nil
      "p" nil
      "t" nil
      "w" nil)

(map! :map evil-org-mode-map
  :n "zc" nil)

(map!
 :desc "Increase font size" :ni "C-=" #'text-scale-increase
 :desc "Decrease font size" :ni "C--" #'text-scale-decrease)

(map!
 :desc "Copilot" :i "C-," #'my/copilot-complete)



(map! :map minibuffer-mode-map
      :desc "Next history" "C-j" #'next-history-element
      :desc "Prev history" "C-k" #'previous-history-element)

(map! :leader
      :desc "M-x" "x" #'counsel-M-x
      :desc "M-:" ";" #'pp-eval-expression)

(map! :leader
      :desc "Find file" "." #'counsel-find-file
      :desc "Find dir"  ">" #'+default/dired

      :desc "Find in project" "SPC" #'+ivy/projectile-find-file
      :desc "Find in project uncached" "C-SPC" #'my/projectile-find-file-nocache)

(defun my/projectile-find-file-nocache ()
  (interactive)
  (projectile-invalidate-cache nil)
  (+ivy/projectile-find-file))

(map! :leader
      :desc "Switch buffer" "," #'+vertico/switch-workspace-buffer
      :desc "Switch all buffers"  "<" #'consult-buffer)

(map! :leader
      :desc "Search online" "/" #'my/counsel-search)

(map! :leader
      :prefix ("b" . "buffers")

      :desc "Switch buffer" "b" #'consult-buffer
      :desc "ibuffer" "i" #'ibuffer

      :desc "Kill buffer" "d" #'kill-current-buffer
      :desc "Kill all buffers" "D" #'doom/kill-all-buffers)

(map! :leader
      :prefix ("f" . "files")

      :desc "Recent files" "r" #'consult-recent-file

      :desc "Find file" "f" #'counsel-find-file
      :desc "Find file as root" "u" #'doom/sudo-find-file
      :desc "Find package" "p" #'counsel-find-library

      :desc "Copy this file" "c" #'doom/copy-this-file
      :desc "Delete this file" "d" #'doom/delete-this-file
      :desc "Delete file" "D" #'delete-file
      :desc "Move this file" "m" #'doom/move-this-file
      :desc "Revert this file" "l" #'revert-buffer

      :desc "Copy file path" "y" #'+default/yank-buffer-path
      :desc "Copy project file path" "Y" #'+default/yank-buffer-path-relative-to-project

      :desc "Open scratch" "x" #'doom/open-scratch-buffer)

(map! :leader
      :prefix ("f s" . "snippets")
      :desc "New snippet"  "n" #'yas-new-snippet
      :desc "Edit snippet" "e" #'yas-visit-snippet-file
      :desc "Browse docs"  "?" #'my/yas-browse-docs)

(defun my/yas-browse-docs ()
  (interactive)
  (browse-url "https://joaotavora.github.io/yasnippet"))

(map! :leader
      :prefix ("f e" . "emacs")
      :desc "Find in config" "f" #'doom/find-file-in-private-config
      :desc "Reload config" "r" #'doom/reload

      :desc "Edit config"   "c" #'my/edit-config
      :desc "Edit packages" "p" #'my/edit-packages
      :desc "Edit env"      "e" #'my/edit-env
      :desc "Edit init"     "i" #'my/edit-init)

(defun my/edit-config ()
  (interactive)
  (find-file (concat doom-private-dir "config.org")))
(defun my/edit-packages ()
  (interactive)
  (find-file (concat doom-private-dir "packages.el")))
(defun my/edit-init ()
  (interactive)
  (find-file (concat doom-private-dir "init.el")))
(defun my/edit-env ()
  (interactive)
  (find-file (concat doom-private-dir "env.el")))

(define-derived-mode org-config-mode org-mode "Org config mode")
(add-to-list 'auto-mode-alist '("config\\.org" . org-config-mode))

(map! :leader
      :prefix ("h" . "help")

      :desc "Apropos" "/" #'consult-apropos
      :desc "Apropos docs" "?" #'apropos-documentation

      :desc "Help at point" "p" #'helpful-at-point
      :desc "Help info" "h" #'info
      :desc "Help for help" "H" #'help-for-help

      :desc "Describe mode" "m" #'describe-mode
      :desc "Describe minor modes" "M" #'doom/describe-active-minor-mode
      :desc "Describe function" "f" #'counsel-describe-function
      :desc "Describe function key" "F" #'where-is
      :desc "Describe variable" "v" #'counsel-describe-variable
      :desc "Describe custom variable" "V" #'doom/help-custom-variable
      :desc "Describe command" "x" #'helpful-command
      :desc "Describe key" "k" #'describe-key-briefly
      :desc "Describe key fully" "K" #'describe-key
      :desc "Describe char" "'" #'describe-char
      :desc "Describe coding system" "\"" #'describe-coding-system
      :desc "Describe input method" "i" #'describe-input-method

      :desc "Emacs manual" "e" #'info-emacs-manual
      :desc "ASCII table" "a" #'my/ascii-table

      :desc "View messages" "e" #'view-echo-area-messages
      :desc "View keystrokes" "l" #'view-lossage)

(defface my/ascii-table-highlight-face
  '((t (:foreground "pink")))
  "Face for highlighting ASCII chars.")

(defun my/ascii-table ()
  "Display basic ASCII table (0 thru 128)."
  (interactive)
  (pop-to-buffer "*ASCII*")
  (erase-buffer)
  (setq buffer-read-only nil)
  (my/buffer-local-set-key "q" #'+popup/quit-window)
  (setq lower32 '("nul" "soh" "stx" "etx" "eot" "enq" "ack" "bel"
                  "bs" "ht" "nl" "vt" "np" "cr" "so" "si"
                  "dle" "dc1" "dc2" "dc3" "dc4" "nak" "syn" "etb"
                  "can" "em" "sub" "esc" "fs" "gs" "rs" "us"))
  (save-excursion (let ((i -1))
                    (insert " Hex  Dec  Char |  Hex  Dec  Char |  Hex  Dec  Char |  Hex  Dec  Char\n")
                    (insert " ---------------+-----------------+-----------------+----------------\n")
                    (while (< i 31)
                      (insert (format "%4x %4d %4s  | %4x %4d %4s  | %4x %4d %4s  | %4x %4d %4s\n"
                                      (setq i (+ 1  i)) i (elt lower32 i)
                                      (setq i (+ 32 i)) i (single-key-description i)
                                      (setq i (+ 32 i)) i (single-key-description i)
                                      (setq i (+ 32 i)) i (single-key-description i)))
                      (overlay-put (make-overlay (- (point) 4)  (- (point) 1))  'face 'my/ascii-table-highlight-face)
                      (overlay-put (make-overlay (- (point) 22) (- (point) 19)) 'face 'my/ascii-table-highlight-face)
                      (overlay-put (make-overlay (- (point) 40) (- (point) 37)) 'face 'my/ascii-table-highlight-face)
                      (overlay-put (make-overlay (- (point) 58) (- (point) 55)) 'face 'my/ascii-table-highlight-face)
                      (setq i (- i 96))
                      ))))

(set-popup-rule! "^\\*ASCII"
  :side 'right
  :select t
  :width 70)

(map! :leader
      :prefix ("h d" . "doom")

      :desc "Doom manual" "d" #'doom/help
      :desc "Doom FAQ" "f" #'doom/help-faq
      :desc "Doom modules" "m" #'doom/help-modules
      :desc "Doom news" "n" #'doom/help-news
      :desc "Doom help search" "/" #'doom/help-search-headings

      :desc "Doom version" "v" #'doom/version

      :desc "Doom package configuration" "p" #'doom/help-package-config
      :desc "Doom sandbox" "x" #'doom/sandbox)

(map! :leader
      :prefix ("p" . "projects")
      :desc "Switch project" "p" #'my/projectile-switch-project
      :desc "Add new project" "a" #'projectile-add-known-project
      :desc "Remove project" "d" #'projectile-remove-known-project

      :desc "Find in project root" "." #'counsel-projectile-find-file
      :desc "Search in project" "/" #'+default/search-project

      :desc "Invalidate project cache" "i" #'projectile-invalidate-cache

      :desc "Run cmd in project root" "!" #'projectile-run-shell-command-in-root
      :desc "Run async cmd in project root" "&" #'projectile-run-async-shell-command-in-root)

(defun my/projectile-find-in-root ()
  (interactive)
  (counsel-find-file nil projectile-project-root))

(map! :leader
      :prefix ("t" . "toggle")
      ;; Wrap
      :desc "Auto Wrap"      "a" #'auto-fill-mode
      :desc "Wrap Indicator" "c" #'global-display-fill-column-indicator-mode
      :desc "Wrap Column"    "C" #'set-fill-column
      :desc "Line Wrap"      "w" #'visual-line-mode
      ;; Modes
      :desc "Flycheck" "f" #'flycheck-mode
      :desc "Keycast"  "k" #'keycast-mode
      ;; Files
      :desc "Read-only" "r" #'read-only-mode)

(defun my/auto-fill-mode (cols)
  (interactive))

(map! :leader
      :prefix-map ("w" . "window")
      ;; Navigation
      :desc "Go..." "w" #'ace-window
      :desc "Go left" "h" #'evil-window-left
      :desc "Go down" "j" #'evil-window-down
      :desc "Go up" "k" #'evil-window-up
      :desc "Go right" "l" #'evil-window-right
      :desc "Go other" "o" #'other-window
      ;; Layout
      :desc "Rotate up" "K" #'evil-window-rotate-upwards
      :desc "Rotate down" "J" #'evil-window-rotate-downwards
      ;; Splits
      :desc "VSplit" "=" #'+evil/window-vsplit-and-follow
      :desc "HSplit" "-" #'+evil/window-split-and-follow
      :desc "Tear off" "t" #'tear-off-window
      ;; History
      :desc "Undo" "u" #'winner-undo
      :desc "Redo" "U" #'winner-redo
      ;; Misc
      :desc "Resize" "r" #'my/hydra-window-resize/body
      :desc "Balance" "b" #'balance-windows
      ;; Management
      :desc "Kill window" "d" #'+workspace/close-window-or-workspace)
;; TODO: Maybe check out:
;; evil-window-mru

(setq my/window-resize-step 3)

(defun my/window-increase-height ()
  (interactive)
  (evil-window-increase-height my/window-resize-step))
(defun my/window-decrease-height ()
  (interactive)
  (evil-window-decrease-height my/window-resize-step))
(defun my/window-increase-width ()
  (interactive)
  (evil-window-increase-width my/window-resize-step))
(defun my/window-decrease-width ()
  (interactive)
  (evil-window-decrease-width my/window-resize-step))

(defhydra my/hydra-window-resize ()
  "Resize window"
  ("=" my/window-increase-height "++Height")
  ("-" my/window-decrease-height "--Height")
  ("<" my/window-decrease-width  "--Width")
  (">" my/window-increase-width  "++Width"))

(map! :map org-config-mode-map
      :localleader
      :v :desc "Eval Region" "e" #'eval-region
      :n :desc "Eval Source" "e" #'my/org-config-eval-source)

(defun my/org-config-eval-source ()
  (interactive)
  (org-ctrl-c-ctrl-c)
  (org-babel-remove-result))

(map! :map rustic-mode-map
      :localleader
      :desc "Debug..." "d" #'my/rust/dap-hydra/body)

(map! :map rustic-mode-map
      :desc "Pluralize import" "," #'my/rust/import-pluralize
      :desc "Singularize import" "<backspace>" #'my/rust/import-singularize
      :desc "Singularize import" "C-<backspace>" #'my/rust/import-c-singularize)

(defhydra my/rust/dap-hydra (:color pink :hint nil :foreign-keys run)
  "
^Stepping^          ^Switch^                 ^Breakpoints^         ^Debug^                     ^Eval
^^^^^^^^----------------------------------------------------------------------------------------------------------------
_n_: Next           _ss_: Session            _bb_: Toggle          _dd_: Debug binary          _ee_: Eval
_i_: Step in        _st_: Thread             _bd_: Delete          _dr_: Restart debugging     _es_: Eval thing at point
_o_: Step out       _sf_: Stack frame        _ba_: Add                                       _ea_: Add expression
_c_: Continue       _su_: Up stack frame     _bc_: Set condition
_Q_: Disconnect     _sd_: Down stack frame   _bh_: Set hit count
                  _sl_: List locals        _bl_: Set log message
                  _sb_: List breakpoints
                  _sS_: List sessions
"
  ("n" dap-next)
  ("i" dap-step-in)
  ("o" dap-step-out)
  ("c" dap-continue)
  ("r" dap-restart-frame)
  ("ss" dap-switch-session)
  ("st" dap-switch-thread)
  ("sf" dap-switch-stack-frame)
  ("su" dap-up-stack-frame)
  ("sd" dap-down-stack-frame)
  ("sl" dap-ui-locals)
  ("sb" dap-ui-breakpoints)
  ("sS" dap-ui-sessions)
  ("bb" dap-breakpoint-toggle)
  ("ba" dap-breakpoint-add)
  ("bd" dap-breakpoint-delete)
  ("bc" dap-breakpoint-condition)
  ("bh" dap-breakpoint-hit-condition)
  ("bl" dap-breakpoint-log-message)
  ("dd" my/rust/debug-binary)
  ("dr" dap-debug-restart)
  ("ee" dap-eval)
  ("ea" dap-ui-expressions-add)
  ("es" dap-eval-thing-at-point)
  ("q" nil "quit" :color blue)
  ("Q" dap-disconnect :color red))

(map! :prefix "z"
 :desc "Kill buffer" :n "x" #'kill-current-buffer
 :desc "Kill window" :n "c" #'+workspace/close-window-or-workspace)

(map! :prefix "["
      :desc "Start of fn" :n "f" #'beginning-of-defun)

(map! :prefix "]"
      :desc "End of fn" :n "f" #'end-of-defun)



(add-to-list 'projectile-globally-ignored-files "Cargo.lock")

(defun my/rust/import-pluralize ()
  "Convert a singular import into a brace-wrapped plural import."
  (interactive)
  (if (and
       (not (my/kbd!-p))
       (my/insert-mode-p)
       (my/line-match-p
        ;; use foo::bar::baz;
        (rx line-start "use "
            (+ (+ word) "::")
            (+ word)
            (? ";") line-end)))
      (kbd! "ESC vb S} f} i,")
    (insert ",")))

(defun my/rust/import-singularize ()
  "Convert a brace-wrapped plural import into a singular import."
  (interactive)
  (if (and
       (not (my/kbd!-p))
       (my/insert-mode-p)
       (my/line-match-p
        ;; use foo::bar::baz::{qux::quo,};
        (rx line-start "use "
            (+ (+ word) "::")
            "{" (* (+ word) "::") (+ word) ",}"
            (? ";") line-end)))
      (kbd! "ESC l dF, ds} $i")
    (evil-delete-backward-char-and-join 1)))

(defun my/rust/import-c-singularize ()
  "Convert a brace-wrapped plural import into a singular import."
  (interactive)
  (if (and
       (not (my/kbd!-p))
       (my/insert-mode-p)
       (my/line-match-p
        ;; use foo::bar::baz::{qux::quo,   };
        (rx line-start
            "use "
            (+ (+ word) "::")
            "{" (* (+ word) "::") (+ word) "," (* whitespace) "}"
            (? ";") line-end)))
      (kbd! "ESC l dF, ds} $i")
    (backward-kill-word 1)))

(defun my/rust/debug-config (args)
  (append
   `(:type "lldb-vscode"
   ;; `(:type "lldb"
     :request "launch"
     :dap-server-path ,(list (executable-find "lldb-vscode"))
     ;; :dap-server-path ,(list (executable-find "rust-lldb"))
     ,@args)))

;; use a::TestThin
;; (:MIMode "gdb"
;;  :miDebuggerPath "gdb"
;;  :stopAtEntry t
;;  :externalConsole
;;  :json-false
;;  :type "cppdbg"
;;  :request "launch"
;;  :name "test test2"
;;  :args ["test2" "--exact" "--nocapture"]
;;  :cwd "/home/lain/Code/test/rust/debug"
;;  :sourceLanguages ["rust"]
;;  :program "/home/lain/Code/test/rust/debug/target/debug/deps/...")

;; (require 'dap-cpptools)
(defun my/rust/debug-binary (args)
  (interactive "sArgs: ")
  (let* ((root (projectile-project-root))
         (name (projectile-project-name))
         (target (concat root "target/debug/" name)))
    ;; (rustic-cargo-build)
    (dap-debug
     (my/rust/debug-config
      `(:program ,target
        :cwd ,root
        :args ,(apply #'vector (split-string-and-unquote args)))))))

(defun my/rust/debug-lsp-runnable (runnable)
  "Select and debug a RUNNABLE action."
  (interactive (list (lsp-rust-analyzer--select-runnable)))
  (-let (((&rust-analyzer:Runnable
           :args (&rust-analyzer:RunnableArgs :cargo-args :workspace-root? :executable-args)
           :label) runnable))
    (pcase (aref cargo-args 0)
      ("run" (aset cargo-args 0 "build"))
      ("test" (when (-contains? (append cargo-args ()) "--no-run")
                (cl-callf append cargo-args (list "--no-run")))))
    (->> (append (list (executable-find "cargo"))
                 cargo-args
                 (list "--message-format=json"))
         (s-join " ")
         (shell-command-to-string)
         (s-lines)
         (-keep (lambda (s)
                  (condition-case nil
                      (-let* ((json-object-type 'plist)
                              ((msg &as &plist :reason :executable) (json-read-from-string s)))
                        (when (and executable (string= "compiler-artifact" reason))
                          executable))
                    (error))))
         (funcall
          (lambda (artifact-spec)
            (pcase artifact-spec
              (`() (user-error "No compilation artifacts or obtaining the runnable artifacts failed"))
              (`(,spec) spec)
              (_ (user-error "Multiple compilation artifacts are not supported")))))
         (list :name label
               :args executable-args
               :cwd workspace-root?
               ;; :sourceLanguages ["rust"]
               :stopAtEntry t
               :stopAtEntry :json-true
               :externalConsole :json-false
               :program)
         (my/rust/debug-config)
         (dap-debug))))
(advice-add #'lsp-rust-analyzer-debug :override #'my/rust/debug-lsp-runnable)

;; (setq projectile-project-search-path
;;       '("~/Code"))

(defun my/projectile-switch-project ()
  (interactive)
  ;; Prune projects which no longer exist
  (dolist (project projectile-known-projects)
    (unless (file-directory-p project)
      (projectile-remove-known-project project)))
  (call-interactively #'counsel-projectile-switch-project))

(setq lsp-ui-doc-show-with-mouse t)

(defun my/counsel-search ()
  (interactive)
  (unless (boundp 'my/kagi-found)
    (my/with-credential
     (:host "kagi.com") token
     (if token
         (progn
           (setq my/kagi-found (if token t nil))
           (setq counsel-search-engines-alist
                 `((kagi
                    "https://duckduckgo.com/ac/"
                    ,(format "https://kagi.com/search?token=%s&q=" token)
                    counsel--search-request-data-ddg)))
           (setq counsel-search-engine 'kagi))
       (warn "Token for kagi.com not found in authinfo. Falling back to default search engine."))))
  (call-interactively #'counsel-search))

(after! keycast
  (define-minor-mode keycast-mode
    "Show current command and its key binding in the mode line."
    :global t
    (if keycast-mode
        (progn
          (add-to-list 'global-mode-string '("" keycast-mode-line))
          (add-hook 'pre-command-hook 'keycast--update t))
      (progn
        (setq global-mode-string (delete '("" keycast-mode-line) global-mode-string))
        (remove-hook 'pre-command-hook 'keycast--update))))

  (dolist (input '(self-insert-command
                    org-self-insert-command))
    (add-to-list 'keycast-substitute-alist `(,input nil)))

  (dolist (event '(mouse-event-p
                   mouse-movement-p
                   mwheel-scroll
                   lsp-ui-doc--handle-mouse-movement
                   ignore))
    (add-to-list 'keycast-substitute-alist `(,event nil))))

(load! "lisp/emacs-everywhere.el")
(setq emacs-everywhere-paste-command '("xdotool" "key" "--clearmodifiers" "ctrl+v"))
(setq emacs-everywhere-frame-parameters
      '((title  . "Emacs Everywhere")
        (width  . 120)
        (height . 36)))
