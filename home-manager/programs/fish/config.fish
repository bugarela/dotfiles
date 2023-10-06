set -U fish_greeting
set -g theme_short_path yes

set GOPATH "$HOME/.gvm/pkgsets/go1.13/global"
set PATH "$HOME/.cargo/bin:/usr/local/kubebuilder/bin:$PATH"
set PATH "$PATH:$HOME/.gvm/gos/go1.13/bin"
set PATH "$PATH:$HOME/.gvm/pkgsets/go1.13/global/bin"
set PATH "$PATH:/opt/texlive/2020/bin/x86_64-linux"
set PATH "$PATH:$HOME/.emacs.d/bin"
set PATH "$PATH:$HOME/google-cloud-sdk/bin"
set PATH "$PATH:$HOME/.dotnet/tools"
set PATH "$PATH:$HOME/.npm/bin"
set PATH "$PATH:$HOME/projects/apalache/bin"
set PATH "$PATH:/nix/store/633qlvqjryvq0h43nwvzkd5vqxh2rh3c-go-1.19.6/bin"
set -x GPG_TTY (tty)

function fish_user_key_bindings
    fish_vi_key_bindings
    bind \cw backward-kill-word
end

alias o='devour xdg-open'

alias gcs='git commit -S'
alias ggpush='git push origin (current_branch)'

function gvm
    bass source ~/.gvm/scripts/gvm ';' gvm $argv
end

function init-polybar
    MONITOR=DP-5 polybar --reload mybar &
    sleep 1
    MONITOR=HDMI-0 polybar --reload mybar &
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
