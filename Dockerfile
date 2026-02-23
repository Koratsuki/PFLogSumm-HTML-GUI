# Usar Ubuntu como base
FROM ubuntu:latest

# Instalar dependencias
RUN apt-get update && apt-get install -y \
    pflogsumm \
    gettext-base \
    apache2 \
    && rm -rf /var/lib/apt/lists/*

# Copiar el proyecto al contenedor
COPY . /opt/PFLogSumm-HTML-GUI

# Crear directorios necesarios
RUN mkdir -p /var/www/html/data

# Crear el archivo de configuración con rutas correctas para el contenedor
RUN mkdir -p /etc && tee /etc/pflogsumui.conf > /dev/null <<EOF
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

# Copiar el archivo de log de ejemplo (asumiendo que mail.log está en el directorio del proyecto)
# Si no existe, crear uno vacío para pruebas
RUN cp /opt/PFLogSumm-HTML-GUI/mail.log /var/log/mail.log 2>/dev/null || touch /var/log/mail.log

# Ejecutar el script para generar los reportes
RUN cd /opt/PFLogSumm-HTML-GUI && ./pflogsummUIReport.sh

# Configurar permisos
RUN chmod -R 755 /var/www/html

# Exponer el puerto 80 para Apache
EXPOSE 80

# Script de inicio
COPY <<'EOF' /entrypoint.sh
#!/bin/bash
set -e

# Regenerar reportes si es necesario
if [ ! -f /var/www/html/index.html ] || [ "$REGENERATE_REPORTS" = "true" ]; then
    echo "Generating reports..."
    cd /opt/PFLogSumm-HTML-GUI && ./pflogsummUIReport.sh
fi

# Iniciar Apache
exec apache2ctl -D FOREGROUND
EOF

RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]