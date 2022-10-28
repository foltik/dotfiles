;;; -*- lexical-binding: t; -*-

(doom-load-envvars-file (concat doom-user-dir "env.el"))

(setq doom-modeline-major-mode-icon t)

(use-package request
  :commands request)

(defmacro request! (url plist success &optional error)
  "Makes an HTTP request with `request`, running SUCCESS on success, and
ERROR on error if specified.

Any arguments of LAMBDA are bound to the corresponding plist keys
returned by `request`."
  (let ((handler (lambda (fn)
                   ;; Wraps a lambda in `cl-function`,
                   ;; and converts args (foo) into (&key foo &allow-other-keys)
                   `(cl-function
                     (lambda
                       ,(append
                         (mapcan (lambda (arg) `(&key ,arg))
                                 (cadr fn))
                         '(&allow-other-keys))
                       ,@(cddr fn))))))

    `(request ,url
       ,@plist
       :success ,(funcall handler success)
       ,@(if error `(:error ,(funcall handler error))))))

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

(setq my//vim!-p nil)
(defun my/vim!-p () (eq my//vim!-p t))

(defun vim! (str)
  "Execute the key sequence defined by STR like a VIM macro."
  (let ((minibuffer-message-timeout 0))
    (when (not (my/vim!-p))
      (setq my//vim!-p t)
      (execute-kbd-macro (read-kbd-macro (my/kbd-replace str)))
      (setq my//vim!-p nil))))

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

(defun ts/proxy-on ()
  (interactive)
  (setq url-proxy-services
        '(("http" . "127.0.0.1:20001")
          ("https" . "127.0.0.1:20001")
          ("no_proxy" . "^.*twosigma\\.com"))))

(defun ts/proxy-off ()
  (interactive)
  (setq url-proxy-services nil))

(setq sourcegraph-url "https://sourcegraph.app.twosigma.com")
(defun ts/sourcegraph-search ()
  (interactive)
  (call-interactively #'sourcegraph-search))
(defun ts/sourcegraph-browse ()
  (interactive)
  (call-interactively #'sourcegraph-open-in-browser))

(setq ts/search-url "https://search.app.twosigma.com/?q=%s")
(defun ts/search (query)
  (interactive "sQuery: ")
  (browse-url (format ts/search-url query)))

(defun ts/repo/root (&optional dir)
  (locate-dominating-file ($cwd dir) ".base_universe"))

(defun ts/repo/codebase (&optional dir)
  (locate-dominating-file ($cwd dir) ".git"))

(defun ts/repo/p (&optional dir)
  (when (ts/repo/root dir) t))

(defun shell! (fmt &rest args)
  (let* ((cmd (apply #'format (cons fmt args)))
         (cmd (format "%s 2>/dev/null" cmd))
         (result (shell-command-to-string cmd))
         (result (replace-regexp-in-string
                  "\r?\n$" ""
                  result)))
    (if (equal result "")
        nil
      result)))

(defun locate! (file &optional dir)
  (locate-dominating-file ($cwd dir) file))

(defun path! (&rest components)
  (apply #'f-join components))

(defun home! (&rest components)
  (apply #'path! (cons ($home) components)))

(defun advice! (fn  components)
  (apply #'f-join components))

(defun $file () buffer-file-name)
(defun $ext (&optional dot) (f-ext ($file) dot))
(defun $cwd (&optional dir)
  (if dir
      dir
    (f-dirname ($file))))
(defun $home ()
  (expand-file-name "~/"))

(setq doom-theme 'doom-catppuccin)

(setq doom-font                (font-spec :family "monospace" :size 13)
      doom-big-font            (font-spec :family "monospace" :size 13)
      doom-variable-pitch-font (font-spec :family "sans-serif" :size 13))

(set-frame-parameter (selected-frame) 'alpha-background 85)
(add-to-list 'default-frame-alist '(alpha-background . 85))

(setq evil-want-fine-undo t)

(defun my/scroll-up ()
  (interactive)
  (evil-scroll-line-up 2))

(defun my/scroll-down ()
  (interactive)
  (evil-scroll-line-down 2))

(defun my/scroll-up-bigly ()
  (interactive)
  (evil-scroll-line-up 5))

(defun my/scroll-down-bigly ()
  (interactive)
  (evil-scroll-line-down 5))

(defmacro my//center-cmd (name &rest body)
  `(defun ,name ()
     (interactive)
     ,@body
     (call-interactively #'evil-scroll-line-to-center)))

(my//center-cmd my/jump-forward  (better-jumper-jump-forward))
(my//center-cmd my/jump-backward (better-jumper-jump-backward))

(my//center-cmd my/search-next (evil-ex-search-next))
(my//center-cmd my/search-prev (evil-ex-search-previous))

(my//center-cmd my/forward-paragraph  (evil-forward-paragraph))
(my//center-cmd my/backward-paragraph (evil-backward-paragraph))

(my//center-cmd my/forward-section-begin (evil-forward-section-begin))
(my//center-cmd my/forward-section-end (evil-forward-section-end))
(my//center-cmd my/backward-section-begin (evil-backward-section-begin))
(my//center-cmd my/backward-section-end (evil-backward-section-end))

(defun my/duplicate-and-comment-line ()
  (interactive)
  (vim! "yyp k gcc j"))

(setq search-invisible t)

(defun my/line-numbers-relative ()
  (setq display-line-numbers 'relative))
(defun my/line-numbers-absolute ()
  (setq display-line-numbers 'absolute))
(add-hook 'evil-insert-state-entry-hook #'my/line-numbers-absolute)
(add-hook 'evil-insert-state-exit-hook #'my/line-numbers-relative)

(global-undo-tree-mode)
(add-hook 'evil-local-mode-hook 'turn-on-undo-tree-mode)

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

(use-package abbrev-mode
  :hook text-mode)

(setq +abbrev-file (concat doom-user-dir "abbrevs.el"))
(setq abbrev-file-name +abbrev-file)



(map! :leader
      ":" nil
      "b" nil
      "f" nil
      "h" nil
      "p" nil
      "t" nil
      "w" nil
      "c" nil)

(map! :map evil-org-mode-map
  :n "zc" nil)

(map!
 :desc "Increase font size" :ni "C-=" #'text-scale-increase
 :desc "Decrease font size" :ni "C--" #'text-scale-decrease
 :desc "Reset font size" :ni "C-+" #'my/text-scale-reset)

(defun my/text-scale-reset ()
  (interactive)
  (text-scale-set 0))

(map!
 :desc "Copilot" :i "C-?" #'my/copilot-complete)

(map! :map lsp-mode-map
      :desc "Apply code action" :ni "C-/" #'lsp-execute-code-action

      :desc "Show definitions" :ni "C-." #'+lookup/definition
      :desc "Show references" :ni "C->" #'my/lsp/lookup-references

      :desc "Jump backward" :ni "C-," #'better-jumper-jump-backward
      :desc "Jump backward" :ni "C-<" #'better-jumper-jump-forward)

(defun my/lsp/lookup-references ()
  (interactive)
  (lsp-treemacs-references t))

(map! :map minibuffer-mode-map
      :desc "Next history" "C-j" #'next-history-element
      :desc "Prev history" "C-k" #'previous-history-element)

(map!
 :desc "Save file" "C-s" #'save-buffer)

(map!
 :desc "Scroll up"         :ni "C-k" #'my/scroll-up
 :desc "Scroll down"       :ni "C-j" #'my/scroll-down
 :desc "Scroll up bigly"   :ni "C-S-k" #'my/scroll-up-bigly
 :desc "Scroll down bigly" :ni "C-S-j" #'my/scroll-down-bigly

 :desc "Jump forward"  :n "C-o" #'my/jump-forward
 :desc "Jump backward" :n "C-o" #'my/jump-backward

 :desc "Search next" :n "n" #'my/search-next
 :desc "Search prev" :n "N" #'my/search-prev

 :desc "Forward paragraph"  :n "}" #'my/forward-paragraph
 :desc "Backward paragraph" :n "{" #'my/backward-paragraph

 :desc "Forward section begin" :n "]]" #'my/forward-section-begin
 :desc "Forward section end"   :n "][" #'my/forward-section-end
 :desc "Backward section begin" :n "[]" #'my/backward-section-begin
 :desc "Backward section end"   :n "[[" #'my/backward-section-end)

(map!
 :desc "Undo tree visualizer" :n "U" #'undo-tree-visualize)

(map!
 :desc "Duplicate and comment line" :n "gC" #'my/duplicate-and-comment-line)

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
      :desc "Kill all buffers" "D" #'doom/kill-all-buffers

      :desc "Rename buffer" "r" #'my/rename-buffer)

(defun my/rename-buffer (name)
  (interactive (list (read-string "Rename: " (buffer-name))))
  (rename-buffer name))

(map! :leader
      :prefix ("c" . "code")

      :desc "Format region/buffer"         "f" #'+format/region-or-buffer
      :desc "Format imports" "F" #'lsp-organize-imports

      :desc "Rename symbol" "r" #'lsp-rename

      :desc "Show errors list" "x" #'+default/diagnostics
      :desc "Show errors tree" "X" #'lsp-treemacs-errors-list
      :desc "Show symbols tree" "s" #'lsp-treemacs-symbols

      :desc "Visit lens" "l" #'lsp-avy-lens

      :desc "Restart LSP" "q" #'lsp-restart-workspace)

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
      :prefix ("f a" . "abbrevs")
      :desc "Edit abbrevs"   "e" #'my/abbrev-edit
      :desc "Reload abbrevs" "r" #'my/abbrev-reload

      :desc "Add global abbrev" "a" #'my/abbrev-add-global
      :desc "Add mode abbrev"   "m" #'my/abbrev-add-mode)

(defun my/abbrev-edit ()
  (interactive)
  (find-file-other-window +abbrev-file))

(defun my/abbrev-reload ()
  (interactive)
  (read-abbrev-file +abbrev-file))

(defun my/abbrev-save ()
  (interactive)
  (write-abbrev-file +abbrev-file))

(defun my/abbrev-add-global ()
  (interactive)
  (call-interactively #'inverse-add-global-abbrev)
  (my/abbrev-save))

(defun my/abbrev-add-mode ()
  (interactive)
  (call-interactively #'inverse-add-mode-abbrev)
  (my/abbrev-save))

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
  (find-file (concat doom-user-dir "config.org")))
(defun my/edit-packages ()
  (interactive)
  (find-file (concat doom-user-dir "packages.el")))
(defun my/edit-init ()
  (interactive)
  (find-file (concat doom-user-dir "init.el")))
(defun my/edit-env ()
  (interactive)
  (find-file (concat doom-user-dir "env.el")))

(define-derived-mode org-config-mode org-mode "Org config mode")
(add-to-list 'auto-mode-alist '("config\\.org" . org-config-mode))

(map! :leader
      :prefix ("f s" . "snippets")
      :desc "Find snippet"    "f" #'my/yas-find-snippet
      :desc "New snippet"     "n" #'yas/new-snippet
      :desc "Edit snippet"    "e" #'my/yas-edit-snippet

      :desc "Describe snippets" "d" #'yas/describe-tables
      :desc "Reload snippets" "r" #'yas/reload-all
      :desc "Browse docs"     "?" #'my/yas-browse-docs)

(defun my/yas-browse-docs ()
  (interactive)
  (browse-url "https://joaotavora.github.io/yasnippet"))

(defun my/yas-edit-snippet ()
  (interactive)
  (call-interactively #'yas/visit-snippet-file))

(defun my/yas-find-snippet ()
  (interactive)
  (counsel-find-file nil +snippets-dir))

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
     :prefix ("l" . "ligma")

     :desc "Search" "s" #'ts/search

     :desc "Sourcegraph search" "g" #'ts/sourcegraph-search
     :desc "Sourcegraph browse" "G" #'ts/sourcegraph-browse)

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
      :desc "Move left" "H" #'+evil/window-move-left
      :desc "Move down" "J" #'+evil/window-move-down
      :desc "Move up" "K" #'+evil/window-move-up
      :desc "Move right" "L" #'+evil/window-move-right
      ;; Splits
      :desc "VSplit" "=" #'+evil/window-vsplit-and-follow
      :desc "HSplit" "-" #'+evil/window-split-and-follow
      :desc "Tear off" "t" #'tear-off-window
      ;; History
      :desc "Undo" "u" #'winner-undo
      :desc "Redo" "U" #'winner-redo
      ;; Misc
      :desc "Resize..." "r" #'my/hydra-window-resize/body
      :desc "Rotate..." "R" #'my/hydra-window-rotate/body
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
  ("k" my/window-increase-height "++Height")
  ("j" my/window-decrease-height "--Height")
  ("h" my/window-decrease-width  "--Width")
  ("l" my/window-increase-width  "++Width")
  ("ESC" nil "Quit" :color blue))

(defhydra my/hydra-window-rotate ()
  "Rotate window"
  ("h" +evil/window-move-left "Move left")
  ("j" +evil/window-move-down "Move down")
  ("k" +evil/window-move-up "Move up")
  ("l" +evil/window-move-right "Move right")
  ("H" evil-window-move-far-left "Move far left")
  ("J" evil-window-rotate-downwards "Rotate Down")
  ("K" evil-window-rotate-upwards "Rotate Up")
  ("L" evil-window-move-far-right "Move far right"))

(map! :map org-config-mode-map
      :localleader
      :v :desc "Eval Region" "e" #'eval-region
      :n :desc "Eval Source" "e" #'my/org-config-eval-source)

(defun my/org-config-eval-source ()
  (interactive)
  (org-ctrl-c-ctrl-c)
  (org-babel-remove-result))

;; (map! :map rustic-mode-map
;;       :localleader
;;       "b" nil
;;       "t" nil)

;; (map! :map rustic-mode-map
;;       :localleader
;;       :desc "Edit Cargo.toml" "t" #'my/rust/edit-cargo-toml)

;; (map! :map rustic-mode-map
;;       :leader
;;       :prefix ("c" . "code")
;;       :desc "Expand macro" "m" #'lsp-rust-analyzer-expand-macro
;;       :desc "Open docs" "h" #'lsp-rust-analyzer-open-external-docs)

;; (map! :map rustic-mode-map
;;       :localleader
;;       :prefix ("b" . "build")

;;       :desc "Build" "b" #'rustic-cargo-check
;;       :desc "Check" "c" #'rustic-cargo-check

;;       :desc "Debug" "d" #'my/rust/dap-hydra/body
;;       :desc "Run" "r" #'rustic-cargo-run

;;       :desc "Bench" "B" #'rustic-cargo-bench
;;       :desc "Test current" "t" #'rustic-cargo-current-test
;;       :desc "Test all" "T" #'rustic-cargo-test)

(map! :map rustic-mode-map
      :desc "Pluralize import" "," #'my/rust/import-pluralize
      :desc "Singularize import" "<backspace>" #'my/rust/import-singularize
      :desc "Singularize import" "C-<backspace>" #'my/rust/import-c-singularize
      :desc "Singularize import" "C-<delete>" #'my/rust/import-rev-singularize)

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

(map! :map cargo-toml-mode-map
      :localleader
      :desc "Add crate (semver)" "a" #'my/rust/cargo-toml-add-crate-semver
      :desc "Add crate (exact)" "A" #'my/rust/cargo-toml-add-crate)

(map! :prefix "z"
 :desc "Kill buffer" :n "x" #'kill-current-buffer
 :desc "Kill window" :n "c" #'+workspace/close-window-or-workspace)

(map! :prefix "["
      :desc "Start of fn" :n "f" #'beginning-of-defun)

(map! :prefix "]"
      :desc "End of fn" :n "f" #'end-of-defun)



(add-to-list 'projectile-globally-ignored-files "Cargo.lock")

(setq lsp-rust-analyzer-inlay-hints-mode t)
(setq lsp-rust-analyzer-server-display-inlay-hints t)

(setq lsp-rust-analyzer-display-closure-return-type-hints t)
(setq lsp-rust-analyzer-display-lifetime-elision-hints-enable "skip_trivial")
(setq lsp-rust-analyzer-display-lifetime-elision-hints-use-parameter-names nil)
(setq lsp-rust-analyzer-display-chaining-hints t)
(setq lsp-rust-analyzer-display-reborrow-hints t)

(rx-let ((crate (or alphanumeric "_" "*")))
  (setq my//rust/import-singular-rx
        ;; use foo::bar::baz;
        (rx "use "
            (+ (+ crate) "::")
            (+ crate)
            (? ";") line-end))
  (setq my//rust/import-plural-rx
        ;; use foo::bar::baz::{qux::quo, };
        (rx "use "
            (+ (+ crate) "::")
            "{" (* (+ crate) "::") (+ crate) "," (* whitespace) "}"
            (? ";") line-end))
  (setq my//rust/import-plural-rev-rx
        ;; use foo::bar::baz::{, qux::quo};
        (rx "use "
            (+ (+ crate) "::")
            "{," (* whitespace) (* (+ crate) "::") (+ crate) "}"
            (? ";") line-end)))

(defun my/rust/import-pluralize ()
  "Convert a singular import into a brace-wrapped plural import."
  (interactive)
  (if (and
       (my/insert-mode-p)
       (my/line-match-p my//rust/import-singular-rx))
      (vim! "ESC vb S} f} i,")
    (insert ",")))

(defun my/rust/import-singularize ()
  "Convert a brace-wrapped plural import into a singular import."
  (interactive)
  (if (and
       (my/insert-mode-p)
       (my/line-match-p my//rust/import-plural-rx))
      (vim! "ESC l dF, ds} $i")
    (evil-delete-backward-char-and-join 1)))

(defun my/rust/import-c-singularize ()
  "Convert a brace-wrapped plural import into a singular import."
  (interactive)
  (if (and
       (my/insert-mode-p)
       (my/line-match-p my//rust/import-plural-rx))
      (vim! "ESC l dF, ds} $i")
    (backward-kill-word 1)))

(defun my/rust/import-rev-singularize ()
  "Convert a brace-wrapped plural import into a singular import."
  (interactive)
  (if (and
       (my/insert-mode-p)
       (my/line-match-p my//rust/import-plural-rev-rx))
      (vim! "ESC ds} dw $i")
    (kill-word 1)))

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

(define-derived-mode cargo-toml-mode conf-toml-mode "Cargo.toml mode")
(add-to-list 'auto-mode-alist '("Cargo\\.toml" . cargo-toml-mode))

(defun my/rust/edit-cargo-toml ()
  (interactive)
  (lsp-rust-analyzer-open-cargo-toml))

(defun my/rust/get-latest-crate-version (crate callback)
  (request! (format "https://crates.io/api/v1/crates/%s/versions" crate)
            (:type "GET" :parser 'json-read)
            (lambda (data)
              (let* ((versions (alist-get 'versions data))
                     (target (elt versions 0))
                     (num (alist-get 'num target)))
                (funcall callback num)))
            (lambda ()
              (message "Crate not found: %s" crate))))

(defun my/rust/cargo-toml-add-crate (crate)
  "Insert `crate = version` with the latest available version of a crate."
  (interactive "sCrate: ")
  (my/rust/get-latest-crate-version
   crate
   (lambda (version)
     (insert (format "%s = \"%s\"" crate version)))))

(defun my/rust/cargo-toml-add-crate-semver (crate)
  "Insert `crate = version` with the latest available version of a crate.
Use any semver compatible version with either the current major release,
or the minor release if the major version is still 0."
  (interactive "sCrate: ")
  (my/rust/get-latest-crate-version
   crate
   (lambda (version)
     (let* ((parts (split-string version "\\."))
            (major (nth 0 parts))
            (minor (nth 1 parts))
            (patch (nth 2 parts))
            (semver (if (equal major "0")
                        (format "%s.%s" major minor)
                      (format "%s" major))))
      (insert (format "%s = \"%s\"" crate semver))))))

(defun my/rust/cargo-toml (&optional dir)
  (path! (locate! "Cargo.toml" dir) "Cargo.toml"))

(defun my/rust/workspace-root (&optional dir)
  (shell! "%s | jq -r '.workspace_root'"
   (cargo! "metadata --no-deps --format-version 1" dir)))

(defun cargo! (cmd &optional dir)
  (format "cargo %s --manifest-path \"%s\""
          cmd
          (my/rust/cargo-toml dir)))

;; (setq projectile-project-search-path
;;       '("~/Code"))

(defun my/project-ignored-p (root)
  (or (doom-project-ignored-p root)
      (f-descendant-of-p root (home! ".rustup"))
      (f-descendant-of-p root "/opt/ts/fuse/artfs_mounts")
      (f-descendant-of-p root "/home/tsdist/vats_deployments")))
(setq projectile-ignored-project-function #'my/project-ignored-p)

(defun my/projectile-switch-project ()
  (interactive)
  ;; Prune projects which no longer exist
  (when (boundp 'projectile-known-projects)
    (dolist (project projectile-known-projects)
      (unless (f-dir-p project)
        (projectile-remove-known-project project))))
  (call-interactively #'counsel-projectile-switch-project))

(setq lsp-ui-doc-show-with-mouse t)

(setq lsp-headerline-breadcrumb-enable t)
(setq lsp-headerline-breadcrumb-segments '(symbols))

(defun my/lsp-find-root (&rest args)
  (or
   (pcase ($ext t)
     (".rs" (my/rust/workspace-root))
     (_ nil))))

(advice-add 'lsp--find-root-interactively :before-until #'my/lsp-find-root)

(defun my/lsp-buffer-killed ()
  (when lsp-mode
    (let ((root (lsp-find-session-folder (lsp-session) ($cwd))))
      ;; If we're in an ignored project, remove it from the LSP session
      (when (my/project-ignored-p root)
        (lsp-workspace-folders-remove root)))))

(add-hook 'kill-buffer-hook #'my/lsp-buffer-killed)

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

(use-package sourcegraph
  :hook (prog-mode . sourcegraph-mode))
(setq sourcegraph-url "https://sourcegraph.app.twosigma.com")

(load! "lisp/emacs-everywhere.el")
(setq emacs-everywhere-paste-command '("xdotool" "key" "--clearmodifiers" "ctrl+v"))
(setq emacs-everywhere-frame-parameters
      '((title  . "Emacs Everywhere")
        (width  . 120)
        (height . 36)))