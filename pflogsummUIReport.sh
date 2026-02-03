#!/usr/bin/env bash
#=====================================================================================================================
#   DESCRIPTION  Generating a stand alone web report for postfix log files, 
#                Runs on all Linux platforms with postfix installed
#   AUTHOR       Riaan Pretorius <pretorius.riaan@gmail.com>
#                Modernized and i18n added by Antigravity
#=====================================================================================================================

#CONFIG FILE LOCATION
PFSYSCONFDIR="/etc"
SCRIPTDIR="/home/koratsuki/Dev/Projects/PFLogSumm-HTML-GUI"

#Create Blank Config File if it does not exist
if [ ! -f ${PFSYSCONFDIR}/"pflogsumui.conf" ]
then
tee ${PFSYSCONFDIR}/"pflogsumui.conf" <<EOF
#PFLOGSUMUI CONFIG

##  Postfix Log Location
LOGFILELOCATION="/var/log/maillog"

##  pflogsumm details
##  NOTE: DONT USE -d today - breaks the script
PFLOGSUMMOPTIONS=" --verbose_msg_detail --zero_fill "
PFLOGSUMMBIN="/usr/sbin/pflogsumm  "

##  HTML Output
HTMLOUTPUTDIR="/var/www/html/"
HTMLOUTPUT_INDEXDASHBOARD="index.html"

## Language (en or es)
LANGUAGE="en"

EOF
echo "DEFAULT configuration file writen to ${PFSYSCONFDIR}/pflogsumui.conf, Please verify the paths before you continue"
exit 0
fi

#Load Config File
. ${PFSYSCONFDIR}/"pflogsumui.conf"

# Default Language if not set
LANGUAGE=${LANGUAGE:-"en"}

# Load Language File
if [ -f "${SCRIPTDIR}/languages/${LANGUAGE}.sh" ]; then
    . "${SCRIPTDIR}/languages/${LANGUAGE}.sh"
else
    echo "Language file ${SCRIPTDIR}/languages/${LANGUAGE}.sh not found, defaulting to English."
    . "${SCRIPTDIR}/languages/en.sh"
fi


#Create the Cache Directory if it does not exist
if [ ! -d $HTMLOUTPUTDIR/data ]; then
  mkdir -p  $HTMLOUTPUTDIR/data;
fi

#TOOLS
ACTIVEHOSTNAME=$(cat /proc/sys/kernel/hostname)
MOVEF="/usr/bin/mv -f "

#Temporal Values
REPORTDATE=$(date '+%Y-%m-%d %H:%M:%S')
CURRENTYEAR=$(date +'%Y')
CURRENTMONTH=$(date +'%b')
CURRENTDAY=$(date +"%e")

# Run pflogsumm
$PFLOGSUMMBIN $PFLOGSUMMOPTIONS  -e $LOGFILELOCATION > /tmp/mailreport

#======================================================
# Extract Sections from PFLOGSUMM
#======================================================
sed -n '/^Grand Totals/,/^Per-Day/p;/^Per-Day/q' /tmp/mailreport | sed -e '1,4d' | sed -e :a -e '$d;N;2,3ba' -e 'P;D' | sed '/^$/d' > /tmp/GrandTotals
sed -n '/^Per-Day Traffic Summary/,/^Per-Hour/p;/^Per-Hour/q' /tmp/mailreport | sed -e '1,4d' | sed -e :a -e '$d;N;2,2ba' -e 'P;D'  > /tmp/PerDayTrafficSummary
sed -n '/^Per-Hour Traffic Daily Average/,/^Host\//p;/^Host\//q' /tmp/mailreport | sed -e '1,4d' | sed -e :a -e '$d;N;2,2ba' -e 'P;D'  > /tmp/PerHourTrafficDailyAverage
sed -n '/^Host\/Domain Summary\: Message Delivery/,/^Host\/Domain Summary\: Messages Received/p;/^Host\/Domain Summary\: Messages Received/q' /tmp/mailreport | sed -e '1,4d' | sed -e :a -e '$d;N;2,2ba' -e 'P;D'  > /tmp/HostDomainSummaryMessageDelivery
sed -n '/^Host\/Domain Summary\: Messages Received/,/^Senders by message count/p;/^Senders by message count/q' /tmp/mailreport | sed -e '1,4d' | sed -e :a -e '$d;N;2,2ba' -e 'P;D'  > /tmp/HostDomainSummaryMessagesReceived
sed -n '/^Senders by message count/,/^Recipients by message count/p;/^Recipients by message count/q' /tmp/mailreport | sed -e '1,2d' | sed -e :a -e '$d;N;2,2ba' -e 'P;D' | sed '/^$/d' > /tmp/Sendersbymessagecount
sed -n '/^Recipients by message count/,/^Senders by message size/p;/^Senders by message size/q' /tmp/mailreport | sed -e '1,2d' | sed -e :a -e '$d;N;2,2ba' -e 'P;D' | sed '/^$/d' > /tmp/Recipientsbymessagecount
sed -n '/^Senders by message size/,/^Recipients by message size/p;/^Recipients by message size/q' /tmp/mailreport | sed -e '1,2d' | sed -e :a -e '$d;N;2,2ba' -e 'P;D' | sed '/^$/d' > /tmp/Sendersbymessagesize
sed -n '/^Recipients by message size/,/^Messages with no size data/p;/^Messages with no size data/q' /tmp/mailreport | sed -e '1,2d' | sed -e :a -e '$d;N;2,2ba' -e 'P;D' | sed '/^$/d' > /tmp/Recipientsbymessagesize
sed -n '/^Messages with no size data/,/^message deferral detail/p;/^message deferral detail/q' /tmp/mailreport | sed -e '1,2d' | sed -e :a -e '$d;N;2,2ba' -e 'P;D' | sed '/^$/d' > /tmp/Messageswithnosizedata
sed -n '/^message deferral detail/,/^message bounce detail (by relay)/p;/^message bounce detail (by relay)/q' /tmp/mailreport | sed -e '1,2d' | sed -e :a -e '$d;N;2,2ba' -e 'P;D' | sed '/^$/d' > /tmp/messagedeferraldetail
sed -n '/^message bounce detail (by relay)/,/^message reject detail/p;/^message reject detail/q' /tmp/mailreport | sed -e '1,2d' | sed -e :a -e '$d;N;2,2ba' -e 'P;D' | sed '/^$/d' > /tmp/messagebouncedetaibyrelay
sed -n '/^Warnings/,/^Fatal Errors/p;/^Fatal Errors/q' /tmp/mailreport | sed -e '1,2d' | sed -e :a -e '$d;N;2,2ba' -e 'P;D' | sed '/^$/d' > /tmp/warnings
sed -n '/^Fatal Errors/,/^Master daemon messages/p;/^Master daemon messages/q' /tmp/mailreport | sed -e '1,2d' | sed -e :a -e '$d;N;2,2ba' -e 'P;D' | sed '/^$/d' > /tmp/FatalErrors

#======================================================
# Extract Information into variables -> Grand Totals
#======================================================
export ReceivedEmail=$(awk '$2=="received" {print $1}'  /tmp/GrandTotals)
export DeliveredEmail=$(awk '$2=="delivered" {print $1}'  /tmp/GrandTotals)
export ForwardedEmail=$(awk '$2=="forwarded" {print $1}'  /tmp/GrandTotals)
export DeferredEmailCount=$(awk '$2=="deferred" {print $1}'  /tmp/GrandTotals)
export DeferredEmailDeferralsCount=$(awk '$2=="deferred" {print $3" "$4}'  /tmp/GrandTotals)
export BouncedEmail=$(awk '$2=="bounced" {print $1}'  /tmp/GrandTotals)
export RejectedEmailCount=$(awk '$2=="rejected" {print $1}'  /tmp/GrandTotals)
export RejectedEmailPercentage=$(awk '$2=="rejected" {print $3}'  /tmp/GrandTotals)
export RejectedWarningsEmail=$(sed 's/reject warnings/rejectwarnings/' /tmp/GrandTotals | awk '$2=="rejectwarnings" {print $1}')
export HeldEmail=$(awk '$2=="held" {print $1}'  /tmp/GrandTotals)
export DiscardedEmailCount=$(awk '$2=="discarded" {print $1}'  /tmp/GrandTotals)
export DiscardedEmailPercentage=$(awk '$2=="discarded" {print $3}'  /tmp/GrandTotals)
export BytesReceivedEmail=$(sed 's/bytes received/bytesreceived/' /tmp/GrandTotals | awk '$2=="bytesreceived" {print $1}'|sed 's/[^0-9]*//g' )
export BytesDeliveredEmail=$(sed 's/bytes delivered/bytesdelivered/' /tmp/GrandTotals | awk '$2=="bytesdelivered" {print $1}'|sed 's/[^0-9]*//g')
export SendersEmail=$(awk '$2=="senders" {print $1}'  /tmp/GrandTotals)
export SendingHostsDomainsEmail=$(sed 's/sending hosts\/domains/sendinghostsdomains/' /tmp/GrandTotals | awk '$2=="sendinghostsdomains" {print $1}')
export RecipientsEmail=$(awk '$2=="recipients" {print $1}'  /tmp/GrandTotals)
export RecipientHostsDomainsEmail=$(sed 's/recipient hosts\/domains/recipienthostsdomains/' /tmp/GrandTotals | awk '$2=="recipienthostsdomains" {print $1}')

#======================================================
# Process Tables into HTML Rows
#======================================================
# Per-Day Traffic Summary
while IFS= read -r var; do
    echo "<tr>$(echo "$var" | awk '{print "<td>"$1" "$2" "$3"</td>""<td>"$4"</td>""<td>"$5"</td>""<td>"$6"</td>""<td>"$7"</td>""<td>"$8"</td>"}')</tr>"
done < /tmp/PerDayTrafficSummary > /tmp/PerDayTrafficSummary.html

# Per-Hour Traffic Daily Average
while IFS= read -r var; do
    echo "<tr>$(echo "$var" | awk '{print "<td>"$1"</td>""<td>"$2"</td>""<td>"$3"</td>""<td>"$4"</td>""<td>"$5"</td>""<td>"$6"</td>"}')</tr>"
done < /tmp/PerHourTrafficDailyAverage > /tmp/PerHourTrafficDailyAverage.html

# Host/Domain Summary Message Delivery
while IFS= read -r var; do
    echo "<tr>$(echo "$var" | awk '{print "<td>"$1"</td>""<td>"$2"</td>""<td>"$3"</td>""<td>"$4" "$5"</td>""<td>"$6" "$7"</td>""<td>"$8"</td>" }')</tr>"
done < /tmp/HostDomainSummaryMessageDelivery > /tmp/HostDomainSummaryMessageDelivery.html

# Host/Domain Summary Messages Received
while IFS= read -r var; do
    echo "<tr>$(echo "$var" | awk '{print "<td>"$1"</td>""<td>"$2"</td>""<td>"$3"</td>"}')</tr>"
done < /tmp/HostDomainSummaryMessagesReceived > /tmp/HostDomainSummaryMessagesReceived.html

# Senders by Message Count
while IFS= read -r var; do
    echo "<tr>$(echo "$var" | awk '{print "<td>"$1"</td>""<td>"$2"</td>"}')</tr>"
done < /tmp/Sendersbymessagecount > /tmp/Sendersbymessagecount.html

# Recipients by Message Count
while IFS= read -r var; do
    echo "<tr>$(echo "$var" | awk '{print "<td>"$1"</td>""<td>"$2"</td>"}')</tr>"
done < /tmp/Recipientsbymessagecount > /tmp/Recipientsbymessagecount.html

# Senders by Message Size
while IFS= read -r var; do
    echo "<tr>$(echo "$var" | awk '{print "<td>"$1"</td>""<td>"$2"</td>"}')</tr>"
done < /tmp/Sendersbymessagesize > /tmp/Sendersbymessagesize.html

# Recipients by message size
while IFS= read -r var; do
    echo "<tr>$(echo "$var" | awk '{print "<td>"$1"</td>""<td>"$2"</td>"}')</tr>"
done < /tmp/Recipientsbymessagesize > /tmp/Recipientsbymessagesize.html

# Messages with no size data
while IFS= read -r var; do
    echo "<tr>$(echo "$var" | awk '{print "<td>"$1"</td>""<td>"$2"</td>"}')</tr>"
done < /tmp/Messageswithnosizedata > /tmp/Messageswithnosizedata.html

#======================================================
# Export Variables and Translations for envsubst
#======================================================
export LANGUAGE ACTIVEHOSTNAME REPORTDATE CURRENTYEAR CURRENTMONTH CURRENTDAY
export $(compgen -v L_)

export PerDayTrafficSummaryTable=$(cat /tmp/PerDayTrafficSummary.html)
export PerHourTrafficDailyAverageTable=$(cat /tmp/PerHourTrafficDailyAverage.html)
export HostDomainSummaryMessageDeliveryTable=$(cat /tmp/HostDomainSummaryMessageDelivery.html)
export HostDomainSummaryMessagesReceived=$(cat /tmp/HostDomainSummaryMessagesReceived.html)
export Sendersbymessagecount=$(cat /tmp/Sendersbymessagecount.html)
export RecipientsbyMessageCount=$(cat /tmp/Recipientsbymessagecount.html)
export SendersbyMessageSize=$(cat /tmp/Sendersbymessagesize.html)
export Recipientsbymessagesize=$(cat /tmp/Recipientsbymessagesize.html)
export Messageswithnosizedata=$(cat /tmp/Messageswithnosizedata.html)
export MessageDeferralDetail=$(cat /tmp/messagedeferraldetail)
export MessageBounceDetailbyrelay=$(cat /tmp/messagebouncedetaibyrelay)
export MailWarnings=$(cat /tmp/warnings)
export MailFatalErrors=$(cat /tmp/FatalErrors)

# Generate the Report HTML
envsubst < "${SCRIPTDIR}/Report_Template.html" > "$HTMLOUTPUTDIR/data/$CURRENTYEAR-$CURRENTMONTH-$CURRENTDAY.html"

#======================================================
# Generate Dashboard Index
#======================================================
# Count reports
JanRPTCount=$(find $HTMLOUTPUTDIR/data -maxdepth 1 -type f -name "*Jan*.html" | wc -l)
FebRPTCount=$(find $HTMLOUTPUTDIR/data -maxdepth 1 -type f -name "*Feb*.html" | wc -l)
MarRPTCount=$(find $HTMLOUTPUTDIR/data -maxdepth 1 -type f -name "*Mar*.html" | wc -l)
AprRPTCount=$(find $HTMLOUTPUTDIR/data -maxdepth 1 -type f -name "*Apr*.html" | wc -l)
MayRPTCount=$(find $HTMLOUTPUTDIR/data -maxdepth 1 -type f -name "*May*.html" | wc -l)
JunRPTCount=$(find $HTMLOUTPUTDIR/data -maxdepth 1 -type f -name "*Jun*.html" | wc -l)
JulRPTCount=$(find $HTMLOUTPUTDIR/data -maxdepth 1 -type f -name "*Jul*.html" | wc -l)
AugRPTCount=$(find $HTMLOUTPUTDIR/data -maxdepth 1 -type f -name "*Aug*.html" | wc -l)
SepRPTCount=$(find $HTMLOUTPUTDIR/data -maxdepth 1 -type f -name "*Sep*.html" | wc -l)
OctRPTCount=$(find $HTMLOUTPUTDIR/data -maxdepth 1 -type f -name "*Oct*.html" | wc -l)
NovRPTCount=$(find $HTMLOUTPUTDIR/data -maxdepth 1 -type f -name "*Nov*.html" | wc -l)
DecRPTCount=$(find $HTMLOUTPUTDIR/data -maxdepth 1 -type f -name "*Dec*.html" | wc -l)

# Build Month Cards
MONTH_CARDS=""
months=("Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec")
for m in "${months[@]}"; do
    count_var="${m}RPTCount"
    count=${!count_var}
    label_var="L_${m^^}"
    label=${!label_var}
    lower_m=$(echo "$m" | tr '[:upper:]' '[:lower:]')
    
    MONTH_CARDS+="
    <div class='col-md-4 col-lg-3 py-2'>
        <div class='card h-100 shadow-sm'>
            <div class='card-body d-flex flex-column'>
                <h5 class='month-header'>$label</h5>
                <div class='mb-3'>
                    <span class='badge bg-primary rounded-pill'>$count ${L_REPORT_COUNT}</span>
                </div>
                <div class='mt-auto'>
                    <button class='btn btn-outline-primary btn-sm w-100' type='button' data-bs-toggle='collapse' data-bs-target='#${m}Card'>
                        <i class='fa-solid fa-folder-open me-2'></i>${L_VIEW_REPORTS}
                    </button>
                    <div id='${m}Card' class='collapse mt-2'>
                        <div class='list-group list-group-flush ${lower_m}List pt-2' style='max-height: 200px; overflow-y: auto;'>
                            <!-- Dynamic Item List-->
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>"
done

export MONTH_CARDS

# Generate Dashboard
envsubst < "${SCRIPTDIR}/index_dashboard_template.html" > "$HTMLOUTPUTDIR/$HTMLOUTPUT_INDEXDASHBOARD"

#======================================================
# Update Clickable Index Files (imported dynamicly)
#======================================================
rm -f $HTMLOUTPUTDIR/data/*_rpt.html

for filename in $HTMLOUTPUTDIR/data/[0-9]*.html; do
    [ -e "$filename" ] || continue
    filenameWithExtOnly="${filename##*/}"
    filenameWithoutExtension="${filenameWithExtOnly%.*}"
 
    case $filenameWithExtOnly in
        *Jan* ) echo "<a href=\"data/${filenameWithoutExtension}.html\" class=\"list-group-item list-group-item-action\">$filenameWithoutExtension</a>" >> $HTMLOUTPUTDIR/data/jan_rpt.html ;;
        *Feb* ) echo "<a href=\"data/${filenameWithoutExtension}.html\" class=\"list-group-item list-group-item-action\">$filenameWithoutExtension</a>" >> $HTMLOUTPUTDIR/data/feb_rpt.html ;;
        *Mar* ) echo "<a href=\"data/${filenameWithoutExtension}.html\" class=\"list-group-item list-group-item-action\">$filenameWithoutExtension</a>" >> $HTMLOUTPUTDIR/data/mar_rpt.html ;;
        *Apr* ) echo "<a href=\"data/${filenameWithoutExtension}.html\" class=\"list-group-item list-group-item-action\">$filenameWithoutExtension</a>" >> $HTMLOUTPUTDIR/data/apr_rpt.html ;;
        *May* ) echo "<a href=\"data/${filenameWithoutExtension}.html\" class=\"list-group-item list-group-item-action\">$filenameWithoutExtension</a>" >> $HTMLOUTPUTDIR/data/may_rpt.html ;;
        *Jun* ) echo "<a href=\"data/${filenameWithoutExtension}.html\" class=\"list-group-item list-group-item-action\">$filenameWithoutExtension</a>" >> $HTMLOUTPUTDIR/data/jun_rpt.html ;;
        *Jul* ) echo "<a href=\"data/${filenameWithoutExtension}.html\" class=\"list-group-item list-group-item-action\">$filenameWithoutExtension</a>" >> $HTMLOUTPUTDIR/data/jul_rpt.html ;;
        *Aug* ) echo "<a href=\"data/${filenameWithoutExtension}.html\" class=\"list-group-item list-group-item-action\">$filenameWithoutExtension</a>" >> $HTMLOUTPUTDIR/data/aug_rpt.html ;;
        *Sep* ) echo "<a href=\"data/${filenameWithoutExtension}.html\" class=\"list-group-item list-group-item-action\">$filenameWithoutExtension</a>" >> $HTMLOUTPUTDIR/data/sep_rpt.html ;;
        *Oct* ) echo "<a href=\"data/${filenameWithoutExtension}.html\" class=\"list-group-item list-group-item-action\">$filenameWithoutExtension</a>" >> $HTMLOUTPUTDIR/data/oct_rpt.html ;;
        *Nov* ) echo "<a href=\"data/${filenameWithoutExtension}.html\" class=\"list-group-item list-group-item-action\">$filenameWithoutExtension</a>" >> $HTMLOUTPUTDIR/data/nov_rpt.html ;;
        *Dec* ) echo "<a href=\"data/${filenameWithoutExtension}.html\" class=\"list-group-item list-group-item-action\">$filenameWithoutExtension</a>" >> $HTMLOUTPUTDIR/data/dec_rpt.html ;;
    esac  
done

# Clean UP
rm -f /tmp/mailreport /tmp/GrandTotals /tmp/PerDayTrafficSummary* /tmp/PerHourTrafficDailyAverage* /tmp/HostDomainSummary* /tmp/Sendersby* /tmp/Recipientsby* /tmp/Messageswithnosizedata* /tmp/messagedeferraldetail /tmp/messagebouncedetaibyrelay /tmp/warnings /tmp/FatalErrors
