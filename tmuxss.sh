#!/usr/bin/env bash

# Define color variables
CSI="\e["
RESET="${CSI}0m"
BOLD_BLUE="${CSI}1;34m"
YELLOW="${CSI}0;33m"
GREEN="${CSI}0;32m"
MAGENTA="${CSI}0;35m"
CYAN="${CSI}0;36m"
DIM="${CSI}2m"

help() {
    local content=`cat << EOF
${BOLD_BLUE}tmuxss${RESET} - a simple tmux multiview session manager

${CYAN}Syntax:${RESET} tmuxss -<${YELLOW}k|a|i|c${RESET}> [-${YELLOW}g${RESET} group] [-${YELLOW}s${RESET} sid] [-${YELLOW}d${RESET}] [-${YELLOW}t${RESET} template] [-${YELLOW}p${RESET} path]

${BOLD_BLUE}Commands:${RESET}
  ${YELLOW}k${RESET}     Kill sessions associated with a SID or group
  ${YELLOW}a${RESET}     Attach to a session group with the given root SID
  ${YELLOW}c${RESET}     Create a session group in the current directory, optionally using a template
  ${YELLOW}i${RESET}     Initialize the main session
  ${YELLOW}h${RESET}     Print the entire help menu

${BOLD_BLUE}Options:${RESET}
  ${YELLOW}s${RESET}     SID (Session ID)
  ${YELLOW}g${RESET}     Group name
  ${YELLOW}t${RESET}     Template name
  ${YELLOW}p${RESET}     Path to template config file
  ${YELLOW}d${RESET}     Stay detached from new session

EOF
`
printf "$content"
echo
echo
}

extended_help() {
    content=`cat << EOF
${BOLD_BLUE}Config Format:${RESET}
${CYAN}{${RESET}
  ${YELLOW}"default"${RESET}: ${GREEN}"<env-name>"${RESET}, ${DIM}# default: \$PWD${RESET}
  ${YELLOW}"envs"${RESET}: ${CYAN}{${RESET}
    ${GREEN}"<env-name>"${RESET}: ${CYAN}{${RESET}
      ${YELLOW}"path"${RESET}: ${GREEN}"<cwd>"${RESET}, ${DIM}# default: \$PWD${RESET}
      ${YELLOW}"group"${RESET}: ${GREEN}"<optional session-group>"${RESET}, ${DIM}# default: basename \$PWD${RESET}
      ${YELLOW}"focused"${RESET}: ${CYAN}<window-index>${RESET}, ${DIM}# default: 0${RESET}
      ${YELLOW}"windows"${RESET}: ${CYAN}[${RESET}
        ${CYAN}{${RESET}
          ${YELLOW}"name"${RESET}: ${GREEN}"<window-name>"${RESET}, ${DIM}# default: index${RESET}
          ${YELLOW}"path"${RESET}: ${GREEN}"<optional path>"${RESET}, ${DIM}# default: \$PWD${RESET}
          ${YELLOW}"command_run"${RESET}: ${GREEN}"<shell command>"${RESET}, ${DIM}# default: ""${RESET}
          ${YELLOW}"command_prepare"${RESET}: ${GREEN}"<setup command>"${RESET}, ${DIM}# default: ""${RESET}
          ${YELLOW}"read_only"${RESET}: ${MAGENTA}true${RESET} | ${MAGENTA}false${RESET}, ${DIM}# default: false${RESET}
          ${YELLOW}"hist_file"${RESET}: ${GREEN}"<path-to-hist-file>"${RESET}, ${DIM}# default: std Hist${RESET}
          ${YELLOW}"hsplit"${RESET}: ${CYAN}[ <pane> , ...]${RESET},
          ${YELLOW}"vsplit"${RESET}: ${CYAN}[ <pane> , ...]${RESET}
        ${CYAN}}, ...]${RESET}
    ${CYAN}}${RESET}
  ${CYAN}}${RESET}
${CYAN}}${RESET}

${BOLD_BLUE}Pane:${RESET}
${CYAN}{${RESET}
  ${YELLOW}"path"${RESET}: ${GREEN}"<optional path>"${RESET}, ${DIM}# default: \$PWD${RESET}
  ${YELLOW}"command_run"${RESET}: ${GREEN}"<shell command>"${RESET}, ${DIM}# default: ""${RESET}
  ${YELLOW}"command_prepare"${RESET}: ${GREEN}"<setup command>"${RESET}, ${DIM}# default: ""${RESET}
  ${YELLOW}"read_only"${RESET}: ${MAGENTA}true${RESET} | ${MAGENTA}false${RESET}, ${DIM}# default: false${RESET}
  ${YELLOW}"hist_file"${RESET}: ${GREEN}"<path-to-hist-file>"${RESET}, ${DIM}# default: std Hist${RESET}
  ${YELLOW}"hsplit"${RESET}?: ${CYAN}[ <pane> , ...]${RESET},
  ${YELLOW}"vsplit"${RESET}?: ${CYAN}[ <pane> , ...]${RESET}
${CYAN}}${RESET}

${BOLD_BLUE}Notes:${RESET}
  - All paths are relative to the environment path unless absolute
  - Only either hsplit or vsplit may be defined

${BOLD_BLUE}Examples:${RESET}
  ${YELLOW}Basic layout:${RESET}
    ${CYAN}{${RESET}
      ${YELLOW}"default"${RESET}: ${GREEN}"default"${RESET},
      ${YELLOW}"envs"${RESET}: ${CYAN}{${RESET}
        ${GREEN}"default"${RESET}: ${CYAN}{${RESET}
          ${YELLOW}"path"${RESET}: ${GREEN}"."${RESET},
          ${YELLOW}"focused"${RESET}: ${CYAN}0${RESET},
          ${YELLOW}"windows"${RESET}: ${CYAN}[${RESET}
            ${CYAN}{${RESET} ${YELLOW}"name"${RESET}: ${GREEN}"code"${RESET}, ${YELLOW}"command_run"${RESET}: ${GREEN}"nvim"${RESET} ${CYAN}},${RESET}
            ${CYAN}{${RESET} ${YELLOW}"name"${RESET}: ${GREEN}"util"${RESET}, ${YELLOW}"command_run"${RESET}: ${GREEN}"htop"${RESET} ${CYAN}}${RESET}
          ${CYAN}]${RESET}
        ${CYAN}}${RESET}
      ${CYAN}}${RESET}
    ${CYAN}}${RESET}

  ${YELLOW}Nested splits with preparation:${RESET}
    ${CYAN}{${RESET}
      ${YELLOW}"envs"${RESET}: ${CYAN}{${RESET}
        ${GREEN}"dev"${RESET}: ${CYAN}{${RESET}
          ${YELLOW}"path"${RESET}: ${GREEN}"~/src/project"${RESET},
          ${YELLOW}"windows"${RESET}: ${CYAN}[${RESET}
            ${CYAN}{${RESET} ${YELLOW}"name"${RESET}: ${GREEN}"code"${RESET}, ${YELLOW}"command_run"${RESET}: ${GREEN}"nvim"${RESET} ${CYAN}},${RESET}
            ${CYAN}{${RESET}
              ${YELLOW}"name"${RESET}: ${GREEN}"runtime"${RESET},
              ${YELLOW}"hsplit"${RESET}: ${CYAN}[${RESET}
                ${CYAN}{${RESET}
                  ${YELLOW}"vsplit"${RESET}: ${CYAN}[${RESET}
                    ${CYAN}{${RESET} ${YELLOW}"command_prepare"${RESET}: ${GREEN}"yarn start"${RESET}, ${YELLOW}"path"${RESET}: ${GREEN}"./frontend"${RESET} ${CYAN}},${RESET}
                    ${CYAN}{${RESET} ${YELLOW}"command_prepare"${RESET}: ${GREEN}"cargo run"${RESET}, ${YELLOW}"path"${RESET}: ${GREEN}"./backend"${RESET} ${CYAN}}${RESET}
                  ${CYAN}]${RESET}
                ${CYAN}},${RESET}
                ${CYAN}{${RESET} ${YELLOW}"command_run"${RESET}: ${GREEN}"htop"${RESET} ${CYAN}}${RESET}
              ${CYAN}]${RESET}
            ${CYAN}}${RESET}
          ${CYAN}]${RESET}
        ${CYAN}}${RESET}
      ${CYAN}}${RESET}
    ${CYAN}}${RESET}

EOF
`
printf "$content"
echo
}

SID=""
GROUP=""
SUBCOMMAND=""
TEMPLATE=""
DETACH=0
YQ_AVAILABLE=$(command -v yq >/dev/null 2>&1 && echo true || echo false)
TEMPLATE_SOURCE="$(echo ~)/tmuxss.json"

while getopts "p:g:t:s:hkaicd" option; do
    case $option in
    h)
        help
        extended_help
        exit 0
        ;;
    s)
        if [[ $OPTARG =~ "#" ]]; then
            echo "\"#\" is a reserved character"
            exit 3
        fi
        SID=$OPTARG ;;
    g)
        if [[ $OPTARG =~ "#" ]]; then
            echo "\"#\" is a reserved character"
            exit 3
        fi
        GROUP=$OPTARG ;;
    t)
        if [[ ! $OPTARG =~ ^[a-zA-Z]+$ ]]; then
            echo "Template names must be only upper and lowercase."
            exit 3
        fi
        # GROUP=$OPTARG
        TEMPLATE=$OPTARG ;;
    p) 
        if [[ ! $OPTARG =~ ^(/)?([^/\0]+(/)?)+$ ]]; then
            echo "Template source must be a valid path."
            exit 3
        fi
        TEMPLATE_SOURCE=$OPTARG ;;
    a)
        SUBCOMMAND="a" ;;
    k)
        SUBCOMMAND="k" ;;
    i)
        SUBCOMMAND="i" ;;
    c)
        SUBCOMMAND="c" ;;
    d)
        DETACH=1 ;;
    ?)
        echo "Invalid option"
        echo "Pull up the help menu with tmuxss -h"
        exit 3
        ;;
    esac
done

ATTACHED_TO=""
SIDINFERED=0

infer() {
if [[ -z $SID ]]; then
    if [[ -n "$TMUX" ]]; then
        local SESSION=$(tmux display-message -p '#S')

        ATTACHED_TO=$SESSION

        SID=${SESSION#*#}

        if [[ -z $SID ]]; then
            echo "No ID found in the current tmux session name: $SESSION"
            exit 66
        fi

        SIDINFERED=1
    fi
fi
}
infer

attachSession() {
    local group=$1
    local sid=$2
    local session="$group#$sid"

    # Check if a session exists in the group with the current SID
    if [[ -z $(tmux list-sessions -F "#{session_name}" | grep "^$session$") ]]; then
        # If no session exists with the current SID, create a new one
        tmux new-session -ds "$session" -t "$group"
    fi

    if [[ $TMUX ]]; then
        tmux switch-client -t "$session"
    else
        tmux attach -t "$session"
    fi
}

sanitize_path() {
    local input=$1

    local sanitized=$(echo "$input" | tr -d '.' | sed 's/[^a-zA-Z0-9]/_/g' | tr '[:upper:]' '[:lower:]')

    echo "$sanitized"
}

resolve_path() {
    local base=$1
    local pair=$2

    [[ -z $pair ]] && pair="."
    [[ $pair == ~* ]] && pair="${pair/#\~/$HOME}"

    if [[ $pair = /* ]]; then
        realpath "$pair"
    else
        realpath "$base/$pair"
    fi
}

# This gets the last bit of performance
setup_pane() {
    local key="$1"
    local pane_id="$2"

    local hist_file="${key}_hist_file"
    hist_file=${!hist_file}
    # Set HISTFILE only if a specific file was provided
    if [[ -n $hist_file ]]; then
        hist_file=$(resolve_path "$BASE_PATH" "$hist_file")
        tmux send-keys -t "$pane_id" "export HISTFILE=\"$hist_file\"; export PROMPT_COMMAND='history -a; history -c; history -r'; history -d \$(history 1)" C-m
    fi

    local read_only="${key}_read_only"
    read_only=${!read_only}
    if [[ $read_only == "true" ]]; then
        tmux send-keys -t "$pane_id" "shopt -ou history; history -d \$(history 1)" C-m
    fi

    tmux send-keys -t "$pane_id" "clear; history -d \$(history 1)" C-m
    tmux clear-history -t "$pane_id"

    local command_run="${key}_command_run"
    command_run=${!command_run}
    [[ -n $command_run ]] && tmux send-keys -t "$pane_id" "$command_run" C-m
    local command_prepare="${key}_command_prepare"
    command_prepare=${!command_prepare}
    [[ -n $command_prepare ]] && tmux send-keys -t "$pane_id" "$command_prepare"
}

visit_pane() {
    local key="$1"
    local window_index="$2"
    local pane_index="${PANE_INDEX[$window_index]:-0}"

    local path="${key}_path"
    path=${!path}

    path=$(resolve_path "$BASE_PATH" "$path")

    local pane_id="$GROUP:$window_index.$pane_index"

    tmux send-keys -t "$pane_id" "cd \"$path\"; history -d \$(history 1)" C-m

    local hsplit="${key}_hsplit"
    local vsplit="${key}_vsplit"

    if grep -q "$hsplit" <<< $DATA; then
        tmux split-window -h -t "$pane_id"
        local i=0;
        while :; do
            if ! $(grep -q "${hsplit}_${i}" <<< "$DATA"); then break; fi
            visit_pane "${hsplit}_${i}" "$window_index" "$pane_index"
            i=$((i + 1))
        done
    elif grep -q "$vsplit" <<< $DATA; then
        tmux split-window -v -t "$pane_id"
        local i=0;
        while :; do
            if ! $(grep -q "${vsplit}_${i}" <<< "$DATA"); then break; fi
            visit_pane "${vsplit}_${i}" "$window_index" "$pane_index"
            i=$((i + 1))
        done
    else
        setup_pane "$key" "$pane_id" &
        PANE_INDEX[$window_index]=$((pane_index + 1))
    fi
}

visit_window() {
    local key="$1"
    local window_index="$2"

    visit_pane "$key" "$window_index" &

    local name="${key}_name"
    name=${!name}
    [[ -n $name ]] && tmux rename-window -t "$GROUP:$window_index" "$name"
}

DATA=""
BASE_PATH=$PWD
declare -A PANE_INDEX

build_template() {
    local path="${template_key}_path"
    path=${!path}
    
    BASE_PATH=$(resolve_path $BASE_PATH $path)

    cd $BASE_PATH && tmux new-session -ds "$GROUP"

    local i=0
    while :; do
       local key="${template_key}_windows_${i}"
        if [ $i -gt 0 ] && ! grep -q "$key" <<< "$DATA"; then break; fi

        [[ $i -gt 0 ]] && tmux new-window -d -t "$GROUP"

        visit_window "$key" "$i" &
        i=$((i + 1))
    done
    wait

    local focused_window="${template_key}_focused"
    focused_window=${!focused_window}
    [[ -z $focused_window ]] && focused_window="0"

    tmux select-window -t "$GROUP:$focused_window"
}

case $SUBCOMMAND in
k)
    if [[ -n $GROUP ]]; then
        SESSION_LIST=$(tmux list-sessions -F "#{session_name}")

        for SESSION in $SESSION_LIST; do
            if [[ $SESSION == "$GROUP#"* || $SESSION == $GROUP ]]; then
                if [[ "$GROUP#$SID" == $ATTACHED_TO && $GROUP != "main" ]]; then
                    attachSession main $SID
                fi

                tmux kill-session -t "$SESSION"
            fi
        done
    fi
    if [[ -n $SID && $SIDINFERED -eq 0 ]]; then
        SESSION_LIST=$(tmux list-sessions -F "#{session_name}")

        for SESSION in $SESSION_LIST; do
            if [[ $SESSION == *#$SID ]]; then
                tmux kill-session -t "$SESSION"
            fi
        done
    fi

    if [[ ( -n $SID && $SIDINFERED -eq 0 ) || -n $GROUP ]]; then
        exit 0
    fi
    ;;
a)
    if [[ -z $GROUP ]]; then
        echo "No group specified"
        echo "Check out tmuxss -h"
        exit 3
    fi
    [[ -z $SID ]] && SID=$$
    attachSession $GROUP $SID
    exit 0
    ;;
i)
    [[ -z $SID ]] && SID=$$

    tmuxss -c -d -t "main" -g "main" -s "$SID"

    trap "tmuxss -k -s $SID" EXIT SIGHUP && tmuxss -a -g "main" -s "$SID"
    exit 0
    ;;
c)
    file=$(<"$TEMPLATE_SOURCE")
    if [[ -n $file ]] && $YQ_AVAILABLE; then
        DATA=$(yq -p=json -o shell <<< "$file") || {
            echo "Invalid template file"
            exit 3
        }
    fi
    if [[ -z $DATA ]]; then
        if [[ -n $TEMPLATE && $TEMPLATE != "main" ]]; then
            ! $YQ_AVAILABLE && { echo "Using templates requires yq to be installed"; exit 1; }
            echo "Could not locate config file"
            exit 1
        fi
        DATA="default='default' envs_default_path='.' envs_main_path='~' envs_main_group='main'"
    fi

    eval "$DATA"

    if [[ -z $TEMPLATE ]]; then
        default_template="default"
        default_template=${!default_template}
        [[ -n $default_template ]] && TEMPLATE=$default_template
    fi

    template_key="envs_${TEMPLATE}"
    if ! grep -q "$template_key" <<< "$DATA"; then { echo "Session template not found"; exit 3; }; fi

    template_group="${template_key}_group"
    template_group=${!template_group}
    [[ -n $template_group ]] && GROUP=$template_group

    if [[ -z $GROUP ]]; then
        GROUP=$(sanitize_path "$(basename "$PWD")")

        # If the current directory is root, set GROUP to "root"
        if [[ $GROUP == "/" ]]; then
            GROUP="root"
        fi
    fi
    [[ -z $SID ]] && SID=$$

    if [[ -z $(tmux list-sessions -F "#{session_name}" | grep "^$GROUP$") ]]; then
        build_template
    fi
    
    if [[ $DETACH -eq 0 ]]; then
        attachSession $GROUP $SID
    fi 
    exit 0
    ;;
esac


if [[ -n $TMUX ]]; then 
    if [[ -z $SUBCOMMAND || $SUBCOMMAND == "a" ]]; then
        SUBCOMMAND="a"
        TITLE="Select to attach"
    fi

    if [[ $SUBCOMMAND == "k" ]]; then
        TITLE="Select to kill"
    fi

    ITEMS=""
    index=1
    SESSION_GROUPS=$(tmux list-sessions -F "#{session_name}" | awk -F '#' '{print $1}' | sort -u)
    while read -r group; do
    if [[ -n "$group" ]]; then
        ITEMS+="$group $index 'run-shell \"tmuxss -$SUBCOMMAND -g \"$group\"\"' "
        ((index++))
    fi
    done <<< "$SESSION_GROUPS"

    if [[ -n $ITEMS ]]; then
        eval "tmux display-menu -T \"$TITLE\" $ITEMS"
    else
        tmux display-message "No session groups found."
    fi
else
    help
fi
