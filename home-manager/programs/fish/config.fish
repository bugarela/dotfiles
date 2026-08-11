set -U fish_greeting
set -g theme_short_path yes

set GOPATH "$HOME/go"
set PATH "$GOPATH/bin:$PATH"
set PATH "$HOME/.cargo/bin:/usr/local/kubebuilder/bin:$PATH"
set PATH "$PATH:/opt/texlive/2020/bin/x86_64-linux"
set PATH "$PATH:$HOME/.emacs.d/bin"
set PATH "$PATH:$HOME/google-cloud-sdk/bin"
set PATH "$PATH:$HOME/.dotnet/tools"
set PATH "$PATH:$HOME/.npm/bin"
set PATH "$PATH:$HOME/projects/apalache/bin"
set PATH "$PATH:/nix/store/633qlvqjryvq0h43nwvzkd5vqxh2rh3c-go-1.19.6/bin"
set SSH_AUTH_SOCK "$HOME/.1password/agent.sock"
set -x GPG_TTY (tty)

function fish_user_key_bindings
    fish_vi_key_bindings
    bind \cw backward-kill-word
    bind -M insert \cf accept-autosuggestion
end

alias o='devour xdg-open'
alias y='xclip -selection clipboard'

alias gcs='git commit -S'
alias ggpush='git push origin (current_branch)'

function gvm
    bass source ~/.gvm/scripts/gvm ';' gvm $argv
end

function init-polybar
    MONITOR=HDMI-A-1 polybar --reload mybar &
    sleep 1
    MONITOR=DisplayPort-0 polybar --reload mybar &
    sleep 1
    for m in (xrandr --query | grep ' connected' | cut -d' ' -f1 | sort)
        MONITOR=$m polybar --reload mybar &
    end
end

__git.init

function _git_branch_name
    echo (command git symbolic-ref HEAD 2> /dev/null | sed -e 's|^refs/heads/||')
end

function fish_prompt
    set -l last_status $status

    set -l cyan (set_color cyan)
    set -l yellow (set_color yellow)
    set -l red (set_color red)
    set -l blue (set_color blue)
    set -l green (set_color green)
    set -l purple (set_color purple)
    set -l normal (set_color normal)

    set -l cwd $purple(pwd | sed "s:^$HOME:~:")

    # Print pwd or full path
    echo -n -s $cwd $normal

    # Show git branch and status
    if [ (_git_branch_name) ]
        set -l git_branch (_git_branch_name)

        set git_info '(' $blue $git_branch $normal ')'
        echo -n -s ' · ' $git_info $normal
    end

    set -l prompt_color $red
    if test $last_status = 0
        set prompt_color $normal
    end

    echo -e -n -s $prompt_color ' $ ' $normal
end

# `zellij action rename-tab` renames the *focused* tab, so a shell in a
# background tab would rename whatever tab you're looking at. Resolve this
# shell's own tab id from $ZELLIJ_PANE_ID and always rename with `-t`.
function __zellij_my_tab_id
    if not set -q __zellij_tab_id
        set -g __zellij_tab_id (zellij action list-panes -t -j \
            | jq -r --argjson p $ZELLIJ_PANE_ID \
                'map(select(.is_plugin == false and .id == $p)) | .[0].tab_id')
    end
    echo $__zellij_tab_id
end

function __zellij_rename_tab
    if set -q ZELLIJ; and set -q ZELLIJ_PANE_ID
        set -l tab (__zellij_my_tab_id)
        test -n "$tab"; and zellij action rename-tab -t $tab $argv[1]
    end
end

function __zellij_dir_name
    basename (git rev-parse --show-toplevel 2>/dev/null; or pwd)
end

function __zellij_tab_update --on-variable PWD
    __zellij_rename_tab (__zellij_dir_name)
end

function __zellij_tab_preexec --on-event fish_preexec
    if string match -qr "^claude" $argv
        __zellij_rename_tab "Claude - "(__zellij_dir_name)
    end
end

function __zellij_tab_postexec --on-event fish_postexec
    if string match -qr "^claude" $argv
        __zellij_rename_tab (__zellij_dir_name)
    end
end

__zellij_tab_update

jj util completion fish | source
