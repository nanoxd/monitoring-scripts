#!/usr/bin/env bash
## Description:
# Pulls IPMI info from Supermicro Motherboard
# to feed into INFLUX

## Requirements
# ipmitool

## Input Parameters for Daemon
HOST=""
HOST_NAME=""
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
    
    cpu1temp=`get_value "CPU1 Temp"`
    cpu2temp=`get_value "CPU2 Temp"`
    systemtemp=`get_value "System Temp"`
    periphtemp=`get_value "Peripheral Temp"`
    pchtemp=`get_value "PCH Temp"`
    
    dimma1temp=`get_value "P1-DIMMA1 TEMP"`
    dimmb1temp=`get_value "P1-DIMMB1 TEMP"`
    dimmc1temp=`get_value "P1-DIMMC1 TEMP"`
    dimmd1temp=`get_value "P1-DIMMD1 TEMP"`
    dimme1temp=`get_value "P1-DIMME1 TEMP"`
    dimmf1temp=`get_value "P2-DIMMF1 TEMP"`
    dimmg1temp=`get_value "P2-DIMMG1 TEMP"`
    dimmh1temp=`get_value "P2-DIMMH1 TEMP"`
    fan1=`get_value "FAN1"`
    fan2=`get_value "FAN2"`
    fan3=`get_value "FAN3"`
    fan4=`get_value "FAN4"`
    fan5=`get_value "FAN5"`
    fan6=`get_value "FAN6"`
    fana=`get_value "FANA"`
    fanb=`get_value "FANB"`
    
    rm tempdatafile
}

print_data () {
    echo "CPU1 Temperature: $cpu1temp"
    echo "CPU2 Temperature: $cpu2temp"
    echo "System Temperature: $systemtemp"
    echo "Peripheral Temperature: $periphtemp"
    echo "PCH Temperature: $periphtemp"
    echo "P1-DIMMA1 Temperature: $dimma1temp"
    echo "P1-DIMMB1 Temperature: $dimmb1temp"
    echo "P1-DIMMC1 Temperature: $dimmc1temp"
    echo "P1-DIMMD1 Temperature: $dimmd1temp"
    echo "P1-DIMME1 Temperature: $dimme1temp"
    echo "P2-DIMMF1 Temperature: $dimmf1temp"
    echo "P2-DIMMG1 Temperature: $dimmg1temp"
    echo "P2-DIMMH1 Temperature: $dimmh1temp"
    echo "Fan1 Speed: $fan1"
    echo "Fan2 Speed: $fan2"
    echo "Fan3 Speed: $fan3"
    echo "Fan4 Speed: $fan4"
    echo "Fan5 Speed: $fan5"
    echo "Fan6 Speed: $fan6"
    echo "FanA Speed: $fana"
    echo "FanB Speed: $fanb"
}

send_sensor_data() {
    sensor="$1"
    value="$2"
    curl -i -XPOST "http://$INFLUX_HOST/write?db=$INFLUX_DB" --data-binary "health_data,host=$HOST_NAME,sensor=$sensor value=${value:=0}"
}

write_data () {
    #Write the data to the database
    declare -A data=(
        ["cpu1temp"]="$cpu1temp"
        ["cpu2temp"]="$cpu2temp"
        ["systemtemp"]="$systemtemp"
        ["periphtemp"]="$periphtemp"
        ["pchtemp"]="$pchtemp"
        ["dimma1temp"]="$dimma1temp"
        ["dimmb1temp"]="$dimmb1temp"
        ["dimmc1temp"]="$dimmc1temp"
        ["dimmd1temp"]="$dimmd1temp"
        ["dimme1temp"]="$dimme1temp"
        ["dimmf1temp"]="$dimmf1temp"
        ["dimmg1temp"]="$dimmg1temp"
        ["dimmh1temp"]="$dimmh1temp"
        ["fan1"]="$fan1"
        ["fan2"]="$fan2"
        ["fan3"]="$fan3"
        ["fan4"]="$fan4"
        ["fan5"]="$fan5"
        ["fan6"]="$fan6"
        ["fana"]="$fana"
        ["fanb"]="$fanb"
    )
    
    for key in ${!data[@]}; do
        send_sensor_data ${key} ${data[${key}]}
    done
}

#Prepare to start the loop and warn the user
get_ipmi_data
print_data
write_data
