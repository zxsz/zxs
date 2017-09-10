#!/bin/bash
#
#echo -ne "\033[43m  \033[0m"
#echo -ne "\033[41m  \033[0m"
w=$1
[ -z $w ] && w=3
color1=$[$[$RANDOM%10]+40]
color2=$[$[$RANDOM%10]+40]
while [ $color1 -eq $color2 ];do
	color2=$[$[$RANDOM%10]+40]
done	
# 打印不换行空格 $1 控制空格的底色; $w 循环个数控制空格的宽度,每次打印2个
echo_space() {
	for i in `seq $w`;do
		echo -ne "\033[$1m  \033[0m"	
	done
}
# 打印颜色相间单行
echo_line () {
	for i in {1..8};do
		if [ $[i%2] -eq 0 ];then
			echo_space $color1
		else
			echo_space $color2
		fi
	done
	echo
}
# 打印出正方形块,调用函数 echo_line 打印 $w 次, 此函数被调用一次 ,color1 和 color2 变量调换一次
echo_block() {
	if [ -z "$1" ];then
		tmp=$color1
		color1=$color2
		color2=$tmp
	fi
	for j in `seq $w`;do
		echo_line
	done
}
# 调用 echo_block 打印8次,每打印一行颜色调换一次
for i in {1..8};do
	echo_block
done
