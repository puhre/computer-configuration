
error() {
    echo $@ 1>&2
}


parse_args() {
    HELP_MESSAGE=`mktemp`
    cat <<EOF > $HELP_MESSAGE
run [GROUP]
    -f, --force         No dry-run
    -i, --install       Install files from repo onto host machine
    -u, --update        Update files in repo with files from host machine
EOF
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

    if [[ ${#POSITIONAL[@]} -eq 0 ]]; then
        error "No group provided"
        return 1
    fi

    local positional_arg=${POSITIONAL[0]}

    local groups=(`yq keys[] ${CONF_FILE} -r`)
    for group in ${groups[@]}; do
        if [[ $group == $positional_arg ]]; then
            error "Processing group '$group'"
            GROUP=$group
        fi
    done

    if [[ -z $GROUP ]]; then
        error "Argument '$positional_arg' is not in list of defined groups" 1
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
        cp $1 $2
    else
        echo "Copying file '$1' to '$2'"
    fi
}
