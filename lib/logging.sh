# Logging utilities
# Usage: source lib/logging.sh
# Levels: LOG_LEVEL_INFO (default), LOG_LEVEL_WARN, LOG_LEVEL_ERROR

LOG_LEVEL_INFO=0
LOG_LEVEL_WARN=1
LOG_LEVEL_ERROR=2

: "${LOG_LEVEL:=0}"

log_info() {
    if [ "$LOG_LEVEL" -le "$LOG_LEVEL_INFO" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $*"
    fi
}

log_warn() {
    if [ "$LOG_LEVEL" -le "$LOG_LEVEL_WARN" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARN] $*" >&2
    fi
}

log_error() {
    if [ "$LOG_LEVEL" -le "$LOG_LEVEL_ERROR" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $*" >&2
    fi
}
