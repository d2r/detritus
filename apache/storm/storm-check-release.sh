#!/bin/bash
# This is a tool checksum/signature.
# Originally used on OSX to validate Apache software releases.

set -e

readonly GPG="$(which gpg2)"

if [[ $# -ne 1 || -z "$1" ]]
then
    echo "USAGE: $(basename "$(readlink "$0")") <release-string>
E.G. 'apache-storm-0.9.1-incubating'" >&2
    exit -1
fi

echo "Checking sigs"

ls $1*.asc | while read f
do
    echo -n "Checking sig '$f'..."
    out="$("$GPG" --verify "$f" 2>&1)"
    if [[ $? -eq 0 ]]
    then
        echo "ok"
    else
        echo 'BAD!'
        echo "$out"
    fi
done


echo "Checking sums"

algos=( MD5 SHA512 )
cmds=( "md5" "shasum -a 512")
ext=( "md5" "sha" )
numAlgos=$((${#algos[@]} - 1))


for i in $(seq 0 $numAlgos)
do
    ls ${1}*.${ext[$i]} | while read f
    do
        expected="$(grep "[0-9A-Z ]\+$" "$f" |sed 's;.*:;;'| sed 's; *;;g' | tr '[A-Z]' '[a-z]'|\
        sed -e :a -e '$!N; s/\n//g;ta')"
        actual="$(${cmds[$i]} "${f%.${ext[$i]}}" | \
            sed -E -e 's;^MD5.*= ([0-9a-f]+);\1;' \
                -e 's;^([0-9a-f]+) .*;\1;')"

        if [[ -z "$expected" || "$expected" != "$actual" ]]
        then
            echo "$f:${algos[$i]} MISMATCH!:"
            echo "expected: $expected"
            echo "actual: $actual"
        else
            echo "$f:${algos[$i]} OK.
		($actual)"
        fi
    done
done
