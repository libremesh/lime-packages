![PIRANHA](https://i.imgur.com/kHWUNOu.png)

## Solução de Voucher e Portal Cativo para redes comunitárias

Esta ferramenta permite que um administrador gerencie um sistema de voucher para controlar o acesso a internet.

Pode ser usado em uma comunidade que deseja compartilhar uma conexão de Internet e para isso os usuários pagam uma parte cada um, mas precisa do pagamento de todos. Então os vouchers permitem controlar os pagamentos através do controle do acesso à Internet.

Além disso, o uso de vouchers pode ser desativado para usar o portal cativo apenas para mostrar informações valiosas (divulgação de um evento, por exemplo) para os visitantes da rede.
## Recursos

Estes são os recursos implementados atualmente:
* Executa diretamente do roteador OpenWRT/LEDE: não há necessidade de hardware extra
* Integra sua administração com o Ubus e o LiMe App
* Possui uma interface de linha de comando para listar, criar e remover vouchers
* O banco de dados de vouchers é compartilhado entre os nós da rede
* O conteúdo da tela inicial do portal (logotipo, título, texto principal, etc.) é distribuído pela rede.
* Pode ser usado sem vouchers.
## Pré-requisitos

Este software pressupõe que será executado em uma distribuição OpenWRT/LEDE (porque usa uci para configuração). Precisa dos pacotes `nftables, liblucihttp0, liblucihttp-lua, uhttpd, uhttpd-mod-lua, uhttpd-mod-ubus`  instalados. 

Os dispositivos (Android, iOS, PC) não devem ter o recurso de MAC aleatório ativado, caso contrário a autenticação por endereço MAC não funcionará.
Essa configuração pode ser alterada [ao se conectar a rede](https://imgur.com/a/4bjBWJQ) ou após estar conectado, [indo nas configurações da rede wifi](https://imgur.com/a/qGpHS4b).


## Instalar

* adicionar o feed de software libremesh ao opkg
* opkg install pirania

## Linha de comando

`epoc` é expresso no formato [Unix Timestamp](https://en.wikipedia.org/wiki/Unix_time). Você pode usar uma ferramenta como [unixtimestamp.com](https://www.unixtimestamp.com/) para obter uma data no formato correto.

### `captive_portal status`

Imprime o status do pirania: habilitado ou desabilitado.

### `captive_portal start`

Inicia o pirania. Se você quiser que o pirania inicie automaticamente, use: `uci set pirania.base_config.enabled=1 && uci commit`

### `captive_portal stop`

Para o pirania. Se você quiser que o pirania pare de iniciar automaticamente, use: `uci set pirania.base_config.enabled=0 && uci commit`

#### `voucher list`

Lista todos os vouchers.

### `voucher list_active`

Lista todos os vouchers que estão ativos no momento.

### `voucher add`

Cria um novo voucher. Este voucher começará desativado e não vinculado a nenhum dispositivo.

Parâmetros:
- `name`: um nome usado para identificar o voucher
- `duration-m`: duração do voucher em minutos. Se nenhum valor for fornecido, um voucher com acesso ilimitado será criado.
A duração entra em vigor quando o voucher é ativado.
- `activation-deadline`: após esta data (horário unix), o voucher não pode ser ativado.

Para criar um voucher de 60 minutos
Ex.: `voucher add my-voucher-name 60`

### `voucher activate`

Ativa um voucher, atribuindo um endereço MAC. Após a ativação, o dispositivo com este
endereço MAC terá acesso à Internet.

Parâmetros:
- `secret-code`: a senha do voucher.
- `mac`: o endereço MAC do dispositivo que terá acesso.

Ex: `voucher activate mysecret 00:11:22:33:44:55`

### `voucher deactivate`

Desativa um voucher com `ID` específico.

Parâmetros:
- `ID`: uma string usada para identificar o voucher.

Ex: `voucher deactivate Qzt3WF`

### `voucher remove_voucher`

Invalida um voucher alterando sua data de expiração para 0.

Parâmetros:
- `voucher`: voucher secret

Ex.: `voucher remove_voucher voucher-secret`

### `voucher is_mac_authorized`

Verifica se um endereço mac específico está autorizado.

Parâmetros:
- `mac`: endereço mac de um dispositivo

Ex.: `voucher is_mac_authorized d0:82:7a:49:e2:37`

### `voucher renew_voucher`

Altere a data de expiração de um voucher.

Parâmetros:
- `id`: o ID do voucher.
- `expiration-date`: a nova data (horário unix) em que o voucher irá expirar

Ex.: `voucher renew_voucher Qzt3WF 1619126965`

# Como funciona

Ele usa regras iptables para filtrar conexões de entrada fora da rede mesh.

## Visão geral da hierarquia de arquivos e função

```
files/
/etc/config/pirania é a configuração UCI
/etc/pirania/vouchers/ (caminho padrão) contém o banco de dados de vouchers
/etc/init.d/pirania-uhttpd inicia um uhttpd na porta 59080 que responde a qualquer solicitação com um redirecionamento para uma URL predefinida

/usr/lib/lua/voucher/ contém bibliotecas lua usadas por /usr/bin/voucher
/usr/bin/voucher é uma CLI para gerenciar o banco de dados (tem funções list, list_active, show_authorized_macs, add, activate, deactivate e is_mac_authorized)
/usr/bin/captive-portal configura regras iptables para capturar tráfego

/usr/libexec/rpcd/pirania ubus pirania API (isso é usado pelo frontend da web)
/usr/share/rpcd/acl.d/pirania.json ACL para a API ubus pirania

/etc/shared-state/publishers/shared-state-publish_vouchers insere no shared-state o banco de dados de vouchers local
/etc/shared-state/hooks/pirania/generate_vouchers traz vouchers atualizados ou novos do banco de dados shared-state para o banco de dados de vouchers local

/usr/lib/lua/read_for_access contém a biblioteca usada por
/usr/lib/lua/portal para gerenciar o acesso no modo de leitura para acesso (também conhecido como sem vouchers)
```

## Exemplo de uso de CLI

```
$ voucher list
$ voucher add san-notebook 60
Q3TJZS san-notebook ZRJUXN xx:xx:xx:xx:xx:xx Qua Set 8 23:47:40 2021 60 - 1
$ voucher list
Q3TJZS san-notebook ZRJUXN xx:xx:xx:xx:xx:xx Qua Set 8 23:47:40 2021 60 - 1
$ voucher list_active
$ voucher activate ZRJUXN 00:11:22:33:44:55
Voucher ativado!
$ voucher list
Q3TJZS san-notebook ZRJUXN 00:11:22:33:44:55 Qua Set 8 23:47:40 2021 60 Qui Set 9 00:48:33 2021 2

$ voucher list_active
Q3TJZS san-notebook ZRJUXN 00:11:22:33:44:55 Qua Set 8 23:47:40 2021 60 Qui Set 9 00:48:33 2021 2

$ voucher deactivate Q3TJZS
ok
$ voucher list_active
$ voucher list
Q3TJZS san-notebook ZRJUXN xx:xx:xx:xx:xx:xx Qua Set 8 23:47:40 2021 60 - 3
```

## API ubus

* enable() -> chama `captive-portal start` e habilita na configuração
* disable() -> chama `captive-portal stop` e desabilita na configuração
* show_url() -> retorna a configuração `pirania.base_config.portal_url`
* change_url(url) -> altera a configuração `pirania.base_config.portal_url`
* ...

## Por baixo dos panos

### Captura de tráfego
`/usr/bin/captive-portal` configura regras do iptables para capturar tráfego.
Ele cria um conjunto de regras que se aplicam a 3 "ipsets" permitidos:
* pirania-auth-macs: macs autorizados entram nesta regra. começa vazio.
* pirania-allowlist-ipv4: com os membros da lista de permissões no arquivo de configuração (10.0.0.0/8, 192.168.0.0/16, 172.16.0.0/12)
* pirania-allowlist-ipv6: o mesmo que ipv4, mas para ipv6

Regras:
* Pacotes DNS, que não são dos ipsets permitidos, são redirecionados para nosso próprio DNS de portal cativo em 59053
* Pacotes HTTP, que não são dos ipsets permitidos, são redirecionados para nosso próprio HTTP de portal cativo em 59080
* Pacotes dos ipsets permitidos são permitidos
* O restante dos pacotes é rejeitado (descartado e enviado um erro para o cliente)

### Fluxo HTTP

`/etc/init.d/pirania-uhttpd` inicia um servidor HTTP (uhttpd) na porta 59080 que responde a qualquer solicitação com um redirecionamento para uma URL predefinida.
- Caso o uso do voucher esteja ativado: `pirania.base_config.url_auth`.
- Caso contrário: `pirania.read_for_access.url_portal`
Isso é realizado pelo script lua `/www/pirania-redirect/redirect`. Como ambas as URLs estão no intervalo de IP da lista de permissões (http://thisnode.info/portal/ por padrão), o servidor HTTP "normal" escutando na porta 80 responderá após o redirecionamento.

Então o fluxo ao usar vouchers é:
* navegar para um IP não permitido: por exemplo `http://orignal.org/baz/?foo=bar`
* ser redirecionado com um 302 onde você pode colocar um código de voucher para entrar: `http://thisnode.info/cgi-bin/portal/auth.html?prev=http%3A%2F%2Foriginal.org%2Fbaz%2F%3Ffoo%3Dbar`
* enviar o formulário deve executar um GET para `http://thisnode.info/cgi-bin/pirania/preactivate_voucher?voucher=secretcode&prev=http%3A%2F%2Foriginal.org%2Fbaz%2F%3Ffoo%3Dbar`
* O script preactivate_voucher faz duas coisas diferentes dependendo do suporte a javascript:
* Se nojs=true então o voucher é ativado com o MAC do cliente (obtido da tabela ARP com seu IP) e o código do voucher. Se a ativação for bem-sucedida, ele redireciona para `url_authenticated`.
* Se nojs=false, há uma verificação se o código do voucher seria válido (há um voucher válido e não utilizado com esse código). Se o voucher for válido, então um redirecionamento para a página INFO do portal (`pirania.base_config.url_info`) é executado com o código do voucher como parâmetro url. As informações do portal mostram as informações atualizadas da comunidade e há um tempo que você tem que esperar para poder continuar (isso é feito com JS). Quando o cronômetro chegar a 0, você pode clicar em continuar. Isso redireciona agora para `http://thisnode.info/cgi-bin/pirania/activate_voucher?voucher=secretcode`. O script `activate_voucher` faz a ativação do voucher. então ele redireciona para `url_authenticated`. Se o código falhar, ele redirecionará para `http://thisnode.info/cgi-bin/portal/fail.html` que é idêntico a auth.html, mas com uma mensagem de erro.

O fluxo sem usar vouchers (leia-se para o modo de acesso) é:
* navegue para um IP não permitido: por exemplo `http://orignal.org/baz/?foo=bar`
* seja redirecionado com um 302 para: `http://thisnode.info/cgi-bin/portal/read_for_access.html?prev=http%3A%2F%2Foriginal.org%2Fbaz%2F%3Ffoo%3Dbar`
* Uma vez lá, se o cliente tiver suporte a js, uma contagem regressiva de 15 segundos será exibida e quando chegar a 0, o usuário poderá clicar em continuar, o que envia uma solicitação GET para `http://minodo.info/cgi-bin/pirania/authorize_mac?prev=http%3A%2F%2Foriginal.org%2Fbaz%2F%3Ffoo%3Dbar`
o que acionará um redirecionamento para a url `prev`.
* Se o cliente não tiver suporte a js, o botão será habilitado imediatamente e, após clicar em continuar, um redirecionamento para `url_authenticated` será acionado.