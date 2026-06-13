# Extract sections from pflogsumm output and generate HTML tables
# Dependencies: lib/logging.sh
#
# NOTE: These sed pipelines are fragile — they depend on exact
# section header text from pflogsumm output. If pflogsumm
# changes its output format, these will break.

# Extract all sections from pflogsumm output into individual temp files
# Usage: extract_all_sections <mailreport_file> <tmpdir>
extract_all_sections() {
    local mailreport="$1"
    local tmpdir="$2"

    log_info "Extracting sections from pflogsumm output..."

    # Grand Totals
    sed -n '/^Grand Totals/,/^Per-Day/p;/^Per-Day/q' "$mailreport" \
        | sed -e '1,4d' \
        | sed -e :a -e '$d;N;2,3ba' -e 'P;D' \
        | sed '/^$/d' > "$tmpdir/GrandTotals"

    # Per-Day Traffic Summary
    sed -n '/^Per-Day Traffic Summary/,/^Per-Hour/p;/^Per-Hour/q' "$mailreport" \
        | sed -e '1,4d' \
        | sed -e :a -e '$d;N;2,2ba' -e 'P;D' > "$tmpdir/PerDayTrafficSummary"

    # Per-Hour Traffic Daily Average
    sed -n '/^Per-Hour Traffic Daily Average/,/^Host\//p;/^Host\//q' "$mailreport" \
        | sed -e '1,4d' \
        | sed -e :a -e '$d;N;2,2ba' -e 'P;D' > "$tmpdir/PerHourTrafficDailyAverage"

    # Host/Domain Summary: Message Delivery
    sed -n '/^Host\/Domain Summary\: Message Delivery/,/^Host\/Domain Summary\: Messages Received/p;/^Host\/Domain Summary\: Messages Received/q' "$mailreport" \
        | sed -e '1,4d' \
        | sed -e :a -e '$d;N;2,2ba' -e 'P;D' > "$tmpdir/HostDomainSummaryMessageDelivery"

    # Host/Domain Summary: Messages Received
    sed -n '/^Host\/Domain Summary\: Messages Received/,/^Senders by message count/p;/^Senders by message count/q' "$mailreport" \
        | sed -e '1,4d' \
        | sed -e :a -e '$d;N;2,2ba' -e 'P;D' > "$tmpdir/HostDomainSummaryMessagesReceived"

    # Senders by message count
    sed -n '/^Senders by message count/,/^Recipients by message count/p;/^Recipients by message count/q' "$mailreport" \
        | sed -e '1,2d' \
        | sed -e :a -e '$d;N;2,2ba' -e 'P;D' \
        | sed '/^$/d' > "$tmpdir/Sendersbymessagecount"

    # Recipients by message count
    sed -n '/^Recipients by message count/,/^Senders by message size/p;/^Senders by message size/q' "$mailreport" \
        | sed -e '1,2d' \
        | sed -e :a -e '$d;N;2,2ba' -e 'P;D' \
        | sed '/^$/d' > "$tmpdir/Recipientsbymessagecount"

    # Senders by message size
    sed -n '/^Senders by message size/,/^Recipients by message size/p;/^Recipients by message size/q' "$mailreport" \
        | sed -e '1,2d' \
        | sed -e :a -e '$d;N;2,2ba' -e 'P;D' \
        | sed '/^$/d' > "$tmpdir/Sendersbymessagesize"

    # Recipients by message size
    sed -n '/^Recipients by message size/,/^Messages with no size data/p;/^Messages with no size data/q' "$mailreport" \
        | sed -e '1,2d' \
        | sed -e :a -e '$d;N;2,2ba' -e 'P;D' \
        | sed '/^$/d' > "$tmpdir/Recipientsbymessagesize"

    # Messages with no size data
    sed -n '/^Messages with no size data/,/^message deferral detail/p;/^message deferral detail/q' "$mailreport" \
        | sed -e '1,2d' \
        | sed -e :a -e '$d;N;2,2ba' -e 'P;D' \
        | sed '/^$/d' > "$tmpdir/Messageswithnosizedata"

    # Message deferral detail
    sed -n '/^message deferral detail/,/^message bounce detail (by relay)/p;/^message bounce detail (by relay)/q' "$mailreport" \
        | sed -e '1,2d' \
        | sed -e :a -e '$d;N;2,2ba' -e 'P;D' \
        | sed '/^$/d' > "$tmpdir/messagedeferraldetail"

    # Message bounce detail (by relay)
    sed -n '/^message bounce detail (by relay)/,/^message reject detail/p;/^message reject detail/q' "$mailreport" \
        | sed -e '1,2d' \
        | sed -e :a -e '$d;N;2,2ba' -e 'P;D' \
        | sed '/^$/d' > "$tmpdir/messagebouncedetaibyrelay"

    # Warnings
    sed -n '/^Warnings/,/^Fatal Errors/p;/^Fatal Errors/q' "$mailreport" \
        | sed -e '1,2d' \
        | sed -e :a -e '$d;N;2,2ba' -e 'P;D' \
        | sed '/^$/d' > "$tmpdir/warnings"

    # Fatal Errors
    sed -n '/^Fatal Errors/,/^Master daemon messages/p;/^Master daemon messages/q' "$mailreport" \
        | sed -e '1,2d' \
        | sed -e :a -e '$d;N;2,2ba' -e 'P;D' \
        | sed '/^$/d' > "$tmpdir/FatalErrors"
}

# Parse Grand Totals into exported variables
# Usage: parse_grand_totals <tmpdir>
parse_grand_totals() {
    local tmpdir="$1"
    local gt="$tmpdir/GrandTotals"

    log_info "Parsing Grand Totals..."

    export ReceivedEmail=$(awk '$2=="received" {print $1}' "$gt")
    export DeliveredEmail=$(awk '$2=="delivered" {print $1}' "$gt")
    export ForwardedEmail=$(awk '$2=="forwarded" {print $1}' "$gt")
    export DeferredEmailCount=$(awk '$2=="deferred" {print $1}' "$gt")
    export DeferredEmailDeferralsCount=$(awk '$2=="deferred" {print $3" "$4}' "$gt")
    export BouncedEmail=$(awk '$2=="bounced" {print $1}' "$gt")
    export RejectedEmailCount=$(awk '$2=="rejected" {print $1}' "$gt")
    export RejectedEmailPercentage=$(awk '$2=="rejected" {print $3}' "$gt")
    export RejectedWarningsEmail=$(sed 's/reject warnings/rejectwarnings/' "$gt" | awk '$2=="rejectwarnings" {print $1}')
    export HeldEmail=$(awk '$2=="held" {print $1}' "$gt")
    export DiscardedEmailCount=$(awk '$2=="discarded" {print $1}' "$gt")
    export DiscardedEmailPercentage=$(awk '$2=="discarded" {print $3}' "$gt")
    export BytesReceivedEmail=$(sed 's/bytes received/bytesreceived/' "$gt" | awk '$2=="bytesreceived" {print $1}'|sed 's/[^0-9]*//g')
    export BytesDeliveredEmail=$(sed 's/bytes delivered/bytesdelivered/' "$gt" | awk '$2=="bytesdelivered" {print $1}'|sed 's/[^0-9]*//g')
    export SendersEmail=$(awk '$2=="senders" {print $1}' "$gt")
    export SendingHostsDomainsEmail=$(sed 's/sending hosts\/domains/sendinghostsdomains/' "$gt" | awk '$2=="sendinghostsdomains" {print $1}')
    export RecipientsEmail=$(awk '$2=="recipients" {print $1}' "$gt")
    export RecipientHostsDomainsEmail=$(sed 's/recipient hosts\/domains/recipienthostsdomains/' "$gt" | awk '$2=="recipienthostsdomains" {print $1}')
}

# Escape HTML special characters to prevent XSS
escape_html() {
    sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g'
}

# Generate HTML tables from extracted sections
# Usage: generate_all_tables <tmpdir>
generate_all_tables() {
    local tmpdir="$1"

    log_info "Generating HTML tables..."

    # Per-Day Traffic Summary (date spans cols 1-3, metrics are cols 4-8)
    while IFS= read -r var; do
        var=$(echo "$var" | escape_html)
        echo "<tr>$(echo "$var" | awk '{print "<td>"$1" "$2" "$3"</td>""<td>"$4"</td>""<td>"$5"</td>""<td>"$6"</td>""<td>"$7"</td>""<td>"$8"</td>"}')</tr>"
    done < "$tmpdir/PerDayTrafficSummary" > "$tmpdir/PerDayTrafficSummary.html"

    # Per-Hour Traffic Daily Average
    while IFS= read -r var; do
        var=$(echo "$var" | escape_html)
        echo "<tr>$(echo "$var" | awk '{print "<td>"$1"</td>""<td>"$2"</td>""<td>"$3"</td>""<td>"$4"</td>""<td>"$5"</td>""<td>"$6"</td>"}')</tr>"
    done < "$tmpdir/PerHourTrafficDailyAverage" > "$tmpdir/PerHourTrafficDailyAverage.html"

    # Host/Domain Summary Message Delivery
    while IFS= read -r var; do
        var=$(echo "$var" | escape_html)
        echo "<tr>$(echo "$var" | awk '{print "<td>"$1"</td>""<td>"$2"</td>""<td>"$3"</td>""<td>"$4" "$5"</td>""<td>"$6" "$7"</td>""<td>"$8"</td>" }')</tr>"
    done < "$tmpdir/HostDomainSummaryMessageDelivery" > "$tmpdir/HostDomainSummaryMessageDelivery.html"

    # Host/Domain Summary Messages Received
    while IFS= read -r var; do
        var=$(echo "$var" | escape_html)
        echo "<tr>$(echo "$var" | awk '{print "<td>"$1"</td>""<td>"$2"</td>""<td>"$3"</td>"}')</tr>"
    done < "$tmpdir/HostDomainSummaryMessagesReceived" > "$tmpdir/HostDomainSummaryMessagesReceived.html"

    # Senders by Message Count
    while IFS= read -r var; do
        var=$(echo "$var" | escape_html)
        echo "<tr>$(echo "$var" | awk '{print "<td>"$1"</td>""<td>"$2"</td>"}')</tr>"
    done < "$tmpdir/Sendersbymessagecount" > "$tmpdir/Sendersbymessagecount.html"

    # Recipients by Message Count
    while IFS= read -r var; do
        var=$(echo "$var" | escape_html)
        echo "<tr>$(echo "$var" | awk '{print "<td>"$1"</td>""<td>"$2"</td>"}')</tr>"
    done < "$tmpdir/Recipientsbymessagecount" > "$tmpdir/Recipientsbymessagecount.html"

    # Senders by Message Size
    while IFS= read -r var; do
        var=$(echo "$var" | escape_html)
        echo "<tr>$(echo "$var" | awk '{print "<td>"$1"</td>""<td>"$2"</td>"}')</tr>"
    done < "$tmpdir/Sendersbymessagesize" > "$tmpdir/Sendersbymessagesize.html"

    # Recipients by message size
    while IFS= read -r var; do
        var=$(echo "$var" | escape_html)
        echo "<tr>$(echo "$var" | awk '{print "<td>"$1"</td>""<td>"$2"</td>"}')</tr>"
    done < "$tmpdir/Recipientsbymessagesize" > "$tmpdir/Recipientsbymessagesize.html"

    # Messages with no size data
    while IFS= read -r var; do
        var=$(echo "$var" | escape_html)
        echo "<tr>$(echo "$var" | awk '{print "<td>"$1"</td>""<td>"$2"</td>"}')</tr>"
    done < "$tmpdir/Messageswithnosizedata" > "$tmpdir/Messageswithnosizedata.html"
}
