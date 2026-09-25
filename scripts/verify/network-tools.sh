# Sourced by scripts/verify.sh: network tool checks.
# shellcheck shell=bash

check_tool tcpdump --version
check_tool tshark --version
check_tool nmap --version
check_tool mitmproxy --version
check_tool scapy -h
check_tool socat -V
