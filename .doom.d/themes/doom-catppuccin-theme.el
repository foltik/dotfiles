;;; doom-catppuccin-theme.el --- inspired by Catppuccin -*- lexical-binding: t; no-byte-compile: t; -*-

(require 'doom-themes)


;;
;;; Variables

(defgroup doom-catppuccin-theme nil
  "Options for the `doom-catppuccin' theme."
  :group 'doom-themes)

(defcustom doom-catppuccin-brighter-modeline nil
  "If non-nil, more vivid colors will be used to style the mode-line."
  :group 'doom-catppuccin-theme
  :type 'boolean)

(defcustom doom-catppuccin-brighter-comments nil
  "If non-nil, comments will be highlighted in more vivid colors."
  :group 'doom-catppuccin-theme
  :type 'boolean)

(defcustom doom-catppuccin-padded-modeline doom-themes-padded-modeline
  "If non-nil, adds a 4px padding to the mode-line.
Can be an integer to determine the exact padding."
  :group 'doom-catppuccin-theme
  :type '(choice integer boolean))


;;
;;; Theme definition

(def-doom-theme doom-catppuccin
  "A dark theme inspired by Catppuccin."

  ;; name        default   256           16
  ((bg         '("#1e1e2e" "black"       "black"  ))
   (fg         '("#d9e0ee" "#bfbfbf"     "brightwhite"  ))

   ;; These are off-color variants of bg/fg, used primarily for `solaire-mode',
   ;; but can also be useful as a basis for subtle highlights (e.g. for hl-line
   ;; or region), especially when paired with the `doom-darken', `doom-lighten',
   ;; and `doom-blend' helper functions.
   (bg-alt     '("#1a1826" "black"       "black"        ))
   (fg-alt     '("#d9e0ee" "#2d2d2d"     "white"        ))

   ;; These should represent a spectrum from bg to fg, where base0 is a starker
   ;; bg and base8 is a starker fg. For example, if bg is light grey and fg is
   ;; dark grey, base0 should be white and base8 should be black.
   (base0      '("#161320" "black"       "black"        ))
   (base1      '("#1a1826" "#1e1e1e"     "brightblack"  ))
   (base2      '("#1e1e1e" "#2e2e2e"     "brightblack"  ))
   (base3      '("#302d41" "#262626"     "brightblack"  ))
   (base4      '("#575268" "#3f3f3f"     "brightblack"  ))
   (base5      '("#6e6c7e" "#525252"     "brightblack"  ))
   (base6      '("#988ba2" "#6b6b6b"     "brightblack"  ))
   (base7      '("#c3bac6" "#979797"     "brightblack"  ))
   (base8      '("#d9e0ee" "#dfdfdf"     "white"        ))

   (grey       base4)
   (red        '("#f28fad" "#ff6655" "red"          ))
   (orange     '("#f8bd96" "#dd8844" "brightred"    ))
   (green      '("#abe9b3" "#99bb66" "green"        ))
   (teal       '("#b5e8e0" "#44b9b1" "brightgreen"  ))
   (yellow     '("#fae3b0" "#ECBE7B" "yellow"       ))
   (blue       '("#96cdfb" "#51afef" "brightblue"   ))
   (dark-blue  '("#96cdfb" "#2257A0" "blue"         ))
   (magenta    '("#f5c2e7" "#c678dd" "brightmagenta"))
   (violet     '("#ddb6f2" "#a9a1e1" "magenta"      ))
   (cyan       '("#89dceb" "#46D9FF" "brightcyan"   ))
   (dark-cyan  '("#89dceb" "#5699AF" "cyan"         ))

   ;; These are the "universal syntax classes" that doom-themes establishes.
   ;; These *must* be included in every doom themes, or your theme will throw an
   ;; error, as they are used in the base theme defined in doom-themes-base.
   (highlight      magenta)
   (vertical-bar   (doom-darken base1 0.1))
   (selection      dark-blue)
   (builtin        teal)
   (comments       (if doom-catppuccin-brighter-comments green base5))
   (doc-comments   (doom-lighten (if doom-catppuccin-brighter-comments green base5) 0.25))
   (constants      orange)
   (functions      blue)
   (keywords       magenta)
   (methods        blue)
   (operators      blue)
   (type           yellow)
   (strings        green)
   (variables      cyan)
   ;; (variables      (doom-lighten magenta 0.4))
   (numbers        orange)
   (region         `(,(doom-lighten (car bg-alt) 0.15) ,@(doom-lighten (cdr base1) 0.35)))
   (error          red)
   (warning        yellow)
   (success        green)
   (vc-modified    orange)
   (vc-added       green)
   (vc-deleted     red)

   ;; These are extra color variables used only in this theme; i.e. they aren't
   ;; mandatory for derived themes.
   (modeline-fg              fg)
   (modeline-fg-alt          base5)
   (modeline-bg              (if doom-catppuccin-brighter-modeline
                                 (doom-darken blue 0.45)
                               (doom-darken bg-alt 0.1)))
   (modeline-bg-alt          (if doom-catppuccin-brighter-modeline
                                 (doom-darken blue 0.475)
                               `(,(doom-darken (car bg-alt) 0.15) ,@(cdr bg))))
   (modeline-bg-inactive     `(,(car bg-alt) ,@(cdr base1)))
   (modeline-bg-inactive-alt `(,(doom-darken (car bg-alt) 0.1) ,@(cdr bg)))

   (-modeline-pad
    (when doom-catppuccin-padded-modeline
      (if (integerp doom-catppuccin-padded-modeline) doom-catppuccin-padded-modeline 4))))


  ;;;; Base theme face overrides
  (((line-number &override) :foreground base4)
   ((line-number-current-line &override) :foreground fg)
   ((font-lock-comment-face &override)
    :background (if doom-catppuccin-brighter-comments (doom-lighten bg 0.05)))
   (mode-line
    :background modeline-bg :foreground modeline-fg
    :box (if -modeline-pad `(:line-width ,-modeline-pad :color ,modeline-bg)))
   (mode-line-inactive
    :background modeline-bg-inactive :foreground modeline-fg-alt
    :box (if -modeline-pad `(:line-width ,-modeline-pad :color ,modeline-bg-inactive)))
   (mode-line-emphasis :foreground (if doom-catppuccin-brighter-modeline base8 highlight))

   ;;;; css-mode <built-in> / scss-mode
   (css-proprietary-property :foreground orange)
   (css-property             :foreground magenta)
   (css-selector             :foreground blue)
   ;;;; doom-modeline
   (doom-modeline-bar :background (if doom-catppuccin-brighter-modeline modeline-bg highlight))
   (doom-modeline-buffer-file :inherit 'mode-line-buffer-id :weight 'bold)
   (doom-modeline-buffer-path :inherit 'mode-line-emphasis :weight 'bold)
   (doom-modeline-buffer-project-root :foreground magenta :weight 'bold)
   ;;;; ivy
   (ivy-current-match :background dark-blue :distant-foreground base0 :weight 'normal)
   ;;;; LaTeX-mode
   (font-latex-math-face :foreground magenta)
   ;;;; markdown-mode
   (markdown-markup-face :foreground base5)
   (markdown-header-face :inherit 'bold :foreground red)
   ((markdown-code-face &override) :background (doom-lighten base3 0.05))
   ;;;; rjsx-mode
   )

  ;;;; Base theme variable overrides-
  ())

;;; doom-catppuccin-theme.el ends here
