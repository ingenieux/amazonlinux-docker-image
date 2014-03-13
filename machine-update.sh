#!/bin/bash

set -ex

yum install -y --enablerepo=epel docker-io ncurses-devel make gcc git patch
chkconfig docker on
