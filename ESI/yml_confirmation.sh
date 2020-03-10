#!/bin/bash
# yml_confirmation.sh
#
# -----------------------------------------------------------------------------
# Purpose : Confirmation of created yml
# -----------------------------------------------------------------------------
# 2017/2/28  create prototype  t.kouda@ntt.com Slack:kouda
# 2017/3/7   Added variable parameter confirmation item
# 2017/3/10  Function change from Line Check to Unnecessary Parameter Check
# 2018/07/11 add dc_name (ff6, os1)
# 2018/08/09 FIX Also apply bs Affinity after c
# 2018/08/20 FIX Line Feed Code
# 2019/06/06 FIX for ESI ver1.17
# 2019/06/27 change check logic(confirmation_readdevice_Variable_param/confirmation_createdevice_Variable_param)
# 2019/07/25 Modify check logic(confirmation_createdevice_Variable_param)

#usage
usage_msg='usage:
      use this shell
      ./confirmation.sh [-SDP] [csv file] [yml_file]'
                        
#変数設定
sdp_name=$(echo $1 | sed s/"-"//g)
csv_name=$(echo $2)
yml_name=$(echo $3)

# 正規表現群
regrex_qfx_main=[a-z]{2}[0-9][a-z]{2}-[a-z]{4}[0-9]{4}m
regrex_qfx_for_key_name=[a-z]{2}[0-9][a-z]{2}_[a-z]{4}[0-9]{4}m
regrex_bmus=[a-z]{2}[0-9][a-z]p-bmus[0-9]{4}n
regrex_storage=[a-z]{2}[0-9][a-z]p-[a-z]{4}[0-9]{4}[ps]

#引数確認
if [ $# != 3 ]
then
  echo 'not argument'
  echo "${usage_msg}"
  exit 1
fi

#locationテンプレート入力関数
function make_template_input_location()
{
  # 変換文字   パラメータ
  #    A      {{ dc_name }}
  cat template/location.yml | sed 's/{{ dc_name }}/A/g' > master_templ
  case "${sdp_name}" in
    bm|bs|fs|fss )
      make_template_input_read_device ;;
    qfx )
      make_template_input_create_device ;;
    * ) echo "$0 : invalid option -- '${sdp_name}'"
        exit 2 ;;
  esac
}

#read_deviceテンプレート入力関数
function make_template_input_read_device()
{
  device_number=$(cat ${csv_name} | cut -d , -f 1 | sort | uniq | grep -v b$ | wc -l)
  count=0
  while :
  do
    if [ ${count} == ${device_number} ]
      then
        break
      else
        # 変換文字   パラメータ
        #    B      {{ qfx_main }}
	#    Z      {{ qfx_for_key_name }}
        cat template/ese_device_read.yml |
        sed 's/{{ qfx_main }}/B/g' |
        sed 's/{{ qfx_for_key_name }}/Z/g' >> master_templ
        echo >> master_templ
        count=$(expr ${count} + 1)
      fi
  done
  
  case "${sdp_name}" in
    bm )
      make_template_input_bm_port ;;
    fs )
      make_template_input_fs_port ;;
    fss )
      make_template_input_fss_port ;;
    bs )
      make_template_input_bs_port ;;
  esac
}

#create_deviceテンプレート入力関数
function make_template_input_create_device()
{
  device_number=$(cat ${csv_name} | cut -d , -f 1 | sort | uniq | grep -v b$ | wc -l)
  count=0
  while :
  do
    if [ ${count} == ${device_number} ]
      then
        break
      else
        # 変換文字   パラメータ
        #    B      {{ qfx_main }}
	#    C      {{ loop_back_ip }}
	#    Z      {{ qfx_for_key_name }}
        cat template/ese_device_create.yml |
        sed 's/{{ qfx_main }}/B/g' |
        sed 's/{{ loop_back_ip }}/C/g' |
        sed 's/{{ qfx_for_key_name }}/Z/g' >> master_templ
        echo >> master_templ
        count=$(expr ${count} + 1)
      fi
  done
  
  reform_qfx_yml
}

#Baremetal_portテンプレート入力関数
function make_template_input_bm_port()
{
  port_number=$(cat ${csv_name} | cut -d "," -f 1 | wc -l)
  count=0
  while :
  do
    if [ ${count} == ${port_number} ]
      then
        break
      else
        # 変換文字   パラメータ
        #    B      {{ qfx_main }}
	#    C      {{ pci_no }}
	#    D      {{ port_no }}
	#    E      {{ qfx_physical_port }}
	#    F      {{ plane }}
	#    G      {{ server_name }}
	#    H      {{ role_no }}
	#    Z      {{ qfx_for_key_name }}
        cat template/bm_ports.yml |
	sed 's/{{ qfx_main }}/B/g' |
	sed 's/{{ pci_no }}/C/g' |
	sed 's/{{ port_no }}/D/g' |
	sed 's/{{ qfx_physical_port }}/E/g' |
	sed 's/{{ plane }}/F/g' |
	sed 's/{{ server_name }}/G/g' |
	sed 's/{{ role_no }}/H/g' |
	sed 's/{{ qfx_for_key_name }}/Z/g'  >> master_templ
        echo >> master_templ
        count=$(expr ${count} + 1)
      fi
  done
  
  reform_bm_yml
}

#FileStorage_portテンプレート入力関数
function make_template_input_fs_port()
{
  port_number=$(cat ${csv_name} | cut -d "," -f 1 | wc -l)
  count=0
  while :
  do
    if [ ${count} == ${port_number} ]
      then
        break
      else
	# 変換文字   パラメータ
        #    B      {{ qfx_main }}
        #    C      {{ qfx_logical_port }}
        #    D      {{ group }}
        #    E      {{ plane }}
        #    F      {{ cluster_role }}
        #    G      {{ role_no }}
        #    H      {{ storage_name }}
        #    I      {{ storage_port }}
        #    Z      {{ qfx_for_key_name }}
        cat template/fs_ports.yml |
        sed 's/{{ qfx_main }}/B/g' |
        sed 's/{{ qfx_logical_port }}/C/g' |
        sed 's/{{ group }}/D/g' |
        sed 's/{{ plane }}/E/g' |
        sed 's/{{ cluster_role }}/F/g' |
        sed 's/{{ storage_name }}/H/g' |
        sed 's/{{ storage_port }}/I/g' |
        sed 's/{{ qfx_for_key_name }}/Z/g' >> master_templ
        echo >> master_templ
        count=$(expr ${count} + 1)
      fi
  done
  
  reform_fs_yml
}

#FileStorageStandard_portテンプレート入力関数
function make_template_input_fss_port()
{
  port_number=$(cat ${csv_name} | cut -d "," -f 1 | wc -l)
  count=0
  while :
  do
    if [ ${count} == ${port_number} ]
      then
        break
      else
	# 変換文字   パラメータ
        #    B      {{ qfx_main }}
        #    C      {{ qfx_logical_port }}
        #    D      {{ group }}
        #    E      {{ plane }}
        #    F      {{ cluster_role }}
        #    G      {{ role_no }}
        #    H      {{ storage_name }}
        #    I      {{ storage_port }}
        #    Z      {{ qfx_for_key_name }}
        cat template/fss_ports.yml |
        sed 's/{{ qfx_main }}/B/g' |
        sed 's/{{ qfx_logical_port }}/C/g' |
        sed 's/{{ group }}/D/g' |
        sed 's/{{ plane }}/E/g' |
        sed 's/{{ cluster_role }}/F/g' |
        sed 's/{{ storage_name }}/H/g' |
        sed 's/{{ storage_port }}/I/g' |
        sed 's/{{ qfx_for_key_name }}/Z/g' >> master_templ
        echo >> master_templ
        count=$(expr ${count} + 1)
      fi
  done
  
  reform_fs_yml
}

#BlockStoragel_portテンプレート入力関数
function make_template_input_bs_port()
{
  port_number=$(cat ${csv_name} | cut -d "," -f 1 | wc -l)
  count=0
  while :
  do
    if [ ${count} == ${port_number} ]
      then
        break
      else
        # 変換文字   パラメータ
        #    B      {{ qfx_main }}
	#    C      {{ qfx_logical_port }}
	#    D      {{ group }}
	#    E      {{ plane }}
	#    F      {{ cluster_role }}
	#    G      {{ role_no }}
	#    H      {{ storage_name }}
	#    I      {{ storage_port }}
	#    Z      {{ qfx_for_key_name }}
        cat template/bs_ports.yml |
	sed 's/{{ qfx_main }}/B/g' |
	sed 's/{{ qfx_logical_port }}/C/g' |
	sed 's/{{ group }}/D/g' |
	sed 's/{{ plane }}/E/g' |
        sed 's/{{ cluster_role }}/F/g' |
	sed 's/{{ storage_name }}/H/g' |
	sed 's/{{ storage_port }}/I/g' |
        sed 's/{{ qfx_for_key_name }}/Z/g' >> master_templ
        echo >> master_templ
        count=$(expr ${count} + 1)
      fi
  done

  reform_bs_yml
}

#Baremetal yml整形関数
function reform_bm_yml()
{
  # 変換文字   パラメータ
  #    B      {{ qfx_main }}
  #    C      {{ pci_no }}
  #    D      {{ port_no }}
  #    E      {{ qfx_physical_port }}
  #    F      {{ plane }}
  #    G      {{ server_name }}
  #    H      {{ role_no }}
  #    Z      {{ qfx_for_key_name }}
  cat ${yml_name} | 
  sed '/- location:/,/- ese_device/ s/name: \"...\"/name: \"A\"/g' |
  sed -r s/${regrex_qfx_main}/'B'/g |
  sed -r s/[12]_[12]_[0-9]\{1,2\}/'C_D_E/g' |
  sed -r s/NetworkdCard[12]_NicPhysicalPort[12]/'NetworkdCardC_NicPhysicalPortD/g' |
  sed 's/plane: \".*\"/plane: \"F\"/g' |
  sed -r s/${regrex_bmus}/'G'/g |
  sed 's/nic[12]_port[12]/nicC_portD/g' |
  sed 's/\"xe-.\/.\/.*\"/\"xe-H\/0\/E\"/g' |
  sed -r s/${regrex_qfx_for_key_name}/'Z'/g  > reform_yml
  diff_check
}

#FileStorage|FilestorageStandard yml整形関数
function reform_fs_yml()
{
  # 変換文字   パラメータ
  #    B      {{ qfx_main }}
  #    C      {{ qfx_logical_port }}
  #    D      {{ group }}
  #    E      {{ plane }}
  #    F      {{ cluster_role }}
  #    G      {{ role_no }}
  #    H      {{ storage_name }}
  #    I      {{ storage_port }}
  #    Z      {{ qfx_for_key_name }}
  cat ${yml_name} |
  sed '/- location:/,/- ese_device/ s/name: \"...\"/name: \"A\"/g' |
  sed -r s/${regrex_qfx_main}/'B'/g |
  sed -r s/ae[0-9]\{1,2\}/C/g |
  sed -r s/Affinity[A-Z]/AffinityD/g |
  sed -r "s/QFX data/QFX E/g" |
  sed -r "s/QFX storage/QFX E/g" |
  sed s/Primary/F/g |
  sed s/Secondary/F/g |
  sed 's/plane: \".*\"/plane: \"E\"/g' |
  sed -r s/${regrex_storage}/H/g |
  sed -r s/a0[ab]/a0I/g |
  sed -r s/${regrex_qfx_for_key_name}/'Z'/g  > reform_yml
  diff_check
}

#BlockStoragel yml整形関数
function reform_bs_yml()
{
  # 変換文字   パラメータ
  #    B      {{ qfx_main }}
  #    C      {{ qfx_logical_port }}
  #    D      {{ group }}
  #    E      {{ plane }}
  #    F      {{ cluster_role }}
  #    G      {{ role_no }}
  #    H      {{ storage_name }}
  #    I      {{ storage_port }}
  #    Z      {{ qfx_for_key_name }}
  cat ${yml_name} |
  sed '/- location:/,/- ese_device/ s/name: \"...\"/name: \"A\"/g' |
  sed -r s/${regrex_qfx_main}/'B'/g |
  sed -r s/ae[0-9]\{1,2\}/C/g |
  sed -r s/Affinity[A-Z]/AffinityD/g |
  sed -r "s/QFX data/QFX E/g" |
  sed -r "s/QFX storage/QFX E/g" |
  sed s/Primary/F/g |
  sed s/Secondary/F/g |
  sed 's/plane: \".*\"/plane: \"E\"/g' |
  sed -r s/${regrex_storage}/H/g |
  sed -r s/a0[ab]/a0I/g |
  sed -r s/${regrex_qfx_for_key_name}/'Z'/g  > reform_yml
  diff_check
}

#QFX yml整形関数
function reform_qfx_yml()
{
  
  # 変換文字   パラメータ
  #    A      {{ dc_name }}
  #    B      {{ qfx_main }}
  #    C      {{ loop_back_ip }}
  #    Z      {{ qfx_for_key_name }}
  cat ${yml_name} | 
  sed '/- location:/,/- ese_device/ s/name: \"...\"/name: \"A\"/g' |
  sed  -r s/${regrex_qfx_main}/'B'/g |
  sed 's/address: \"*.*.*.*\"/address: \"C\"/g' | 
  sed  -r s/${regrex_qfx_for_key_name}/Z/g > reform_yml
  diff_check
}

#全行突合関数
function diff_check()
{
  diff master_templ reform_yml > error.txt 2>&1
  return=$(echo $?)
  
  if [ ${return} == 0 ]
  then
    echo "Unnecessary Parameter Check: OK"
    rm -f error.txt master_templ reform_yml
  else
    echo "Unnecessary Parameter Check: NG"
    echo "============="
    echo -n "LineNo: "
    cat error.txt | egrep -v "^<|^>" | awk -F'[acd]' '{print $2}' | sed '/^$/d'
    echo -e "============="\\n
    rm -f error.txt master_templ reform_yml
  fi
}

#戻り値確認関数
function returncode_check()
{
  return=$(tail -1 return.txt)
  
  if [ ${return} == 1 ]
  then
    sed -i -e "s/$/${part}/g" temp_error.txt
    grep "<" temp_error.txt >> error.txt
  fi
}

#locationリソース可変パラメータ確認関数
function confirmation_Variable_param_location()
{
  cat ${csv_name} | cut -d , -f 1 | cut -c 1-3 >> temp_loc_source
  sort -u temp_loc_source -o temp_loc_source

  part=" (location)"

  cat ${yml_name} | sed -n '/- location/,/- ese_device/p' | grep name | cut -d \" -f 2 > loc_yml
  # 延伸対応
  if [ $(cat temp_loc_source) == hh3 ]
  then 
    echo lo8 > loc_source
    rm -f temp_loc_source temp_error*
  elif [ $(cat temp_loc_source) == ff6 ]
  then 
    echo ff1 > loc_source
    rm -f temp_loc_source temp_error*
  elif [ $(cat temp_loc_source) == os1 ]
  then 
    echo os5 > loc_source
    rm -f temp_loc_source temp_error*
  else
    mv temp_loc_source loc_source
    rm -f temp_loc_source temp_error*
  fi

  diff loc_yml loc_source > temp_error.txt 2>&1
  echo $? > return.txt
  returncode_check

    case "${sdp_name}" in
      bm|bs|fs|fss )
        rm -f loc_yml loc_source
        confirmation_readdevice_Variable_param ;;
      qfx )
        rm -f loc_yml loc_source
        confirmation_createdevice_Variable_param ;;
    esac
}

#ese_device(read)リソース可変パラメータ確認関数
function confirmation_readdevice_Variable_param()
{
  cut -d , -f 1 ${csv_name} | sed -e "/b$/d" | sort | uniq > qfx_main_source

  part=" (esedevice-arrayname)"
  #grep "^- ese_device" ${yml_name} | grep -oE ${regrex_qfx_for_key_name} | sed 's/_/-/g' | sort > qfx_main_yml
  grep "^- ese_device" -A6 ${yml_name} | grep name | cut -d\" -f2 | sed s/\"//g | sort > qfx_main_yml
  diff qfx_main_yml qfx_main_source > temp_error.txt 2>&1
  echo $? >> return.txt
  returncode_check

  part=" (esedevice-name)"
  cat ${yml_name} | sed -n '/- ese_device/,/- physical_port/p' | grep name | cut -d \" -f 2 > qfx_main_yml
  sort -u qfx_main_yml -o qfx_main_yml
  diff qfx_main_yml qfx_main_source > temp_error.txt 2>&1
  echo $? >> return.txt
  returncode_check

  rm -f qfx_main_* temp_error*

    case "${sdp_name}" in
      bm )
        confirmation_bm_port_Variable_param ;;
      fs|fss )
        confirmation_fs_port_Variable_param ;;
      bs )
        confirmation_bs_port_Variable_param ;;
    esac
}

#ese_device(create)リソース可変パラメータ確認関数
function confirmation_createdevice_Variable_param()
{
  cut -d , -f 1 ${csv_name} > qfx_main_source
  cut -d , -f 2 ${csv_name} > loop_back_ip_source
  
  part=" (esedevice-arrayname)"
  #grep "^- ese_device" ${yml_name} | grep -oE ${regrex_qfx_for_key_name} | sed 's/_/-/g' > qfx_main_yml
  grep "hostname" ${yml_name} | cut -d\" -f2 | sed s/\"//g > qfx_main_yml
  diff qfx_main_yml qfx_main_source > temp_error.txt 2>&1
  echo $? >> return.txt
  returncode_check
  
  part=" (esedevice-description)"
  cat ${yml_name} | sed -n '/- ese_device/,/- physical_port/p' |
  grep description | cut -d \" -f 2 > qfx_main_yml
  diff qfx_main_yml qfx_main_source > temp_error.txt 2>&1
  echo $? >> return.txt
  returncode_check

  part=" (esedevice-hostname)"
  cat ${yml_name} | 
  sed -n '/- ese_device/,/- physical_port/p' | grep hostname | cut -d \" -f 2 > qfx_main_yml
  diff qfx_main_yml qfx_main_source > temp_error.txt 2>&1
  echo $? >> return.txt
  returncode_check
  
  part=" (esedevice-name)"
  cat ${yml_name} | sed -n '/- ese_device/,/- physical_port/p' |
  grep name | grep -v host | cut -d \" -f 2 > qfx_main_yml
  diff qfx_main_yml qfx_main_source > temp_error.txt 2>&1
  echo $? >> return.txt
  returncode_check

  part=" (esedevice-public_ip)"
  cat ${yml_name} | sed -n '/- ese_device/,/- physical_port/p' |
  grep public_ip | cut -d \" -f 2 > loop_back_ip_yml
  diff loop_back_ip_yml loop_back_ip_source > temp_error.txt 2>&1
  echo $? >> return.txt
  returncode_check
 
  part=" (esedevice-management_ip)"
  cat ${yml_name} | sed -n '/- ese_device/,/- physical_port/p' |
  grep management_ip | cut -d \" -f 2 > loop_back_ip_yml
  diff loop_back_ip_yml loop_back_ip_source > temp_error.txt 2>&1
  echo $? >> return.txt
  returncode_check
  
  rm -f qfx_main_* loop_back_ip_* temp_error*

    Variable_param_returnCode_check
}

#Baremetal portリソース(physical_port,ese_physical_port)可変パラメータ確認関数
function confirmation_bm_port_Variable_param()
{
  cut -d , -f 1 ${csv_name} > temp_qfx_main_source
  for i in $(cat temp_qfx_main_source)
  do
    if [ $(echo $i | cut -c 15) == b ]
    then
      af=$(echo ${i} | cut -c 16-22)
      sw=$(echo ${i} | cut -d _ -f 1 | sed -e "s/b$/m/g")
      bn=$(echo ${i} | cut -d _ -f 1 | cut -c 11-14 )
      an=$(expr $bn - 1)
      nw=$(printf %04d $(echo $an))
      swn=$(echo ${sw} | sed -e "s/$bn/$nw/g")
      echo ${swn}${af} >> qfx_main_source
    else
      echo ${i} >> qfx_main_source
    fi
  done
  
  awk -F , '{gsub("NIC","");print $4}' ${csv_name} | cut -d \- -f 1 > pci_no_source
  awk -F , '{gsub("NIC","");print $4}' ${csv_name} | cut -d \- -f 2 > port_no_source
  cut -d , -f 2 ${csv_name} | cut -d \/ -f 3 > qfx_physical_port_source
  
  cut -d , -f 3 ${csv_name} > server_name_source
  
  cat ${csv_name} | cut -d , -f 1 | cut -c 9 > temp_plane_source
  for i in $(cat temp_plane_source)
  do
    if [ ${i} == s ]
    then
      echo "storage" >> plane_source
    elif [ ${i} == d ]
    then
      echo "data" >> plane_source
    fi
  done

  for i in $(cat ${csv_name})
  do
    if [ $(echo ${i} | cut -d , -f 1 | cut -c 15) == b ]
    then
      echo ${i} | cut -d , -f 2 | sed "s/xe-0/xe-1/g" >> role_no_source
    else
      echo ${i} | cut -d , -f 2 >> role_no_source
    fi
  done
  # - -> _ key名対策
  paste -d _ qfx_main_source pci_no_source port_no_source qfx_physical_port_source > arrayname_source
  sed -e "s/^/NetworkdCard/g" pci_no_source > pci_no_source_2
  sed -e "s/^/NicPhysicalPort/g" port_no_source > port_no_source_2
  paste -d _ pci_no_source_2 port_no_source_2 > name_source
  rm -rf pci_no_source_2 port_no_source_2 

  sed -e "s/^/nic/g" pci_no_source > pci_no_source_2
  sed -e "s/^/port/g" port_no_source > port_no_source_2
  paste -d _ server_name_source pci_no_source_2 port_no_source_2 > description_source
  rm -rf pci_no_source_2 port_no_source_2 

  part=" (physicalport-arrayname)"
  grep "^- physical_port" ${yml_name} | cut -d _ -f 3-7 |
  sed -e "s/://g" > physical_arrayname_yml
  # - -> _ key名対策
  diff physical_arrayname_yml <(cat arrayname_source | sed s/\-/_/g) > temp_error.txt 2>&1
  echo $? >> return.txt
  returncode_check

  part=" (physicalport-name)"
  cat ${yml_name} | sed -n '/- physical_port/,/- ese_physical_port/p' |
  grep name | cut -d \" -f 2 > name_yml
  diff name_yml name_source > temp_error.txt 2>&1
  echo $? >> return.txt
  returncode_check

  part=" (physicalport-plane)"
  cat ${yml_name} | sed -n '/- physical_port/,/- ese_physical_port/p' |
  grep plane | cut -d \" -f 2 > plane_yml
  diff plane_yml plane_source > temp_error.txt 2>&1
  echo $? >> return.txt
  returncode_check

  part=" (esephysicalport-arrayname)"
  grep "^- ese_physical_port" ${yml_name} | cut -d _ -f 4-8 |
  sed -e "s/://g" > ese_physical_arrayname_yml
  diff ese_physical_arrayname_yml <(cat arrayname_source | sed s/\-/_/g) > temp_error.txt 2>&1
  echo $? >> return.txt
  returncode_check

  part=" (esephysicalport-description)"
  cat ${yml_name} | sed -n '/- ese_physical_port/,/- physical_port/p' |grep description |
  awk -F \" '{print $2}' | cut -d \" -f 2 > ese_physical_description_yml
  diff ese_physical_description_yml description_source > temp_error.txt 2>&1
  echo $? >> return.txt
  returncode_check

  part=" (esephysicalport-name)"
  cat ${yml_name} | sed -n '/- ese_physical_port/,/- physical_port/p' |
  grep name | cut -d \" -f 2 > role_no_yml
  diff role_no_yml role_no_source > temp_error.txt 2>&1
  echo $? >> return.txt
  returncode_check

  part=" (esephysicalport-esedevice_id)"
  # _ -> _ (key名対策)
  cat ${yml_name} | sed -n '/- ese_physical_port/,/- physical_port/p' |
  grep ese_device | cut -d _ -f 5,6 | cut -d } -f 1 | sed s/_/-/g > qfx_main_yml
  diff qfx_main_yml qfx_main_source > temp_error.txt 2>&1
  echo $? >> return.txt
  returncode_check

  part=" (esephysicalport-connected_port_id)"
  cat ${yml_name} | sed -n '/- ese_physical_port/,/- physical_port/p' |
  grep port_id | cut -d _ -f 5-9 | cut -d } -f 1 > portid_yml
  diff portid_yml <(cat arrayname_source | sed s/\-/_/g) > temp_error.txt 2>&1
  echo $? >> return.txt
  returncode_check

  rm -f temp_qfx_main_source qfx_main_source pci_no_source port_no_source qfx_physical_port_source\
  ese_physical_description_yml qfx_main_yml temp_error.txt server_name_source temp_plane_source\
  plane_source role_no_source arrayname_source name_source description_source physical_arrayname_yml\
  name_yml plane_yml ese_physical_arrayname_yml role_no_yml portid_yml
  Variable_param_returnCode_check
}

#FileStorage portリソース(physical_port,ese_physical_port)可変パラメータ確認関数
function confirmation_fs_port_Variable_param()
{
  cut -d , -f 1 ${csv_name} > qfx_main_source
  cut -d , -f 2 ${csv_name} > qfx_logical_port_source
  cut -d , -f 3 ${csv_name} > storage_name_source

  for i in $(cat qfx_main_source | cut -c 9)
  do
    if [ ${i} == s ]
    then
      echo "a0a" >> storage_port_source
    elif [ ${i} == d ]
    then
      echo "a0b" >> storage_port_source
    fi
  done

  for i in $(cat qfx_main_source | cut -c 9)
  do
    if [ ${i} == s ]
    then
      echo "storage" >> plane_source
    elif [ ${i} == d ]
    then
      echo "data" >> plane_source
    fi
  done

  paste -d - qfx_main_source qfx_logical_port_source > arrayname_source
  paste -d - storage_name_source storage_port_source > physical_discription_source

  part=" (physicalport-arrayname)"
  grep "^- physical_port" ${yml_name} | cut -d _ -f 3-5 | cut -d : -f 1 > qfx_main_yml
  diff qfx_main_yml <(cat arrayname_source | sed s/\-/_/g) > temp_error.txt 2>&1
  echo $? >> return.txt
  returncode_check
  
  part=" (physicalport-description)"
  cat ${yml_name} | sed -n '/- physical_port/,/- ese_physical_port/p' |grep description |
  awk '{gsub("\"","");print $3}' > storage_name_yml
  diff storage_name_yml physical_discription_source > temp_error.txt 2>&1
  echo $? >> return.txt
  returncode_check

  part=" (physicalport-name)"
  cat ${yml_name} | sed -n '/- physical_port/,/- ese_physical_port/p' | grep name |
  awk -F \" '{print $2}' > qfx_main_yml
  diff qfx_main_yml arrayname_source > temp_error.txt 2>&1
  echo $? >> return.txt
  returncode_check

  part=" (physicalport-plane)"
  cat ${yml_name} |    sed -n '/- physical_port/,/- ese_physical_port/p' |
  grep plane | cut -d \" -f 2 > plane_yml
  diff plane_yml plane_source > temp_error.txt 2>&1
  echo $? >> return.txt
  returncode_check

  part=" (esephysicalport-arrayname)"
  grep "^- ese_physical_port" ${yml_name} | cut -d _ -f4- | sed s/://g > qfx_main_yml
  diff qfx_main_yml <(cat arrayname_source | sed s/\-/_/g) > temp_error.txt 2>&1
  echo $? >> return.txt
  returncode_check

  part=" (esephysicalport-description[FSname])"
  cat ${yml_name} |    sed -n '/- ese_physical_port/,/- physical_port/p' | 
  grep description | cut -d " " -f 12 > storage_name_yml
  diff storage_name_yml storage_name_source > temp_error.txt 2>&1
  echo $? >> return.txt
  returncode_check

  part=" (esephysicalport-description[FSport])"
  cat ${yml_name} | sed -n '/- ese_physical_port/,/- physical_port/p' |
  grep description | awk '{print $5}' > storage_port_yml
  diff storage_port_yml storage_port_source > temp_error.txt 2>&1
  echo $? >> return.txt
  returncode_check

  part=" (esephysicalport-description[QFXname])"
  cat ${yml_name} | sed -n '/- ese_physical_port/,/- physical_port/p' |
  grep description | awk '{print $8}' > qfx_main_yml
  diff qfx_main_yml qfx_main_source > temp_error.txt 2>&1
  echo $? >> return.txt
  returncode_check

  part=" (esephysicalport-description[QFXport])"
  cat ${yml_name} | sed -n '/- ese_physical_port/,/- physical_port/p' |
  grep description | awk '{gsub(")\"","");print $9}'  > qfx_logical_port_yml
  diff qfx_logical_port_yml qfx_logical_port_source > temp_error.txt 2>&1
  echo $? >> return.txt
  returncode_check

  part=" (esephysicalport-name)"
  cat ${yml_name} |    sed -n '/- ese_physical_port/,/- physical_port/p' |
  grep name | cut -d \" -f 2 > qfx_logical_port_yml
  diff qfx_logical_port_yml qfx_logical_port_source > temp_error.txt 2>&1
  echo $? >> return.txt
  returncode_check

  part=" (esephysicalport-ese_device_id)"
  cat ${yml_name} | sed -n '/- ese_physical_port/,/- physical_port/p' |
  grep device_id | cut -d  _ -f 5- | cut -d } -f 1 > qfx_main_yml
  diff qfx_main_yml <(cat qfx_main_source | sed s/\-/_/g) > temp_error.txt 2>&1
  echo $? >> return.txt
  returncode_check

  part=" (esephysicalport-connected_port_id)"
  cat ${yml_name} | sed -n '/- ese_physical_port/,/- physical_port/p' |
  grep port_id | cut -d _ -f 5- | cut -d } -f 1 > qfx_main_yml
  diff qfx_main_yml <(cat arrayname_source | sed s/\-/_/g) > temp_error.txt 2>&1
  echo $? >> return.txt
  returncode_check

  rm -f qfx_main_* qfx_logical_port_* storage_name_* storage_port_* plane_*\
  temp_error* arrayname_source storage_name_yml physical_discription_source
  Variable_param_returnCode_check
}

#BlockStorage portリソース(physical_port,ese_physical_port)可変パラメータ確認関数
function confirmation_bs_port_Variable_param()
{
  cut -d , -f 1 ${csv_name} > qfx_main_source
  cut -d , -f 2 ${csv_name} > qfx_logical_port_source
  
  for i in $(cat qfx_main_source | cut -c 4)
  do
      Affi=$(echo ${i} | sed 's/\(.*\)/\U\1/')
      echo "Affinity${Affi}" >> group_source
  done

  for i in $(cat qfx_main_source | cut -c 9)
  do
    if [ ${i} == s ]
    then
      echo "storage" >> plane_source
    elif [ ${i} == d ]
    then
      echo "data" >> plane_source
    fi
  done

  cut -d , -f 3 ${csv_name} > storage_name_source

  for i in $(cat storage_name_source | cut -c 15)
  do
    if [ ${i} == p ]
    then
      echo "Primary" >> cluster_role_source
    elif [ ${i} == s ]
    then
      echo "Secondary" >> cluster_role_source
    fi
  done

  for i in $(cat qfx_main_source | cut -c 9)
  do
    if [ ${i} == s ]
    then
      echo "a0a" >> storage_port_source
    elif [ ${i} == d ]
    then
      echo "a0b" >> storage_port_source
    fi
  done

  paste -d - qfx_main_source qfx_logical_port_source > arrayname_source

  part=" (physicalport-arrayname)"
  grep "^- physical_port" ${yml_name} | cut -d _ -f 3-5 | cut -d : -f 1 > qfx_main_yml
  diff qfx_main_yml <(cat arrayname_source | sed s/\-/_/g) > temp_error.txt 2>&1
  echo $? >> return.txt
  returncode_check

  part=" (physicalport-description[Affinity])"
  cat ${yml_name} | sed -n '/- physical_port/,/- ese_physical_port/p' |
  grep description | awk '{gsub("\"","");print $2}' > group_yml
  diff group_yml group_source > temp_error.txt 2>&1
  echo $? >> return.txt
  returncode_check
  
  part=" (physicalport-description[plane])"
  cat ${yml_name} | sed -n '/- physical_port/,/- ese_physical_port/p' |
  grep description | awk '{print $4}' > plane_yml
  diff plane_yml plane_source > temp_error.txt 2>&1
  echo $? >> return.txt
  returncode_check
  
  part=" (physicalport-description[role])"
  cat ${yml_name} | sed -n '/- physical_port/,/- ese_physical_port/p' |
  grep description | awk '{print $7}' > cluster_role_yml
  diff cluster_role_yml cluster_role_source > temp_error.txt 2>&1
  echo $? >> return.txt
  returncode_check
  
  part=" (physicalport-name)"
  cat ${yml_name} | sed -n '/- physical_port/,/- ese_physical_port/p' |
  grep name | awk -F \" '{print $2}' > qfx_main_yml
  diff qfx_main_yml arrayname_source > temp_error.txt 2>&1
  echo $? >> return.txt
  returncode_check

  part=" (physicalport-plane)"
  cat ${yml_name} |    sed -n '/- physical_port/,/- ese_physical_port/p' |
  grep plane | cut -d \" -f 2 > plane_yml
  diff plane_yml plane_source > temp_error.txt 2>&1
  echo $? >> return.txt
  returncode_check

  part=" (esephysicalport-arrayname)"
  grep "^- ese_physical_port" ${yml_name} | cut -d _ -f4- | sed s/://g > qfx_main_yml
  diff qfx_main_yml <(cat arrayname_source | sed s/\-/_/g) > temp_error.txt 2>&1
  echo $? >> return.txt
  returncode_check

  part=" (esephysicalport-description[BSname])"
  cat ${yml_name} | sed -n '/- ese_physical_port/,/- physical_port/p' |
  grep description | awk '{print $4}' > storage_name_yml
  diff storage_name_yml storage_name_source > temp_error.txt 2>&1
  echo $? >> return.txt
  returncode_check

  part=" (esephysicalport-description[BSport])"
  cat ${yml_name} | sed -n '/- ese_physical_port/,/- physical_port/p' |
  grep description | awk '{print $5}' > storage_port_yml
  diff storage_port_yml storage_port_source > temp_error.txt 2>&1
  echo $? >> return.txt
  returncode_check

  part=" (esephysicalport-description[QFXname])"
  cat ${yml_name} | sed -n '/- ese_physical_port/,/- physical_port/p' |
  grep description | awk '{print $8}' > qfx_main_yml
  diff qfx_main_yml qfx_main_source > temp_error.txt 2>&1
  echo $? >> return.txt
  returncode_check

  part=" (esephysicalport-description[QFXport])"
  cat ${yml_name} | sed -n '/- ese_physical_port/,/- physical_port/p' |
  grep description | awk '{gsub(")\"","");print $9}' > qfx_logical_port_yml
  diff qfx_logical_port_yml qfx_logical_port_source > temp_error.txt 2>&1
  echo $? >> return.txt
  returncode_check

  part=" (esephysicalport-name)"
  cat ${yml_name} | sed -n '/- ese_physical_port/,/- physical_port/p' |
  grep name | cut -d \" -f 2 > qfx_logical_port_yml
  diff qfx_logical_port_yml qfx_logical_port_source > temp_error.txt 2>&1
  echo $? >> return.txt
  returncode_check

  part=" (esephysicalport-ese_device_id)"
  cat ${yml_name} | sed -n '/- ese_physical_port/,/- physical_port/p' |
  grep device_id | cut -d _ -f 5- | cut -d } -f 1 > qfx_main_yml
  diff qfx_main_yml <(cat qfx_main_source | sed s/\-/_/g) > temp_error.txt 2>&1
  echo $? >> return.txt
  returncode_check

  part=" (esephysicalport-connected_port_id)"
  cat ${yml_name} | sed -n '/- ese_physical_port/,/- physical_port/p' |
  grep port_id | cut -d _ -f 5- | awk -F } '{print $1}' > qfx_main_yml
  diff qfx_main_yml <(cat arrayname_source | sed s/\-/_/g) > temp_error.txt 2>&1
  echo $? >> return.txt
  returncode_check

  rm -f qfx_main_* qfx_logical_port_* group_* plane_* storage_name_* cluster_role_*\
  storage_port_* temp_error* arrayname_source
  Variable_param_returnCode_check
}

#可変パラメータ戻り値確認関数
function Variable_param_returnCode_check()
{
  sort -u return.txt -o return.txt
  line=$(wc -l return.txt  | cut -d ' ' -f 1)
  
  if [ ${line} == 1 ]
  then
    if [ $(cat return.txt) == 0 ]
    then
      echo "Variable param Check: OK"
      rm -f return.txt error.txt
    fi
  else
    echo "Variable param Check: NG"
    echo "============="
    cat error.txt
    echo -e "============="\\n
    rm -f return.txt error.txt
  fi
}

#確認実行
make_template_input_location
confirmation_Variable_param_location

exit 0
