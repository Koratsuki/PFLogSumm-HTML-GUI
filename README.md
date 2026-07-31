# PFLogSumm-HTML-GUI

A modern, responsive Bash shell script that generates beautiful Postfix statistics HTML reports using `pflogsumm` as the backend.

The tool refines raw `pflogsumm` output into a premium, interactive dashboard with dynamic graphs, multi-language support, dark mode, table search, CSV export, and a mobile-friendly interface.

## Key Features

- **Modern UI**: Powered by **Bootstrap 5**, providing a sleek, responsive dashboard and detailed report views with automatic dark mode.
- **Interactive Graphs**: Visualizes traffic trends (Per-Day and Per-Hour) and email distribution using **Chart.js** (MIT license).
- **Multi-Language (i18n)**: Fully supports **English** and **Spanish** out of the box. Easily extendable to other languages.
- **Dynamic Dashboard**: Auto-generates a monthly overview with loading indicators and error handling for quick navigation between reports.
- **Table Search & CSV Export**: Filter large tables (senders, recipients, host/domain) in real-time and export any table as CSV.
- **Security**: Content-Security-Policy headers, Subresource Integrity (SRI) on all CDN assets, and HTML escaping to prevent XSS.
- **Modular Architecture**: Functionality split into `lib/logging.sh`, `lib/extract.sh`, and `lib/render.sh` for maintainability.
- **Docker-Ready**: Pre-configured with non-root user, healthchecks, and automatic daily report regeneration via cron.
- **Lightweight & Portable**: Orchestrated entirely in Bash, using `envsubst` for template rendering.
- **Distribution-Aware Log Detection**: Automatically detects whether your system uses `/var/log/maillog` (Red Hat family) or `/var/log/mail.log` (Debian family) — no manual path configuration needed. Falls back gracefully with auto-detection on first run and at validation time.

## Screenshots

![Dashboard Overview](Screenshot1.png)
*Modern Dashboard with Monthly Report Navigation*

![Detailed Report](Screenshot2.png)
*Detailed Statistics with Status Cards and Interactive Graphs*

## Requirements

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

## Project Installation

Clone the repository to a location of your choice:

```bash
cd /opt
git clone https://github.com/RiaanPretoriusSA/PFLogSumm-HTML-GUI.git
```

The script auto-detects its installation directory — no manual `SCRIPTDIR` configuration needed.

### Keeping it Updated

If you installed via Git, you can easily pull the latest improvements:

```bash
cd /opt/PFLogSumm-HTML-GUI
git pull
```

## Project Structure

```
PFLogSumm-HTML-GUI/
├── pflogsummUIReport.sh     # Main entry point (orchestrator)
├── pfstats.sh               # Quick CLI stats utility
├── lib/
│   ├── detect.sh            # Distribution-aware mail log detection
│   ├── logging.sh           # Logging with timestamps and levels
│   ├── extract.sh           # Section extraction and HTML table generation
│   └── render.sh            # Template rendering and dashboard building
├── languages/
│   ├── en.sh                # English translations
│   └── es.sh                # Spanish translations
├── Report_Template.html     # Detailed report HTML template
├── index_dashboard_template.html  # Dashboard index HTML template
├── Dockerfile               # Container build file
└── docker-compose.yml       # Container orchestration
```

## Configuration

The script uses a configuration file located at `/etc/pflogsumui.conf`. Running the script for the first time will automatically generate a default configuration if it does not exist.

### Automatic Log Path Detection

The mail log path is automatically detected based on your distribution:

| Distribution Family | Detected Path |
|---|---|
| Red Hat (RHEL, CentOS, Fedora, Rocky, AlmaLinux) | `/var/log/maillog` |
| Debian (Debian, Ubuntu) | `/var/log/mail.log` |

The detection logic (`lib/detect.sh`) works in three steps:
1. **Check existing files** — if `/var/log/maillog` or `/var/log/mail.log` already exists, that path is used.
2. **Read `/etc/os-release`** — identifies the distribution family when no log file exists yet.
3. **Fallback to legacy files** — checks `/etc/redhat-release`, `/etc/debian_version`, etc.

The `pflogsumm` binary path is also auto-detected, searching common locations (`/usr/sbin/pflogsumm`, `/usr/bin/pflogsumm`, `.pl` variants) and falling back to `command -v`.

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

> **Note**: `SCRIPTDIR` is auto-detected from the script's location. You only need to set it in the config if the auto-detection fails (e.g., in unusual system configurations).
> **Note**: `LOGFILELOCATION` is auto-detected during first-run config generation and re-detected at runtime if the configured path does not exist.

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
> To add a new language, copy `languages/en.sh` to a new file (e.g., `languages/fr.sh`) and translate the definitions. The following keys should be translated:
> - Month names (L_JAN through L_DEC)
> - UI strings (dashboard, report, table headers)
> - Search and CSV labels (L_SEARCH, L_EXPORT_CSV)

## Automation (Crontab)

To keep your dashboard up to date, schedule the script to run daily via Cron. Since `pflogsumm` usually reports on the current day's logs, running it just before midnight is recommended.

**Note**: The script requires root or a user with write access to the web directory and read access to the mail.log.

### Example Crontab (Runs daily at 11:50 PM)

```bash
50 23 * * * /opt/PFLogSumm-HTML-GUI/pflogsummUIReport.sh >/dev/null 2>&1
```

## Docker

A Dockerfile and docker-compose.yml are provided for containerized deployment.

### Building and Running

```bash
docker-compose up -d
```

This starts an Apache web server on port 8080 serving the generated reports. The container includes:

- **Non-root user** (`pflogsumm`) for report generation
- **Cron** configured to regenerate reports daily at 11:50 PM
- **Healthcheck** that verifies Apache is responding every 30 seconds
- **Auto-restart** via `restart: unless-stopped`

### Configuration

Mount your Postfix mail log to `/var/log/mail.log` in the container:

```yaml
volumes:
  - /var/log/mail.log:/var/log/mail.log
```

Set `REGENERATE_REPORTS=true` to force report generation on every container start.

## Security

> [!WARNING]
> The generated reports expose end-user email addresses. **You MUST password-protect the directory** where these files are hosted (e.g., using `.htaccess` or your web server's authentication mechanism).

Additional security measures implemented:

- **Content-Security-Policy (CSP)**: Both templates include CSP meta tags restricting scripts and styles to known CDN origins.
- **Subresource Integrity (SRI)**: All CDN-loaded assets include `integrity` hashes to prevent tampering.
- **HTML Escaping**: All dynamic table values are HTML-escaped to prevent XSS attacks.
- **Non-root Container**: The Docker container runs report generation as an unprivileged user.

## Logging

The script outputs timestamped log messages at three levels:

| Level | Prefix | Output |
|---|---|---|
| INFO | `[timestamp] [INFO]` | stdout (default) |
| WARN | `[timestamp] [WARN]` | stderr |
| ERROR | `[timestamp] [ERROR]` | stderr |

To suppress INFO messages:

```bash
LOG_LEVEL=1 ./pflogsummUIReport.sh
```

## Zimbra Integration

If you are using Zimbra, it includes its own `pflogsumm` version. You can point the script to it by creating a symlink:

```bash
ln -s /opt/zimbra/common/bin/pflogsumm.pl /usr/sbin/pflogsumm
```

---

*Created by [Riaan Pretorius](mailto:pretorius.riaan@gmail.com). Modernized and enhanced by the community.*
