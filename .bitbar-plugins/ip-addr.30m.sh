#!/bin/bash

dig +short myip.opendns.com @resolver1.opendns.com;
echo '---'
ifconfig en0
