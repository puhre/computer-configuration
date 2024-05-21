
error() {
    echo $@ 1>&2
}


parse_args() {
    HELP_MESSAGE=`mktemp`
    cat <<EOF > $HELP_MESSAGE
run [GROUP]
    -f, --force             No dry-run
    -i, --install           Install files from repo onto host machine
    -u, --update            Update files in repo with files from host machine
    -c, --commit=[BRANCH]   Commit changes to specified branch
    -p, --push=[BRANCH]     Commit and push changes to specified branch, if branch is
                            not already checked out the script will fail.
    --config=[CONFIG_FILE]  Path to config file, defaults to ./tracked-files.yaml
EOF
    shopt -s extglob;
    POSITIONAL=()
    while [[ $# -gt 0 ]]; do
        key="$1"

        case $key in
            -f|--force)
            DRY_RUN=false
            shift
            ;;
            -i|--install)
            INSTALL=false
            UPDATE=true
            shift
            ;;
            -u|--update)
            UPDATE=true
            INSTALL=false
            shift
            ;;
            --commit=[A-Za-z-]*)
            GIT_COMMIT=true
            BRANCH=${1#*=}
            shift
            ;;
            -c|--commit)
            if [[ $# -lt 2 ]]; then
              error "No branch defined"
              exit 1
            fi
            GIT_COMMIT=true
            BRANCH=$2
            shift
            shift
            ;;
            --push=[A-Za-z-]*)
            GIT_COMMIT=true
            GIT_PUSH=true
            BRANCH=${1#*=}
            shift
            ;;
            -p|--push)
            if [[ $# -lt 2 ]]; then
              error "No branch defined"
              exit 1
            fi
            GIT_COMMIT=true
            GIT_PUSH=true
            BRANCH=$2
            shift
            shift
            ;;
            --config=[A-Za-z-]*)
            CONFIG_FILE_ORIG=${1#*=}
            shift
            ;;
            --config)
            if [[ $# -lt 2 ]]; then
              error "No config file defined"
              exit 1
            fi
            CONFIG_FILE_ORIG=$2
            shift
            shift
            ;;
            -h|--help)
            cat $HELP_MESSAGE
            rm $HELP_MESSAGE
            exit 0
            ;;
            *)    # Positional arguments
            POSITIONAL+=($1)
            shift
            ;;
        esac
    done
    shopt -u extglob;

    if [[ ${#POSITIONAL[@]} -eq 0 ]]; then
        error "No group provided"
        return 1
    fi

    local groups=(`yq keys[] ${CONF_FILE} -r`)
    for positional_arg in ${POSITIONAL[*]}; do
      for group in ${groups[@]}; do
          if [[ $group == $positional_arg ]]; then
              error "Processing group '$group'"
              _GROUPS+=($group)
          fi
      done
    done

    if [[ ${#_GROUPS[*]} -eq 0 ]]; then
        error "Argument '${POSITIONAL[@]}' is not in list of defined groups" 1
        return 1
    fi

    if [[ $GIT_COMMIT == true && $BRANCH == "" || $GIT_PUSH == true && $BRANCH == "" ]]; then
      error "No branch defined"
      return 1
    fi
    
    if [[ ! -f ${CONFIG_FILE_ORIG} ]]; then
      error "No file at ${CONFIG_FILE_ORIG}"
      return 1
    fi
}

copy_from_to() {
    if git check-ignore $1 &> /dev/null || git check-ignore $2 &> /dev/null; then
        error Ignoring $1
        return 0
    fi

    if [[ -d $1 ]]; then
        for f in `ls -A $1`; do
            copy_from_to $1/$f $2/$f
        done
        return 0
    fi

    if [[ ! -f $1 ]]; then
        error "Source file '$1' does not exist"
        return 1
    fi

    if diff $1 $2 &> /dev/null;  then
        error File $1 has no change
        return 0
    fi

    if [[ $DRY_RUN != true ]]; then
        mkdir -p `dirname $2`
        cp $1 $2
    else
        echo "Copying file '$1' to '$2'"
    fi
}
