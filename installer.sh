#!/bin/bash
#!/usr/bin/env bash

########################################################################
#                                                                      #
#                Créditos para a Rest API Sistemas                    #
#                                                                      #
#  Desenvolvido por: Seu Nome ou Nome da Sua Empresa                    #
#  Contato: Seu Endereço de E-mail ou Outro Meio de Contato             #
#  GitHub: Link para o Repositório no GitHub (se aplicável)            #
#                                                                      #
#  Este projeto é distribuído sob a Licença XYZ. Consulte o arquivo     #
#  LICENSE para obter detalhes sobre os termos de uso.                 #
#                                                                      #
#  Agradecemos a todos os colaboradores e comunidade que contribuíram  #
#  para o desenvolvimento desta Rest API Sistemas.                      #
#                                                                      #
########################################################################


### VARIAVEIS ###

dist="$(. /etc/os-release && echo "$ID")"
version="$(. /etc/os-release && echo "$VERSION_ID")"

### VERIFICAÇÕES ###

function trap_ctrlc ()
{
    echo "Bye!"
    exit 2
}
trap "trap_ctrlc" 2

warning(){
    echo -e '\e[31m'"$1"'\e[0m';

}

### CHECKS ###

if [[ $EUID -ne 0 ]]; then
    echo ""
    echo "[!] Desculpe, mas você precisa ser root para executar este script."
    echo "Na maioria das vezes, isso pode ser feito digitando sudo su no seu terminal."
    exit 1
fi


if ! [ -x "$(command -v curl)" ]; then
    echo ""
    echo "[!] cURL é necessário para executar este script."
    echo "Para continuar, por favor, instale o cURL em sua máquina."
    echo ""
    echo "Sistemas baseados em Debian: apt install curl"
    echo "CentOS: yum install curl"
    exit 1
fi


### ### Instalação do Painel Pterodactyl ### ###

send_summary() {
    clear
    echo ""
    
    if [ -d "/var/www/pterodactyl" ]; then
        warning "[!] AVISO: O Pterodactyl já está instalado. Este script falhará!"
    fi

    echo ""
    echo "[!] Resumo:"
    echo "    URL do Painel: $FQDN"
    echo "    Servidor Web: $WEBSERVER"
    echo "    SSL: $SSLSTATUS"
    echo "    Nome de Usuário: $USERNAME"
    echo "    Primeiro Nome: $FIRSTNAME"
    echo "    Último Nome: $LASTNAME"
    echo "    Senha: $USERPASSWORD"
    echo ""
    
    if [ "$dist" = "centos" ] && [ "$version" = "7" ]; then
        echo "    Você está usando CentOS 7. O NGINX será selecionado como servidor web."
    fi
    
    echo ""
}


panel(){
    echo ""
    echo "[!] Antes da instalação, precisamos de algumas informações."
    echo ""
    panel_webserver
}


finish(){
    clear
    cd
    echo -e "Resumo da instalação\n\nURL do Painel: $FQDN\nServidor Web: $WEBSERVER\nNome de usuário: $USERNAME\nNome: $FIRSTNAME\nSobrenome: $LASTNAME\nSenha: $USERPASSWORD\nSenha do banco de dados: $DBPASSWORD\nSenha para o Host do Banco de Dados: $DBPASSWORDHOST" >> panel_credentials.txt

    echo "[!] Instalação do Painel Pterodactyl concluída"
    echo ""
    echo "    Resumo da instalação" 
    echo "    URL do Painel: $FQDN"
    echo "    Servidor Web: $WEBSERVER"
    echo "    SSL: $SSLSTATUS"
    echo "    Nome de usuário: $USERNAME"
    echo "    Nome: $FIRSTNAME"
    echo "    Sobrenome: $LASTNAME"
    echo "    Senha: $USERPASSWORD"
    echo "" 
    echo "    Senha do banco de dados: $DBPASSWORD"
    echo "    Senha para o Host do Banco de Dados: $DBPASSWORDHOST"
    echo "" 
    echo "    Essas credenciais foram salvas em um arquivo chamado" 
    echo "    panel_credentials.txt no seu diretório atual"
    echo ""
    echo "    Gostaria de instalar também o Wings? (S/N)"
    read -r WINGS_ON_PANEL

    if [[ "$WINGS_ON_PANEL" =~ [Ss] ]]; then
        wings
    fi
    if [[ "$WINGS_ON_PANEL" =~ [Nn] ]]; then
        exit 0
    fi
}


panel_webserver(){
    send_summary
    echo "[!] Selecionar Servidor Web"
    echo "    (1) NGINX"
    echo "    (2) Apache"
    echo "    Digite 1-2"
    read -r option
    case $option in
        1 ) option=1
            WEBSERVER="NGINX"
            panel_fqdn
            ;;
        2 ) option=2
            WEBSERVER="Apache"
            panel_fqdn
            ;;
        * ) echo ""
            echo "Por favor, digite uma opção válida de 1 a 2"
    esac
}


panel_conf(){
    [ "$SSLSTATUS" == true ] && appurl="https://$FQDN"
    [ "$SSLSTATUS" == false ] && appurl="http://$FQDN"
    mariadb -u root -e "CREATE USER 'pterodactyluser'@'127.0.0.1' IDENTIFIED BY '$DBPASSWORDHOST';" && mariadb -u root -e "GRANT ALL PRIVILEGES ON *.* TO 'pterodactyluser'@'127.0.0.1' WITH GRANT OPTION;"
    mariadb -u root -e "CREATE USER 'pterodactyl'@'127.0.0.1' IDENTIFIED BY '$DBPASSWORD';" && mariadb -u root -e "CREATE DATABASE panel;" && mariadb -u root -e "GRANT ALL PRIVILEGES ON panel.* TO 'pterodactyl'@'127.0.0.1' WITH GRANT OPTION;" && mariadb -u root -e "FLUSH PRIVILEGES;"
    php artisan p:environment:setup --author="$EMAIL" --url="$appurl" --timezone="CET" --telemetry=false --cache="redis" --session="redis" --queue="redis" --redis-host="localhost" --redis-pass="null" --redis-port="6379" --settings-ui=true
    php artisan p:environment:database --host="127.0.0.1" --port="3306" --database="panel" --username="pterodactyl" --password="$DBPASSWORD"
    php artisan migrate --seed --force
    php artisan p:user:make --email="$EMAIL" --username="$USERNAME" --name-first="$FIRSTNAME" --name-last="$LASTNAME" --password="$USERPASSWORD" --admin=1
    chown -R www-data:www-data /var/www/pterodactyl/*
    if [ "$dist" = "centos" ]; then
        chown -R nginx:nginx /var/www/pterodactyl/*
        sudo systemctl enable --now redis
        fi
    curl -o /etc/systemd/system/pteroq.service https://raw.githubusercontent.com/guldkage/Pterodactyl-Installer/main/configs/pteroq.service
    (crontab -l ; echo "* * * * * php /var/www/pterodactyl/artisan schedule:run >> /dev/null 2>&1")| crontab -
    sudo systemctl enable --now redis-server
    sudo systemctl enable --now pteroq.service

    if [ "$dist" = "centos" ] && { [ "$version" = "7" ] || [ "$SSLSTATUS" = "true" ]; }; then
        sudo yum install epel-release -y
        sudo yum install certbot -y
        curl -o /etc/nginx/conf.d/pterodactyl.conf https://raw.githubusercontent.com/guldkage/Pterodactyl-Installer/main/configs/pterodactyl-nginx-ssl.conf
        sed -i -e "s@<domain>@${FQDN}@g" /etc/nginx/conf.d/pterodactyl.conf
        sed -i -e "s@/run/php/php8.1-fpm.sock@/var/run/php-fpm/pterodactyl.sock@g" /etc/nginx/conf.d/pterodactyl.conf
        systemctl stop nginx
        certbot certonly --standalone -d $FQDN --staple-ocsp --no-eff-email -m $EMAIL --agree-tos
        systemctl start nginx
        finish
        fi
    if [ "$dist" = "centos" ] && { [ "$version" = "7" ] || [ "$SSLSTATUS" = "false" ]; }; then
        curl -o /etc/nginx/conf.d/pterodactyl.conf https://raw.githubusercontent.com/guldkage/Pterodactyl-Installer/main/configs/pterodactyl-nginx.conf
        sed -i -e "s@<domain>@${FQDN}@g" /etc/nginx/conf.d/pterodactyl.conf
        sed -i -e "s@/run/php/php8.1-fpm.sock@/var/run/php-fpm/pterodactyl.sock@g" /etc/nginx/conf.d/pterodactyl.conf
        systemctl restart nginx
        finish
        fi
    if [ "$SSLSTATUS" = "true" ] && [ "$WEBSERVER" = "NGINX" ]; then
        rm -rf /etc/nginx/sites-enabled/default
        curl -o /etc/nginx/sites-enabled/pterodactyl.conf https://raw.githubusercontent.com/guldkage/Pterodactyl-Installer/main/configs/pterodactyl-nginx-ssl.conf
        sed -i -e "s@<domain>@${FQDN}@g" /etc/nginx/sites-enabled/pterodactyl.conf

        systemctl stop nginx
        certbot certonly --standalone -d $FQDN --staple-ocsp --no-eff-email -m $EMAIL --agree-tos
        systemctl start nginx
        finish
        fi
    if [ "$SSLSTATUS" = "true" ] && [ "$WEBSERVER" = "Apache" ]; then
        a2dissite 000-default.conf && systemctl reload apache2
        curl -o /etc/apache2/sites-enabled/pterodactyl.conf https://raw.githubusercontent.com/guldkage/Pterodactyl-Installer/main/configs/pterodactyl-apache-ssl.conf
        sed -i -e "s@<domain>@${FQDN}@g" /etc/apache2/sites-enabled/pterodactyl.conf
        apt install libapache2-mod-php
        sudo a2enmod rewrite
        sudo a2enmod ssl
        systemctl stop apache2
        certbot certonly --standalone -d $FQDN --staple-ocsp --no-eff-email -m $EMAIL --agree-tos
        systemctl start apache2
        finish
        fi
    if [ "$SSLSTATUS" = "false" ] && [ "$WEBSERVER" = "NGINX" ]; then
        rm -rf /etc/nginx/sites-enabled/default
        curl -o /etc/nginx/sites-enabled/pterodactyl.conf https://raw.githubusercontent.com/guldkage/Pterodactyl-Installer/main/configs/pterodactyl-nginx.conf
        sed -i -e "s@<domain>@${FQDN}@g" /etc/nginx/sites-enabled/pterodactyl.conf
        systemctl restart nginx
        finish
        fi
    if [ "$SSLSTATUS" = "false" ] && [ "$WEBSERVER" = "Apache" ]; then
        a2dissite 000-default.conf && systemctl reload apache2
        curl -o /etc/apache2/sites-enabled/pterodactyl.conf https://raw.githubusercontent.com/guldkage/Pterodactyl-Installer/main/configs/pterodactyl-apache.conf
        sed -i -e "s@<domain>@${FQDN}@g" /etc/apache2/sites-enabled/pterodactyl.conf
        sudo a2enmod rewrite
        systemctl stop apache2
        systemctl start apache2
        finish
        fi
}

panel_install(){
    echo "" 
    if  [ "$dist" =  "ubuntu" ] && [ "$version" = "20.04" ]; then
        apt update
        apt -y install software-properties-common curl apt-transport-https ca-certificates gnupg
        LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
        curl -fsSL https://packages.redis.io/gpg | sudo gpg --dearmor --batch --yes -o /usr/share/keyrings/redis-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/redis.list
        curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash
        apt update
        sudo add-apt-repository "deb http://archive.ubuntu.com/ubuntu $(lsb_release -sc) universe"
    fi
    if [ "$dist" = "debian" ] && [ "$version" = "11" ]; then
        apt update
        apt -y install software-properties-common curl ca-certificates gnupg2 sudo lsb-release
        echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/sury-php.list
        curl -fsSL  https://packages.sury.org/php/apt.gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/sury-keyring.gpg
        curl -fsSL https://packages.redis.io/gpg | sudo gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/redis.list
        apt update -y
        curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash
    fi
    if [ "$dist" = "debian" ] && [ "$version" = "12" ]; then
        apt update
        apt -y install software-properties-common curl ca-certificates gnupg2 sudo lsb-release
        sudo apt install -y apt-transport-https lsb-release ca-certificates wget
        wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
        echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/php.list
        curl -fsSL https://packages.redis.io/gpg | sudo gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/redis.list
        apt update -y
        curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash
    fi
    if [ "$dist" = "centos" ] && [ "$version" = "7" ]; then
        yum update -y
        yum install -y policycoreutils policycoreutils-python selinux-policy selinux-policy-targeted libselinux-utils setroubleshoot-server setools setools-console mcstrans -y

        curl -o /etc/yum.repos.d/mariadb.repo https://raw.githubusercontent.com/guldkage/Pterodactyl-Installer/main/configs/mariadb.repo

        yum update -y
        yum install -y mariadb-server
        systemctl start mariadb
        systemctl enable mariadb

        yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
        yum -y install https://rpms.remirepo.net/enterprise/remi-release-7.rpm
        yum install -y yum-utils
        yum-config-manager --disable 'remi-php*'
        yum-config-manager --enable remi-php81

        yum update -y
        yum install -y php php-{common,fpm,cli,json,mysqlnd,mcrypt,gd,mbstring,pdo,zip,bcmath,dom,opcache}

        yum install -y zip unzip
        curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
        yum install -y nginx

        yum install -y --enablerepo=remi redis
        systemctl start redis
        systemctl enable redis

        setsebool -P httpd_can_network_connect 1
        setsebool -P httpd_execmem 1
        setsebool -P httpd_unified 1

        curl -o /etc/php-fpm.d/www-pterodactyl.conf https://raw.githubusercontent.com/guldkage/Pterodactyl-Installer/main/configs/www-pterodactyl.conf
        systemctl enable php-fpm
        systemctl start php-fpm

        pause 0.5s
        mkdir /var
        mkdir /var/www
        mkdir /var/www/pterodactyl
        cd /var/www/pterodactyl
        curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
        tar -xzvf panel.tar.gz
        chmod -R 755 storage/* bootstrap/cache/
        cp .env.example .env
        command composer install --no-dev --optimize-autoloader --no-interaction --ignore-platform-reqs
        php artisan key:generate --force

        WEBSERVER=NGINX
        panel_conf
        fi

    apt update
    apt install certbot -y

    apt install -y mariadb-server tar unzip git redis-server
    apt -y install php8.1 php8.1-{cli,gd,mysql,pdo,mbstring,tokenizer,bcmath,xml,fpm,curl,zip}
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
    pause 0.5s
    mkdir /var
    mkdir /var/www
    mkdir /var/www/pterodactyl
    cd /var/www/pterodactyl
    curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
    tar -xzvf panel.tar.gz
    chmod -R 755 storage/* bootstrap/cache/
    cp .env.example .env
    command composer install --no-dev --optimize-autoloader --no-interaction
    php artisan key:generate --force
    if  [ "$WEBSERVER" =  "NGINX" ]; then
        apt install nginx -y
        panel_conf
    fi
    if  [ "$WEBSERVER" =  "Apache" ]; then
        sudo apt install apache2 libapache2-mod-php8.1 -y
        panel_conf
    fi
}

panel_summary(){
    clear
    DBPASSWORD=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1`
    USERPASSWORD=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1`
    DBPASSWORDHOST=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1`
    echo ""
    echo "[!] Summary:"
    echo "    Panel URL: $FQDN"
    echo "    Webserver: $WEBSERVER"
    echo "    SSL: $SSLSTATUS"
    echo "    Username: $USERNAME"
    echo "    First name: $FIRSTNAME"
    echo "    Last name: $LASTNAME"
    echo "    Password: $USERPASSWORD"
    echo ""
    echo "    These credentials will be saved in a file called" 
    echo "    panel_credentials.txt in your current directory"
    echo "" 
    echo "    Do you want to start the installation? (Y/N)" 
    read -r PANEL_INSTALLATION

    if [[ "$PANEL_INSTALLATION" =~ [Yy] ]]; then
        panel_install
    fi
    if [[ "$PANEL_INSTALLATION" =~ [Nn] ]]; then
        echo "[!] Installation has been aborted."
        exit 1
    fi
}

panel_fqdn(){
    send_summary
    echo "[!] Por favor, insira o FQDN. Você acessará o Painel com isso."
    echo "[!] Exemplo: panel.seudomínio.com."
    read -r FQDN
    [ -z "$FQDN" ] && echo "O FQDN não pode estar vazio."
    IP=$(dig +short myip.opendns.com @resolver2.opendns.com -4)
    DOMAIN=$(dig +short ${FQDN})
    if [ "${IP}" != "${DOMAIN}" ]; then
        echo ""
        echo "Seu FQDN não resolve para o IP desta máquina."
        echo "Continuando de qualquer maneira em 10 segundos... CTRL+C para parar."
        sleep 10s
        panel_ssl
    else
        panel_ssl
    fi
}


panel_ssl(){
    send_summary
    echo "[!] Você deseja usar SSL para o seu Painel? Isso é recomendado. (S/N)"
    echo "[!] O SSL é recomendado para todos os painéis."
    read -r SSL_CONFIRM

    if [[ "$SSL_CONFIRM" =~ [Ss] ]]; then
        SSLSTATUS=true
        panel_email
    fi
    if [[ "$SSL_CONFIRM" =~ [Nn] ]]; then
        SSLSTATUS=false
        panel_email
    fi
}

panel_email(){
    send_summary
    if  [ "$SSLSTATUS" =  "true" ]; then
        echo "[!] Por favor, insira seu e-mail. Ele será compartilhado com o Lets Encrypt e usado para configurar este Painel."
    fi
    if  [ "$SSLSTATUS" =  "false" ]; then
        echo "[!] Por favor, insira seu e-mail. Ele será usado para configurar este Painel."
    fi
    read -r EMAIL
    panel_username
}


panel_username(){
    send_summary
    echo "[!] Por favor, insira o nome de usuário para a conta de administrador. Você pode usar o nome de usuário para fazer login na sua conta Pterodactyl."
    read -r USERNAME
    panel_firstname
}

panel_firstname(){
    send_summary
    echo "[!] Por favor, insira o primeiro nome para a conta de administrador."
    read -r FIRSTNAME
    panel_lastname
}

panel_lastname(){
    send_summary
    echo "[!] Por favor, insira o último nome para a conta de administrador."
    read -r LASTNAME
    panel_summary
}

### Pterodactyl Wings Installation ###

wings(){
    if [ "$dist" = "debian" ] || [ "$dist" = "ubuntu" ]; then
        apt install dnsutils certbot -y
        apt-get -y install curl tar unzip
    fi
    if [ "$dist" = "centos" ]; then
        sudo yum install bind-utils certbot -y
        yum install -y policycoreutils policycoreutils-python selinux-policy selinux-policy-targeted libselinux-utils setroubleshoot-server setools setools-console mcstrans -y
        yum install tar unzip zip
    fi
    clear
    echo ""
    echo "[!] Antes da instalação, precisamos de algumas informações."
    echo ""
    wings_fqdn
}


wings_fqdnask(){
    echo "[!] Você deseja instalar um certificado SSL? (S/N)"
    echo "    Se sim, será solicitado um endereço de e-mail."
    echo "    O e-mail será compartilhado com o Lets Encrypt."
    read -r WINGS_SSL

    if [[ "$WINGS_SSL" =~ [Ss] ]]; then
        panel_fqdn
    fi
    if [[ "$WINGS_SSL" =~ [Nn] ]]; then
        WINGS_FQDN_STATUS=false
        wings_full
    fi
}


wings_full(){
    if  [ "$WINGS_FQDN_STATUS" =  "true" ]; then
        systemctl stop nginx apache2
        apt install -y certbot && certbot certonly --standalone -d $WINGS_FQDN --staple-ocsp --no-eff-email --agree-tos

        curl -sSL https://get.docker.com/ | CHANNEL=stable bash
        systemctl enable --now docker

        mkdir -p /etc/pterodactyl || exit || echo "An error occurred. Could not create directory." || exit
        apt-get -y install curl tar unzip
        curl -L -o /usr/local/bin/wings "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_$([[ "$(uname -m)" == "x86_64" ]] && echo "amd64" || echo "arm64")"
        curl -o /etc/systemd/system/wings.service https://raw.githubusercontent.com/guldkage/Pterodactyl-Installer/main/configs/wings.service
        chmod u+x /usr/local/bin/wings
        clear
        echo ""
        echo "[!] Pterodactyl Wings successfully installed."
        echo "    You still need to setup the Node"
        echo "    on the Panel and restart Wings after."
        echo ""
        fi
    if  [ "$WINGS_FQDN_STATUS" =  "false" ]; then
        curl -sSL https://get.docker.com/ | CHANNEL=stable bash
        systemctl enable --now docker

        mkdir -p /etc/pterodactyl || exit || echo "An error occurred. Could not create directory." || exit
        curl -L -o /usr/local/bin/wings "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_$([[ "$(uname -m)" == "x86_64" ]] && echo "amd64" || echo "arm64")"
        curl -o /etc/systemd/system/wings.service https://raw.githubusercontent.com/guldkage/Pterodactyl-Installer/main/configs/wings.service
        chmod u+x /usr/local/bin/wings
        clear
        echo ""
        echo "[!] Pterodactyl Wings successfully installed."
        echo "    You still need to setup the Node"
        echo "    on the Panel and restart Wings after."
        echo ""
        fi
}

wings_fqdn(){
    echo "[!] Por favor, insira o seu FQDN se desejar instalar um certificado SSL. Se não, pressione Enter e deixe em branco."
    read -r WINGS_FQDN
    IP=$(dig +short myip.opendns.com @resolver2.opendns.com -4)
    DOMAIN=$(dig +short ${WINGS_FQDN})
    if [ "${IP}" != "${DOMAIN}" ]; then
        echo ""
        echo "FQDN cancelado. Ou o FQDN está incorreto ou você deixou em branco."
        WINGS_FQDN_STATUS=false
        wings_full
    else
        WINGS_FQDN_STATUS=true
        wings_full
    fi
}


### PHPMyAdmin Installation ###

phpmyadmin(){
    apt install dnsutils -y
    echo ""
    echo "[!] Antes da instalação, precisamos de algumas informações."
    echo ""
    phpmyadmin_fqdn
}

phpmyadmin_finish(){
    cd
    echo -e "Instalação do PHPMyAdmin\n\nResumo da instalação\n\nURL do PHPMyAdmin: $PHPMYADMIN_FQDN\nServidor Web pré-selecionado: NGINX\nSSL: $PHPMYADMIN_SSLSTATUS\nUsuário: $PHPMYADMIN_USER_LOCAL\nEmail: $PHPMYADMIN_EMAIL" > phpmyadmin_credentials.txt
    clear
    echo "[!] Instalação do PHPMyAdmin concluída"
    echo ""
    echo "    Resumo da instalação" 
    echo "    URL do PHPMyAdmin: $PHPMYADMIN_FQDN"
    echo "    Servidor Web pré-selecionado: NGINX"
    echo "    SSL: $PHPMYADMIN_SSLSTATUS"
    echo "    Usuário: $PHPMYADMIN_USER_LOCAL"
    echo "    Email: $PHPMYADMIN_EMAIL"
    echo ""
    echo "    Essas credenciais foram salvas em um arquivo chamado" 
    echo "    phpmyadmin_credentials.txt no seu diretório atual"
    echo ""
}



phpmyadminweb(){
    if  [ "$PHPMYADMIN_SSLSTATUS" =  "true" ]; then
        rm -rf /etc/nginx/sites-enabled/default
        curl -o /etc/nginx/sites-enabled/phpmyadmin.conf https://raw.githubusercontent.com/guldkage/Pterodactyl-Installer/main/configs/phpmyadmin-ssl.conf
        sed -i -e "s@<domain>@${PHPMYADMIN_FQDN}@g" /etc/nginx/sites-enabled/phpmyadmin.conf
        systemctl stop nginx || exit || echo "An error occurred. NGINX is not installed." || exit
        certbot certonly --standalone -d $PHPMYADMIN_FQDN --staple-ocsp --no-eff-email -m $PHPMYADMIN_EMAIL --agree-tos || exit || echo "An error occurred. Certbot not installed." || exit
        systemctl start nginx || exit || echo "An error occurred. NGINX is not installed." || exit

        apt install mariadb-server -y
        PHPMYADMIN_USER=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1`
        mariadb -u root -e "CREATE USER 'admin'@'localhost' IDENTIFIED BY '$PHPMYADMIN_USER';" && mariadb -u root -e "GRANT ALL PRIVILEGES ON *.* TO 'admin'@'localhost' WITH GRANT OPTION;"
        phpmyadmin_finish
        fi
    if  [ "$PHPMYADMIN_SSLSTATUS" =  "false" ]; then
        rm -rf /etc/nginx/sites-enabled/default || exit || echo "An error occurred. NGINX is not installed." || exit
        curl -o /etc/nginx/sites-enabled/phpmyadmin.conf https://raw.githubusercontent.com/guldkage/Pterodactyl-Installer/main/configs/phpmyadmin.conf || exit || echo "An error occurred. cURL is not installed." || exit
        sed -i -e "s@<domain>@${PHPMYADMIN_FQDN}@g" /etc/nginx/sites-enabled/phpmyadmin.conf || exit || echo "An error occurred. NGINX is not installed." || exit
        systemctl restart nginx || exit || echo "An error occurred. NGINX is not installed." || exit

        apt install mariadb-server -y
        PHPMYADMIN_USER=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1`
        mariadb -u root -e "CREATE USER '$PHPMYADMIN_USER_LOCAL'@'localhost' IDENTIFIED BY '$PHPMYADMIN_USER';" && mariadb -u root -e "GRANT ALL PRIVILEGES ON *.* TO 'admin'@'localhost' WITH GRANT OPTION;"
        phpmyadmin_finish
        fi
}

phpmyadmin_fqdn(){
    send_phpmyadmin_summary
    echo "[!] Por favor, insira o FQDN. Você acessará o PHPMyAdmin com isso."
    read -r PHPMYADMIN_FQDN
    [ -z "$PHPMYADMIN_FQDN" ] && echo "O FQDN não pode estar vazio."
    IP=$(dig +short myip.opendns.com @resolver2.opendns.com -4)
    DOMAIN=$(dig +short ${PHPMYADMIN_FQDN})
    if [ "${IP}" != "${DOMAIN}" ]; then
        echo ""
        echo "Seu FQDN não resolve para o IP desta máquina."
        echo "Continuando de qualquer maneira em 10 segundos... CTRL+C para parar."
        sleep 10s
        phpmyadmin_ssl
    else
        phpmyadmin_ssl
    fi
}


phpmyadmininstall(){
    apt update
    apt install nginx certbot -y
    mkdir /var/www/phpmyadmin && cd /var/www/phpmyadmin || exit || echo "An error occurred. Could not create directory." || exit
    cd /var/www/phpmyadmin
    if  [ "$dist" =  "ubuntu" ] && [ "$version" = "20.04" ]; then
        apt -y install software-properties-common curl apt-transport-https ca-certificates gnupg
        LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
        curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash
        apt update
        sudo add-apt-repository "deb http://archive.ubuntu.com/ubuntu $(lsb_release -sc) universe"
    fi
    if [ "$dist" = "debian" ] && [ "$version" = "11" ]; then
        apt -y install software-properties-common curl ca-certificates gnupg2 sudo lsb-release
        echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/sury-php.list
        curl -fsSL  https://packages.sury.org/php/apt.gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/sury-keyring.gpg
        apt update -y
        curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash
    fi
    if [ "$dist" = "debian" ] && [ "$version" = "12" ]; then
        apt -y install software-properties-common curl ca-certificates gnupg2 sudo lsb-release
        sudo apt install -y apt-transport-https lsb-release ca-certificates wget
        wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
        echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/php.list
        apt update -y
        curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash
    fi
    
    wget https://files.phpmyadmin.net/phpMyAdmin/5.2.1/phpMyAdmin-5.2.1-all-languages.tar.gz
    tar xzf phpMyAdmin-5.2.1-all-languages.tar.gz
    mv /var/www/phpmyadmin/phpMyAdmin-5.2.1-all-languages/* /var/www/phpmyadmin
    chown -R www-data:www-data *
    mkdir config
    chmod o+rw config
    cp config.sample.inc.php config/config.inc.php
    chmod o+w config/config.inc.php
    rm -rf /var/www/phpmyadmin/config
    phpmyadminweb
}


phpmyadmin_summary(){
    clear
    echo ""
    echo "[!] Resumo:"
    echo "    URL do PHPMyAdmin: $PHPMYADMIN_FQDN"
    echo "    Servidor Web pré-selecionado: NGINX"
    echo "    SSL: $PHPMYADMIN_SSLSTATUS"
    echo "    Usuário: $PHPMYADMIN_USER_LOCAL"
    echo "    Email: $PHPMYADMIN_EMAIL"
    echo ""
    echo "    Essas credenciais foram salvas em um arquivo chamado" 
    echo "    phpmyadmin_credentials.txt no seu diretório atual"
    echo "" 
    echo "    Deseja iniciar a instalação? (S/N)" 
    read -r PHPMYADMIN_INSTALLATION

    if [[ "$PHPMYADMIN_INSTALLATION" =~ [Ss] ]]; then
        phpmyadmininstall
    fi
    if [[ "$PHPMYADMIN_INSTALLATION" =~ [Nn] ]]; then
        echo "[!] A instalação foi abortada."
        exit 1
    fi
}


send_phpmyadmin_summary(){
    clear
    if [ -d "/var/www/phpymyadmin" ] 
    then
        echo ""
        warning "[!] AVISO: Parece que já existe uma instalação do PHPMyAdmin! Este script falhará!"
        echo ""
        echo "[!] Resumo:"
        echo "    URL do PHPMyAdmin: $PHPMYADMIN_FQDN"
        echo "    Servidor Web pré-selecionado: NGINX"
        echo "    SSL: $PHPMYADMIN_SSLSTATUS"
        echo "    Usuário: $PHPMYADMIN_USER_LOCAL"
        echo "    Email: $PHPMYADMIN_EMAIL"
        echo ""
    else
        echo ""
        echo "[!] Resumo:"
        echo "    URL do PHPMyAdmin: $PHPMYADMIN_FQDN"
        echo "    Servidor Web pré-selecionado: NGINX"
        echo "    SSL: $PHPMYADMIN_SSLSTATUS"
        echo "    Usuário: $PHPMYADMIN_USER_LOCAL"
        echo "    Email: $PHPMYADMIN_EMAIL"
        echo ""
    fi
}


phpmyadmin_ssl(){
    send_phpmyadmin_summary
    echo "[!] Você deseja usar SSL para o PHPMyAdmin? Isso é recomendado. (S/N)"
    read -r SSL_CONFIRM

    if [[ "$SSL_CONFIRM" =~ [Ss] ]]; then
        PHPMYADMIN_SSLSTATUS=true
        phpmyadmin_email
    fi
    if [[ "$SSL_CONFIRM" =~ [Nn] ]]; then
        PHPMYADMIN_SSLSTATUS=false
        phpmyadmin_email
    fi
}


phpmyadmin_user(){
    send_phpmyadmin_summary
    echo "[!] Por favor, insira o nome de usuário para a conta de administrador."
    read -r PHPMYADMIN_USER_LOCAL
    phpmyadmin_summary
}

phpmyadmin_email(){
    send_phpmyadmin_summary
    if  [ "$PHPMYADMIN_SSLSTATUS" =  "true" ]; then
        echo "[!] Por favor, insira seu e-mail. Ele será compartilhado com o Lets Encrypt."
        read -r PHPMYADMIN_EMAIL
        phpmyadmin_user
    fi
    if  [ "$PHPMYADMIN_SSLSTATUS" =  "false" ]; then
        phpmyadmin_user
        PHPMYADMIN_EMAIL="Indisponível"
    fi
}


### Removal of Wings ###

wings_remove(){
    echo ""
    echo "[!] Tem certeza de que deseja remover o Wings? Se houver algum servidor nesta máquina, eles também serão removidos. (S/N)"
    read -r UNINSTALLWINGS

    if [[ "$UNINSTALLWINGS" =~ [Ss] ]]; then
        sudo systemctl stop wings # Para o wings
        sudo rm -rf /var/lib/pterodactyl # Remove servidores de jogo e arquivos de backup
        sudo rm -rf /etc/pterodactyl  || exit || warning "Pterodactyl Wings não instalado!"
        sudo rm /usr/local/bin/wings || exit || warning "Wings não está instalado!" # Remove wings
        sudo rm /etc/systemd/system/wings.service # Remove o arquivo de serviço wings
        echo ""
        echo "[!] Pterodactyl Wings foi desinstalado."
        echo ""
    fi
}


### Removal of Panel ###

uninstallpanel(){
    echo ""
    echo "[!] Você realmente deseja excluir o Painel Pterodactyl? Todos os arquivos e configurações serão excluídos. (S/N)"
    read -r UNINSTALLPANEL

    if [[ "$UNINSTALLPANEL" =~ [Ss] ]]; then
        uninstallpanel_backup
    fi
}

uninstallpanel_backup(){
    echo ""
    echo "[!] Deseja manter seu banco de dados e fazer backup do seu arquivo .env? (S/N)"
    read -r UNINSTALLPANEL_CHANGE

    if [[ "$UNINSTALLPANEL_CHANGE" =~ [Ss] ]]; then
        BACKUPPANEL=true
        uninstallpanel_confirm
    fi
    if [[ "$UNINSTALLPANEL_CHANGE" =~ [Nn] ]]; then
        BACKUPPANEL=false
        uninstallpanel_confirm
    fi
}


uninstallpanel_confirm(){
    if  [ "$BACKUPPANEL" =  "true" ]; then
        mv /var/www/pterodactyl/.env .
        sudo rm -rf /var/www/pterodactyl || exit || warning "O Painel não está instalado!" # Remove arquivos do painel
        sudo rm /etc/systemd/system/pteroq.service # Remove o serviço pteroq
        sudo unlink /etc/nginx/sites-enabled/pterodactyl.conf # Remove a configuração do nginx (se estiver usando o nginx)
        sudo unlink /etc/apache2/sites-enabled/pterodactyl.conf # Remove a configuração do Apache (se estiver usando o Apache)
        sudo rm -rf /var/www/pterodactyl # Removendo arquivos do painel
        systemctl restart nginx
        clear
        echo ""
        echo "[!] O Painel Pterodactyl foi desinstalado."
        echo "    Seu banco de dados do Painel não foi excluído"
        echo "    e seu arquivo .env está no seu diretório atual."
        echo ""
    fi
    if  [ "$BACKUPPANEL" =  "false" ]; then
        sudo rm -rf /var/www/pterodactyl || exit || warning "O Painel não está instalado!" # Remove arquivos do painel
        sudo rm /etc/systemd/system/pteroq.service # Remove o serviço pteroq
        sudo unlink /etc/nginx/sites-enabled/pterodactyl.conf # Remove a configuração do nginx (se estiver usando o nginx)
        sudo unlink /etc/apache2/sites-enabled/pterodactyl.conf # Remove a configuração do Apache (se estiver usando o Apache)
        sudo rm -rf /var/www/pterodactyl # Removendo arquivos do painel
        mariadb -u root -e "DROP DATABASE panel;" # Remove o banco de dados do painel
        mysql -u root -e "DROP DATABASE panel;" # Remove o banco de dados do painel
        systemctl restart nginx
        clear
        echo ""
        echo "[!] O Painel Pterodactyl foi desinstalado."
        echo "    Arquivos, serviços, configurações e seu banco de dados foram excluídos."
        echo ""
    fi
}


### Switching Domains ###

switch(){
    if  [ "$SSLSWITCH" =  "true" ]; then
        echo ""
        echo "[!] Alterar domínios"
        echo ""
        echo "    O script está agora alterando seu domínio Pterodactyl."
        echo "      Isso pode levar alguns segundos para a parte SSL, pois os certificados SSL estão sendo gerados."
        rm /etc/nginx/sites-enabled/pterodactyl.conf
        curl -o /etc/nginx/sites-enabled/pterodactyl.conf https://raw.githubusercontent.com/guldkage/Pterodactyl-Installer/main/configs/pterodactyl-nginx-ssl.conf || exit || warning "Painel Pterodactyl não instalado!"
        sed -i -e "s@<domain>@${DOMAINSWITCH}@g" /etc/nginx/sites-enabled/pterodactyl.conf
        systemctl stop nginx
        certbot certonly --standalone -d $DOMAINSWITCH --staple-ocsp --no-eff-email -m $EMAILSWITCHDOMAINS --agree-tos || exit || warning "Ocorreram erros."
        systemctl start nginx
        echo ""
        echo "[!] Alterar domínios"
        echo ""
        echo "    Seu domínio foi alterado para $DOMAINSWITCH"
        echo "    Este script não atualiza sua URL do APP, você pode"
        echo "    atualizá-lo em /var/www/pterodactyl/.env"
        echo ""
        echo "    Se estiver usando certificados Cloudflare para o seu Painel, por favor, leia isso:"
        echo "    O script usa o Lets Encrypt para concluir a alteração do seu domínio,"
        echo "    se você normalmente usa Certificados Cloudflare,"
        echo "    você pode alterá-lo manualmente em sua configuração que está no mesmo local que antes."
        echo ""
    fi
    if  [ "$SSLSWITCH" =  "false" ]; then
        echo "[!] Alternando seu domínio.. Isso não levará muito tempo!"
        rm /etc/nginx/sites-enabled/pterodactyl.conf || exit || echo "Ocorreu um erro. Não foi possível excluir o arquivo." || exit
        curl -o /etc/nginx/sites-enabled/pterodactyl.conf https://raw.githubusercontent.com/guldkage/Pterodactyl-Installer/main/configs/pterodactyl-nginx.conf || exit || warning "Painel Pterodactyl não instalado!"
        sed -i -e "s@<domain>@${DOMAINSWITCH}@g" /etc/nginx/sites-enabled/pterodactyl.conf
        systemctl restart nginx
        echo ""
        echo "[!] Alterar domínios"
        echo ""
        echo "    Seu domínio foi alterado para $DOMAINSWITCH"
        echo "    Este script não atualiza sua URL do APP, você pode"
        echo "    atualizá-lo em /var/www/pterodactyl/.env"
    fi
}


switchemail(){
    echo ""
    echo "[!] Trocar domínios"
    echo "    Para instalar o certificado do seu novo domínio no seu Painel, seu endereço de e-mail deve ser compartilhado com o Let's Encrypt."
    echo "    Eles enviarão um e-mail quando seu certificado estiver prestes a expirar. Um certificado dura 90 dias e você pode renová-lo gratuitamente e facilmente, mesmo com este script."
    echo ""
    echo "    Quando você criou o certificado para o seu painel antes, eles também pediram seu endereço de e-mail. É exatamente a mesma coisa aqui, com seu novo domínio."
    echo "    Portanto, insira seu e-mail. Se não quiser fornecer seu e-mail, o script não poderá continuar. Pressione CTRL + C para sair."
    echo ""
    echo "      Por favor, insira seu e-mail"

    read -r EMAILSWITCHDOMAINS
    switch
}

switchssl(){
    echo "[!] Selecione a opção que melhor descreve a sua situação"
    warning "   [1] Eu quero SSL no meu Painel no novo domínio"
    warning "   [2] Eu não quero SSL no meu Painel no novo domínio"
    read -r option
    case $option in
        1 ) option=1
            SSLSWITCH=true
            switchemail
            ;;
        2 ) option=2
            SSLSWITCH=false
            switch
            ;;
        * ) echo ""
            echo "Por favor, insira uma opção válida."
    esac
}


switchdomains(){
    echo ""
    echo "[!] Trocar domínios"
    echo "    Por favor, insira o domínio (painel.meudominio.com) para o qual deseja trocar."
    read -r DOMAINSWITCH
    switchssl
}


### OS Check ###

oscheck(){
    echo "Verificando seu sistema operacional.."
    if { [ "$dist" = "ubuntu" ] && [ "$version" = "18.04" ] || [ "$version" = "20.04" ] || [ "$version" = "22.04" ]; } || { [ "$dist" = "centos" ] && [ "$version" = "7" ]; } || { [ "$dist" = "debian" ] && [ "$version" = "11" ] || [ "$version" = "12" ]; }; then
        options
    else
        echo "Seu sistema operacional, $dist $version, não é suportado."
        exit 1
    fi
}


# Função para a opção 5
tema_br() {
    bash <(curl -s https://raw.githubusercontent.com/zacvirus1/Pterodactyl-Installer/main/tema-br.sh)
}


### Options ###
options(){
    if [ "$dist" = "centos" ] && [ "$version" = "7" ]; then
        echo "Suas opções foram limitadas devido ao CentOS 7."
        echo ""
        echo "O que você gostaria de fazer?"
        echo "[1] Instalar o Painel."
        echo "[2] Instalar o Wings."
        echo "[3] Remover o Painel."
        echo "[4] Remover o Wings."
        echo "[5] Instalar Tema BR."
        echo "Digite 1-5"
        read -r option
        case $option in
            1 ) panel ;;
            2 ) wings ;;
            3 ) uninstallpanel ;;
            4 ) wings_remove ;;
            5 ) tema_br ;;
            * ) echo ""
                echo "Por favor, digite uma opção válida de 1 a 5."
        esac
    else
echo "O que você gostaria de fazer?"
echo "[1] Instalar o Painel."
echo "[2] Instalar o Wings."
echo "[3] Instalar o PHPMyAdmin."
echo "[4] Remover o Wings."
echo "[5] Remover o Painel."
echo "[6] Trocar o Domínio do Pterodactyl."
echo "[7] Instalar Tema BR."
echo "Digite 1-7"
read -r option

        case $option in
            1 ) option=1
                panel
                ;;
            2 ) option=2
                wings
                ;;
            3 ) option=3
                phpmyadmin
                ;;
            4 ) option=4
                wings_remove
                ;;
            5 ) option=5
                uninstallpanel
                ;;
            6 ) option=6
                switchdomains
                ;;
            7 ) option=7
                tema_br
                ;;
            * ) echo ""
                echo "Please enter a valid option from 1-6"
        esac
    fi
}

### Start ###

clear
echo ""
# Arte ASCII para "Rest API Sistemas"
ascii_art="
## ######   #######   #####   ########             ##    ######    ######            #####    ######   #####   ######## #######  ##   ##     ##     ##### #
#  ##  ##   ##  ##  ##   ##  #  ##  #            ####    ##  ##     ##             ##   ##     ##    ##   ##  #  ##  #  ##  ##  ### ###    ####   ##   ## #
#  ##  ##   ##      ##          ##              ##  ##   ##  ##     ##             ##          ##    ##          ##     ##      #######   ##  ##  ## #
#  #####    ####     #####      ##              ######   ##  ##     ##              #####      ##     #####      ##     ####    ## # ##   ######   ##### #
#  ####     ##           ##     ##              ##  ##   #####      ##                  ##     ##         ##     ##     ##      ##   ##   ##  ##       ## #
#  ## ##    ##  ##  ##   ##     ##              ##  ##   ##         ##             ##   ##     ##    ##   ##     ##     ##  ##  ##   ##   ##  ##  ##   ## #
# ###  ##  #######   #####     ####             ##  ##  ###       ######            #####    ######   #####     ####   #######  ##   ##   ##  ##   ##### #
"

# Exibir arte ASCII
echo -e "$ascii_art"
echo "Pterodactyl Installer Português v4.0"
echo "Desenvolvido por Rest API Sistemas"
echo ""
echo "Este script não possui afiliação com o Painel Pterodactyl oficial."
echo ""
oscheck
