#!/bin/bash

rm -f asm2.log

printf "> Running compatible asm1 tests in evaluation mode\n\n"
for test in legacy*
do
	rm -f "$test.out"
	../../some_lang.native "$test" &> "$test.out"
	cmp -s "$test.out" "expected/$test.exp"
	if [ $? -eq 0 ]; then
		printf "✅  Passed $test\n"
	else
		printf "❗  Failed $test\n"
		printf "===== Failed $test =====\n\n" >> asm2.log
		printf "===== Input:\n" >> asm2.log
		cat "$test" >> asm2.log
		printf "===== Expected:\n" >> asm2.log
		cat "expected/$test.exp" >> asm2.log
		printf "\n===== Output:\n" >> asm2.log
		cat "$test.out" >> asm2.log
		printf "\n===== Error:\n" >> asm2.log
		cmp "$test.out" "expected/$test.exp" >> asm2.log
		printf "\n\n" >> asm2.log
	fi
done

printf "\n> Running asm2 evaluation tests\n\n"
for test in test*
do
	rm -f "$test.out"
	../../some_lang.native "$test" &> "$test.out"
	cmp -s "$test.out" "expected/$test.exp"
	if [ $? -eq 0 ]; then
		printf "✅  Passed $test\n"
	else
		printf "❗  Failed $test\n"
		printf "===== Failed $test =====\n\n" >> asm2.log
		printf "===== Input:\n" >> asm2.log
		cat "$test" >> asm2.log
		printf "===== Expected:\n" >> asm2.log
		cat "expected/$test.exp" >> asm2.log
		printf "\n===== Output:\n" >> asm2.log
		cat "$test.out" >> asm2.log
		printf "\n===== Error:\n" >> asm2.log
		cmp "$test.out" "expected/$test.exp" >> asm2.log
		printf "\n\n" >> asm2.log
	fi
done

rm -f *.out
