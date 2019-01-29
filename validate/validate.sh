#!/bin/bash

yum -y update

yum -y install tmux

tmux new-session -d -s openshift-install

chmod +x /root/run.sh

tmux send -t openshift-install /root/run.sh ENTER