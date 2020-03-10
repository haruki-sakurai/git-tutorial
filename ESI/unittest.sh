#!/bin/bash
OK='\e[1;32mOK\e[m'
NG='\e[1;31mNG\e[m'

echo "##### TEMPLATE SUM CHECK #####"
sums='c0287e83a58c2fc97441b89268967013  ./template/bm_ports.yml
1ddc33c0a321b0fc50a59cd22b322587  ./template/bs_ports.yml
b7664ad25d756371ab39cf38f1b1e701  ./template/ese_device_create.yml
1c890c81e39f88cef28d21990e0abf86  ./template/ese_device_read.yml
d893520402a7718b8ecfe7f22c98ea61  ./template/fs_ports.yml
1d6f0c4bb469dd4a8e5cfd2f2ccefd11  ./template/fss_ports.yml
fc10af98998876b6fd11c3cd8345836d  ./template/location.yml
2526bf2982cef85309a517f9f2ef88b1  ./template/param_list.csv'

for i in $(echo "${sums}" | sed s/"  "/,/g)
do
  _file=$(echo "${i}" | cut -d, -f2)
  _check=$(echo "${i}" | cut -d, -f1)
  _result=$(md5sum ${_file} | sed s/"  "/,/g | cut -d "," -f1)
  if [ ${_check} = ${_result} ]
  then
    printf "${_file}:\t${OK}\n"
  else
    printf "${_file}:\t${NG}\n"
  fi
done

echo "##### ERROR TEST ######"
printf "Show usage message : \t"
./make_yaml.sh 1>/dev/null 2>/dev/null
if [ $? -eq 1 ]
  then
    printf "${OK}\n"
  else
    printf "${NG}\n"
  fi

printf "Error Option Code2:\t"
./make_yaml.sh hoge fuga 1>/dev/null 2>/dev/null
if [ $? -eq 2 ]
  then
    printf "${OK}\n"
  else
    printf "${NG}\n"
  fi

printf "Error Option Code3:\t"
./make_yaml.sh -hoge fuga 1>/dev/null 2>/dev/null
if [ $? -eq 3 ]
  then
    printf "${OK}\n"
  else
    printf "${NG}\n"
  fi

printf "Error Option Code4:\t"
./make_yaml.sh -hoge ./test_data/test_baremetal.csv 1>/dev/null 2>/dev/null
if [ $? -eq 4 ]
  then
    printf "${OK}\n"
  else
    printf "${NG}\n"
  fi

echo "##### SUCCESS TEST ##### "
printf "Baremetal:\t"
./make_yaml.sh -bm ./test_data/test_baremetal.csv 1>/dev/null 2>/dev/null
if [ $? -eq 0 ]
  then
    printf "${OK}\n"
  else
    printf "${NG}\n"
  fi

printf "BlockStorage:\t"
./make_yaml.sh -bs ./test_data/test_blockstorage.csv 1>/dev/null 2>/dev/null
if [ $? -eq 0 ]
  then
    printf "${OK}\n"
  else
    printf "${NG}\n"
  fi

printf "FileStorage:\t"
./make_yaml.sh -fs ./test_data/test_filestorage.csv 1>/dev/null 2>/dev/null
if [ $? -eq 0 ]
  then
    printf "${OK}\n"
  else
    printf "${NG}\n"
  fi

printf "FileStorageStandard:\t"
./make_yaml.sh -fs ./test_data/test_filestoragestandard.csv 1>/dev/null 2>/dev/null
if [ $? -eq 0 ]
  then
    printf "${OK}\n"
  else
    printf "${NG}\n"
  fi
printf "New QFX:\t"
./make_yaml.sh -fs ./test_data/test_qfx.csv 1>/dev/null 2>/dev/null
if [ $? -eq 0 ]
  then
    printf "${OK}\n"
  else
    printf "${NG}\n"
  fi
