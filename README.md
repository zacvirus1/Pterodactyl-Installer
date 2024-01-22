```markdown
# Pterodactyl Installer

Com este script, você pode instalar, atualizar ou excluir facilmente o Painel Pterodactyl. Tudo está reunido em um único script.

Por favor, observe que este script é feito para funcionar em uma instalação limpa. Existe uma boa chance de falha se não for uma instalação limpa. O script deve ser executado como root.

Leia sobre [Pterodactyl](https://pterodactyl.io/) aqui. Este script não está associado ao Projeto Pterodactyl oficial.

# Recursos
Suporta a versão mais recente do Pterodactyl! Este script é um dos únicos que possui um recurso de Troca de Domínios bem funcional.

- Instalar Painel
- Instalar Wings
- Instalar PHPMyAdmin
- Trocar Domínios do Pterodactyl
- Desinstalar Painel
- Desinstalar Wings
- Autoinstalar [APENAS NGINX E BETA]

# SO e Servidor Web Suportados
Sistemas operacionais suportados.

| Sistema Operacional | Versão                 | Suportado                         |   PHP |
| ------------------- | ----------------------| ---------------------------------- | ----- |
| Ubuntu              | de 18.04 a 22.04       | :white_check_mark:                 | 8.1   |
| Debian              | de 10 a 12             | :white_check_mark:                 | 8.1   |
| CentOS              | centos 7               | :white_check_mark:                 | 8.1   |
| Rocky Linux         | versões não suportadas | :x:                                | :x:   |

:warning: Cuidado ao usar o CentOS 7. Ele está fora de suporte e não haverá suporte para qualquer versão mais recente do CentOS neste script. Se estiver usando CentOS e quiser usar este script, você deve mudar para uma nova distribuição, como Debian ou Ubuntu.

| Servidor Web        | Suportado             |
| ------------------- | --------------------  | 
| NGINX               | :white_check_mark:    |
| Apache              | :white_check_mark:    |
| LiteSpeed           | :x:                   |
| Caddy               | :x:                   |

# Contribuidores
Copyright 2022-2023, [Malthe K](https://github.com/guldkage), me@malthe.cc
<br>
Criado e mantido por [Malthe K.](https://github.com/guldkage)

# Suporte
O script foi testado muitas vezes sem correções de bugs, no entanto, eles ainda podem ocorrer.
<br>
Se encontrar erros, sinta-se à vontade para abrir um "Issue" no GitHub.

# Instalação Interativa/Normal
A maneira recomendada de usar este script.
```bash
bash <(curl -s https://raw.githubusercontent.com/guldkage/Pterodactyl-Installer/main/installer.sh)
```

### Raspbian
Apenas para usuários do Raspbian. Eles podem precisar de um < extra no início.
```bash
bash < <(curl -s https://raw.githubusercontent.com/guldkage/Pterodactyl-Installer/main/installer.sh)
```

# Autoinstalação / Instalação de Desenvolvedor
Use apenas se souber o que está fazendo!
Agora você pode instalar o Pterodactyl usando 1 comando sem precisar digitar manualmente qualquer coisa após a execução do comando.

### [BETA] Gerar Comando de Autoinstalação
Você pode usar meu [gerador de comando de autoinstalação](https://malthe.cc/api/autoinstall/) para instalar Pterodactyl e Wings com 1 comando.

### Campos Obrigatórios
```
<fqdn> = Como você deseja acessar seu painel. Ex. painel.dominio.ltda
<ssl> = Se deseja usar SSL. As opções são true ou false.
<email> = Seu e-mail. Se escolher SSL, será compartilhado com o Lets Encrypt.
<username> = Nome de usuário para a conta de administrador no Pterodactyl
<firstname> = Primeiro nome para a conta de administrador no Pterodactyl
<lastname> = Sobrenome para a conta de administrador no Pterodactyl
<password> = A senha para a conta de administrador no Pterodactyl
<wings> = Se deseja ter o Wings instalado automaticamente também. As opções são true ou false.
```

Você deve ser preciso ao usar este script. 1 erro de digitação e tudo pode dar errado.
Também precisa ser executado em uma versão limpa do Ubuntu ou Debian.

```bash
bash <(curl -s https://raw.githubusercontent.com/guldkage/Pterodactyl-Installer/main/autoinstall.sh)  <fqdn> <ssl> <email> <username> <firstname <lastname> <password> <wings>
```
```