#!/bin/bash
ANDROID_PATH=$(pwd)/myandroid
UBOOT_PATH=${ANDROID_PATH}/bootable/bootloader/uboot-imx
UBOOT_OUT_PATH=${ANDROID_PATH}/bootable/bootloader/uboot-imx/
KERNEL_DIR=${ANDROID_PATH}/kernel_imx
KERNEL_DTS_DIR=${ANDROID_PATH}/kernel_imx/arch/arm/boot/dts
KERNEL_CONFIGS_DIR=${ANDROID_PATH}/kernel_imx/arch/arm/configs
CPU_COUNT=$(grep process /proc/cpuinfo | wc -l)
OPTION_PROJECT=$(cat ${ANDROID_PATH}/device/fsl/imx6/vendorsetup.sh | grep add_lunch_combo |cut -c 17-)
UBOOT_PROJECT_CONFIG_PATH=${UBOOT_OUT_PATH}/include/configs/
SD_BURN_OPTION_PROJECT=$(cat ${ANDROID_PATH}/device/fsl/imx6/vendorsetup.sh | grep add_lunch_combo |cut -c 17- |cut -d - -f 1)
UBOOT_CONFIGS_PATH=${ANDROID_PATH}/bootable/bootloader/uboot-imx/configs/

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
	prjdir=${ANDROID_PATH}/device/fsl/${IMX6_TARGET_PRODUCT}/project/
	getdir ${ANDROID_PATH}/device/fsl/${IMX6_TARGET_PRODUCT}/project
	for i in ${arr[@]}
	do
		echo "git checkout "${i:${#prjdir}}
		git checkout ${i:${#prjdir}}
	done
}

build_android()
{
	set -e
	
	rm -rf ${ANDROID_PATH}/out/target/product/${TARGET_PRODUCT}/system

	if [ -f ${ANDROID_PATH}/device/fsl/${TARGET_PRODUCT}/vendor/vendor_copy.sh ]; then
		${ANDROID_PATH}/device/fsl/${TARGET_PRODUCT}/vendor/vendor_copy.sh
	fi
		
	echo -e "\n\nBuild android start...\n\n"
	cd ${ANDROID_PATH}
	
	source build/envsetup.sh
	lunch ${IMX6_TARGET_PRODUCT_COMBO}
	make 2>&1 |tee Build_Log.txt
	#make -j$CPU_COUNT
	if [ $? -ne 0 ] ; then
		echo -e "\n\n\033[0;31;5m Build android failed!!\033[0m\n\n"
		exit 1
    fi
    last_version=`cat ${ANDROID_PATH}/out/target/product/${TARGET_PRODUCT}/system/build.prop |grep "ro.build.display.id" | tail -n 1 | cut -d "=" -f2- | awk '{print $1}'`
    echo -e "$last_version"
    echo $last_version > last_successful_version.txt

    echo -e "\n\033[0;32;1m  Build android successfully\033[0m\n"
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
	lunch ${IMX6_TARGET_PRODUCT_COMBO}
	if [ $? -ne 0 ] ; then
		echo -e "\n\n\033[0;31;5m Build android failed!!\033[0m\n\n"
		exit 1
    fi
	make PRODUCT=${IMX6_TARGET_PRODUCT_COMBO} otapackage -j$CPU_COUNT
}

build_uboot()
{
	set -e

	echo -e "\n\nBuild u-boot start...\n\n"
	cd ${UBOOT_PATH}
	make distclean
	if [ -f ${UBOOT_PATH}/configs/${IMX6_TARGET_PRODUCT}_defconfig ];then
		make ${IMX6_TARGET_PRODUCT}_config
	else
		make mx6qsabresdandroid_config;
	fi
	
	if [ ! -f "${UBOOT_PROJECT_CONFIG_PATH}/mx6sabre_project.h" ];then
		echo -e "\n\n\033[0;31;5m u-boot project config file not exist,pls check!!\033[0m\n\n"
		return
	fi
	
	if [ "$IMX6_TARGET_PRODUCT" = sd_burn ];then
		sed -i '/CONFIG_MX6_PROJECT/d' ${UBOOT_PROJECT_CONFIG_PATH}/mx6sabre_project.h
		sed '5 i#define CONFIG_MX6_PROJECT_'${BUILD_TARGET_SD_BURN_CONFIG} -i ${UBOOT_PROJECT_CONFIG_PATH}/mx6sabre_project.h
	else
		sed -i '/CONFIG_MX6_PROJECT/d' ${UBOOT_PROJECT_CONFIG_PATH}/mx6sabre_project.h
		sed '5 i#define CONFIG_MX6_PROJECT_'${IMX6_TARGET_PRODUCT} -i ${UBOOT_PROJECT_CONFIG_PATH}/mx6sabre_project.h
	fi

	make -j$CPU_COUNT
	if [ $? -ne 0 ] ; then
		echo -e "\n\n\033[0;31;5m Build uboot failed!!\033[0m\n\n"
		exit 1
	fi
	cp -f ${UBOOT_OUT_PATH}/u-boot.imx ${IMX6_ANDROID_OUT_DIR}/u-boot-imx6q.imx	
	cp -f ${UBOOT_OUT_PATH}/u-boot.imx ${IMX6_ANDROID_OUT_DIR}/
	echo -e "\n\033[0;32;1m Build u-boot successfully\033[0m\n"
}

build_uboot_dl()
{
	set -e
	
	echo -e "\n\nBuild u-boot start...\n\n"
	cd ${UBOOT_PATH}
	make distclean
	make mx6dlsabresdandroid_config
	make -j$CPU_COUNT
	if [ $? -ne 0 ] ; then
		echo -e "\n\n\033[0;31;5m Build uboot failed!!\033[0m\n\n"
		exit 1
	fi
	cp -f ${UBOOT_OUT_PATH}/u-boot.imx ${IMX6_ANDROID_OUT_DIR}/u-boot-imx6dl.imx	
	echo -e "\n\033[0;32;1m Build u-boot successfully\033[0m\n"
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
	
	export PATH=${ANDROID_PATH}/bootable/bootloader/uboot-imx/tools:$PATH
	
	cd ${ANDROID_PATH}/kernel_imx
	echo $ARCH && echo $CROSS_COMPILE &&echo $PATH
	
	if [ "${IMX6_TARGET_PRODUCT}" == "sabresd_6dq" ];then
		make imx_v7_android_defconfig
	else
		make ${IMX6_TARGET_PRODUCT}_defconfig
	fi
	make KCFLAGS=-mno-android -j$CPU_COUNT
	make uImage LOADADDR=0x10008000 KCFLAGS=-mno-android -j$CPU_COUNT
	if [ $? -ne 0 ] ; then
		echo -e "\n\n\033[0;31;5m Make uImage failed!!\033[0m\n\n"
		exit 1
	fi
	echo -e "\n\033[0;32;1m Make kernel successfully\033[0m\n"
}

build_boot_image()
{
	set -e
	cp ${ANDROID_PATH}/device/fsl/${IMX6_TARGET_PRODUCT}/fstab_emmc.freescale ${ANDROID_PATH}/device/fsl/${IMX6_TARGET_PRODUCT}/fstab.freescale
	cp ${ANDROID_PATH}/device/fsl/${IMX6_TARGET_PRODUCT}/fstab_emmc.freescale ${ANDROID_PATH}/out/target/product/${IMX6_TARGET_PRODUCT}/root/fstab.freescale
	echo -e "\n\nBuild boot.img start...\n\n"
	cd ${ANDROID_PATH}
	source build/envsetup.sh
	lunch ${IMX6_TARGET_PRODUCT_COMBO}
	make bootimage
	if [ $? -ne 0 ] ; then
		echo -e "\n\n\033[0;31;5m Make bootimage failed!!\033[0m\n\n"
		exit 1
	fi
	echo -e "\n\033[0;32;1m Make bootimage successfully\033[0m\n"
}

build_debug_bootimage()
{
	build_kernel
	sleep 1
	cp ${ANDROID_PATH}/kernel_imx/arch/arm/boot/zImage ${ANDROID_PATH}/out/target/product/${TARGET_PRODUCT}/kernel
	${ANDROID_PATH}/out/host/linux-x86/bin/mkbootimg  --kernel ${ANDROID_PATH}/out/target/product/${TARGET_PRODUCT}/kernel --ramdisk ${ANDROID_PATH}/out/target/product/${TARGET_PRODUCT}/ramdisk.img --cmdline "console=ttymxc0,115200 init=/init video=mxcfb0:dev=ldb,bpp=32 video=mxcfb1:dev=hdmi,1920x1080M@60,bpp=32 video=mxcfb2:off video=mxcfb3:off vmalloc=256M androidboot.console=ttymxc0 consoleblank=0 androidboot.hardware=freescale cma=384M androidboot.selinux=disabled androidboot.dm_verity=disabled" --base 0x14000000 --second ${ANDROID_PATH}/kernel_imx/arch/arm/boot/dts/${TARGET_PRODUCT}.dtb  --output ${ANDROID_PATH}/out/target/product/${TARGET_PRODUCT}/boot-imx6q.img
}

build_boot_image_sd()
{
	set -e
	cp ${ANDROID_PATH}/device/fsl/${IMX6_TARGET_PRODUCT}/fstab_sd.freescale ${ANDROID_PATH}/device/fsl/${IMX6_TARGET_PRODUCT}/fstab.freescale
	cp ${ANDROID_PATH}/device/fsl/${IMX6_TARGET_PRODUCT}/fstab_sd.freescale ${ANDROID_PATH}/out/target/product/${IMX6_TARGET_PRODUCT}/root/fstab.freescale
	echo -e "\n\nBuild boot.img start...\n\n"
	cd ${ANDROID_PATH}
	source build/envsetup.sh
	lunch ${IMX6_TARGET_PRODUCT_COMBO}
	make bootimage BUILD_TARGET_DEVICE=sd
	if [ $? -ne 0 ] ; then
		echo -e "\n\n\033[0;31;5m Make bootimage sd failed!!\033[0m\n\n"
		exit 1
	fi
	echo -e "\n\033[0;32;1m Make bootimage sd successfully\033[0m\n"
}

build_recovery_image_sd()
{
	set -e

	echo -e "\n\nBuild boot.img start...\n\n"
	cd ${ANDROID_PATH}
	source build/envsetup.sh
	lunch ${IMX6_TARGET_PRODUCT_COMBO}
	make recoveryimage BUILD_TARGET_DEVICE=sd
	if [ $? -ne 0 ] ; then
		echo -e "\n\n\033[0;31;5m Make recoveryimage failed!!\033[0m\n\n"
		exit 1
	fi
	echo -e "\n\033[0;32;1m Make recoveryimage successfully\033[0m\n"
}

distclean_kernel()
{
	echo "distclean_kernel"
	cd ${ANDROID_PATH}/kernel_imx
	make distclean
}

setup_env()
{
	if [ -z $1 ];then
		export IMX6_TARGET_PRODUCT_COMBO=sabresd_6dq-user
	else
		echo "$OPTION_PROJECT" | grep -x $1
		if [ $? == 0 ];then
			export IMX6_TARGET_PRODUCT_COMBO=$1
		else
			echo -e "\033[0;31;1m ######Error: $1 is not a valid project ###### \033[0m"
			usage
			return 1
		fi
	fi
	export IMX6_TARGET_PRODUCT=$(echo ${IMX6_TARGET_PRODUCT_COMBO} | cut -d- -f1)
	export IMX6_ANDROID_OUT_DIR=${ANDROID_PATH}/out/target/product/${IMX6_TARGET_PRODUCT}
	export JAVA_HOME=/usr/lib/jvm/java-1.7.0-openjdk-amd64
	export JRE_HOME=${JAVA_HOME}/jre
	export PATH=$JAVA_HOME/bin:${JRE_HOME}/bin:$PATH
	export JAVA_PATH=${JAVA_HOME}/bin:${JRE_HOME}/bin
	export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
	export ARCH=arm
	export CROSS_COMPILE=${ANDROID_PATH}/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/bin/arm-linux-androideabi-

	cd ${ANDROID_PATH}

	source build/envsetup.sh
	lunch ${IMX6_TARGET_PRODUCT_COMBO}
	cd ..
	export PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:[$TARGET_PRODUCT]\[\033[01;34m\]\w\[\033[00m\]\$'

	echo -e "\n\ncp project files...\n\n"

	if [ -f ${ANDROID_PATH}/device/fsl/${TARGET_PRODUCT}/project_copy.sh ]; then
		${ANDROID_PATH}/device/fsl/${TARGET_PRODUCT}/project_copy.sh
	fi
    sleep 1
    ./release-build.sh
}

rm_boot_recovery_img() 
{
	rm -f ${IMX6_ANDROID_OUT_DIR}/boot-imx6dl.img
	rm -f ${IMX6_ANDROID_OUT_DIR}/recovery-imx6dl.img
}

usage()
{
    echo "
    Usage:
	source build.sh env [prj]       ---- setup building enviroment, use sabresd_6dq-user as default if no prj input
	例如宇通项目： source build.sh env Q1011YT17A-user
	L10项目: source build.sh env Q1014HL17A-user
	雷诺科雷嘉：source build.sh env RENAULT_KADJAR-user
	项目可选prj参数: "$OPTION_PROJECT"
	$0 uboot                ---- build uboot image
	$0 clean-uboot          ---- clean uboot
	$0 kernel               ---- build kernel image
	$0 distclean-kernel     ---- distclean kernel
	$0 android              ---- build android image
	$0 clean-android        ---- clean android
	$0 clean-uboot-kernel   ---- clean u-boot & kernel
	$0 update               ---- make ota update image
	$0 pack                 ---- pack android image
	$0 bootsd		---- make booting which booting from sdcard(not emmc)
	$0 recoverysd		---- make recovery.img which booting from sdcard(not emmc)
	$0 rm_boot		---- delete boot.img which is at android output directory
	$0 all                  ---- make all
	"
}
if [ -z ${IMX6_TARGET_PRODUCT} ] && [ "$1" != "env" ];then
	usage
	echo -e "第一步先执行：\033[0;31;1m source build.sh env [prj] \033[0m ,不传入prj时默认使用sabresd_6dq-user"
	echo -e "例如宇通项目:	source build.sh env Q1011YT17A-user"
	echo -e "L10项目:	source build.sh env Q1014HL17A-user"
	echo -e "项目可选prj参数: $OPTION_PROJECT\n"
	exit 1
fi

if [ "$IMX6_TARGET_PRODUCT" = sd_burn ];then
    if [ "$1" != "env" ] && [ "$2" = "" ];then
        echo -e "\033[0;31;1m请选择母卡对应项目,例如mmc项目母卡：./build.sh all Q9020TA16A，可选prj参数: $SD_BURN_OPTION_PROJECT \033[0m\n"
	    exit 1
    else
        BUILD_TARGET_SD_BURN_CONFIG=$2
        echo -e "BUILD_TARGET_SD_BURN_CONFIG = $BUILD_TARGET_SD_BURN_CONFIG"
        cd ${KERNEL_DTS_DIR}
        dts_dir=$(pwd)
        echo -e "dtspwd=$dts_dir\n"
        cp -f ${BUILD_TARGET_SD_BURN_CONFIG}.dtb ./sd_burn.dtb
        cp -f ${BUILD_TARGET_SD_BURN_CONFIG}.dts ./sd_burn.dts
        cp -f ${BUILD_TARGET_SD_BURN_CONFIG}.dtsi ./sd_burn.dtsi
	    touch ${ANDROID_PATH}/kernel_imx
        cd ${KERNEL_CONFIGS_DIR}
        kernel_configs_dir=$(pwd)
        echo -e "kernel_confpwd=$kernel_configs_dir\n"
        cp -f ${BUILD_TARGET_SD_BURN_CONFIG}_defconfig ./sd_burn_defconfig
        cd ${UBOOT_CONFIGS_PATH}
        uboot_configs_dir=$(pwd)
        echo -e "uboot_confpwd=$uboot_configs_dir\n"
        cp -f ${BUILD_TARGET_SD_BURN_CONFIG}_defconfig ./mx6qsabresdandroid_defconfig
	    echo -e "\033[0;31;1m 母卡 Uboot Kernel 配置文件拷贝完成！！！ \033[0m\n"
    fi
fi

case $1 in
	uboot)
		build_uboot
		;;
	uboot_dl)
		build_uboot_dl
		;;
	clean-uboot)
		clean_uboot
		;;
	kernel)
		build_kernel
		if [ $? -eq 0 ];then 
			echo #build_boot_image
		else
			echo -e "Build kernel failed"
			exit 1;
		fi
		;;
	bootimg)
		build_kernel
		build_boot_image
		;;
	debug-bootimg)
                build_debug_bootimage
                ;;
	distclean-kernel)
		distclean_kernel
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
		build_kernel
		build_boot_image_sd
		;;
	recoverysd)
		build_recovery_image_sd
		;;
	rm_boot)
		rm_boot_recovery_img
		;;
	env)
		setup_env $2
		;;
	checkout)
		checkout_diff
		;;
	all)
		build_uboot
		distclean_kernel		
		build_kernel
		build_boot_image
		build_android
		#make_otapackage
		;;
	all_sd)
		build_uboot
		distclean_kernel		
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
		echo -e "\n\nwrong target cmd: $1,pls check! �?⊙ω⊙�?"
		usage
		exit 1
		;;
esac
