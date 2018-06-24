#/usr/bin/env sh
## Description:
# Pulls count of streams

## Variables
HOST="http://localhost:8181"
HOST_NAME=""
API_KEY=""
INFLUX_HOST="localhost:8086"
INFLUX_DB="telegraf"
JSON=`curl -s "$HOST/api/v2?cmd=get_activity&apikey=$API_KEY" | jq '.response.data'`

send_data() {
    sensor="$1"
    value="$2"
    curl -i -XPOST "http://$INFLUX_HOST/write?db=$INFLUX_DB" --data-binary "plex_stats,host=$HOST_NAME,sensor=$sensor value=${value:=0}"
}

direct_play=`echo $JSON | jq '.stream_count_direct_play'`
direct_stream=`echo $JSON | jq '.stream_count_direct_stream'`
transcode=`echo $JSON | jq '.stream_count_transcode'`

send_data "direct_plays" "$direct_play"
send_data "direct_streams" "$direct_stream"
send_data "transcodes" "$transcode"
