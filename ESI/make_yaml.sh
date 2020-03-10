#!/bin/bash
# make_yaml.sh
#
# -----------------------------------------------------------------------------
# Purpose : Making of yaml file for ESI registration
# -----------------------------------------------------------------------------
# 2016/11/29 created  d.morita@ntt.com Slack:d.morita
# 2016/12/01 fixed ver1.1
# 2016/12/12 fixed ver1.2
# 2016/12/21 ./unittest.sh add function (no add this script) ver1.3
# 2017/05/23 add function for FileStorageStandard
# 2018/07/11 add dc_name (ff6, os1)
# 2019/05/28 fixed for ESI v1.17 (Because hyphen can not be used in yml)
# usage
usage_msg='usage:
      use this shell
      ./make_yaml.sh   [-SDP]   [input data as csv file] 
                        -bm     cablemap info as physical   #make yaml for baremetal
                        -bs     connection info as logical  #make yaml for blockstorage
                        -fs     connection info as logical  #make yaml for filestorage
                        -fss    connection info as logical  #make yaml for FileStorageStandard
                        -qfx    QFX infomation              #make yaml for adding QFX(make ese_devices)'

# parameter list as repalcement for yml
# #(comment) lines do not read.
param_list=$(cat ./template/param_list.csv | grep -v "#")

# check number of aruguments
if [ $# -ne 2 ]
then
  echo 'not argument'
  echo "${usage_msg}"
  exit 1
fi

# make yml (main function)
# usage:
# makeYml [-SDP]   [input data as csv file]
: result:
# make yml and standard output
function makeYml()
{
  # Confirmation of option notation
  if [ $(echo $1 | cut -c1 ) != "-" ]
  then
    echo "$0 : invalid option -- '$1'"
    echo "Please try ' $0 -$1 $2'"
    exit 2
  fi
  #sdp name (String)
  local _sdp_name=$(echo $1 | sed s/"-"//g)

  # input data as CSV File Name (String)
  # exits input data
  if [ ! -e $2 ]
    then
      echo "$2 : No such file or directory"
      exit 3
  fi
  # input data (filename)
  local _idata=$2

  # make location and ese_device yml
  # process each SDP
  case "${_sdp_name}" in
    bm|bs|fs|fss )
      makeLocation ${_idata}
      makeReadDevice ${_idata} ;;
    qfx )
      makeLocation ${_idata}
      makeCreateDevice ${_idata} ;;
    * ) echo "$0 : invalid option -- '${_sdp_name}'"
        exit 4 ;;
  esac
  # make physical port and ese physical port yml 
  case "${_sdp_name}" in
    bm ) makeBaremetalPorts ${_idata} ;;
    bs ) makeStorageports ${_sdp_name} ${_idata} ;;
    fs ) makeStorageports ${_sdp_name} ${_idata} ;;
    fss ) makeStorageports ${_sdp_name} ${_idata} ;;
  esac
}

# yml for location
function makeLocation()
{
  #replace string
  # $1 : input data
  local _info=$(cat $1 | grep -v "#")
  # template yml
  local _tmp=$(cat ./template/location.yml)
  # DC
  local _dc_name=$(echo "${_info}" | head -n1 | cut -d "," -f1 | cut -c1-3)
  #Only Hemel3 DC ( hh3 -> lo8 )
  if [ $(echo "${_dc_name}") == "hh3" ]
  then
    _dc_name="lo8"
  #Only ff6 DC ( ff6 -> ff1 )
  elif [ $(echo "${_dc_name}") == "ff6" ]
  then
    _dc_name="ff1"
  #Only os1 DC ( os1 -> os5 )
  elif [ $(echo "${_dc_name}") == "os1" ]
  then
    _dc_name="os5"
  fi
  # get parameter as replace strings
  local _re_dc_name=$(echo "${param_list}" | grep "dc_name" | cut -d "," -f2)
  # result
  echo "${_tmp}" | sed s/"${_re_dc_name}"/"${_dc_name}"/g
  echo
}

# yml for ese_device as create
function makeCreateDevice()
{
  # $1 : input data (qfx_main,loopback ip)
  local _info=$(cat $1 | grep -v "#")
  # template yml
  local _tmp=$(cat ./template/ese_device_create.yml)
  # get parameter as replace strings
  local _qfxs=$(echo "${_info}" | cut -d "," -f1)
  # Loop by the number of QFX main
  for _qfx_main in $(echo "${_qfxs}" | grep ".m$" | uniq )
  do
    local _loop_back_ip=$(echo "${_info}" | grep "${_qfx_main}" | cut -d "," -f2)
    # for yaml key name
    local _qfx_for_key_name=$(echo ${_qfx_main} | sed s/\-/_/g)
    # get parameter as replace strings
    local _re_qfx_main=$(echo "${param_list}" | grep "qfx_main" | cut -d "," -f2)
    local _re_loop_back_ip=$(echo "${param_list}" | grep "loop_back_ip" | cut -d "," -f2)
    local _re_qfx_for_key_name=$(echo "${param_list}" | grep "qfx_for_key_name" | cut -d "," -f2)
  echo "${_tmp}" | sed -e s/"${_re_qfx_main}"/"${_qfx_main}"/g \
                       -e s/"${_re_loop_back_ip}"/"${_loop_back_ip}"/g \
	               -e s/"${_re_qfx_for_key_name}"/"${_qfx_for_key_name}"/g
  echo
  done
}
# yml for ese_device as read
function makeReadDevice()
{
  #$1 : input data
  local _info=$(cat $1 | grep -v "#")
  #template yml
  local _tmp=$(cat ./template/ese_device_read.yml)
  #get parameter
  local _qfxs=$(echo "${_info}" | cut -d "," -f1 | sort | uniq )
  # Loop by the number of QFX main
  for _qfx_main in $(echo "${_qfxs}" | grep ".m$" | uniq )
  do
    # for yaml key name
    local _qfx_for_key_name=$(echo ${_qfx_main} | sed s/\-/_/g)
    # get parameter as replace strings
    local _re_qfx_main=$(echo "${param_list}" | grep "qfx_main" | cut -d "," -f2)
    local _re_qfx_for_key_name=$(echo "${param_list}" | grep "qfx_for_key_name" | cut -d "," -f2)
    echo "${_tmp}" | sed -e s/"${_re_qfx_main}"/"${_qfx_main}"/g \
	                 -e s/"${_re_qfx_for_key_name}"/"${_qfx_for_key_name}"/g
    echo
  done
}

# yml for server ports
function makeBaremetalPorts()
{
  #$1 : input data
  local _info=$(cat $1 | grep -v "#")
  # template yml
  local _tmp=$(cat ./template/bm_ports.yml)
  # get parameter
  local i
  for i in  $(echo "${_info}")
  do
    # get parameter
    local _qfx_name=$(echo "${i}" | cut -d "," -f1)
    local _qfx_physical_port=$(echo "${i}" | cut -d "," -f2 | cut -d "/" -f3)
    local _server_name=$(echo "${i}" | cut -d "," -f3)
    local _pci_no=$(echo "${i}" | cut -d "," -f4 |cut -c4)
    local _port_no=$(echo "${i}" | cut -d "," -f4 | cut -c6)
    local _group=$(echo "${_qfx_name}" | cut -c4)
    # which leaf
    if [ $(echo "${_qfx_name}" | cut -c9) == "s" ]
    then
      # Storage Leaf : a
      local _plane="storage"
    else
      # Data Leaf :b
      local  _plane="data"
    fi
    # which role
    if [ $(echo "${_qfx_name}" | rev | cut -c1) == "m" ]
    then
      #main
      local _qfx_main=$(echo "${_qfx_name}")
      local _role_no="0"
    else
      #backup
      local _backup_number=$(echo "${_qfx_name}" | rev | cut -c2-5 | rev )
      local _main_number=$(printf "%04d" $(expr $(echo "${_backup_number}") - 1 ))
      local _head=$(echo ${_qfx_name} | rev | cut -c6- | rev )
      local _qfx_main=$(echo "${_head}${_main_number}m")
      local _role_no=1
    fi
    # for yaml key name
    local _qfx_for_key_name=$(echo ${_qfx_main} | sed s/\-/_/g)
    # get parameter as replace strings
    local _re_qfx_main=$(echo "${param_list}" | grep "qfx_main" | cut -d "," -f2)
    local _re_qfx_physical_port=$(echo "${param_list}" | grep "qfx_physical_port" | cut -d "," -f2)
    local _re_server_name=$(echo "${param_list}" | grep "server_name" | cut -d "," -f2)
    local _re_pci_no=$(echo "${param_list}" | grep "pci_no" | cut -d "," -f2)
    local _re_port_no=$(echo "${param_list}" | grep "port_no" | cut -d "," -f2)
    local _re_role_no=$(echo "${param_list}" | grep "role_no" | cut -d "," -f2)
    local _re_group=$(echo "${param_list}" | grep "group" | cut -d "," -f2)
    local _re_plane=$(echo "${param_list}" | grep "plane" | cut -d "," -f2)
    local _re_qfx_for_key_name=$(echo "${param_list}" | grep "qfx_for_key_name" | cut -d "," -f2)
    # result
    echo "${_tmp}" | sed -e s/"${_re_qfx_main}"/"${_qfx_main}"/g \
                         -e s/"${_re_qfx_physical_port}"/"${_qfx_physical_port}"/g \
                         -e s/"${_re_server_name}"/"${_server_name}"/g \
                         -e s/"${_re_pci_no}"/"${_pci_no}"/g \
                         -e s/"${_re_port_no}"/"${_port_no}"/g \
                         -e s/"${_re_role_no}"/"${_role_no}"/g \
                         -e s/"${_re_group}"/"${_group}"/g \
                         -e s/"${_re_plane}"/"${_plane}"/g \
	                 -e s/"${_re_qfx_for_key_name}"/"${_qfx_for_key_name}"/g
    echo
  done
}

function makeStorageports()
{
  local  _tmp=$(cat ./template/${1}_ports.yml)
  #$2 : input data
  local _info=$(cat $2 | grep -v "#")
  #get parameter
  local i
  for i in $(echo "${_info}")
  do
    local _group=$(echo "${i}" | cut -c4)
    local _qfx_main=$(echo "${i}" | cut -d "," -f1)
    local _qfx_logical_port=$(echo "${i}" | cut -d "," -f2)
    local _storage_name=$(echo "${i}" | cut -d "," -f3)
    # which leaf
    if [ $(echo "${_qfx_main}" | cut -c9) == "s" ]
    then
      # Storage Leaf : a
      local _storage_port="a"
      local _plane="storage"
    else
      # Data Leaf :b
      local _storage_port="b"
      local _plane="data"
    fi
    # which role
    if [ $(echo "${_storage_name}" | rev | cut -c1 ) == "p" ]
    then
      local _cluster_role="Primary"
    else
      local _cluster_role="Secondary"
    fi
    # for yaml key name
    local _qfx_for_key_name=$(echo ${_qfx_main} | sed s/\-/_/g)
    # get parameter as replace strings
    local _re_qfx_main=$(echo "${param_list}" | grep "qfx_main" | cut -d "," -f2)
    local _re_qfx_logical_port=$(echo "${param_list}" | grep "qfx_logical_port" | cut -d "," -f2)
    local _re_storage_name=$(echo "${param_list}" | grep "storage_name" | cut -d "," -f2)
    local _re_storage_port=$(echo "${param_list}" | grep "storage_port" | cut -d "," -f2)
    local _re_cluster_role=$(echo "${param_list}" | grep "cluster_role" | cut -d "," -f2)
    local _re_group=$(echo "${param_list}" | grep "group" | cut -d "," -f2)
    local _re_plane=$(echo "${param_list}" | grep "plane" | cut -d "," -f2)
    local _re_qfx_for_key_name=$(echo "${param_list}" | grep "qfx_for_key_name" | cut -d "," -f2)
  #result
     echo "${_tmp}" | sed -e s/"${_re_qfx_main}"/"${_qfx_main}"/g \
                          -e s/"${_re_qfx_logical_port}"/"${_qfx_logical_port}"/g \
                          -e s/"${_re_storage_name}"/"${_storage_name}"/g \
                          -e s/"${_re_storage_port}"/"${_storage_port}"/g \
                          -e s/"${_re_cluster_role}"/"${_cluster_role}"/g \
                          -e s/"${_re_group}"/"${_group~}"/g \
                          -e s/"${_re_plane}"/"${_plane}"/g \
	                  -e s/"${_re_qfx_for_key_name}"/"${_qfx_for_key_name}"/g
     echo
  done
}

makeYml $1 $2
