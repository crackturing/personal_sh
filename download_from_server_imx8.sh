#!/bin/sh

USER=tuppie
IP_ADDR=192.168.12.161

CUR_PATH=$(pwd)
SERVER_PATH=$USER@$IP_ADDR
FILES_PATH=/home/tuppie/android_imx8/beta_android/myandroid/out/target/product/mek_8q
WIN7_PATH=/home/tuppie/tuppiecsu/win7_share

DTB_PATH=/home/tuppie/android_imx8/beta_android/myandroid/vendor/nxp-opensource/kernel_imx/arch/arm64/boot/dts/freescale
IMAGE_PATH=/home/tuppie/android_imx8/beta_android/myandroid/vendor/nxp-opensource/kernel_imx/arch/arm64/boot

FILE_1=u-boot-imx8qxp.imx
FILE_2=boot-imx8qxp-dual.img
FILE_3=system.img
FILE_4=recovery-imx8qxp.img
FILE_5=partition-table-28GB.img
FILE_6=vendor.img
FILE_7=vbmeta-imx8qxp-dual.img

function down_uboot
{
echo "download $FILE_1 beginning..."
scp $SERVER_PATH:$FILES_PATH/$FILE_1 $CUR_PATH
}

function down_bootimg
{
echo "download $FILE_2 beginning..."
scp $SERVER_PATH:$FILES_PATH/$FILE_2 $CUR_PATH
}

function down_system
{
echo "download $FILE_3 beginning..."
scp $SERVER_PATH:$FILES_PATH/$FILE_3 $CUR_PATH
}

function down_recovery
{
echo "download $FILE_4 beginning..."
scp $SERVER_PATH:$FILES_PATH/$FILE_4 $CUR_PATH
}

function down_partition
{
echo "download $FILE_5 beginning..."
scp $SERVER_PATH:$FILES_PATH/$FILE_5 $CUR_PATH
}

function down_vendor
{
echo "download $FILE_6 beginning..."
scp $SERVER_PATH:$FILES_PATH/$FILE_6 $CUR_PATH
}

function down_vbmeta
{
echo "download $FILE_7 beginning..."
scp $SERVER_PATH:$FILES_PATH/$FILE_7 $CUR_PATH
}

function down_dtb
{
echo "download $FILE_8 beginning..."
scp $SERVER_PATH:$DTB_PATH/$FILE_8 $CUR_PATH
scp $SERVER_PATH:$DTB_PATH/$FILE_10 $CUR_PATH

}

function down_image
{
echo "download $FILE_9 beginning..."
scp $SERVER_PATH:$IMAGE_PATH/$FILE_9 $CUR_PATH
}

function update_to_win7
{
echo "update_to_win7 beginning..."
mv boot-imx8qxp-dual.img /home/tuppie/tuppiecsu/win7_share/boot-imx8qxp.img
mv vbmeta-imx8qxp-dual.img /home/tuppie/tuppiecsu/win7_share/vbmeta-imx8qxp.img
mv partition-table-28GB.img /home/tuppie/tuppiecsu/win7_share/partition-table.img
sync
}

echo $FILES_PATH

case $1 in
    uboot)
        down_uboot
        ;;
    bootimg)
        down_bootimg
        down_vbmeta
        update_to_win7
        ;;
    system)
        down_system
        ;;
    recovery)
        down_recovery
        ;;
    partition)
        down_partition
        ;;    
    vendor)
        down_vendor
        ;;   
    vbmeta)
        down_bootimg
        down_vbmeta
        ;; 
    dtb)
        down_dtb
        ;; 
    image)
        down_image
        ;; 
    all)
		down_uboot
		down_bootimg
        down_partition
        down_vendor
        down_vbmeta
        update_to_win7
		;;  
    alls)
        down_uboot
        down_bootimg
        down_partition
        down_vendor
        down_vbmeta
        down_system
        update_to_win7
        ;;   
    *)
        echo -e "\nwrong target cmd: $1,please check!"
        exit 1
        ;;
esac

sync