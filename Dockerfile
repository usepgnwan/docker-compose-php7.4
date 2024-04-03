FROM mcr.microsoft.com/mssql-tools as mssql
FROM php:7.4.9-apache

COPY --from=mssql /opt/microsoft/ /opt/microsoft/
COPY --from=mssql /opt/mssql-tools/ /opt/mssql-tools/
COPY --from=mssql /usr/lib/libmsodbcsql-13.so /usr/lib/libmsodbcsql-13.so

ENV ACCEPT_EULA=Y
RUN apt-get update && apt-get install -y gnupg2
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - 
RUN curl https://packages.microsoft.com/config/ubuntu/20.04/prod.list > /etc/apt/sources.list.d/mssql-release.list 
RUN apt-get update 
RUN ACCEPT_EULA=Y apt-get -y --no-install-recommends install msodbcsql17 unixodbc-dev 
RUN pecl install sqlsrv-5.10.1 pdo_sqlsrv-5.10.1 
RUN docker-php-ext-enable sqlsrv pdo_sqlsrv

RUN apt-get update && apt-get install -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
		libzip-dev \
		&& docker-php-ext-configure gd --with-freetype --with-jpeg \
		&& docker-php-ext-install -j$(nproc) gd

RUN docker-php-ext-configure gd --with-freetype --with-jpeg
RUN docker-php-ext-install gd

RUN docker-php-ext-install bcmath \
    && docker-php-ext-configure calendar && docker-php-ext-install calendar \
    && docker-php-ext-install pdo pdo_mysql mysqli
    

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN apt-get install -y \
    libzip-dev \
    && docker-php-ext-install zip

RUN docker-php-ext-configure pcntl --enable-pcntl
RUN docker-php-ext-install pcntl

RUN apt-get install -y curl g++ make libxml2-dev

RUN docker-php-ext-install soap && docker-php-ext-enable soap
RUN docker-php-ext-install tokenizer

RUN apt-get -y update \
&& apt-get install -y libicu-dev \
&& docker-php-ext-configure intl \
&& docker-php-ext-install intl

RUN \ 
apt-get update && \
apt-get install libldap2-dev -y && \
rm -rf /var/lib/apt/lists/* && \
docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ && \
docker-php-ext-install ldap

RUN apt-get update && apt-get install -y libpq-dev && docker-php-ext-install pdo pdo_pgsql pgsql

RUN apt-get update && apt-get install -y libmcrypt-dev && pecl install mcrypt-1.0.4
RUN docker-php-ext-enable mcrypt

RUN pecl install -o -f redis \
&&  rm -rf /tmp/pear \
&&  docker-php-ext-enable redis

RUN apt-get update && apt-get install -y tzdata openssh-client


RUN apt-get update && \
    apt-get install -y \
        libc-client-dev libkrb5-dev && \
    rm -r /var/lib/apt/lists/*
    
RUN docker-php-ext-configure imap --with-kerberos --with-imap-ssl && \
    docker-php-ext-install -j$(nproc) imap

RUN apt-get update && apt-get install -y telnet
RUN apt-get update && apt-get install -y iputils-ping net-tools

# Configure OpenSSL
RUN sed -i '/oid_section\s*=\s*new_oids/a # System default\nopenssl_conf = default_conf' /etc/ssl/openssl.cnf
RUN echo "[default_conf]\nssl_conf = ssl_sect\n\n[ssl_sect]\nsystem_default = system_default_sect\n\n[system_default_sect]\nMinProtocol = TLSv1.2\nCipherString = DEFAULT@SECLEVEL=1" >> /etc/ssl/openssl.cnf

RUN sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf
RUN a2enmod rewrite

COPY ./php.ini /usr/local/etc/php/conf.d/custom.ini

RUN rm -r /var/lib/apt/lists/*








