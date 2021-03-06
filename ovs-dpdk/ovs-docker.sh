#!/bin/bash

export VHOST_SOCK_DIR=/usr/local/var/run/openvswitch

sudo docker run -it --name=ovs-docker -v /dev/hugepages:/dev/hugepages -v ${VHOST_SOCK_DIR}:/var/run/openvswitch --privileged dpdk_suite
