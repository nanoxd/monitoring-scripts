#!/usr/bin/env bash
## Description:
# Pulls IPMI info from Supermicro Motherboard
# to feed into InfluxDB

## Requirements
# ipmitool

## Input Parameters for Daemon
HOST="10.0.0.150"
HOST_NAME="Gringotts"
IPMI_USER=""
IPMI_PASS=""
INFLUX_HOST=""
INFLUX_DB=""

get_value() {
    key="$1"
    echo `cat tempdatafile | grep "$key" | cut -f2 -d"|" | grep -o '[0-9]\+'`
}

get_ipmi_data() {
    #Get ipmi data
    ipmitool -H $HOST -U "$IPMI_USER" -P "$IPMI_PASS" sdr > tempdatafile
    
    cputemp=`get_value "CPU Temp"`
    systemtemp=`get_value "System Temp"`
    periphtemp=`get_value "Peripheral Temp"`
    mb10g=`get_value "MB_10G Temp"`
    dimma1temp=`get_value "DIMMA1 Temp"`
    dimma2temp=`get_value "DIMMA2 Temp"`
    dimmb1temp=`get_value "DIMMB1 Temp"`
    dimmb2temp=`get_value "DIMMB2 Temp"`
    fan1=`get_value "FAN1"`
    fan2=`get_value "FAN2"`
    fan3=`get_value "FAN3"`
    fana=`get_value "FANA"`
    
    rm tempdatafile
}

print_data () {
    echo "CPU Temperature: $cputemp"
    echo "System Temperature: $systemtemp"
    echo "Peripheral Temperature: $periphtemp"
    echo "MB_10G Temperature: $mb10g"
    echo "DIMMA1 Temperature: $dimma1temp"
    echo "DIMMA2 Temperature: $dimma2temp"
    echo "DIMMB1 Temperature: $dimmb1temp"
    echo "DIMMB2 Temperature: $dimmb2temp"
    echo "Fan1 Speed: $fan1"
    echo "Fan2 Speed: $fan2"
    echo "Fan3 Speed: $fan3"
    echo "FanA Speed: $fana"
}

send_sensor_data() {
    sensor="$1"
    value="$2"
    curl -i -XPOST "http://$INFLUX_HOST/write?db=$INFLUX_DB" --data-binary "health_data,host=$HOST_NAME,sensor=$sensor value=${value:=0}"
}

write_data () {
    #Write the data to the database
    declare -A data=(
        ["cputemp"]="$cputemp"
        ["systemtemp"]="$systemtemp"
        ["periphtemp"]="$periphtemp"
        ["mb10g"]="$mb10g"
        ["dimma1temp"]="$dimma1temp"
        ["dimma2temp"]="$dimma2temp"
        ["dimmb1temp"]="$dimmb1temp"
        ["dimmb2temp"]="$dimmb2temp"
        ["fan1"]="$fan1"
        ["fan2"]="$fan2"
        ["fan3"]="$fan3"
        ["fana"]="$fana"
    )
    
    for key in ${!data[@]}; do
        send_sensor_data ${key} ${data[${key}]}
    done
}

#Prepare to start the loop and warn the user
get_ipmi_data
print_data
write_data
