#!/bin/bash
ANDROID_PATH=$(pwd)/myandroid
UBOOT_PATH=${ANDROID_PATH}/vendor/nxp-opensource/uboot-imx
KERNEL_DIR=${ANDROID_PATH}/vendor/nxp-opensource/kernel_imx

UBOOT_FIRMWARE=${ANDROID_PATH}/vendor/nxp/fsl-proprietary/uboot-firmware/imx8q
UBOOT_CREATE_PATH=${ANDROID_PATH}/vendor/nxp-opensource/imx-mkimage

KERNEL_DTS_DIR=${KERNEL_DIR}/arch/arm64/boot/dts/freescale
KERNEL_CONFIGS_DIR=${KERNEL_DIR}/arch/arm64/configs
CPU_COUNT=$(grep process /proc/cpuinfo | wc -l)
OPTION_PROJECT=$(cat ${ANDROID_PATH}/device/fsl/imx8/vendorsetup.sh | grep add_lunch_combo |cut -c 17-)
SD_BURN_OPTION_PROJECT=$(cat ${ANDROID_PATH}/device/fsl/imx8/vendorsetup.sh | grep add_lunch_combo |cut -c 17- |cut -d - -f 1)
UBOOT_CONFIGS_PATH=${UBOOT_PATH}/configs
DEFAULT_ANDROID_CONFIG=mek_8q-userdebug
DEFAULT_UBOOT_CONFIG=mx8qxp_mek_android_defconfig
#mx8qxp_lpddr4_mek_android_defconfig  mx8qxp_mek_android_defconfig imx8qxp_mek_defconfig
SOC_TYPE=imx8qxp
M4_PATH=$(pwd)/m4_imx8qxp
#imx8qm   imx8qxp

function getdir(){
#   echo $1
    for file in $1/*
    do
    if test -f $file
    then
#       echo $file
        arr=(${arr[*]} $file)
    else
        getdir $file
    fi
    done
}

function checkout_diff(){
	cd ${ANDROID_PATH}
	prjdir=${ANDROID_PATH}/device/fsl/${IMX8_TARGET_PRODUCT}/project/
	getdir ${ANDROID_PATH}/device/fsl/${IMX8_TARGET_PRODUCT}/project
	for i in ${arr[@]}
	do
		echo "git checkout "${i:${#prjdir}}
		git checkout ${i:${#prjdir}}
	done
}

build_android()
{
	set -e
		
	echo -e "\n\nBuild android start...\n\n"
	cd ${ANDROID_PATH}
	
	source build/envsetup.sh
	lunch ${IMX8_TARGET_PRODUCT_COMBO}
	make -j$CPU_COUNT 2>&1 | tee build_android_log.txt
	#make -j$CPU_COUNT
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
	lunch ${IMX8_TARGET_PRODUCT_COMBO}
	if [ $? -ne 0 ] ; then
		echo -e "\n\n\033[0;31;5m Build android failed!!\033[0m\n\n"
		exit 1
    fi
	make PRODUCT=${IMX8_TARGET_PRODUCT_COMBO} otapackage -j$CPU_COUNT
}

create_uboot()
{
	set -e

	echo -e "\n\n create uboot-${SOC_TYPE}.imx start...\n\n"

	cd ${ANDROID_PATH}

	if [ "${SOC_TYPE}" == "imx8qm" ]; then 
		MKIMAGE_PLATFORM=`echo iMX8QM`; 
		SCFW_PLATFORM=`echo 8qm`;  
	elif [ "${SOC_TYPE}" == "imx8qxp" ]; then 
		MKIMAGE_PLATFORM=`echo iMX8QX`; 
		SCFW_PLATFORM=`echo 8qx`; 
	fi; 

	if [ -f ${UBOOT_FIRMWARE}/${IMX8_TARGET_PRODUCT}_dcd.cfg.tmp ];then
		UBOOT_DCD_CFG=${IMX8_TARGET_PRODUCT}_dcd.cfg.tmp
	else
		UBOOT_DCD_CFG=imx8qx_dcd.cfg.tmp
	fi

	cp ${UBOOT_PATH}/u-boot.bin ${UBOOT_CREATE_PATH}/iMX8QX/u-boot.bin
	cp ${UBOOT_FIRMWARE}/mx8qx-scfw-tcm.bin ${UBOOT_CREATE_PATH}/iMX8QX/scfw_tcm.bin
	#cp ${UBOOT_FIRMWARE}/${UBOOT_DCD_CFG} ${UBOOT_CREATE_PATH}/iMX8QX/imx8qx_dcd.cfg
	cp ${UBOOT_FIRMWARE}/bl31-${SOC_TYPE}.bin ${UBOOT_CREATE_PATH}/iMX8QX/bl31.bin
	
	cd ${UBOOT_CREATE_PATH}
	make -C ${UBOOT_CREATE_PATH} clean; 
	make -C ${UBOOT_CREATE_PATH} SOC=iMX8QX flash; 

	cp ${UBOOT_CREATE_PATH}/iMX8QX/flash.bin ${IMX8_ANDROID_OUT_DIR}/u-boot-${SOC_TYPE}.imx
	cp ${UBOOT_CREATE_PATH}/iMX8QX/flash.bin ${IMX8_ANDROID_OUT_DIR}/u-boot.imx

	echo -e "\n\033[0;32;1m create uboot-${SOC_TYPE}.imx success\033[0m\n"
}

build_uboot()
{
	set -e

	cd ${UBOOT_PATH}
	make distclean

	if [ -f ${UBOOT_PATH}/configs/${IMX8_TARGET_PRODUCT}_defconfig ];then
		echo -e "\n\nBuild u-boot ${IMX8_TARGET_PRODUCT}_defconfig start...\n\n"
		make ${IMX8_TARGET_PRODUCT}_defconfig
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
	
	if [ ! -f ${KERNEL_DIR}/arch/arm64/configs/${IMX8_TARGET_PRODUCT}_defconfig ];then
		echo -e "Build android_defconfig...\n"
		make android_defconfig
	else
		echo -e "Build ${IMX8_TARGET_PRODUCT}_defconfig...\n"
		make ${IMX8_TARGET_PRODUCT}_defconfig
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
	lunch ${IMX8_TARGET_PRODUCT_COMBO}
	make bootimage
	if [ $? -ne 0 ] ; then
		echo -e "\n\n\033[0;31;5m Make bootimage failed!!\033[0m\n\n"
		exit 1
	fi
	echo -e "\n\033[0;32;1m Make bootimage success\033[0m\n"
}

build_boot_image_sd()
{
	set -e

	echo -e "\n\nBuild boot.img start...\n\n"
	cd ${ANDROID_PATH}
	source build/envsetup.sh
	lunch ${IMX8_TARGET_PRODUCT_COMBO}
	make bootimage BUILD_TARGET_DEVICE=sd
	if [ $? -ne 0 ] ; then
		echo -e "\n\n\033[0;31;5m Make bootimage sdcard failed!!\033[0m\n\n"
		exit 1
	fi
	echo -e "\n\033[0;32;1m Make bootimage sdcard success\033[0m\n"
}

build_recovery_image()
{
	set -e

	echo -e "\n\nBuild boot.img start...\n\n"
	cd ${ANDROID_PATH}
	source build/envsetup.sh
	lunch ${IMX8_TARGET_PRODUCT_COMBO}
	make recoveryimage 
	if [ $? -ne 0 ] ; then
		echo -e "\n\n\033[0;31;5m Make recoveryimage failed!!\033[0m\n\n"
		exit 1
	fi
	echo -e "\n\033[0;32;1m Make recoveryimage success\033[0m\n"
}

build_recovery_image_sd()
{
	set -e

	echo -e "\n\nBuild boot.img start...\n\n"
	cd ${ANDROID_PATH}
	source build/envsetup.sh
	lunch ${IMX8_TARGET_PRODUCT_COMBO}
	make recoveryimage BUILD_TARGET_DEVICE=sd
	if [ $? -ne 0 ] ; then
		echo -e "\n\n\033[0;31;5m Make recoveryimage sdcard failed!!\033[0m\n\n"
		exit 1
	fi
	echo -e "\n\033[0;32;1m Make recoveryimage sdcard success\033[0m\n"
}

setup_env()
{
	if [ -z $1 ];then
		export IMX8_TARGET_PRODUCT_COMBO=$DEFAULT_ANDROID_CONFIG
		echo "$OPTION_PROJECT" | grep -x $1
	else
		echo "$OPTION_PROJECT" | grep -x $1
		if [ $? == 0 ];then
			export IMX8_TARGET_PRODUCT_COMBO=$1
		else
			echo -e "\033[0;31;1m ######Error: $1 is not a valid project ###### \033[0m"
			usage
			return 1
		fi
	fi

	export IMX8_TARGET_PRODUCT=$(echo ${IMX8_TARGET_PRODUCT_COMBO} | cut -d- -f1)
	export IMX8_ANDROID_OUT_DIR=${ANDROID_PATH}/out/target/product/${IMX8_TARGET_PRODUCT}
	export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64
	export JRE_HOME=${JAVA_HOME}/jre
	export PATH=$JAVA_HOME/bin:${JRE_HOME}/bin:$PATH
	export JAVA_PATH=${JAVA_HOME}/bin:${JRE_HOME}/bin
	export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
	export ARCH=arm64
	export CROSS_COMPILE=${ANDROID_PATH}/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-

	cd ${ANDROID_PATH}
	source build/envsetup.sh
	lunch ${IMX8_TARGET_PRODUCT_COMBO}
	mkdir -p ${IMX8_ANDROID_OUT_DIR}
	cd ..

	if [ -f ${ANDROID_PATH}/device/fsl/${IMX8_TARGET_PRODUCT}/project_copy.sh ]; then
		${ANDROID_PATH}/device/fsl/${IMX8_TARGET_PRODUCT}/project_copy.sh
	fi
	sleep 1

	if [ -f ${M4_PATH}/setup_env.sh ]; then
		cd ${M4_PATH}
		source ${M4_PATH}/setup_env.sh
		cd ../
	fi

	export PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:[$IMX8_TARGET_PRODUCT]\[\033[01;34m\]\w\[\033[00m\]\$'
}

usage()
{
    echo "
    Usage:
	source build.sh env [prj]       ---- setup building enviroment, use $DEFAULT_ANDROID_CONFIG as default
	例如绿驰项目： source build.sh env Q1205LC17A-user
	项目可选prj参数: "$OPTION_PROJECT"
	$0 uboot                ---- build uboot image
	$0 clean-uboot          ---- clean uboot
	$0 kernel               ---- build kernel image
	$0 clean-kernel     	---- clean kernel
	$0 android              ---- build android image
	$0 clean-android        ---- clean android
	$0 clean-uboot-kernel   ---- clean u-boot & kernel
	$0 update               ---- make ota update image
	$0 bootsd		 	    ---- make boot.img from sdcard
	$0 recoverysd			---- make recovery.img boot from sdcard
	$0 all                  ---- make all
	"
}

if [ -z ${IMX8_TARGET_PRODUCT} ] && [ "$1" != "env" ];then
	usage
	echo -e "第一步先执行：\033[0;31;1m source build.sh env [prj] \033[0m ,不传入prj时默认使用$DEFAULT_ANDROID_CONFIG"
	echo -e "例如绿驰项目:	source build.sh env Q1205LC17A-user"
	echo -e "项目可选prj参数: $OPTION_PROJECT\n"
	exit 1
else
	mkdir -p ${IMX8_ANDROID_OUT_DIR}
fi

if [ "$IMX8_TARGET_PRODUCT" = sd_burn ];then
    if [ "$1" != "env" ] && [ "$2" = "" ];then
        echo -e "\033[0;31;1mPlease choice board card project：./build.sh all Q1205LC17A，project_list: $SD_BURN_OPTION_PROJECT \033[0m\n"
	    exit 1
    else
        BUILD_TARGET_SD_BURN_CONFIG=$2

        echo -e "BUILD_TARGET_SD_BURN_CONFIG = $BUILD_TARGET_SD_BURN_CONFIG"

        cd ${KERNEL_DTS_DIR}
        cp -f ${BUILD_TARGET_SD_BURN_CONFIG}.dts ./sd_burn.dts
        cp -f ${BUILD_TARGET_SD_BURN_CONFIG}.dtsi ./sd_burn.dtsi

        cd ${KERNEL_CONFIGS_DIR}
        cp -f ${BUILD_TARGET_SD_BURN_CONFIG}_defconfig ./sd_burn_defconfig

        cd ${UBOOT_CONFIGS_PATH}
        cp -f ${BUILD_TARGET_SD_BURN_CONFIG}_defconfig ./sd_burn_defconfig

		if [ "${SOC_TYPE}" == "imx8qm" ]; then 
			SCFW_PLATFORM=`echo 8qm`;  
		elif [ "${SOC_TYPE}" == "imx8qxp" ]; then 
			SCFW_PLATFORM=`echo 8qx`; 
		fi;

        if [ -f ${UBOOT_FIRMWARE}/${BUILD_TARGET_SD_BURN_CONFIG}_dcd.cfg.tmp ];then
			cp -f ${UBOOT_FIRMWARE}/${BUILD_TARGET_SD_BURN_CONFIG}_dcd.cfg.tmp ${UBOOT_FIRMWARE}/sd_burn_dcd.cfg.tmp
		else
			cp -f ${UBOOT_FIRMWARE}/imx${SCFW_PLATFORM}_dcd.cfg.tmp ${UBOOT_FIRMWARE}/sd_burn_dcd.cfg.tmp
		fi

	    echo -e "\033[0;31;1m copy Uboot Kernel configs finish \033[0m\n"
    fi
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
	bootsd)
		build_boot_image_sd
		;;
	recoverysd)
		build_recovery_image_sd
		;;
	env)
		setup_env $2 
		;;
	checkout)
		checkout_diff
		;;
	all)
		build_uboot
		build_kernel
		build_boot_image
		build_android
		#make_otapackage
		;;
	all_sd)
		build_uboot
		build_kernel
		build_boot_image_sd
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
		echo -e "\n\nwrong target cmd: $1,pls check!"
		usage
		exit 1
		;;
esac

