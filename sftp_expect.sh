#!/bin/bash

arg_count=$#

ssh_user=${1}; shift
ssh_host=${1}; shift
ssh_port=${1}; shift
ssh_key=${1}; shift
ssh_ppf=${1}; shift

case $ssh_key in
  "/home/jason/.ssh/id_rsa" ) 
    expected_args=5
    source "${ssh_ppf}"
    ##JH pp="1234wrongpw"
    ;;
  "/home/jason/.ssh/id_rsa_2" ) expected_args=4;;
esac

function usage() {
  if [ ${1} -ne ${2} ] ; then
    echo "Usage: ${0} user host port keyfile [passfile]"
    exit 1
  fi
}

usage $arg_count $expected_args

expect << EOF
##JH  spawn ssh -p ${ssh_port} ${ssh_user}@${ssh_host} "touch /home/jason/Desktop/test.file_$(date +%Y%m%d_%H%M%S)"
  spawn sftp -oIdentityFile=${ssh_key} -P ${ssh_port} ${ssh_user}@${ssh_host}
##JH  expect "Enter passphrase"
##JH  send "${pp}\r"
##JH  expect "sftp>"
##JH  send "put test*.txt\rquit\r"
##JH  expect eof
  expect {
    "Enter passphrase" {send "${pp}\r"; exp_continue}
    "Permission denied" {catch wait result; send_user "invalid password or account\n"; exit [lindex \$result 3]}
    "Connection refused" {catch wait result; send_user "Connection to ${ssh_user}@${ssh_host} via port ${ssh_port} failed\n"; exit [lindex \$result 3]}
    timeout {catch wait result; send_user "connection to ${ssh_host} timed out\n"; exit [lindex \$result 3]}
    "sftp>" {send "put test*.txt\rquit\r"; exp_continue}
    eof {catch wait result; exit [lindex \$result 3]}
  }
##JH    timeout {send_user "connection to ${ssh_host} timed out\n"; exit}
##JH    eof {exit}
EOF
exp_exit_code=$?

echo -e "\ndone with this crap"
exit ${exp_exit_code}

