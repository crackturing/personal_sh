#!/bin/bash
ANDROID_PATH=$(pwd)/IMX8_beta
UBOOT_PATH=${ANDROID_PATH}/vendor/nxp-opensource/uboot-imx
KERNEL_DIR=${ANDROID_PATH}/vendor/nxp-opensource/kernel_imx

UBOOT_FIRMWARE=${ANDROID_PATH}/vendor/nxp/fsl-proprietary/uboot-firmware/imx8q
UBOOT_CREATE_PATH=${ANDROID_PATH}/vendor/nxp-opensource/imx-mkimage

TEMP_CPU_COUNT=$(grep process /proc/cpuinfo | wc -l)
if [ ${TEMP_CPU_COUNT} -gt 32 ];then
	CPU_COUNT=`expr $(($TEMP_CPU_COUNT/4))`
else
	CPU_COUNT=${TEMP_CPU_COUNT}
fi
echo -e "Output the cpu count: ${CPU_COUNT}\n"

OPTION_PROJECT=$(cat ${ANDROID_PATH}/device/fsl/imx8/vendorsetup.sh | grep add_lunch_combo |cut -c 17-)

DEFAULT_UBOOT_CONFIG=mx8qxp_mek_android_defconfig
DEFAULT_KERNEL_CONFIG=android_defconfig
DEFAULT_ANDROID_PRODUCT=mek_8q-eng

build_android()
{
	set -e
		
	echo -e "\n\nBuild android start...\n\n"
	cd ${ANDROID_PATH}
	
	source build/envsetup.sh
	lunch ${IMX8_TARGET_PROJECT}
	make -j$CPU_COUNT 2>&1 | tee build_android_log.txt
	if [ $? -ne 0 ] ; then
		echo -e "\n\n\033[0;31;5m Build android failed!!\033[0m\n\n"
		exit 1
    fi

    echo -e "\n\033[0;32;1m  Build android success\033[0m\n"
}

clean_android()
{
	echo -e "\n\nClean android start...\n\n"	
	
	cd ${ANDROID_PATH}
	make clean
}

make_otapackage()
{
	set -e

	echo -e "\n\nMake ota_package start...\n\n"	
	
	cd ${ANDROID_PATH}
	
	source build/envsetup.sh
	lunch ${IMX8_TARGET_PROJECT}
	if [ $? -ne 0 ] ; then
		echo -e "\n\n\033[0;31;5m Build android failed!!\033[0m\n\n"
		exit 1
    fi
	make PRODUCT=${IMX8_TARGET_PROJECT} otapackage -j$CPU_COUNT
}

create_uboot()
{
	set -e

	echo -e "\n\n create uboot-imx8qxp.imx start...\n\n"

	cd ${ANDROID_PATH}
 
	if [ -f ${UBOOT_FIRMWARE}/${IMX8_PROJECT_NAME}_dcd.cfg.tmp ];then
		UBOOT_DCD_CFG=${IMX8_PROJECT_NAME}_dcd.cfg.tmp
	else
		UBOOT_DCD_CFG=imx8qx_dcd.cfg.tmp
	fi

	cp ${UBOOT_PATH}/u-boot.bin ${UBOOT_CREATE_PATH}/iMX8QX/u-boot.bin
	cp ${UBOOT_FIRMWARE}/mx8qx-scfw-tcm.bin ${UBOOT_CREATE_PATH}/iMX8QX/scfw_tcm.bin
	#cp ${UBOOT_FIRMWARE}/${UBOOT_DCD_CFG} ${UBOOT_CREATE_PATH}/iMX8QX/imx8qx_dcd.cfg
	cp ${UBOOT_FIRMWARE}/bl31-imx8qxp.bin ${UBOOT_CREATE_PATH}/iMX8QX/bl31.bin
	
	cd ${UBOOT_CREATE_PATH}
	make -C ${UBOOT_CREATE_PATH} clean; 
	make -C ${UBOOT_CREATE_PATH} SOC=iMX8QX flash;
	#make -C ${UBOOT_CREATE_PATH} SOC=iMX8QX flash_dcd; 

	cp ${UBOOT_CREATE_PATH}/iMX8QX/flash.bin ${IMX8_ANDROID_OUT_DIR}/u-boot-imx8qxp.imx

	echo -e "\n\033[0;32;1m create uboot-imx8qxp.imx success\033[0m\n"
}

build_uboot()
{
	set -e

	cd ${UBOOT_PATH}
	make distclean

	if [ -f ${UBOOT_PATH}/configs/${IMX8_PROJECT_NAME}_defconfig ];then
		echo -e "\n\nBuild u-boot ${IMX8_PROJECT_NAME}_defconfig start...\n\n"
		make ${IMX8_PROJECT_NAME}_defconfig
	else
		echo -e "\n\nBuild u-boot ${DEFAULT_UBOOT_CONFIG} start...\n\n"
		make ${DEFAULT_UBOOT_CONFIG};
	fi
	
	make -j$CPU_COUNT
	if [ $? -ne 0 ] ; then
		echo -e "\n\n\033[0;31;5m Build uboot failed!!\033[0m\n\n"
		exit 1
	fi

	echo -e "\n\033[0;32;1m Build u-boot success\033[0m\n"

	create_uboot
}

clean_uboot()
{
	echo -e "\n\nClean u-boot start...\n\n"
	
	cd ${UBOOT_PATH}
	make distclean	
}

build_kernel()
{
	set -e

	echo -e "\n\nBuild kernel start...\n\n"
		
	cd ${KERNEL_DIR}
	
	if [ ! -f ${KERNEL_DIR}/arch/arm64/configs/${IMX8_PROJECT_NAME}_defconfig ];then
		echo -e "Build ${DEFAULT_KERNEL_CONFIG}...\n"
		make ${DEFAULT_KERNEL_CONFIG}
	else
		echo -e "Build ${IMX8_PROJECT_NAME}_defconfig...\n"
		make ${IMX8_PROJECT_NAME}_defconfig
	fi

	make KCFLAGS=-mno-android -j$CPU_COUNT
	if [ $? -ne 0 ] ; then
		echo -e "\n\n\033[0;31;5m Make kernel failed!!\033[0m\n\n"
		exit 1
	fi
	echo -e "\n\033[0;32;1m Make kernel success\033[0m\n"
}

clean_kernel()
{
	echo "clean_kernel"
	cd ${KERNEL_DIR}
	make distclean
}

build_boot_image()
{
	set -e

	echo -e "\n\nBuild boot.img start...\n\n"
	cd ${ANDROID_PATH}
	source build/envsetup.sh
	lunch ${IMX8_TARGET_PROJECT}
	make bootimage -j$CPU_COUNT
	if [ $? -ne 0 ] ; then
		echo -e "\n\n\033[0;31;5m Make bootimage failed!!\033[0m\n\n"
		exit 1
	fi
	echo -e "\n\033[0;32;1m Make bootimage success\033[0m\n"
}

build_recovery_image()
{
	set -e

	echo -e "\n\nBuild boot.img start...\n\n"
	cd ${ANDROID_PATH}
	source build/envsetup.sh
	lunch ${IMX8_TARGET_PROJECT}
	make recoveryimage -j$CPU_COUNT
	if [ $? -ne 0 ] ; then
		echo -e "\n\n\033[0;31;5m Make recoveryimage failed!!\033[0m\n\n"
		exit 1
	fi
	echo -e "\n\033[0;32;1m Make recoveryimage success\033[0m\n"
}

setup_env()
{
	if [ -z $1 ];then
		export IMX8_TARGET_PROJECT=$DEFAULT_ANDROID_PRODUCT
		echo "$OPTION_PROJECT" | grep -x ${IMX8_TARGET_PROJECT}
	else
		echo "$OPTION_PROJECT" | grep -x $1
		if [ $? == 0 ];then
			export IMX8_TARGET_PROJECT=$1
		else
			echo -e "\033[0;31;1m ######Error: $1 is not a valid project ###### \033[0m"
			usage
			return 1
		fi
	fi

	export IMX8_PROJECT_NAME=$(echo ${IMX8_TARGET_PROJECT} | cut -d- -f1)
	export IMX8_ANDROID_OUT_DIR=${ANDROID_PATH}/out/target/product/${IMX8_PROJECT_NAME}
	export ARCH=arm64
	export CROSS_COMPILE=${ANDROID_PATH}/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-

	mkdir -p ${IMX8_ANDROID_OUT_DIR}
}

usage()
{
echo -e "Usage:
\033[0;31;1m source build.sh env [prj] \033[0m  use mek_8q-eng as default prj
例如imx8项目： source build.sh env mek_8q-eng
项目可选prj参数: ${OPTION_PROJECT}\n
command: 
    $0 uboot                ---- build uboot image
    $0 kernel               ---- build kernel image
    $0 android              ---- build android image
    $0 clean-uboot          ---- clean uboot
    $0 clean-kernel         ---- clean kernel
    $0 clean-android        ---- clean android
    $0 clean-uboot-kernel   ---- clean uboot & kernel
    $0 update               ---- make ota update image
    $0 all                  ---- make all
"
}

if [ -z ${IMX8_TARGET_PROJECT} ] && [ "$1" != "env" ];then
	usage
	exit 1	
fi

case $1 in
	uboot)
		build_uboot
		;;
	clean-uboot)
		clean_uboot
		;;
	kernel)
		build_kernel
		;;
	clean-kernel)
		clean_kernel
		;;
	bootimg)
		build_kernel
		build_boot_image
		;;
	android)
		build_android
		;;
	clean-android)
		clean_android
		;;
	update)
		make_otapackage
		;;
	env)
		setup_env $2 
		;;
	all)
		build_uboot
		build_kernel
		build_boot_image
		build_android
		#make_otapackage
		;;
	clean-uboot-kernel)
		clean_uboot
		clean_kernel
		;;
	clean-all)
		clean_uboot
		clean_kernel
		clean_android		
		;;
	*)
		echo -e "\nwrong target cmd: $1,please check!"
		usage
		exit 1
		;;
esac

