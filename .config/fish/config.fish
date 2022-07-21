#
# Setup
#
set -U fish_greeting ''
function fish_user_key_bindings
    # ctrl-del
    bind \e\[3\;5~ kill-word

    # ctrl-backspace
    bind \cH backward-kill-path-component
end

#
# Variables
#

fish_add_path ~/.local/bin
fish_add_path ~/.go/bin
fish_add_path ~/.volta/bin/node
fish_add_path ~/.spicetify

set -gx TERM xterm-256color
set -gx VISUAL emacsclient -c
set -gx EDITOR nvim

# Yubikey
set -gx SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)
set -gx GPG_TTY (tty)
gpg-connect-agent updatestartuptty /bye >/dev/null



#
# Functions
#

# Shorthand
abbr -a g git
function ls; exa $argv; end
function ll; exa -l $argv; end
function vim; nvim $argv; end

# Dotfiles management
function dots
    if test (count $argv) -eq 1
        if test "$argv[1]" = "ls"
            dots ls-tree --full-tree -r --name-only HEAD
            return
        end
        if test "$argv[1]" = "sync"
            for f in (dots ls-files --modified)
                dots add $f
            end
            dots commit -m "$(date +'%d %b %Y %T')"
            dots push
            return
        end
    end

    git --git-dir=$HOME/.dotfiles --work-tree=$HOME $argv
end

# Reload fish configuration
function reload
    . ~/.config/fish/config.fish
end

# Editor shorthand
function e
    emacsclient -nc $argv[1]
end
function ez
    set target (f $argv)
    if test -f $target
        e $target
    else
        return 1
    end
end
function v
    nvim $argv[1]
end
function vz
    set target (f $argv)
    if test -f $target
        v $target
    else
        return 1
    end
end

# Process Management
set ps "-ax" "-o" "pid,user,pcpu,pmem,start_time,cmd"
function pg
    ps $ps | head -n1
    ps $ps -h | rg -v rg | rg $argv
end
function pk
    if test (count $argv) -gt 0
        set pids (pg $argv | tail -n +2 | awk '{print $1}')
    else
        set pids (ps $ps -h | fzf -m | awk '{print $1}')
    end

    if test -n "$pids"
        for pid in $pids
            kill $pid
        end
        echo "Killed $(count $argv)"
    else
        return 1
    end
end

# Archive creation
function tcz
    set dir $argv[1]
    tar cvfz "$dir.tar.gz" "$dir"
end
function tcj
    set dir $argv[1]
    tar cvfJ "$dir.tar.xz" "$dir"
end
function tx
    tar xvf $argv[1]
end

# Clipboard
function clip
    xclip -sel c
end



#
# Theme: Tomorrow Night Bright
#
set -U fish_color_normal normal
set -U fish_color_command c397d8
set -U fish_color_quote b9ca4a
set -U fish_color_redirection 70c0b1
set -U fish_color_end c397d8
set -U fish_color_error d54e53
set -U fish_color_param 7aa6da
set -U fish_color_comment e7c547
set -U fish_color_match --background=brblue
set -U fish_color_selection white --bold --background=brblack
set -U fish_color_search_match bryellow --background=brblack
set -U fish_color_history_current --bold
set -U fish_color_operator 00a6b2
set -U fish_color_escape 00a6b2
set -U fish_color_cwd green
set -U fish_color_cwd_root red
set -U fish_color_valid_path --underline
set -U fish_color_autosuggestion 969896
set -U fish_color_user brgreen
set -U fish_color_host normal
set -U fish_color_cancel --reverse
set -U fish_pager_color_prefix normal --bold --underline
set -U fish_pager_color_progress brwhite --background=cyan
set -U fish_pager_color_completion normal
set -U fish_pager_color_description B3A06D
set -U fish_pager_color_selected_background --background=brblack
