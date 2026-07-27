#!/usr/bin/env bash
#=====================================================================================================================
#   DESCRIPTION  Generating a stand alone web report for postfix log files, 
#                Runs on all Linux platforms with postfix installed
#   AUTHOR       Riaan Pretorius <pretorius.riaan@gmail.com>
#                Modernized and i18n added by Antigravity
#=====================================================================================================================

set -euo pipefail

SCRIPTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source library modules
. "${SCRIPTDIR}/lib/logging.sh"
. "${SCRIPTDIR}/lib/detect.sh"
. "${SCRIPTDIR}/lib/extract.sh"
. "${SCRIPTDIR}/lib/render.sh"

#======================================================
# Configuration
#======================================================
PFSYSCONFDIR="${PFSYSCONFDIR:-/etc}"
CONFIG_FILE="${PFSYSCONFDIR}/pflogsumui.conf"

#Create Blank Config File if it does not exist
if [ ! -f "$CONFIG_FILE" ]; then
    log_info "Creating default configuration at $CONFIG_FILE"
    DETECTED_LOG=$(detect_mail_log)
    tee "$CONFIG_FILE" <<EOF
#PFLOGSUMUI CONFIG

##  Postfix Log Location
LOGFILELOCATION="${DETECTED_LOG}"

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
    log_info "Default configuration written to $CONFIG_FILE"
    echo "Please verify the paths in $CONFIG_FILE before running again"
    exit 0
fi

#Load Config File
log_info "Loading configuration from $CONFIG_FILE"
. "$CONFIG_FILE"

# Default Language if not set
LANGUAGE=${LANGUAGE:-"en"}

# Load Language File
if [ -f "${SCRIPTDIR}/languages/${LANGUAGE}.sh" ]; then
    . "${SCRIPTDIR}/languages/${LANGUAGE}.sh"
    log_info "Loaded language: $LANGUAGE"
else
    log_warn "Language file ${SCRIPTDIR}/languages/${LANGUAGE}.sh not found, defaulting to English"
    . "${SCRIPTDIR}/languages/en.sh"
fi

#Create the Cache Directory if it does not exist
if [ ! -d "$HTMLOUTPUTDIR/data" ]; then
    mkdir -p "$HTMLOUTPUTDIR/data"
fi

#======================================================
# Environment
#======================================================
ACTIVEHOSTNAME=$(cat /proc/sys/kernel/hostname)
REPORTDATE=$(date '+%Y-%m-%d %H:%M:%S')
CURRENTYEAR=$(date +'%Y')
CURRENTMONTH=$(date +'%b')
CURRENTDAY=$(date +"%e")

#======================================================
# Validate inputs
#======================================================
log_info "Validating configuration..."

if [ ! -f "$LOGFILELOCATION" ]; then
    log_warn "Log file not found: $LOGFILELOCATION"
    DETECTED_LOG=$(detect_mail_log)
    if [ "$DETECTED_LOG" != "$LOGFILELOCATION" ] && [ -f "$DETECTED_LOG" ]; then
        log_info "Auto-detected mail log: $DETECTED_LOG"
        LOGFILELOCATION="$DETECTED_LOG"
    else
        log_error "No mail log found at $LOGFILELOCATION or $DETECTED_LOG"
        log_error "Please set LOGFILELOCATION in $CONFIG_FILE"
        exit 1
    fi
fi

PFLOGSUMM_BIN="${PFLOGSUMMBIN%% *}"
if ! command -v "$PFLOGSUMM_BIN" &>/dev/null; then
    log_error "pflogsumm binary not found: $PFLOGSUMM_BIN"
    exit 1
fi

if [ ! -d "$HTMLOUTPUTDIR" ]; then
    log_error "Output directory does not exist: $HTMLOUTPUTDIR"
    exit 1
fi

# Create temp directory
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

#======================================================
# Run pflogsumm
#======================================================
log_info "Running pflogsumm on $LOGFILELOCATION..."
if ! $PFLOGSUMMBIN $PFLOGSUMMOPTIONS -e "$LOGFILELOCATION" > "$TMPDIR/mailreport"; then
    log_error "pflogsumm failed on $LOGFILELOCATION"
    exit 1
fi
log_info "pflogsumm completed successfully"

#======================================================
# Extract sections and parse data
#======================================================
extract_all_sections "$TMPDIR/mailreport" "$TMPDIR"
parse_grand_totals "$TMPDIR"
generate_all_tables "$TMPDIR"

#======================================================
# Export and Render Report HTML
#======================================================
export LANGUAGE ACTIVEHOSTNAME REPORTDATE CURRENTYEAR CURRENTMONTH CURRENTDAY
export $(compgen -v L_)

export_table_data "$TMPDIR"

if ! render_report "$SCRIPTDIR" "$HTMLOUTPUTDIR/data/$CURRENTYEAR-$CURRENTMONTH-$CURRENTDAY.html"; then
    log_error "Failed to generate report HTML"
    exit 1
fi

#======================================================
# Generate Dashboard Index
#======================================================
log_info "Generating dashboard..."

count_monthly_reports "$HTMLOUTPUTDIR/data"
MONTH_CARDS=$(build_month_cards)

if ! render_dashboard "$SCRIPTDIR" "$HTMLOUTPUTDIR/$HTMLOUTPUT_INDEXDASHBOARD" "$MONTH_CARDS"; then
    log_error "Failed to generate dashboard HTML"
    exit 1
fi

#======================================================
# Build month navigation links
#======================================================
build_month_links "$HTMLOUTPUTDIR/data"

log_info "Report generated successfully: $HTMLOUTPUTDIR/data/$CURRENTYEAR-$CURRENTMONTH-$CURRENTDAY.html"
log_info "Dashboard updated: $HTMLOUTPUTDIR/$HTMLOUTPUT_INDEXDASHBOARD"
