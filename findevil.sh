
#!/bin/bash
# Bernd Helber
# Free Beerware Licence
## Version 0.2
#purpose: Check Home Directories for wrong Permissions#
#
#set -x
# Please adjust the LOGDIR Value to match your needs
# ToDO:
# implement automatic Mailings

#####x
LOGDIR="/var/log"
PROTOCOL="evilperm"
EVILPATH="/home"
HTIMESTAMP=$(date  '+%nDATE : %m-%d-%y%nTIME : %H-%M-%S')
#DATUM=`date +'%y/%m/%d_%H:%M'`
DATUM=` date +'%y_%d_%m_%H:%M'`
LOGFILE="${LOGDIR}/evilperm_${DATUM}.log"
VALUE=" (777|755|775)"

touch $LOGFILE
#set -x
echo "check for 777, 755, 775 Directories"
echo "Please check the Protocol under $LOGDIR/"
##########Write Startupdate to Logfile
echo " Startzeit $HTIMESTAMP" >> $LOGFILE
#### find Path ... run stat on folders replace strings:  ttr, Open Bracket, Closed Bracket, Semicolon with sed. Remove the first Column with awk. Pipe Information with tee append to the Logfile.

find $EVILPATH -print  -maxdepth 2 |while read EVILDIRS; do stat -c "%attr (%a,%U,%G)  /%n" "$EVILDIRS"  |sed s'/[    ,  (  ) ]/ /g'  |egrep $VALUE |awk '{$1=""}1'    |tee -a $LOGFILE ; done
exit 1
