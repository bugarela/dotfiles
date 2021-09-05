set -U fish_greeting
set -g theme_short_path yes

set CLUSTERING "$HOME/projects/clustering-engine"
set STATION "$HOME/projects/rdstation"

set GOPATH "$HOME/.gvm/pkgsets/go1.13/global"
set PATH "$HOME/.cargo/bin:/usr/local/kubebuilder/bin:$PATH"
set PATH "$PATH:$HOME/.gvm/gos/go1.13/bin"
set PATH "$PATH:$HOME/.gvm/pkgsets/go1.13/global/bin"
set PATH "$PATH:/opt/texlive/2020/bin/x86_64-linux"
set PATH "$PATH:$HOME/.emacs.d/bin"
set PATH "$PATH:$HOME/google-cloud-sdk/bin"
set -x GPG_TTY (tty)

function fish_user_key_bindings
    fish_vi_key_bindings
    bind \cw backward-kill-word
end

alias o='devour xdg-open'

alias gcs='git commit -S'
alias ggpush='git push origin (current_branch)'

alias dr='docker-compose run web /bin/bash'
alias de='docker-compose exec web /bin/bash'
alias rd-docker='~/.rd-docker/rd-docker-cli'

alias kc="kubectl --context production"
function kc-bash
         kubectl --context production -n core exec (kubectl --context production get pods -n core | grep $argv | head -n1 | cut -f1 -d ' ') -it bash
end
alias ks="kubectl --context staging -n contact-mgmt"

function gvm
    bass source ~/.gvm/scripts/gvm ';' gvm $argv
end

function workers
     docker-compose exec web /bin/bash -c 'bundle exec paddy -m MutationConsumerWorker#perform -s cdp-development/mutation_notification/my_subscription &\
        bundle exec paddy -m ImpactEvaluationWorker#perform -b 100 -s cdp-development/clustering_engine_events_topic/clustering_engine_events_subscription &\
        bundle exec paddy -m MutationEventsWorker#perform -s cdp-development/clustering_engine_mutation_events/clustering_engine_mutation_events &\
        bundle exec paddy -m RelationEventsWorker#perform -s cdp-development/clustering_engine_relation_events/clustering_engine_relation_events &\
        bundle exec paddy -m ClusterTestRequestWorker#perform -s cdp-development/clustering_engine_test_request/clustering_engine_test_request &\
        bundle exec paddy -m External::EsIndexingWorker#perform -b 100 -s cdp-development/entity_cluster_notifications/clustering_engine_es_indexing'
end

function clustering
    alacritty -e fish -c 'sleep 20 && de' &
    alacritty -e fish -c 'sleep 20 && docker-compose exec web bundle exec sidekiq -q clusters -q predicates -q refresh' &
    alacritty -e fish -c 'docker-compose up' &
    sleep 12 && workers
end

function workflow
    rd-docker e web 'bundle exec rake workflow_automation:pull_clustering_engine_entered_entities_notifications &
    bundle exec rake workflow_automation:dequeue_and_fire_entered_cluster_notifications & bundle exec rake workflow_automation:process_priority_entry_queue & bundle exec rake workflow_automation:process_execution_priority_queue'
end

function rd-staging
    echo -e "\033]11;#262d1a\a"
    ssh GabrielaMoreira@rdconsole-staging.rdops.systems
    echo -e "\033]11;#2c1a2d\a"
end

function rd-production
    # echo -e "\033]11;#DDDDDD\a"
    ssh GabrielaMoreira@rdconsole-production.rdops.systems
    # echo -e "\033]11;#\a"
end

function migration-dashboard
    curl -u cdp:agoravai -XGET https://cdp.rd.services/cdp-launcher/api/v1/dashboard_data/ | jq
end

function init-polybar
    MONITOR=DP-5 polybar --reload mybar &
    sleep 1
    MONITOR=HDMI-0 polybar --reload mybar &
    sleep 1
    for m in (xrandr --query | grep ' connected' | cut -d' ' -f1 | sort); MONITOR=$m polybar --reload mybar &; end
end

__git.init
