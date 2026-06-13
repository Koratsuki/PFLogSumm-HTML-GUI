# HTML template rendering utilities
# Dependencies: lib/logging.sh

# Export all table data for envsubst
# Usage: export_table_data <tmpdir>
export_table_data() {
    local tmpdir="$1"

    export PerDayTrafficSummaryTable=$(cat "$tmpdir/PerDayTrafficSummary.html")
    export PerHourTrafficDailyAverageTable=$(cat "$tmpdir/PerHourTrafficDailyAverage.html")
    export HostDomainSummaryMessageDeliveryTable=$(cat "$tmpdir/HostDomainSummaryMessageDelivery.html")
    export HostDomainSummaryMessagesReceived=$(cat "$tmpdir/HostDomainSummaryMessagesReceived.html")
    export Sendersbymessagecount=$(cat "$tmpdir/Sendersbymessagecount.html")
    export RecipientsbyMessageCount=$(cat "$tmpdir/Recipientsbymessagecount.html")
    export SendersbyMessageSize=$(cat "$tmpdir/Sendersbymessagesize.html")
    export Recipientsbymessagesize=$(cat "$tmpdir/Recipientsbymessagesize.html")
    export Messageswithnosizedata=$(cat "$tmpdir/Messageswithnosizedata.html")
    export MessageDeferralDetail=$(cat "$tmpdir/messagedeferraldetail")
    export MessageBounceDetailbyrelay=$(cat "$tmpdir/messagebouncedetaibyrelay")
    export MailWarnings=$(cat "$tmpdir/warnings")
    export MailFatalErrors=$(cat "$tmpdir/FatalErrors")
}

# Render report HTML using envsubst
# Usage: render_report <scriptdir> <output_path>
render_report() {
    local template="$1/Report_Template.html"
    local output="$2"

    log_info "Rendering report: $output"
    if ! envsubst < "$template" > "$output"; then
        log_error "Failed to render report template: $template"
        return 1
    fi
}

# Count reports per month in the output directory
# Usage: count_monthly_reports <data_dir> <var_prefix>
# Sets variables like ${prefix}JanRPTCount, ${prefix}FebRPTCount, etc.
count_monthly_reports() {
    local data_dir="$1"
    local prefix="${2:-}"

    for month in Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec; do
        export "${prefix}${month}RPTCount"=$(find "$data_dir" -maxdepth 1 -type f -name "*${month}*.html" | wc -l)
    done
}

# Build month cards HTML for the dashboard
# Usage: build_month_cards
# Relies on ${prefix}MonthRPTCount variables being set
build_month_cards() {
    local cards=""
    local prefix="${1:-}"

    for m in Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec; do
        local count_var="${prefix}${m}RPTCount"
        local count=${!count_var}
        local label_var="L_${m^^}"
        local label=${!label_var}
        local lower_m=$(echo "$m" | tr '[:upper:]' '[:lower:]')

        cards+="
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
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>"
    done

    echo "$cards"
}

# Render dashboard HTML using envsubst
# Usage: render_dashboard <scriptdir> <output_path>
render_dashboard() {
    local template="$1/index_dashboard_template.html"
    local output="$2"
    local month_cards="$3"

    export MONTH_CARDS="$month_cards"

    log_info "Rendering dashboard: $output"
    if ! envsubst < "$template" > "$output"; then
        log_error "Failed to render dashboard template: $template"
        return 1
    fi
}

# Build month link files for dynamic loading
# Usage: build_month_links <data_dir>
build_month_links() {
    local data_dir="$1"

    log_info "Building month navigation links..."
    rm -f "$data_dir/"*_rpt.html

    for filename in "$data_dir"/[0-9]*.html; do
        [ -e "$filename" ] || continue
        local basename="${filename##*/}"
        local name="${basename%.*}"

        case $basename in
            *Jan*) echo "<a href=\"data/${name}.html\" class=\"list-group-item list-group-item-action\">$name</a>" >> "$data_dir/jan_rpt.html" ;;
            *Feb*) echo "<a href=\"data/${name}.html\" class=\"list-group-item list-group-item-action\">$name</a>" >> "$data_dir/feb_rpt.html" ;;
            *Mar*) echo "<a href=\"data/${name}.html\" class=\"list-group-item list-group-item-action\">$name</a>" >> "$data_dir/mar_rpt.html" ;;
            *Apr*) echo "<a href=\"data/${name}.html\" class=\"list-group-item list-group-item-action\">$name</a>" >> "$data_dir/apr_rpt.html" ;;
            *May*) echo "<a href=\"data/${name}.html\" class=\"list-group-item list-group-item-action\">$name</a>" >> "$data_dir/may_rpt.html" ;;
            *Jun*) echo "<a href=\"data/${name}.html\" class=\"list-group-item list-group-item-action\">$name</a>" >> "$data_dir/jun_rpt.html" ;;
            *Jul*) echo "<a href=\"data/${name}.html\" class=\"list-group-item list-group-item-action\">$name</a>" >> "$data_dir/jul_rpt.html" ;;
            *Aug*) echo "<a href=\"data/${name}.html\" class=\"list-group-item list-group-item-action\">$name</a>" >> "$data_dir/aug_rpt.html" ;;
            *Sep*) echo "<a href=\"data/${name}.html\" class=\"list-group-item list-group-item-action\">$name</a>" >> "$data_dir/sep_rpt.html" ;;
            *Oct*) echo "<a href=\"data/${name}.html\" class=\"list-group-item list-group-item-action\">$name</a>" >> "$data_dir/oct_rpt.html" ;;
            *Nov*) echo "<a href=\"data/${name}.html\" class=\"list-group-item list-group-item-action\">$name</a>" >> "$data_dir/nov_rpt.html" ;;
            *Dec*) echo "<a href=\"data/${name}.html\" class=\"list-group-item list-group-item-action\">$name</a>" >> "$data_dir/dec_rpt.html" ;;
        esac
    done
}
