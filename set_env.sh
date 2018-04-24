#!/bin/bash

FILE_PATH="/home/chinatsp/public/document"

user=$(whoami)

function rename(){
    sed -i "s/zhangdan/$user/g" ~/.gitconfig
    echo set name : ${user}
}

function copy_file(){   
    echo "1.拷贝git环境配置文件"
    cp -rvf $FILE_PATH/.gitconfig ~/
    echo "2.拷贝git提交配置文件"
    cp -rvf $FILE_PATH/.commit_temp ~/
    echo "4.拷贝bash开发环境配置文件"
    cp -rvf $FILE_PATH/.bashrc ~/
}

pwd
echo "copy env files"
copy_file

echo "rename gitconfig"
rename

echo "create ssh-key"
$FILE_PATH/ssh-key.sh
