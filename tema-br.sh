#!/bin/bash


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

# Função para exibir a arte ASCII e esperar 2 segundos
show_ascii_art() {
    echo -e "$ascii_art"
    sleep 3
}

# Função para exibir mensagem e esperar 2 segundos
show_message() {
    echo "$1"
    sleep 3
}


# Função para realizar a instalação
install_jexactyl_brasil() {
    show_message "Renomeando a estrutura original do Pterodactyl..."
    sudo mv /var/www/pterodactyl /var/www/pterodactyl-backup

    show_message "Despejando o banco de dados MySQL e salvando no diretório de backup..."
    show_message "Insira a Senha do Banco de Dados"
    sudo mysqldump -u root -p panel > /var/www/pterodactyl-backup/panel.sql

    show_message "Criando e entrando na pasta do novo diretório Jexactyl-Brasil..."
    sudo mkdir /var/www/pterodactyl
    cd /var/www/pterodactyl

    show_message "Copiando o .env do diretório de backup..."
    sudo cp /var/www/pterodactyl-backup/.env /var/www/pterodactyl/

    show_message "Baixando a versão mais recente do Jexactyl-Brasil usando CURL..."
    sudo curl -L -o panel.tar https://github.com/zacvirus1/tema-br/releases/download/1.1.0/panel.tar

    show_message "Baixando os arquivos atualizados e excluindo o arquivo compactado..."
    sudo tar -xzvf panel.tar && rm -f panel.tar

    show_message "Configurando permissões..."
    sudo chmod -R 755 storage/* bootstrap/cache

    show_message "Baixando as dependências do Composer..."
    sudo composer install --no-dev --optimize-autoloader

    show_message "Atualizando migrações do banco de dados..."
    sudo php artisan migrate --seed --force

    show_message "Reatribuindo permissões do servidor web (NGINX ou Apache)..."
    sudo chown -R www-data:www-data /var/www/pterodactyl/*

    show_message "Reiniciando os trabalhadores da fila (pode não ser necessário)..."
    sudo php artisan queue:restart

    show_message "Marcando o painel como online (pode não ser necessário)..."
    sudo php artisan up

    show_message "Parabéns! Você migrou para o Jexactyl-Brasil e tudo deve estar funcionando normalmente."
    show_message "Se encontrar algum problema, informe-nos em nosso Discord: [seu link do Discord]"
    show_message "Instalação concluída!"
}

# Função para exibir o menu de opções.
show_menu() {
echo ""
echo ""
echo "Pterodactyl Installer Português v4.0"
echo "Desenvolvido por Rest API Sistemas"
echo ""
echo "Este script não possui afiliação com o Painel Pterodactyl oficial."
echo ""
echo ""
    echo "Selecione uma opção:"
    echo "1) Iniciar a instalação do Jexactyl-Brasil"
    echo "2) Sair"
}

# Loop principal
while true; do
    show_ascii_art
    show_menu
    read -p "Opção: " choice

    case $choice in
        1 ) install_jexactyl_brasil ;;
        2 ) echo "Saindo..."; exit 0 ;;
        * ) echo "Opção inválida. Tente novamente." ;;
    esac
done
