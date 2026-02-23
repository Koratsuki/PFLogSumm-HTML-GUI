# PFLogSumm-HTML-GUI

A modern, responsive Bash shell script that generates beautiful Postfix statistics HTML reports using `pflogsumm` as the backend.

The tool refines raw `pflogsumm` output into a premium, interactive dashboard with dynamic graphs, multi-language support, and a mobile-friendly interface.

## 🚀 Key Features

- **Modern UI**: Powered by **Bootstrap 5**, providing a sleek, responsive dashboard and detailed report views.
- **Interactive Graphs**: Visualizes traffic trends (Per-Day and Per-Hour) using **Highcharts**.
- **Multi-Language (i18n)**: Fully supports **English** and **Spanish** out of the box. Easily extendable to other languages.
- **Dynamic Dashboard**: Auto-generates a monthly overview for quick navigation between reports.
- **Lightweight & Portable**: Orchestrated entirely in Bash, using external templates for easy maintenance.

## 📸 Screenshots

![Dashboard Overview](Screenshot1.png)
*Modern Dashboard with Monthly Report Navigation*

![Detailed Report](Screenshot2.png)
*Detailed Statistics with Status Cards and Interactive Graphs*

## 🛠 Requirements

- **pflogsumm**: The primary backend for log analysis.
- **envsubst**: Used for template variable replacement (usually part of `gettext-base` or `gettext`).

### Installation for RedHat/CentOS/Fedora

```bash
yum -y install postfix-perl-scripts gettext
```

### Installation for Ubuntu/Debian

```bash
apt-get update
apt-get -y install pflogsumm gettext-base
```

## 📥 Project Installation

Clone the repository to a location of your choice:

```bash
cd /opt
git clone https://github.com/RiaanPretoriusSA/PFLogSumm-HTML-GUI.git
```

### Keeping it Updated

If you installed via Git, you can easily pull the latest improvements:

```bash
cd /opt/PFLogSumm-HTML-GUI
git pull
```

## ⚙️ Configuration

The script uses a configuration file located at `/etc/pflogsumui.conf`. Running the script for the first time will automatically generate a default configuration if it does not exist.

### Example Configuration (`/etc/pflogsumui.conf`)

```bash
# PFLOGSUMUI CONFIGURATION

## Postfix Log Location
LOGFILELOCATION="/var/log/mail.log"

## pflogsumm binary and options
PFLOGSUMMBIN="/usr/sbin/pflogsumm"
PFLOGSUMMOPTIONS=" --verbose_msg_detail --zero_fill "

## HTML Output Settings
HTMLOUTPUTDIR="/var/www/html/"
HTMLOUTPUT_INDEXDASHBOARD="index.html"

## Script Directory (Required for i18n and Templates)
SCRIPTDIR="/opt/PFLogSumm-HTML-GUI"

## Selected Language (en | es)
LANGUAGE="en"
```

### Internationalization (i18n)

The tool supports multiple languages. Language files are stored in the `languages/` directory.

- To switch languages permanently, update `LANGUAGE` in your `/etc/pflogsumui.conf`.
- To override the language for a single run, prefix the command with the `LANGUAGE` variable:

```bash
# Run in Spanish
LANGUAGE=es /opt/PFLogSumm-HTML-GUI/pflogsummUIReport.sh

# Run in English
LANGUAGE=en /opt/PFLogSumm-HTML-GUI/pflogsummUIReport.sh
```

> [!NOTE]
> If `LANGUAGE` is explicitly set in `/etc/pflogsumui.conf`, it will overwrite the command-line environment variable. To allow command-line overrides, ensure the `LANGUAGE` line in the config file is commented out or removed.
> [!TIP]
> To add a new language, copy `languages/en.sh` to a new file (e.g., `languages/fr.sh`) and translate the definitions.

## ⏲️ Automation (Crontab)

To keep your dashboard up to date, schedule the script to run daily via Cron. Since `pflogsumm` usually reports on the current day's logs, running it just before midnight is recommended.

**Note**: The script requires root or a user with write access to the web directory and read access to the mail.log.

### Example Crontab (Runs daily at 11:50 PM)

```bash
50 23 * * * /opt/PFLogSumm-HTML-GUI/pflogsummUIReport.sh >/dev/null 2>&1
```

## 🛡️ Security Note

> [!WARNING]
> The generated reports expose end-user email addresses. **You MUST password-protect the directory** where these files are hosted (e.g., using `.htaccess` or your web server's authentication mechanism).

## 🏢 Zimbra Integration

If you are using Zimbra, it includes its own `pflogsumm` version. You can point the script to it by creating a symlink:

```bash
ln -s /opt/zimbra/common/bin/pflogsumm.pl /usr/sbin/pflogsumm
```

---
*Created by [Riaan Pretorius](mailto:pretorius.riaan@gmail.com). Modernized and enhanced by the community.*
