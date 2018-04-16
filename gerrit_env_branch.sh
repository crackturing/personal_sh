#!/bin/bash

BRANCH=master

if [ ! -n "$1" ];
then
    echo -e "\033[0;31;1m请配置提交参数, ./gerrit_env_branch 提交人姓名 项目审核人姓名 仓库名 分支名, \n
          例如：./gerrit_env_branch lixiaotian zhanleqing imx6_package master. \033[0m\n"

	exit;
elif [ ! -n "$2" ];
then
	echo "[error]: please input reveiwer name"
	exit;
elif [ ! -n "$3" ];
then 
	echo "[error]: please input your project name"
	exit;
elif [ -n "$4" ];
then 
	echo "[Notice] Use branch $4"
	BRANCH=$4
fi

echo welcome $1,now begin config......

#config git user name and email
git config --global user.name "$1"
git config --global user.email $1@roadrover.cn

#download commit-msg for change-Id
echo "Download the commit-msg file from gerrit server..."
scp -P 29418 -p $1@192.168.10.53:hooks/commit-msg .git/hooks/
chmod 777 .git/hooks/commit-msg
echo "Dowmload completed."

#check the git config file 
if grep -q review .git/config;
then
	echo "recovery git config file......"
	cp .git/.config-bak .git/config
else
	cp .git/config .git/.config-bak

fi

#modify the git config file,add reviewer
echo "[remote \"review\"]
	url = ssh://$1@192.168.10.53:29418/$3
	push = HEAD:refs/for/$BRANCH%r=$2@roadrover.cn,cc=qiuxiaofeng@roadrover.cn" >> .git/config
echo Config Success Done!
