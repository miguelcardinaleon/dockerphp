# Usar una imagen base de Ubuntu
FROM ubuntu:20.04

# Establecer la zona horaria no interactiva
ENV DEBIAN_FRONTEND=noninteractive
RUN ln -fs /usr/share/zoneinfo/Etc/UTC /etc/localtime \
    && apt-get update \
    && apt-get install -y tzdata

# Instalar Apache, PHP y dependencias necesarias
RUN apt-get update && apt-get install -y \
    apache2 \
    php \
    libapache2-mod-php \
    php-fileinfo \
    php-iconv \
    php-zip \
    php-mbstring \
    php-curl \  
    php-xml \
    && apt-get clean

# Crear un nuevo usuario llamado "user" con ID de usuario 1000
RUN useradd -m -u 1000 user

# Añadir ServerName en la configuración global de Apache
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Cambiar el puerto de Apache a 8000
RUN sed -i 's/Listen 80/Listen 8000/g' /etc/apache2/ports.conf

# Cambiar al usuario "user"
USER user

# Establecer el home al directorio del usuario
ENV HOME=/home/user
ENV PATH=/home/user/.local/bin:$PATH

# Establecer el directorio de trabajo al home del usuario
WORKDIR $HOME/app

# Copiar todos los contenidos del directorio actual al contenedor en $HOME/app, estableciendo el propietario al usuario
COPY --chown=user:user . $HOME/app

# Copiar el archivo de configuración de Apache a su ubicación correcta, con el propietario adecuado
COPY --chown=user:user ./apache-config.conf /etc/apache2/sites-available/000-default.conf

# Copiar el contenido web
COPY --chown=user:user ./www /var/www/html

# Cambiar al usuario root para crear directorios y ajustar permisos
USER root
RUN mkdir -p /var/run/apache2 /var/lock/apache2 /var/log/apache2 \
    && chown -R user:user /var/run/apache2 /var/lock/apache2 /var/log/apache2 \
    && chmod -R 755 /var/run/apache2 /var/lock/apache2 /var/log/apache2

# Habilitar extensiones y configurar PHP
RUN echo "file_uploads = On" >> /etc/php/7.4/apache2/php.ini \
    && echo "upload_tmp_dir = /tmp" >> /etc/php/7.4/apache2/php.ini \
    && echo "upload_max_filesize = 64M" >> /etc/php/7.4/apache2/php.ini \
    && echo "open_basedir = none" >> /etc/php/7.4/apache2/php.ini \
    && mkdir -p /var/www/html/uploads \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# **Ajustes para permisos globales en /var/www/html**

# 1. Dar permisos 777 a todos los archivos y directorios dentro de /var/www/html
RUN chmod -R 777 /var/www/html

# 2. Asegurar que los nuevos archivos y directorios creados dentro de /var/www/html también tengan permisos 777
#    Esto se logra aplicando el bit `setgid` al directorio y configurando los permisos predeterminados
RUN find /var/www/html -type d -exec chmod 2777 {} \; \
    && find /var/www/html -type f -exec chmod 666 {} \;



# Cambiar al usuario "user" para la ejecución final
USER user

# Exponer el puerto 8000
EXPOSE 8000

# Ejecutar Apache en primer plano
CMD ["apachectl", "-D", "FOREGROUND"]
