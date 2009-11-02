#!/bin/bash

TOGREP="perl sysfink.pl"
TOGREP="/usr/bin/perl /root/sysfink-client/sysfink-client.pl"
OUT_FN="sysfink-mem-usage.txt"
SLEEP_TIME=1

PWD=`pwd`

echo "Searching process with: \"$TOGREP\""
echo "Output file: \"$OUT_FN\"";
echo "Running in loop. Press <Ctrl>+C to stop it ..."
echo ""

echo "" > $OUT_FN

for ((i=1;1;i++)); do

	PID=`pgrep -f "$TOGREP"`

	if [ ! -z "$PID" ]; then
		NAME=`ps --pid $PID -o cmd=`
		DATE=`date`
		echo "Run number $i ($DATE)"
		echo "Found PID $PID ($NAME)"
	
		echo "Run number $i ($DATE)" >> $OUT_FN
		echo "Found PID $PID ($NAME)" >> $OUT_FN
		/usr/bin/perl $PWD/smaps.pl $PID >> $OUT_FN
		echo "" >> $OUT_FN
	fi

	sleep $SLEEP_TIME

done 
