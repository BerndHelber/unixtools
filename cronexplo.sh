#!/bin/bash
#set -xv
# System-wide cronTABULATOR file and cron job directory. Change these for your system.
####Binaries wie make user of########
BINCRONTAB="/usr/bin/crontab"
BINMV="/usr/bin/mv"
BINSORT="/usr/bin/sort"
BINTOUCH="/usr/bin/touch"
BINAWK="/bin/gawk"
BINCAT="/usr/bin/cat"
BINSED="/usr/bin/sed"
BINCOLUMN="/usr/bin/column"
BINECHO="/usr/bin/echo"
BINCUT="/usr/bin/cut"
BINLOGGER="/usr/bin/logger"
BINEGREP="/usr/bin/egrep"
########PATH we make use of#############
CRONTAB="/etc/crontab"
#CRONDIR="/etc/cron.d"
USERCRON="/var/spool/cron/tabs"
LOGDIR="/var/log"
######FILES we make use of#############
MKCRONFILE="$LOGDIR/cronresult.log"
OLDLOGFILE="$LOGDIR/cronresult_`date +%m.%d.%H:%M`.log"
${BINMV}  ${MKCRONFILE} ${OLDLOGFILE}

${BINTOUCH}  ${MKCRONFILE} || exit 1

# Einzelner Tab dummerweise notwendig. 
TABULATOR=$(${BINECHO} -en "\t")

# Crontab , ausklammern von Nihct Cron Job Zeilen und Zeichen
# Moegliche mehrface Whitespace Character werden durch einen einzelnen Whitespace ersetzt 
function saubermachen_cron_zeilen() {
    while read line ; do
        ${BINECHO} "${line}" |
            ${BINEGREP} --invert-match '^($|\s*#|\s*[[:alnum:]_]+=)' |
            ${BINSED} --regexp-extended "s/\s+/ /g" |
            ${BINSED} --regexp-extended "s/^ //"
    done;
}

# 
function sortiere_cron_eintraege() {
while read line ; do
match=$($BINECHO "${line}" | ${BINEGREP} -o 'run-parts (-{1,2}\S+ )*\S+')

if [[ -z "${match}" ]] ; then
    ${BINECHO} "${line}"
else
    CRONTAB_FELDER=$($BINECHO "${line}" | $BINCUT -f1-6 -d' ')
    USERCRON=$($BINECHO  "${match}" | ${BINAWK} '{print $NF}')

    if [[ -d "${USERCRON}" ]] ; then
	for CRON_JOB_DATEI in "${USERCRON}" ; do 
	    [[ -f "${CRON_JOB_DATEI}" ]] && ${BINECHO} "${CRONTAB_FELDER} ${CRON_JOB_DATEI}"
	done
    fi
fi
done;
}

# Alle systemweiten Jobs der reguelaern Cron raus suchen und einsortieren 
${BINAWK} -F: '{print $1}' "${CRONTAB}" | saubermachen_cron_zeilen | sortiere_cron_eintraege >>"${MKCRONFILE}" 

# Fuege die  hinzu falls diese existieren. Der Username wird zwischen den Fuenf Cronfeldern und 
# dem abzusetzenden Kommando eingefuegt.
while read user ; do
${BINCRONTAB} -l -u "${user}" 2> /dev/null |
saubermachen_cron_zeilen |
${BINSED} --regexp-extended "s/^((\S+ +){5})(.+)$/\1${user} \3/" >>"${MKCRONFILE}"
done < <($BINCUT --fields=1 --delimiter=: /etc/passwd)

# Output aller erfassten  Crontabs, der einzelne  Whitespace zwischen den Feldern wird
# durch einen Tabulator ersetzt, die Zeilen nach Minute, Stunde, Monat, Woche und Benutzer sortiert
# Ein Header wird eingefuegt und das Resultat als Tabelle formatiert
# Ein Alptraum in SED und Regular Expression 
${BINCAT}  "${MKCRONFILE}" |
####SED Einruecken und Spalten setzen
    ${BINSED} --regexp-extended "s/^(\S+) +(\S+) +(\S+) +(\S+) +(\S+) +(\S+) +(.*)$/\1|\t\2|\t\3|\t\4|\t\5|\t\6|\t\7/" |
    ${BINSORT}  --numeric-sort --field-separator="${TABULATOR}" --key=2,1 |
    ${BINSED} "1i\Minute|\tStunde|\tTag|\tMonat|\tWoche|\tBenutzer|\tKommando|" |
   # ${BINCOLUMN} -s"${TABULATOR}" -t
    ${BINCOLUMN} -s "${TABULATOR}" -t | sed 's/.*/\x1b[1;4m&\x1b[0m/'
#Schreibe Message ins Syslog 
$BINLOGGER -t "${0##*/}[ $ $]" "cronexplo run and $MKCRONFILE written "
exit 1
