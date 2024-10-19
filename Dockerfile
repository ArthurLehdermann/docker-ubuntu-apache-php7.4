# Usar imagem base do Ubuntu 22.04
FROM ubuntu:22.04

# Definir variáveis de ambiente
ENV LC_ALL=C.UTF-8
ENV DEBIAN_FRONTEND=noninteractive
ENV ACCEPT_EULA=Y
ENV TERM=xterm

# Atualizar pacotes e instalar utilitários básicos
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    vim curl wget git software-properties-common supervisor apache2 libcurl4 imagemagick libmagickwand-dev

# Remover pacotes de PHP existentes
RUN apt-get purge -y php*

# Adicionar o repositório Ondrej PHP e instalar PHP 7.4 e extensões
RUN add-apt-repository ppa:ondrej/php && apt-get update && apt-get install -y \
    libapache2-mod-php7.4 \
    php7.4 \
    php7.4-cgi \
    php7.4-cli \
    php7.4-dev \
    php7.4-phpdbg \
    php7.4-bcmath \
    php7.4-bz2 \
    php7.4-common \
    php7.4-curl \
    php7.4-dba \
    php7.4-enchant \
    php7.4-gd \
    php7.4-gmp \
    php7.4-imagick \
    php7.4-imap \
    php7.4-interbase \
    php7.4-intl \
    php7.4-ldap \
    php7.4-mbstring \
    php7.4-mcrypt \
    php7.4-mysql \
    php7.4-odbc \
    php7.4-pdo \
    php7.4-pgsql \
    php7.4-pspell \
    php7.4-redis \
    php7.4-readline \
    php7.4-soap \
    php7.4-sqlite3 \
    php7.4-sybase \
    php7.4-tidy \
    php7.4-xml \
    php7.4-xmlrpc \
    php7.4-zip \
    php7.4-opcache \
    php-json \
    php-apcu \
    php-memcached \
    php-pear \
    sendmail \
    && apt-get clean \
    && rm -fr /var/lib/apt/lists/*

# Instalar o Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Instalar NVM e Node.js (LTS)
SHELL ["/bin/bash", "--login", "-i", "-c"]
RUN curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash \
    && source /root/.bashrc \
    && nvm install node --lts

# Instalar UnixODBC e pacotes relacionados
RUN apt-get update && apt-get install -y \
        gcc \
        g++ \
        make \
        autoconf \
        libc-dev \
        pkg-config \
        libssl-dev \
        libxml2-dev \
        gnupg \
        odbcinst1debian2 \
        odbcinst \
        unixodbc \
        unixodbc-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Corrigir o problema da chave GPG da Microsoft
RUN curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /etc/apt/trusted.gpg.d/microsoft.asc.gpg

# Adicionar repositório da Microsoft e instalar ODBC Driver para SQL Server
RUN curl https://packages.microsoft.com/config/ubuntu/22.04/prod.list > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get install -y mssql-tools msodbcsql18

# Atualizar alternativas para o PHP
RUN update-alternatives --set php /usr/bin/php7.4

# Instalar as extensões sqlsrv e pdo_sqlsrv para PHP 7.4
RUN pecl install sqlsrv-5.9.0 pdo_sqlsrv-5.9.0 \
    && echo "extension=sqlsrv.so" >> /etc/php/7.4/apache2/php.ini \
    && echo "extension=pdo_sqlsrv.so" >> /etc/php/7.4/apache2/php.ini

# Instalar locais e configurar
RUN apt-get update && apt-get install -y locales \
    && echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
    && locale-gen

# Limpeza final
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Habilitar módulos do Apache
RUN a2enmod rewrite

# Copiar arquivos de configuração (substitua pelo caminho correto se necessário)
COPY conf/apache/000-default.conf /etc/apache2/sites-available/000-default.conf
COPY conf/apache/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY conf/run.sh /run.sh
COPY conf/config /config

# Definir permissões para o script de inicialização
RUN chmod 755 /run.sh

# Definir o diretório de trabalho
WORKDIR /var/www/html/public

# Expor a porta 80
EXPOSE 80

# Comando padrão para iniciar
CMD ["/run.sh"]
