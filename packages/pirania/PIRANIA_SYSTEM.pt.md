# Visao geral do sistema Pirania

Este documento explica como o Pirania esta organizado, o que cada componente faz e como o fluxo do portal cativo funciona nos modos de voucher e de ler-para-acesso. Ele se baseia no codigo atual em `packages/pirania/`.

## 1. O que e o Pirania

Pirania e um portal cativo para nos OpenWrt/LibreMesh. Ele controla o acesso a Internet por endereco MAC e oferece dois modos de acesso:

- **Modo voucher**: a pessoa usuaria precisa informar um codigo de voucher; o voucher fica associado ao MAC do dispositivo.
- **Modo ler-para-acesso**: a pessoa usuaria ve a pagina do portal e espera uma contagem regressiva; o MAC fica temporariamente autorizado.

A lista de autorizacao e armazenada localmente e sincronizada com as regras do nftables para que os dispositivos autorizados passem direto pelo portal.

## 2. Arquitetura de alto nivel

```
Dispositivo cliente
  -> regras nftables (capturam DNS/HTTP/HTTPS para MACs nao autorizados)
  -> DNS local na porta 59053 (pirania-dnsmasq)
  -> redirecionamento HTTP local na porta 59080 (pirania-uhttpd)
  -> paginas do portal em /www/portal/
  -> handlers CGI autorizam o MAC
  -> captive-portal update (atualiza o set de MACs no nftables)
  -> acesso normal a Internet
```

O comportamento central e implementado por:

- `packages/pirania/files/usr/bin/captive-portal`
- `packages/pirania/files/etc/init.d/pirania-dnsmasq`
- `packages/pirania/files/etc/init.d/pirania-uhttpd`
- `packages/pirania/files/www/pirania-redirect/redirect`
- `packages/pirania/files/usr/lib/lua/portal/portal.lua`

## 3. Configuracao (UCI)

O arquivo principal de configuracao e `packages/pirania/files/etc/config/pirania`.

Opcoes principais em `base_config`:

- `enabled`: se o portal esta ativo no boot
- `with_vouchers`: alterna entre modo voucher e modo ler-para-acesso
- `portal_domain`: dominio usado nas URLs do portal (padrao `thisnode.info`)
- `url_auth`, `url_authenticated`, `url_info`, `url_fail`: caminhos das paginas do portal
- `db_path`: diretorio do banco de vouchers (arquivos JSON)
- `hooks_path`: diretorio de scripts de hook (ex.: sincronizacao shared-state)
- `allowlist_ipv4`, `allowlist_ipv6`: faixas que bypassam o portal cativo

Opcoes do modo de acesso ficam em `config access_mode 'read_for_access'`:

- `url_portal`: caminho para a pagina de ler-para-acesso
- `duration_m`: duracao da autorizacao em minutos

## 4. Servicos e inicializacao

- `packages/pirania/files/etc/init.d/pirania` inicia o portal se estiver habilitado e executa hooks.
- `packages/pirania/files/etc/init.d/pirania-dnsmasq` roda um dnsmasq dedicado na porta 59053.
- `packages/pirania/files/etc/init.d/pirania-uhttpd` roda um uhttpd pequeno na porta 59080.
- `packages/pirania/files/etc/uci-defaults/90-captive-portal-cron` instala um cron para atualizar o nftables a cada 10 minutos.

## 5. Captura de trafego (nftables)

`packages/pirania/files/usr/bin/captive-portal` configura regras nftables na tabela `inet pirania`:

- Cria sets para MACs autorizados (`pirania-auth-macs`) e faixas IPv4/IPv6 na allowlist.
- Redireciona DNS (UDP/53) para a porta 59053 para MACs nao autorizados.
- Redireciona HTTP (TCP/80) para a porta 59080 para MACs nao autorizados.
- Bloqueia HTTPS (TCP/443) para MACs nao autorizados.
- Libera trafego para MACs em `pirania-auth-macs` e destinos nas allowlists.

Os MACs autorizados vem de `packages/pirania/files/usr/bin/pirania_authorized_macs`, que delega para a biblioteca Lua do portal e retorna MACs do modo voucher ou do modo ler-para-acesso.

## 6. Sequestro de DNS

`packages/pirania/files/etc/init.d/pirania-dnsmasq` inicia uma instancia de dnsmasq que:

- Resolve `thisnode.info` para o IP do no.
- Usa hosts do shared-state em `/var/hosts/shared-state-dnsmasq_hosts`.
- Envia dominios desconhecidos para um IP de fallback (1.2.3.4).

Isso garante que o dominio do portal resolva localmente quando a pessoa usuaria estiver capturada.

## 7. Servico de redirecionamento HTTP

`packages/pirania/files/etc/init.d/pirania-uhttpd` inicia um servidor HTTP na porta 59080 servindo `packages/pirania/files/www/pirania-redirect/redirect`.

O script de redirecionamento:

- Monta a URL `prev` a partir da requisicao original.
- Escolhe a pagina de entrada do portal com base em `with_vouchers`:
  - Modo voucher: `base_config.url_auth`
  - Modo ler-para-acesso: `read_for_access.url_portal`
- Envia um redirect 302 para `http://<portal_domain><path>?prev=<original>`.

## 8. Paginas e assets do portal

As paginas estaticas ficam em `packages/pirania/files/www/portal/`:

- `auth.html` (entrada de voucher)
- `info.html` (espera/informacao)
- `authenticated.html` (sucesso)
- `fail.html` (erro)
- `read_for_access.html` (fluxo sem voucher)

O conteudo do portal (titulo, texto, logo, cores) fica em `packages/pirania/files/etc/pirania/portal.json`. O modulo Lua `packages/pirania/files/usr/lib/lua/portal/portal.lua` pode ler/atualizar esse conteudo e sincroniza-lo via shared-state (`pirania_persistent`).

## 9. Subsistema de vouchers

A logica de vouchers fica em `packages/pirania/files/usr/lib/lua/voucher/` e e exposta pela CLI `packages/pirania/files/usr/bin/voucher`.

Arquivos principais:

- `vouchera.lua`: modelo e operacoes de voucher (criar, ativar, invalidar, listar, status).
- `store.lua`: armazenamento em JSON (`db_path/<id>.json`).
- `config.lua`: le `db_path`, `hooks_path`, configuracao de pruning.
- `hooks.lua`: executa hooks em `hooks_path/<action>/` quando ha mudancas.
- `utils.lua`: parsing de URL e descoberta de IP/MAC via ARP/neigh.

Ciclo de vida do voucher:

1. **Criar**: `voucher add` chama `vouchera.create`, grava um JSON e dispara `hooks.run('db_change')`.
2. **Ativar**: o codigo e associado a um MAC e `captive-portal update` atualiza o nftables.
3. **Invalidar**: define `invalidation_date`, mantendo o registro para pruning; atualiza o nftables se necessario.
4. **Prunar**: vouchers expirados/invalidos sao removidos quando `vouchera.init()` roda.

A CLI encapsula essas operacoes em `packages/pirania/files/usr/bin/voucher`.

## 10. Subsistema de ler-para-acesso

O modo ler-para-acesso usa:

- `packages/pirania/files/usr/lib/lua/read_for_access/read_for_access.lua`
- `packages/pirania/files/usr/lib/lua/read_for_access/cgi_handlers.lua`

MACs sao armazenados em `/tmp/pirania/read_for_access/auth_macs` com timestamp de expiracao (baseado em uptime). Quando a pessoa usuaria conclui a espera no portal, o MAC e adicionado e `captive-portal update` atualiza o nftables.

## 11. Endpoints CGI

As paginas do portal chamam scripts CGI em `packages/pirania/files/www/cgi-bin/pirania/`:

- `preactivate_voucher`: valida voucher e redireciona para `info.html` (fluxo com JS) ou ativa imediatamente (fluxo sem JS).
- `activate_voucher`: endpoint final de ativacao, associa voucher ao MAC.
- `authorize_mac`: usado no modo ler-para-acesso para autorizar um MAC por tempo limitado.
- `client_ip`: endpoint legado que referencia modulos antigos e nao e usado no fluxo atual de voucher.

## 12. API Ubus/rpcd

O servico ubus esta em `packages/pirania/files/usr/libexec/rpcd/pirania` e e exposto via ACLs em `packages/pirania/files/usr/share/rpcd/acl.d/pirania.json`.

Chamadas suportadas incluem:

- `get_portal_config`, `set_portal_config`
- `add_vouchers`, `list_vouchers`, `invalidate`, `rename`
- `get_portal_page_content`, `set_portal_page_content`

Essas chamadas sao consumidas pela Lime-App ou outras ferramentas de gestao.

## 13. Testes

Os testes do Pirania ficam em `packages/pirania/tests/` e cobrem fluxos do portal, logica de vouchers, handlers rpcd e helpers CGI.

## 14. Resumo do fluxo ponta a ponta

Modo voucher:

1. A pessoa usuaria acessa um site externo; DNS/HTTP sao redirecionados para o Pirania.
2. A pessoa usuaria chega em `auth.html` e envia o codigo de voucher.
3. `preactivate_voucher` valida o codigo; se valido, a pessoa usuaria espera em `info.html` (fluxo JS) e entao chama `activate_voucher`.
4. O voucher e associado ao MAC e o nftables e atualizado.
5. A pessoa usuaria e redirecionada para a URL original ou para `authenticated.html`.

Modo ler-para-acesso:

1. A pessoa usuaria acessa um site externo; DNS/HTTP sao redirecionados para o Pirania.
2. A pessoa usuaria chega em `read_for_access.html` e espera a contagem.
3. `authorize_mac` grava o MAC com TTL curto e atualiza o nftables.
4. A pessoa usuaria e redirecionada para a URL original ou para `authenticated.html`.

## 15. Observacoes e ressalvas

- A implementacao atual usa **nftables** (nao iptables) via `captive-portal`.
- `catch_interfaces`/`catch_bridged_interfaces` existem no UCI mas nao sao aplicadas nas regras nftables atualmente.
- O CGI `client_ip` parece depender de modulos legados (`voucher.logic`, `voucher.db`).

---

Se quiser, posso adicionar uma secao curta de guia operacional (comandos comuns, troubleshooting, ou um diagrama de fluxo) baseada no seu modo de deploy do Pirania.
