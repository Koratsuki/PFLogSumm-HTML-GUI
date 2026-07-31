detect_mail_log() {
    if [ -f "/var/log/maillog" ]; then
        echo "/var/log/maillog"
    elif [ -f "/var/log/mail.log" ]; then
        echo "/var/log/mail.log"
    elif [ -f "/etc/os-release" ]; then
        if grep -qi "ID_LIKE.*rhel\|ID_LIKE.*fedora\|ID_LIKE.*centos\|ID=rhel\|ID=centos\|ID=fedora\|ID=almalinux\|ID=rocky" /etc/os-release 2>/dev/null; then
            echo "/var/log/maillog"
        elif grep -qi "ID_LIKE.*debian\|ID=debian\|ID=ubuntu" /etc/os-release 2>/dev/null; then
            echo "/var/log/mail.log"
        else
            echo "/var/log/mail.log"
        fi
    elif [ -f "/etc/redhat-release" ] || [ -f "/etc/centos-release" ] || [ -f "/etc/fedora-release" ]; then
        echo "/var/log/maillog"
    elif [ -f "/etc/debian_version" ]; then
        echo "/var/log/mail.log"
    else
        echo "/var/log/mail.log"
    fi
}

detect_pflogsumm() {
    for path in "/usr/sbin/pflogsumm" "/usr/bin/pflogsumm" "/usr/sbin/pflogsumm.pl" "/usr/bin/pflogsumm.pl"; do
        if [ -x "$path" ]; then
            echo "$path"
            return
        fi
    done
    command -v pflogsumm 2>/dev/null || echo "/usr/sbin/pflogsumm"
}
