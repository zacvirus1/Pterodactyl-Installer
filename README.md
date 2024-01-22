```markdown
# Instalador Pterodactyl

Bem-vindo ao Instalador Pterodactyl em Português, fornecido pela Rest API Sistemas! Este script facilita a instalação, atualização e remoção do Painel Pterodactyl em seu servidor. 

Por favor, esteja ciente de que este script é otimizado para instalações limpas. Se possível, execute-o como root.

Leia mais sobre o [Pterodactyl](https://pterodactyl.io/) aqui. Este script é uma iniciativa independente e não está afiliado ao Projeto Pterodactyl oficial.

## Principais Recursos

- Instalação fácil do Painel, Wings e PHPMyAdmin.
- Troca simplificada de domínios para seu Painel Pterodactyl.
- Desinstalação rápida e eficiente do Painel e Wings.
- Suporte às versões mais recentes do Pterodactyl.

## Compatibilidade com SO e Servidores Web

| Sistema Operacional | Versão      | Suportado | PHP  |
| ------------------- | ----------- | --------- | ---- |
| Ubuntu              | 18.04 - 22.04| ✅        | 8.1  |
| Debian              | 10 - 12      | ✅        | 8.1  |
| CentOS              | 7            | ✅        | 8.1  |
| Rocky Linux         | Não suportado| ❌       | ❌   |

⚠️ Recomendamos evitar o uso do CentOS 7, pois está fora de suporte. Considere migrar para Debian ou Ubuntu.

| Servidor Web        | Suportado    |
| ------------------- | ------------ | 
| NGINX               | ✅            |
| Apache              | ✅            |
| LiteSpeed           | ❌           |
| Caddy               | ❌           |

## Como Instalar

Execute o seguinte comando no seu terminal:

```bash
bash <(curl -s https://raw.githubusercontent.com/zacvirus1/Pterodactyl-Installer/main/installer.sh)
```

**Nota:** Usuários do Raspbian podem precisar adicionar um `<` extra no início.

Agradecemos à comunidade pela colaboração e apoio no desenvolvimento deste instalador!

🚀 Tenha uma excelente experiência com o Pterodactyl!
```
