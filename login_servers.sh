#!/bin/bash

VALUE=111
if [ ! -n "$1" ];
then
	VALUE=111
else
	VALUE=$1
fi

#/home/chinatsp/.ssh/authorized_keys auto login

case ${VALUE} in
	82)
		ssh tangqishun@10.100.129.82
		;;
	*)
		ssh tangqishun@10.100.129.111
		;;
esac





