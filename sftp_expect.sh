#!/bin/bash

arg_count=$#

ssh_user=${1}; shift
ssh_host=${1}; shift
remote_dir=${1}; shift
ssh_port=${1}; shift
ssh_key=${1}; shift
ssh_ppf=${1}; shift

case $ssh_key in
  "/home/jason/.ssh/id_rsa" ) 
    expected_args=6
    source "${ssh_ppf}"
    ##JH pp="1234wrongpw"
    ;;
  "/home/jason/.ssh/id_rsa_2" )
    expected_args=5
    pp="none";;
esac

function usage() {
  if [ ${1} -ne ${2} ] ; then
    echo "Usage: ${0} user host remote_dir port keyfile [passfile]"
    exit 1
  fi
}

usage $arg_count $expected_args

expect << EOF
  spawn sftp -oIdentityFile=${ssh_key} -P ${ssh_port} ${ssh_user}@${ssh_host}:${remote_dir}
  set timeout 2
  expect "Enter passphrase" {send "${pp}\r"}
##JH  send "${pp}\r"
  expect {
    "Permission denied" {send_user "invalid password or account\n"; exit 1}
    "Connection refused" {send_user "Connection to ${ssh_user}@${ssh_host} via port ${ssh_port} failed\n"; exit 1}
    "Connected" {exp_continue}
    "Changing" {exp_continue}
  }
  expect "sftp"
  send "put test*.txt\rquit\r"
  expect {
    "No such file or directory" {send "quit\r"; send_user "the file was not found.\n"; exit 1}
    eof {exit}
  }
EOF
exp_exit_code=$?

echo -e "\ndone with this crap"
exit ${exp_exit_code}

