FROM debian:bookworm-slim

# Instalar dependencias
RUN apt-get update && apt-get install -y \
    pflogsumm \
    gettext-base \
    apache2 \
    cron \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Crear usuario no-root para generación de reportes
RUN useradd -r -m -d /opt/PFLogSumm-HTML-GUI -s /usr/sbin/nologin pflogsumm

# Crear directorios necesarios
RUN mkdir -p /var/www/html/data /etc

# Crear el archivo de configuración con rutas correctas para el contenedor
RUN tee /etc/pflogsumui.conf > /dev/null <<EOF
#PFLOGSUMUI CONFIG

##  Postfix Log Location
LOGFILELOCATION="/var/log/mail.log"

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

# Copiar el proyecto (primero scripts, luego templates para cache óptimo)
COPY lib/ /opt/PFLogSumm-HTML-GUI/lib/
COPY languages/ /opt/PFLogSumm-HTML-GUI/languages/
COPY *.sh *.html /opt/PFLogSumm-HTML-GUI/

# Asignar permisos
RUN chown -R pflogsumm:pflogsumm /opt/PFLogSumm-HTML-GUI && \
    chown -R pflogsumm:pflogsumm /var/www/html && \
    chmod -R 755 /var/www/html

# Crear archivo de log vacío (será reemplazado por volumen en producción)
RUN touch /var/log/mail.log && chown pflogsumm:pflogsumm /var/log/mail.log

# Configurar cron para regenerar reportes diariamente a las 23:50
RUN echo "50 23 * * * pflogsumm /opt/PFLogSumm-HTML-GUI/pflogsummUIReport.sh >/dev/null 2>&1" > /etc/cron.d/pflogsumm && \
    chmod 0644 /etc/cron.d/pflogsumm

# Exponer el puerto 80 para Apache
EXPOSE 80

# Healthcheck: verificar que Apache responde
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

# Script de inicio
COPY <<'EOF' /entrypoint.sh
#!/bin/bash
set -e

# Iniciar cron daemon en background
service cron start

# Regenerar reportes al iniciar como usuario no-root
if [ ! -f /var/www/html/index.html ] || [ "${REGENERATE_REPORTS:-false}" = "true" ]; then
    echo "Generating reports..."
    su -s /bin/bash -c '/opt/PFLogSumm-HTML-GUI/pflogsummUIReport.sh' pflogsumm
fi

# Iniciar Apache en foreground (Apache dropea privilegios internamente)
exec apache2ctl -D FOREGROUND
EOF

RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
