#!/usr/bin/env bash

source ~/.config/bash/colors.sh

run_test()
{
    printf "[$1] "
    if eval "$2"
    then
        normal_color 2 PASS
    else
        normal_color 1 FAIL
    fi
    echo
}

declare -A tests_options
tests_options[show-ends]="-E tests/test1.txt"
tests_options[show-ends-no]="tests/test1.txt"
tests_options[number]="-n tests/test2.txt"
tests_options[number-E]="-nE tests/test2.txt"
tests_options[number-no]="tests/test2.txt"
tests_options[number-b]="-b tests/test2b.txt"
tests_options[number-bE]="-bE tests/test2b.txt"
tests_options[number-b-no]="tests/test2b.txt"
tests_options[squeeze-blank]="-s tests/test3.txt"
tests_options[squeeze-blank-no]="tests/test3.txt"
tests_options[show-tabs]="-T tests/test4.txt"
tests_options[show-tabs-no]="tests/test4.txt"
tests_options[number-nonblank]="-b tests/test5.txt"
tests_options[number-nonblank-no]="tests/test5.txt"
tests_options[number-nonblank-override]="-bn tests/test5.txt"

declare -A tests_chars
tests_chars[test-chars-A]="-A tests/test_chars.txt"
tests_chars[test-chars-e]="-e tests/test_chars.txt"
tests_chars[test-chars-t]="-t tests/test_chars.txt"
tests_chars[test-chars-v]="-v tests/test_chars.txt"

declare -A tests_multi
tests_multi[test-multi-1]="-n tests/test_multi1.txt tests/test_multi2.txt tests/test_multi3.txt"

declare -A tests_text
declare -A tests_stdin

select=
case "$1" in
    "--options"|"--long"|"--chars")
        select="tests_${1/--/}"
        shift
        ;;
    "--multi")
        select="tests_${1/--/}"
        shift
        ;;
    "--text"|"--stdin")
        mode=${1/--/}
        select="tests_$mode"
        # A b e E n s t T u v
        [[ "$mode" == "text" ]] && num=100 || num=10
        for (( i = 0, j = 0; i < num && j < 1000; ++j))
        do
            flags=""
            randomh=$(($RANDOM % (1 << 10)))
            randoml=$(($RANDOM % (1 << 10)))
            random=$(( (randomh << 10) | randoml ))
            # 25% change to select each flag.
            if (( ( random & (3 << 18) ) == (3 << 18) ))
            then
                flags+="A"
            fi
            if (( ( random & (3 << 16) ) == (3 << 16) ))
            then
                flags+="b"
            fi
            if (( ( random & (3 << 14) ) == (3 << 14) ))
            then
                flags+="e"
            fi
            if (( ( random & (3 << 12) ) == (3 << 12) ))
            then
                flags+="E"
            fi
            if (( ( random & (3 << 10) ) == (3 << 10) ))
            then
                flags+="n"
            fi
            if (( ( random & (3 << 8) ) == (3 << 8) ))
            then
                flags+="s"
            fi
            if (( ( random & (3 << 6) ) == (3 << 6) ))
            then
                flags+="t"
            fi
            if (( ( random & (3 << 4) ) == (3 << 4) ))
            then
                flags+="T"
            fi
            if (( ( random & (3 << 2) ) == (3 << 2) ))
            then
                flags+="u"
            fi
            if (( ( random & (3 << 0) ) == (3 << 0) ))
            then
                flags+="v"
            fi
            [[ -n "$flags" ]] && flags="-$flags"
            key="test-${mode}$flags"
            eval "[[ -v tests_$mode[$key] ]] && continue"
            eval "tests_$mode[$key]=\"$flags tests/test_$mode.txt\""
            ((++i))
        done
        shift
        ;;
    *)
        ;;
esac

eval "keys=(\"\${!${select}[@]}\")"

cabal build >/dev/null

if [[ -n "$1" ]]
then
    eval "if [[ -v $select[\$1] ]] || [[ -n "\$mode" ]]
    then
        vim -d <(cabal run hcat -- \${$select[$1]}) <(cat \${$select[\$1]})
    else
        echo Test \'$1\' not found.
    fi"
    exit
fi

use_dash=0
for t in "${keys[@]}"
do
    if [[ "$select" == "tests_stdin" ]]
    then
        eval "read flags file <<< \"x\${$select[$t]}\""
        flags="${flags:1}"
        # Test stdin both without argument and "-" as argument
        [[ "$use_dash" -eq 1 ]] && dash="-" || dash=
        cmd="diff -q <(cat \$file | cabal run hcat -- \$flags \$dash) <(cat \${$select[$t]}) >/dev/null"
        (( use_dash ^= 1 ))
    else
        cmd="diff -q <(cabal run hcat -- \${$select[$t]}) <(cat \${$select[$t]}) >/dev/null"
    fi
    run_test "$t" "$cmd"
done

if [[ "$select" == "tests_multi" ]]
then
    run_test "test-multi-2" "diff -q \
        <(cat tests/test_multi1.txt | cabal run hcat -- -n - tests/test_multi{2,3}.txt) \
        <(cat -n tests/test_multi{1..3}.txt)"
    run_test "test-multi-3" "diff -q \
        <(cat tests/test_multi2.txt | cabal run hcat -- -n tests/test_multi1.txt - tests/test_multi3.txt) \
        <(cat -n tests/test_multi{1..3}.txt)"
    run_test "test-multi-4" "diff -q \
        <(cat tests/test_multi3.txt | cabal run hcat -- -n tests/test_multi{1,2}.txt -) \
        <(cat -n tests/test_multi{1..3}.txt)"
fi
