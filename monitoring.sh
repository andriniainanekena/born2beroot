#!/bin/bash

system_arch=$(uname -a)

physical_cpus=$(grep "physical id" /proc/cpuinfo | wc -l)
virtual_cpus=$(grep "processor" /proc/cpuinfo | wc -l)

mem_total=$(free --mega | awk '$1 == "Mem:" {print $2}')
mem_used=$(free --mega | awk '$1 == "Mem:" {print $3}')
mem_usage_percent=$(free --mega | awk '$1 == "Mem:" {printf("%.2f"), $3/$2*100}')

disk_total=$(df -m | grep "/dev/" | grep -v "/boot" | awk '{disk_total += $2} END {printf ("%.1fGb\n"), disk_total/1024}')
disk_used=$(df -m | grep "/dev/" | grep -v "/boot" | awk '{disk_used += $3} END {print disk_used}')
disk_usage_percent=$(df -m | grep "/dev/" | grep -v "/boot" | awk '{disk_used += $3} {disk_total += $2} END {printf("%d"), disk_used/disk_total*100}')

cpu_idle=$(vmstat 1 2 | tail -1 | awk '{printf $15}')
cpu_usage=$(expr 100 - $cpu_idle)
cpu_usage_percent=$(printf "%.1f" $cpu_usage)

last_boot=$(who -b | awk '$1 == "system" {print $3 " " $4}')

lvm_active=$(if [ $(lsblk | grep "lvm" | wc -l) -gt 0 ]; then echo yes; else echo no; fi)

tcp_connections=$(ss -ta | grep ESTAB | wc -l)

users_logged=$(users | wc -w)

ip_address=$(hostname -I)
mac_address=$(ip link | grep "link/ether" | awk '{print $2}')

sudo_commands_count=$(journalctl _COMM=sudo | grep COMMAND | wc -l)

wall "	Architecture: $system_arch
	CPU physical: $physical_cpus
	vCPU: $virtual_cpus
	Memory Usage: $mem_used/${mem_total}MB ($mem_usage_percent%)
	Disk Usage: $disk_used/${disk_total} ($disk_usage_percent%)
	CPU load: $cpu_usage_percent%
	Last boot: $last_boot
	LVM use: $lvm_active
	Connections TCP: $tcp_connections ESTABLISHED
	User log: $users_logged
	Network: IP $ip_address ($mac_address)
	Sudo: $sudo_commands_count cmd"


