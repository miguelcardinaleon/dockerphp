# Usa la imagen base de PHP con Apache
FROM php:8.0-apache

# Habilita el módulo de reescritura de Apache
RUN a2enmod rewrite

# Copia los archivos de tu aplicación al directorio de Apache
COPY . /var/www/html/

# Establece los permisos adecuados para el directorio
RUN chown -R www-data:www-data /var/www/html

# Exponer el puerto 80
EXPOSE 80

# Comando por defecto para iniciar Apache
CMD ["apache2-foreground"]
