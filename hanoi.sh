#!/bin/bash
#
step=0
hanoi(){
	[[ ! $1 =~ ^[1-9][0-9]*$ ]]&&echo "error! please input a positive interger" && exit
	if [ $1 -eq  1 ];then
		let step++
		echo "$step:  move plate $1   $2 -----> $4"
	else
		hanoi "$[$1-1]" $2 $4 $3
		let step++
		echo "$step:  move plate $1   $2 -----> $4"
		hanoi  "$[$1-1]" $3  $2  $4
	fi
}
read -p "please input the  number of plates: "  number
hanoi $number A B C
