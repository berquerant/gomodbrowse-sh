#!/bin/bash

usage() {
    cat - <<EOS
NAME
  gomodbrowse.sh - Open the repository file downloaded with go mod in browser

SYNOPSIS
  gomodbrowse.sh [target]
  gomodbrowse.sh PATH opens the PATH of the repo.
  gomodbrowse.sh FILE:LINUM opens the line LINUM of the FILE of the repo.
  gomodbrowse.sh opens the directory of the repo.

ENVIRONMENT VARIABLES
  GMBROWSE_OPEN
    command to open file in browser

  GMBROWSE_CURL
    curl command

  GMBROWSE_TRY_URL_FAIL
    make url check fail for debug
EOS
}

GMBROWSE_OPEN="${GMBROWSE_OPEN:-open}"
GMBROWSE_CURL="${GMBROWSE_CURL:-curl}"
GMBROWSE_TRY_URL_FAIL="${GMBROWSE_TRY_URL_FAIL}"

find_mod_dir() {
    begin="$1"
    orig="$1"
    while [ "$begin" != "/" ] ; do
        if echo "$begin" | grep -q -E '/pkg/mod$' ; then
            echo "$begin"
            cd "$orig"
            return 0
        fi
        cd ../
        begin="$(pwd)"
    done

    cd "$orig"
    return 1
}

find_repo_dir() {
    begin="$1"
    while [ "$begin" != "/" ] ; do
        if basename "$begin" | grep -q -F "@" ; then
            echo "$begin"
            cd "$orig"
            return 0
        fi
        cd ../
        begin="$(pwd)"
    done

    cd "$orig"
    return 1
}

get_repo_path() {
    begin="$1"
    mdir="$(find_mod_dir $begin)"
    rdir="$(find_repo_dir $begin)"
    echo "$rdir" | sed "s|${mdir}/||"
}

get_relative_location() {
    begin="$1"
    rdir="$(find_repo_dir $begin)"
    if [ "$rdir" = "$begin" ] ; then
        echo ""
    else
        echo "$begin" | sed "s|${rdir}/||"
    fi
}

build_relative_path() {
    begin="$1"
    path="$2"
    rpath="$(get_relative_location $begin)"
    if [ -n "$rpath" ] ; then
        echo "${rpath}/${path}"
    else
        echo "$path"
    fi
}

get_repo() {
    get_repo_path "$1" | cut -d "@" -f 1
}

get_repo_version() {
    p="$(get_repo_path $1)"
    if echo "$p" | grep -q "@" ; then
        echo "$p"| cut -d "@" -f 2
    else
        echo ""
    fi
}

is_commit_version() {
    echo "$1" | grep -qE 'v[^-]+-[^-]+-.+'
}

get_commit_from_repo_version() {
    if is_commit_version "$1" ; then
        echo "$1" | cut -d "-" -f 3
    else
        echo ""
    fi
}

build_repo_version() {
    repo_version="$(get_repo_version $1)"
    if [ -n "$repo_version" ] ; then
        commit="$(get_commit_from_repo_version $repo_version)"
        if [ -n "$commit" ] ; then
            echo "$commit"
        else
            echo "$repo_version"
        fi
    else
        echo master
    fi
}

build_url() {
    repo="$1"
    ref="$2"
    path="$3"
    linum="$4"

    url="https://${repo}/blob/${ref}"
    if [ -n "$path" ] ; then
        url="${url}/${path}"
    fi
    if [ -n "$linum" ] ; then
        url="${url}#L${linum}"
    fi
    echo "$url"
}

try_url() {
    [ -z "$GMBROWSE_TRY_URL_FAIL" ] && [ $($GMBROWSE_CURL -s -o /dev/null -w "%{http_code}" "$1") = 200 ]
}

open_url() {
    url="$1"
    echo "$url"
    try_url "$url" && "$GMBROWSE_OPEN" "$url"
}

build_open_url() {
    repo="$1"
    ref="$2"
    path="$3"
    linum="$4"

    open_url "$(build_url $repo $ref $path $linum)"
}

open_url_fallback() {
    repo="$1"
    path="$2"
    linum="$3"

    build_open_url "$repo" master "$path" "$linum" ||\
        build_open_url "$repo" main "$path" "$linum" ||\
        open_url "https://${repo}"
}

get_target_path() {
    echo "$1" | cut -d ":" -f 1
}

get_target_linum() {
    if echo "$1" | grep -q ":" ; then
        echo "$1" | cut -d ":" -f 2
    else
        echo ""
    fi
}

main() {
    set -e
    location="$1"
    target="$2"

    repo="$(get_repo $location)"
    ref="$(build_repo_version $location)"
    tpath="$(get_target_path $target)"
    path="$(build_relative_path $location $tpath)"
    linum="$(get_target_linum $target)"

    build_open_url "$repo" "$ref" "$path" "$linum" || open_url_fallback "$repo" "$path" "$linum"
}

if [ "$1" = "-h" ] ; then
    usage
else
    main "$(pwd)" "$@"
fi
