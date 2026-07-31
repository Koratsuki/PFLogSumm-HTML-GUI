#!/usr/bin/env bash
set -euo pipefail
# Debug option - should be disabled unless required
#set -x

SCRIPTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "${SCRIPTDIR}/lib/detect.sh"

# Defaults for optional parameters
CUSTOMDATE=""
CUSTOMLOG=""
CUSTOMMONTH=""

#Get Command Line Parameters for the custom date e.g.  -d "Nov 03"
POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -d|--date)
    CUSTOMDATE="$2"
    shift # past argument
    shift # past value
    ;;

    -l|--logfile)
    CUSTOMLOG="$2"
    shift # past argument
    shift # past value
    ;;

    -m|--month)
    CUSTOMMONTH="$2"
    shift # past argument
    shift # past value
    ;;    

    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
if [[ ${#POSITIONAL[@]} -gt 0 ]]; then
    set -- "${POSITIONAL[@]}" # restore positional parameters
else
    set --
fi

#Select Temporal
if [[ -z "${CUSTOMMONTH}" ]]; then
    #If custom date is not set - default to current date e.g. 'Dec  9'
    if [[ -z "${CUSTOMDATE}" ]]; then
        LOGDATE=$(date +'%b %e')
        LOGDATE_PATTERN="$(date +'%b %e')|$(date +'%Y-%m-%d')"
    else
        LOGDATE=$CUSTOMDATE
        LOGDATE_PATTERN=$CUSTOMDATE
    fi
else
    LOGDATE=$( echo ${CUSTOMMONTH} | sed 's/.*/\L&/; s/[a-z]*/\u&/g')
    LOGDATE_PATTERN=$LOGDATE
fi

#Custom Log file(s)
if [[ -z "${CUSTOMLOG}" ]]; then
    LOGFILELOCATION=$(detect_mail_log)
else
    LOGFILELOCATION=${CUSTOMLOG}
fi

#Test for a valid log file
if ! ls $LOGFILELOCATION 1> /dev/null 2>&1; then
    echo "Not a valid log file" >&2; exit 1
fi



#Temporal Values
REPORTDATE=$(date '+%Y-%m-%d %H:%M:%S')
CURRENTYEAR=$(date +'%Y')
CURRENTMONTH=$(date +'%b')
CURRENTDAY=$(date +'%e')


#Get Counts

count_matches() {
    local pattern=$1
    grep -E "$LOGDATE_PATTERN" "$LOGFILELOCATION" 2>/dev/null \
        | grep -E -c "$pattern" \
        || true
}

Sent=$(count_matches 'postfix/smtp.*status=sent')
Dfr=$(count_matches 'postfix/smtp.*status=deferred')
Bnc=$(count_matches 'postfix/smtp.*status=bounce')
RelayAccDnd=$(count_matches 'postfix/smtp.*Relay access denied')
EnvelopeBlocked=$(count_matches '550.*Envelope blocked')

greylist=$(count_matches 'postfix/smtp.*[Gg]reylist')
Received=$(count_matches 'postfix/smtpd.*client=')
Rejected=$(count_matches 'rejected: ')
SpamCount=$(count_matches 'status=sent.*spam')
MailVirus=$(count_matches '[Ii][Nn][Ff][Ee][Cc][Tt][Ee][Dd]')

PREGREET=$(count_matches 'postfix/postscreen.*PREGREET')
CONNECT=$(count_matches 'postfix/postscreen.*CONNECT')
DISCONNECT=$(count_matches 'postfix/postscreen.*DISCONNECT')
HANGUP=$(count_matches 'postfix/postscreen.*HANGUP')
DNSBL=$(count_matches 'postfix/postscreen.*DNSBL')
AccountLogins=$(count_matches 'postfix/.*sasl_username')

warning=$(count_matches '[Ww][Aa][Rr][Nn][Ii][Nn][Gg]')
error=$(count_matches '[Ee][Rr][Rr][Oo][Rr]')
fatal=$(count_matches '[Ff][Aa][Tt][Aa][Ll]')
panic=$(count_matches '[Pp][Aa][Nn][Ii][Cc]')

echo "Report Run       : $REPORTDATE"
echo "Log Date Extract : $LOGDATE"

echo '-------------------------------------------'
echo "Total Messages Delivered    : $Sent"
echo "Total Messages Deferred     : $Dfr"
echo "Total Messages Bounced      : $Bnc"
echo "Total Messages Rejected     : $Rejected"
echo "Total Messages Received     : $Received"
echo "Total Relay Access Denied   : $RelayAccDnd"
echo "Total Greylisted            : $greylist"
echo "Total Virus                 : $MailVirus"
echo "Total Spam                  : $SpamCount"

echo "Envelope Blocked (550)      : $EnvelopeBlocked"
echo "SASL Account Logins         : $AccountLogins"

echo "Total postscreen PREGREETS  : $PREGREET"
echo "Total postscreen CONNECT    : $CONNECT"
echo "Total postscreen DISCONNECT : $DISCONNECT"
echo "Total postscreen HANGUP     : $HANGUP"
echo "Total postscreen DNSBL      : $DNSBL"

echo "Postfix Warnings            : $warning"
echo "Postfix Errors              : $error"
echo "Postfix Fatal               : $fatal"
echo "Postfix Panic               : $panic"


echo

exit 0
