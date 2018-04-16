#!/bin/bash

Releasefile=$(pwd)/imx6_project_version/${IMX6_TARGET_PRODUCT}_release  



get_envionment_variables()
{
	
	
	project_version_file=$(grep "project_version_file=" ${Releasefile} |  cut  -d '=' -f 2)
	echo "project_version_file=${project_version_file}"

	uboot_warehuse_number=$(grep "UBOOT_COMMIT_PATH=" ${Releasefile} | wc -l)
	echo "uboot_warehuse_number=${uboot_warehuse_number}"
	for((i=0;i<${uboot_warehuse_number};i++))
               do
               	n=$((i+1))
                 uboot_array[i]=$(grep "UBOOT_COMMIT_PATH=" ${Releasefile} | sed -n ''${n}'p' | cut -d '=' -f 2)
             done


             kernel_warehuse_number=$(grep "KERNE_COMMITL_PATH=" ${Releasefile} | wc -l)
             echo "kernel_warehuse_number=${kernel_warehuse_number}"
             for((i=0;i<${kernel_warehuse_number};i++))
               do
               	n=$((i+1))
                 kernel_array[i]=$(grep "KERNE_COMMITL_PATH=" ${Releasefile} | sed -n ''${n}'p' |  cut -d '=' -f 2)
             done
         

             android_warehuse_number=$(grep "ANDROID_COMMIT_PATH=" ${Releasefile} | wc -l)
             echo "android_warehuse_number =${android_warehuse_number}"
             for((i=0;i<${android_warehuse_number};i++))
               do
               	n=$((i+1))
                 android_array[i]=$(grep "ANDROID_COMMIT_PATH=" ${Releasefile} | sed -n ''${n}'p' |  cut -d '=' -f 2)
             done
        

              app_warehuse_number=$(grep -i "APP_COMMIT_PATH=" ${Releasefile} | wc -l)
             echo "app_warehuse_number=${app_warehuse_number}"
             for((i=0;i<${app_warehuse_number};i++))
               do
               	n=$((i+1))
                 app_array[i]=$(grep -i "APP_COMMIT_PATH=" ${Releasefile} | sed -n ''${n}'p' | cut -d '=' -f 2)
                 name=$(grep -i "APP_COMMIT_PATH=" ${Releasefile} | sed -n ''${n}'p' | cut -d '=' -f 1)
                 app_name_array[i]=$(echo ${name%APP_*})
             done
             
}



checkout_file()
{
	echo "begin check out  release file>>>>"
	if [ -f ${Releasefile} ];then
		echo "${Releasefile} is exist "
	else 
	              touch ${Releasefile}
	fi
	if test -s ${Releasefile}; then
               echo "hi"
            else
              echo "release file empty"
          echo -e "\033[0;31;1musage
             将编译所需库路径写入release文件:
              project_version_file=
             UBOOT_COMMIT_PATH=
             KERNE_COMMITL_PATH=
             ANDROID_COMMIT_PATH=
             APP_COMMIT_PATH=
             "
             exit 1
            fi	
	
}

get_project_commit()
{
	# get project commit
	for((i=0;i<${uboot_warehuse_number};i++))
               do
               	n=$((i+1))
                uboot_project_commit[i]=$(tail -n 1 ${uboot_array[i]} | sed 's/ /\n/g' | sed -n '2p')
	
             done
	
	for((i=0;i<${kernel_warehuse_number};i++))
               do
               	n=$((i+1))
                kernel_project_commit[i]=$(tail -n 1 ${kernel_array[i]} | sed 's/ /\n/g' | sed -n '2p')
	
             done

             for((i=0;i<${android_warehuse_number};i++))
               do
               	n=$((i+1))
                android_project_commit[i]=$(tail -n 1 ${android_array[i]} | sed 's/ /\n/g' | sed -n '2p')
	
             done

             for((i=0;i<${app_warehuse_number};i++))
               do
               	n=$((i+1))
                app_project_commit[i]=$(tail -n 1 ${app_array[i]} | sed 's/ /\n/g' | sed -n '2p')
	        
             done
	
	
}

get_log_commit()
{
	#get changelog release
            new_log_number_line=$(sed -n '/^$/=' ${Releasefile} | head -n 1 | wc -l)
             new_log_number=$(sed -n '/^$/=' ${Releasefile} | head -n 1)
             if [ "${new_log_number_line}" -ne "0" ] ; then
             uboot_log_commit_number=$(head -n ${new_log_number}  ${Releasefile} | grep -i "uboot_commit"  | wc -l)
             for((i=0;i<${uboot_log_commit_number};i++))
               do
               	n=$((i+1))
                uboot_log_commit[i]=$(head -n ${new_log_number}  ${Releasefile} | grep -i "uboot_commit"| sed -n ''${n}'p' | cut  -d '-' -f 2)
	
             done

             kernel_log_commit_number=$(head -n ${new_log_number}  ${Releasefile} | grep -i "kernel_commit"  | wc -l)
             for((i=0;i<${kernel_log_commit_number};i++))
               do
               	n=$((i+1))
                kernel_log_commit[i]=$(head -n ${new_log_number}  ${Releasefile} | grep -i "kernel_commit"| sed -n ''${n}'p' | cut  -d '-' -f 2)
	
             done

             android_log_commit_number=$(head -n ${new_log_number}  ${Releasefile} | grep -i "android_commit"  | wc -l)
             for((i=0;i<${android_log_commit_number};i++))
               do
               	n=$((i+1))
                android_log_commit[i]=$(head -n ${new_log_number}  ${Releasefile} | grep -i "android_commit"| sed -n ''${n}'p' | cut  -d '-' -f 2)
	
             done

             app_log_commit_number=$(head -n ${new_log_number}  ${Releasefile} | grep -i "app_commit"  | wc -l)
             for((i=0;i<${app_log_commit_number};i++))
               do
               	n=$((i+1))
                app_log_commit[i]=$(head -n ${new_log_number}  ${Releasefile} | grep -i "app_commit"| sed -n ''${n}'p' | cut  -d '-' -f 2)
	         
             done      
         else
         	uboot_log_commit_number=0
         	kernel_log_commit_number=0
         	android_log_commit_number=0
         	app_log_commit_number=0
          fi  
}



compare_commit()
{
	uboot_state=0
	if [ ${uboot_warehuse_number} == ${uboot_log_commit_number} ] ; then
		 for var in ${uboot_log_commit[@]};
 	  do
              same_number=0
		for((i=0;i<${uboot_warehuse_number};i++))
		do
		if [ ${var} == ${uboot_project_commit[i]} ] ; then
			same_number=$((same_number+1))
	 	else
	 		continue
		fi
		done
              if [ "${same_number}" -gt "1" ] ; then
                   echo -e "\033[0;31;1mrelease文件中存在多条commit号一致的uboot_path,请检查uboot库的路径。"
              fi
             if [ "${same_number}" -eq "0" ] ; then
                 uboot_state=1
                break
             fi
             if [ "${same_number}" -eq "1" ] ; then
                    uboot_state=0
              fi
	 done

	else
		uboot_state=1
               fi

               kernel_state=0
               if [ ${kernel_warehuse_number} == ${kernel_log_commit_number} ] ; then
		 for var in ${kernel_log_commit[@]};
 	  do
               same_number=0
		for((i=0;i<${kernel_warehuse_number};i++))
		do
		if [ ${var} == ${kernel_project_commit[i]} ] ; then
                  same_number=$((same_number+1))
	 	else
	 		continue
		fi
		done
               if [ "${same_number}" -gt "1" ] ; then
                   echo -e "\033[0;31;1mrelease文件中存在多条commit号一致的kernel_path,请检查kernel库的路径。"
              fi
             if [ "${same_number}" -eq "0" ] ; then
                 kernel_state=1
                break
             fi
             if [ "${same_number}" -eq "1" ] ; then
                    kernel_state=0
              fi
	 done

	else
		kernel_state=1
               fi

               android_state=0
               if [ ${android_warehuse_number} == ${android_log_commit_number} ] ; then
		 for var in ${android_log_commit[@]};
 	  do
              same_number=0
		for((i=0;i<${android_warehuse_number};i++))
		do
		if [ ${var} == ${android_project_commit[i]} ] ; then
			same_number=$((same_number+1))
	 	else
	 		continue
		fi
		done
              if [ "${same_number}" -gt "1" ] ; then
                   echo -e "\033[0;31;1mrelease文件中存在多条commit号一致的android_path,请检查android库的路径。"
              fi
             if [ "${same_number}" -eq "0" ] ; then
                 android_state=1
                break
             fi
             if [ "${same_number}" -eq "1" ] ; then
                    android_state=0
              fi
	 done

	else
		android_state=1
               fi

               app_state=0
               if [ ${app_warehuse_number} == ${app_log_commit_number} ] ; then
		 for var in ${app_log_commit[@]};
 	  do
              same_number=0
		for((i=0;i<${app_warehuse_number};i++))
		do                          
		if [ ${var} == ${app_project_commit[i]} ] ; then
			same_number=$((same_number+1))
	 	else
	 		continue
		fi
		done
              if [ "${same_number}" -gt "1" ] ; then
                   echo -e "\033[0;31;1mrelease文件中存在多条commit号一致的app_path,请检查app库的路径。"
              fi
             if [ "${same_number}" -eq "0" ] ; then
                 app_state=1
                break
             fi
             if [ "${same_number}" -eq "1" ] ; then
                    app_state=0
              fi
	 done

	else
		app_state=1
               fi

        
          
}

update_release_files()
{
	sum=0
	state=1
	project_version=$(grep "ro.build.display.id=${TARGET_PRODUCT}" ${project_version_file} | awk '{printf $2}' | cut -d '"' -f 2 | cut -d '=' -f 2 | cut -d '-' -f 4)
	if [ "$(grep "ro.build.display.id" ${Releasefile} | wc -l)" -eq "0" ]; then
		new_project_viesion="V1.0.00B0"
	else
	log_project_version=$(grep "ro.build.display.id" ${Releasefile} | head -1 | cut  -d '-' -f 2)
	echo "${log_project_version}"
	  version_nume1=$(echo ${log_project_version} | cut -c 9)
	  echo "${version_nume1}"
	  version_nume2=$(echo ${log_project_version} | cut -c 7)
	   echo "${version_nume2}"
	   version_nume3=$(echo ${log_project_version} | cut -c 6)
	   echo "${version_nume3}"
	   version_nume4=$(echo ${log_project_version} | cut -c 4)
	   echo "${version_nume4}"
	   version_nume5=$(echo ${log_project_version} | cut -c 2)
	   echo "${version_nume5}"
          sign=$(echo ${log_project_version} | cut -c 8)
          echo "${sign}"
	   array=(${version_nume1} ${version_nume2} ${version_nume3} ${version_nume4} ${version_nume5})  
                 for var in ${array[@]};
                 do 
                 if [  ${var} == "10" ];then
                           array[sum]="0"
                            sum=$((sum+1))
                          array[sum]=$((array[sum]+1))
                 else
                          if [  ${var} == "9" ];then
                          array[sum]="0"
                           sum=$((sum+1))
                          array[sum]=$((array[sum]+1))    
                          if [ ${array[sum]} == "10" ]; then
                                       continue
                           else
                           	       break 
                           fi   
                          else
                          	if [ "$state" -eq "1" ]; then
                  	array[sum]=$((array[sum]+1))
                  	 sum=$((sum+1))   
                  	 state=0            
                  	fi
                         fi
                fi
               done
               version_nume1=${array[0]}
               version_nume2=${array[1]}
               version_nume3=${array[2]}
               version_nume4=${array[3]}
               version_nume5=${array[4]}
       
              new_project_viesion=V${version_nume5}.${version_nume4}.${version_nume3}${version_nume2}${sign}${version_nume1}
                echo "${new_project_viesion}"
            fi
                #update new version
              sed -i 's/'${project_version}'/'${new_project_viesion}'/' ${project_version_file}
}

update_log_file()
{
       number=$((app_warehuse_number+android_warehuse_number+kernel_warehuse_number+uboot_warehuse_number))
	sed '1 i\\n' -i ${Releasefile}

	for((i=0;i<${app_warehuse_number};i++))
               do
               	
               sed '1 i'${number}.${app_name_array[i]}app_commit-${app_project_commit[i]} -i ${Releasefile}
	                number=$((number-1))
             done

	for((i=0;i<${android_warehuse_number};i++))
               do
               	
               sed '1 i'${number}.android_commit-${android_project_commit[i]} -i ${Releasefile}
               number=$((number-1))
	
             done
             
             for((i=0;i<${kernel_warehuse_number};i++))
               do
               	
               sed '1 i'${number}.kernel_commit-${kernel_project_commit[i]} -i ${Releasefile}
               number=$((number-1))
	
             done
              
              for((i=0;i<${uboot_warehuse_number};i++))
               do
               	
               sed '1 i'${number}.uboot_commit-${uboot_project_commit[i]} -i ${Releasefile}
               number=$((number-1))
	
             done

   	sed '1 iro.build.display.id-'${new_project_viesion} -i ${Releasefile}          
}

checkout_file
get_envionment_variables
get_project_commit
get_log_commit
compare_commit
if [ "$uboot_state" -eq "1" ] || [ "$kernel_state" -eq "1" ] || [ "$android_state" -eq "1" ] || [ "$app_state" -eq "1" ]; then
	update_release_files
	update_log_file
  else
   project_version=$(grep "ro.build.display.id=${TARGET_PRODUCT}" ${project_version_file} | awk '{printf $2}' | cut -d '"' -f 2 | cut -d '=' -f 2 | cut -d '-' -f 4)
   log_project_version=$(grep "ro.build.display.id" ${Releasefile} | head -1 | cut  -d '-' -f 2)
   sed -i 's/'${project_version}'/'${log_project_version}'/' ${project_version_file}
              
fi



