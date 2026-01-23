# Pirania - Documentacao Tecnica Detalhada

## Visao Geral

O **Pirania** e um sistema de **Portal Cativo com Vouchers** para redes comunitarias que rodam sobre **OpenWrt**/**LibreMesh**. Ele permite controlar o acesso a internet atraves de:

1. **Modo Voucher**: Usuarios precisam de um codigo (voucher) para acessar a internet
2. **Modo Read For Access**: Usuarios aguardam um tempo para ter acesso (sem voucher)

---

## Glossario de Termos e Tecnologias

> **Dica:** Termos tecnicos estao em **negrito** ao longo do documento. Consulte esta secao para ver as definicoes.

### Linguagens de Programacao

| Linguagem | Descricao | Uso no Pirania |
|-----------|-----------|----------------|
| **Lua** | Linguagem de script leve e rapida, muito usada em sistemas embarcados. Sintaxe simples, tipagem dinamica. | Backend principal: logica de vouchers, handlers CGI, API ubus |
| **Shell Script (sh)** | Linguagem de comandos do Unix/Linux para automacao. | Script `captive-portal` que configura firewall |
| **JavaScript (JS)** | Linguagem de programacao para web, roda no navegador. | Frontend: interacao com usuario, countdown, chamadas ubus |
| **HTML** | Linguagem de marcacao para estruturar paginas web. | Paginas do portal cativo |
| **CSS** | Linguagem de estilos para aparencia visual de paginas web. | Estilizacao das paginas do portal |
| **JSON** | Formato de dados texto, facil de ler e escrever. | Armazenamento de vouchers, configuracoes, comunicacao API |

### Sistemas e Plataformas

| Termo | Descricao |
|-------|-----------|
| **OpenWrt** | Sistema operacional Linux para roteadores. Leve, customizavel, base do LibreMesh. |
| **LibreMesh** | Firmware para redes mesh comunitarias, construido sobre OpenWrt. Permite criar redes descentralizadas. |
| **Roteador** | Dispositivo que conecta redes e direciona pacotes de dados entre elas. |
| **Firmware** | Software permanente gravado no hardware do roteador. |

### Conceitos de Rede

| Termo | Descricao |
|-------|-----------|
| **Portal Cativo** | Pagina web que aparece automaticamente quando voce conecta em uma rede WiFi, pedindo login ou aceitacao de termos. |
| **MAC Address** | Endereco fisico unico de cada placa de rede (ex: `AA:BB:CC:DD:EE:FF`). Usado para identificar dispositivos. |
| **IP Address** | Endereco logico de um dispositivo na rede (ex: `192.168.1.100` para IPv4, `fe80::1` para IPv6). |
| **IPv4** | Versao 4 do protocolo IP. Enderecos com 4 numeros (ex: `10.0.0.1`). |
| **IPv6** | Versao 6 do protocolo IP. Enderecos mais longos (ex: `fc00::1`). Suporta mais dispositivos. |
| **DNS** | Sistema que traduz nomes (ex: `google.com`) para IPs. Como uma "agenda telefonica" da internet. |
| **HTTP/HTTPS** | Protocolos para transferir paginas web. HTTPS e a versao segura (criptografada). |
| **Porta** | Numero que identifica um servico especifico (ex: porta 80 = HTTP, porta 443 = HTTPS). |
| **Firewall** | Sistema que filtra trafego de rede, permitindo ou bloqueando conexoes. |
| **Rede Mesh** | Rede onde cada no pode se conectar a varios outros, sem ponto central. Mais resiliente. |
| **ARP** | Protocolo que mapeia IPs para MACs na rede local. |
| **Bridge** | Conexao que une duas redes como se fossem uma so. |

### Ferramentas e Servicos

| Termo | Descricao | Uso no Pirania |
|-------|-----------|----------------|
| **nftables** | Framework moderno de firewall do Linux. Substitui iptables. | Captura e redireciona trafego de usuarios nao autorizados |
| **iptables** | Framework antigo de firewall do Linux (versao anterior usava). | Substituido por nftables |
| **dnsmasq** | Servidor DNS e DHCP leve. | `pirania-dnsmasq`: DNS que redireciona usuarios para o portal |
| **uhttpd** | Servidor HTTP leve para OpenWrt. | `pirania-uhttpd`: serve paginas do portal cativo |
| **ubus** | Sistema de comunicacao entre processos no OpenWrt. Como um "barramento" de mensagens. | API para LiMe-App e outros aplicativos |
| **rpcd** | Daemon que expoe funcoes via ubus. | Expoe API do pirania |
| **procd** | Sistema de init e gerenciamento de processos do OpenWrt. | Gerencia servicos pirania-dnsmasq e pirania-uhttpd |
| **cron** | Agendador de tarefas periodicas no Linux. | Atualiza MACs autorizados a cada 10 minutos |
| **shared-state** | Sistema LibreMesh para sincronizar dados entre nos da rede mesh. | Sincroniza vouchers entre todos os roteadores |

### Estrutura de Arquivos Linux/OpenWrt

| Caminho | Descricao |
|---------|-----------|
| `/etc/config/` | Arquivos de configuracao UCI (formato especifico do OpenWrt) |
| `/etc/init.d/` | Scripts de inicializacao de servicos. Controlam start/stop de programas. |
| `/etc/uci-defaults/` | Scripts executados uma vez apos instalacao de pacote. |
| `/usr/bin/` | Programas executaveis disponiveis para todos usuarios. |
| `/usr/lib/lua/` | Bibliotecas Lua compartilhadas. |
| `/usr/libexec/rpcd/` | Scripts que expoe funcoes via ubus/rpcd. |
| `/usr/share/rpcd/acl.d/` | Arquivos de controle de acesso para API ubus. |
| `/www/` | Arquivos servidos pelo servidor web (paginas HTML, CSS, JS). |
| `/www/cgi-bin/` | Scripts CGI executados pelo servidor web. |
| `/tmp/` | Arquivos temporarios (perdidos ao reiniciar). |

### Conceitos de Programacao

| Termo | Descricao |
|-------|-----------|
| **CGI** | Common Gateway Interface. Forma de executar scripts no servidor quando uma URL e acessada. |
| **API** | Interface de Programacao. Forma padronizada de um programa se comunicar com outro. |
| **Handler** | Funcao que "trata" ou "responde" a um evento ou requisicao. |
| **Callback** | Funcao passada como parametro para ser executada depois. |
| **Hook** | Ponto onde codigo externo pode ser executado. Permite extensibilidade. |
| **Modulo** | Arquivo de codigo que pode ser importado e reutilizado. |
| **Closure** | Funcao que "lembra" variaveis do contexto onde foi criada. |
| **JSON-RPC** | Protocolo para chamar funcoes remotamente usando JSON. |
| **Redirect 302** | Resposta HTTP que diz ao navegador para ir para outra URL. |
| **Query String** | Parte da URL apos `?` com parametros (ex: `?voucher=ABC123`). |
| **Timestamp** | Numero que representa data/hora (segundos desde 1970). |

### Termos Especificos do Pirania

| Termo | Descricao |
|-------|-----------|
| **Voucher** | Codigo que da acesso a internet por tempo limitado. |
| **Voucher ID** | Identificador interno unico do voucher (6 caracteres). |
| **Voucher Code** | Codigo secreto que o usuario digita para ativar (6 caracteres). |
| **Ativacao** | Momento em que um voucher e associado a um MAC e comeca a contar tempo. |
| **Invalidacao** | Cancelamento de um voucher (soft delete - mantem registro). |
| **Pruning** | Limpeza automatica de vouchers muito antigos do banco de dados. |
| **Allowlist** | Lista de IPs que sempre tem acesso (redes locais, mesh). |
| **Read For Access** | Modo sem voucher: usuario aguarda X segundos e ganha acesso temporario. |
| **thisnode.info** | Dominio especial que sempre aponta para o roteador local. |
| **anygw** | IP do gateway compartilhado na rede mesh LibreMesh. |

### Siglas

| Sigla | Significado |
|-------|-------------|
| **UCI** | Unified Configuration Interface - sistema de config do OpenWrt |
| **ACL** | Access Control List - lista de controle de acesso |
| **DHCP** | Dynamic Host Configuration Protocol - atribui IPs automaticamente |
| **NAT** | Network Address Translation - traduz IPs privados para publicos |
| **TCP** | Transmission Control Protocol - protocolo de transporte confiavel |
| **UDP** | User Datagram Protocol - protocolo de transporte rapido |
| **RFC** | Request for Comments - documentos que definem padroes da internet |

---

## Arquitetura de Alto Nivel

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           PIRANIA - ARQUITETURA                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────┐     ┌──────────────┐     ┌─────────────────────────────┐  │
│  │   Cliente   │────▶│   nftables   │────▶│  Captive Portal (porta 59080)│  │
│  │  (Browser)  │     │   (filtro)   │     │     pirania-uhttpd          │  │
│  └─────────────┘     └──────────────┘     └──────────────┬──────────────┘  │
│                                                          │                  │
│                                                          ▼                  │
│                      ┌───────────────────────────────────────────────────┐  │
│                      │              /www/pirania-redirect/redirect       │  │
│                      │         (Redireciona para portal de autenticacao) │  │
│                      └───────────────────────────────────────────────────┘  │
│                                           │                                 │
│                    ┌──────────────────────┼────────────────────┐            │
│                    ▼                      ▼                    ▼            │
│  ┌──────────────────────┐  ┌───────────────────┐  ┌────────────────────┐   │
│  │  /portal/auth.html   │  │/portal/info.html  │  │/portal/read_for_   │   │
│  │   (Form voucher)     │  │  (Info comunidade)│  │   access.html      │   │
│  └──────────┬───────────┘  └─────────┬─────────┘  └────────┬───────────┘   │
│             │                        │                     │               │
│             ▼                        ▼                     ▼               │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │                      CGI Scripts (/cgi-bin/pirania/)                 │  │
│  │  preactivate_voucher │ activate_voucher │ authorize_mac │ client_ip  │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                      │                                      │
│                                      ▼                                      │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │                     Bibliotecas Lua (/usr/lib/lua/)                  │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌────────────────┐  ┌──────────┐  │  │
│  │  │   voucher/  │  │   portal/   │  │read_for_access/│  │ ubus API │  │  │
│  │  │  vouchera   │  │   portal    │  │read_for_access │  │ pirania  │  │  │
│  │  │   store     │  │             │  │ cgi_handlers   │  │          │  │  │
│  │  │  config     │  └─────────────┘  └────────────────┘  └──────────┘  │  │
│  │  │   utils     │                                                      │  │
│  │  │   hooks     │                                                      │  │
│  │  │ functools   │                                                      │  │
│  │  │cgi_handlers │                                                      │  │
│  │  └─────────────┘                                                      │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                      │                                      │
│                                      ▼                                      │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │                    Banco de Dados (JSON files)                       │  │
│  │                   /etc/pirania/vouchers/*.json                       │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                      │                                      │
│                                      ▼                                      │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │                      shared-state-pirania                            │  │
│  │           (Sincronizacao entre nos da rede mesh)                     │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Componentes Macro

### 1. Captura de Trafego (`/usr/bin/captive-portal`)

Script **Shell** que configura regras **nftables** para interceptar trafego.

**Dependencias:** `nftables`, `liblucihttp0`, `liblucihttp-lua`, `uhttpd`, `uhttpd-mod-lua`, `uhttpd-mod-ubus`

**Funcionalidades:**
- `start`: Inicia servicos DNS/HTTP, limpa tabelas e configura regras nftables
- `stop/clean`: Remove tabela nftables do pirania
- `update`: Atualiza sets com MACs autorizados
- `enabled`: Habilita pirania na config UCI

**Sets nftables criados (tabela `inet pirania`):**
- `pirania-auth-macs`: MACs autorizados (type ether_addr)
- `pirania-allowlist-ipv4`: IPs IPv4 permitidos sem autenticacao (type ipv4_addr, flags interval)
- `pirania-allowlist-ipv6`: IPs IPv6 permitidos sem autenticacao (type ipv6_addr, flags interval)

**Chains nftables:**
- `prerouting`: type nat hook prerouting priority 0
- `input`: type filter hook input priority 0
- `forward`: type filter hook forward priority 0

**Regras principais (chain prerouting):**
1. MACs autorizados (`@pirania-auth-macs`) → ACCEPT
2. Destino em allowlist IPv4 (`@pirania-allowlist-ipv4`) → ACCEPT
3. Destino em allowlist IPv6 (`@pirania-allowlist-ipv6`) → ACCEPT
4. DNS (porta 53) de MACs nao autorizados → redirect para porta 59053
5. HTTP (porta 80) de MACs nao autorizados → redirect para porta 59080
6. HTTPS (porta 443) de MACs nao autorizados → DROP

### 2. Servidor HTTP do Portal (`pirania-uhttpd`)

**Init script:** `/etc/init.d/pirania-uhttpd`

Inicia um servidor **uhttpd** na porta **59080** que responde qualquer requisicao com um **redirecionamento 302** para o portal de autenticacao.

**Comando:** `uhttpd -k 0 -f -h /www/pirania-redirect/ -E / -l / -L /www/pirania-redirect/redirect -n 20 -p 59080`

### 3. Servidor DNS do Portal (`pirania-dnsmasq`)

**Init script:** `/etc/init.d/pirania-dnsmasq`

Inicia um **dnsmasq** na porta **59053** que:
- Resolve `thisnode.info` para o IP do no (**anygw**)
- Resolve outros dominios para `1.2.3.4` (forcando redirecionamento)

### 4. Sistema de Vouchers (Lua)

Gerencia criacao, ativacao, desativacao e validacao de vouchers.

### 5. Sistema Read For Access (Lua)

Alternativa ao voucher - autoriza MAC por tempo apos aguardar periodo.

### 6. API ubus/RPCD

Expoe funcionalidades via **ubus** para integracao com LiMe-App.

### 7. Sincronizacao entre Nos (`shared-state-pirania`)

Sincroniza banco de vouchers entre todos os nos da rede mesh usando **shared-state**.

---

## Estrutura de Arquivos Detalhada

### `/packages/pirania/`

```
pirania/
├── Makefile                    # Build do pacote OpenWrt
├── Readme.md                   # Documentacao em ingles
├── Leeme.md                    # Documentacao em espanhol
├── PIRANIA_SYSTEM.md           # Documentacao tecnica (EN)
├── PIRANIA_SYSTEM.pt.md        # Documentacao tecnica (PT)
├── PIRANIA_FLUXO_SIMPLIFICADO.pt.md  # Fluxo simplificado (PT)
│
├── files/
│   ├── etc/
│   │   ├── config/
│   │   │   └── pirania         # Configuracao UCI principal
│   │   │
│   │   ├── init.d/
│   │   │   ├── pirania         # Init script principal
│   │   │   ├── pirania-dnsmasq # Init do DNS captivo
│   │   │   └── pirania-uhttpd  # Init do HTTP captivo
│   │   │
│   │   ├── pirania/
│   │   │   └── portal.json     # Conteudo default do portal (logo, texto)
│   │   │
│   │   └── uci-defaults/
│   │       └── 90-captive-portal-cron  # Configura cron para update
│   │
│   ├── usr/
│   │   ├── bin/
│   │   │   ├── captive-portal          # Script nftables (shell)
│   │   │   ├── voucher                 # CLI para vouchers (lua)
│   │   │   └── pirania_authorized_macs # Lista MACs autorizados (lua)
│   │   │
│   │   ├── lib/lua/
│   │   │   ├── voucher/                # Modulo principal de vouchers
│   │   │   │   ├── vouchera.lua        # Logica principal de vouchers
│   │   │   │   ├── store.lua           # Persistencia (JSON files)
│   │   │   │   ├── config.lua          # Carrega config UCI
│   │   │   │   ├── utils.lua           # Utilitarios (IP, MAC, URL)
│   │   │   │   ├── functools.lua       # Funcoes funcionais (map, filter)
│   │   │   │   ├── hooks.lua           # Sistema de hooks
│   │   │   │   └── cgi_handlers.lua    # Handlers para CGI
│   │   │   │
│   │   │   ├── portal/
│   │   │   │   └── portal.lua          # Configuracao e estado do portal
│   │   │   │
│   │   │   └── read_for_access/
│   │   │       ├── read_for_access.lua # Logica de acesso sem voucher
│   │   │       └── cgi_handlers.lua    # Handlers CGI para read_for_access
│   │   │
│   │   ├── libexec/rpcd/
│   │   │   └── pirania                 # API ubus/RPCD
│   │   │
│   │   └── share/rpcd/acl.d/
│   │       └── pirania.json            # ACL para API ubus
│   │
│   └── www/
│       ├── pirania-redirect/
│       │   └── redirect                # Script lua de redirecionamento
│       │
│       ├── cgi-bin/pirania/
│       │   ├── preactivate_voucher     # Pre-ativacao de voucher
│       │   ├── activate_voucher        # Ativacao de voucher
│       │   ├── authorize_mac           # Autorizacao MAC (read_for_access)
│       │   └── client_ip               # Retorna IP/MAC do cliente
│       │
│       └── portal/
│           ├── auth.html               # Pagina de entrada de voucher
│           ├── info.html               # Pagina de informacao da comunidade
│           ├── read_for_access.html    # Pagina para modo sem voucher
│           ├── authenticated.html      # Pagina de sucesso
│           ├── fail.html               # Pagina de erro
│           ├── css/
│           │   ├── main.css
│           │   ├── normalize.css
│           │   └── loader2.css
│           └── js/
│               ├── content.js          # Carrega conteudo do portal
│               ├── int.js              # Internacionalizacao
│               └── ubusFetch.js        # Cliente ubus para frontend
│
└── tests/
    ├── pirania_test_utils.lua
    ├── test_vouchera.lua
    ├── test_cgi_handlers.lua
    ├── test_pirania_rpcd.lua
    ├── test_portal.lua
    ├── test_read_for_access.lua
    └── test_redirect.lua
```

### `/packages/shared-state-pirania/`

```
shared-state-pirania/
├── Makefile
└── files/
    └── etc/
        ├── pirania/hooks/
        │   ├── db_change/
        │   │   ├── 01-publish_db       # Publica no shared-state
        │   │   └── 02-sync_db          # Sincroniza com outros nos
        │   └── start/
        │       └── 01-publish_and_sync # Na inicializacao
        │
        ├── shared-state/
        │   ├── hooks/pirania-vouchers/
        │   │   └── generate_vouchers   # Importa vouchers do shared-state
        │   └── publishers/
        │       └── shared-state-publish_vouchers  # Exporta vouchers
        │
        └── uci-defaults/
            └── 90-pirania-cron
```

---

## Analise Detalhada por Arquivo

### `/usr/bin/captive-portal` (Shell Script - nftables)

**Proposito:** Configura regras nftables para captura de trafego.

**Funcoes:**

| Funcao | Descricao |
|--------|-----------|
| `clean_tables()` | Remove tabela `inet pirania` se existir |
| `set_nftables()` | Cria tabela, chains e regras de captura |
| `update_ipsets()` | Atualiza sets com MACs autorizados e IPs da allowlist |

**Fluxo de `set_nftables()`:**
```
1. Cria tabela: nft create table inet pirania
2. Cria chains: prerouting (nat), input (filter), forward (filter)
3. Cria sets: pirania-auth-macs, pirania-allowlist-ipv4, pirania-allowlist-ipv6
4. Adiciona regras de ACCEPT para MACs/IPs autorizados
5. Adiciona regras de redirect para DNS (59053) e HTTP (59080)
6. Adiciona regra de DROP para HTTPS (443)
```

**Fluxo de `update_ipsets()`:**
```
1. Para cada MAC de pirania_authorized_macs:
   nft add element inet pirania pirania-auth-macs {$mac}
2. Flush e repopula allowlist IPv4 e IPv6 da config UCI
```

**Comandos disponiveis:**
- `captive-portal start` - Inicia servicos + configura nftables
- `captive-portal stop/clean` - Remove tabela nftables
- `captive-portal update` - Atualiza MACs autorizados
- `captive-portal enabled` - Habilita na config UCI

---

### Bibliotecas Lua

#### `/usr/lib/lua/voucher/vouchera.lua`

**Proposito:** Modulo principal para gerenciamento de vouchers.

**Imports:**
```lua
local store = require('voucher.store')
local config = require('voucher.config')
local utils = require('lime.utils')
local portal = require('portal.portal')
local hooks = require('voucher.hooks')
```

**Constantes:**
- `vouchera.ID_SIZE = 6` - Tamanho do ID do voucher
- `vouchera.CODE_SIZE = 6` - Tamanho do codigo secreto

**Estrutura do Voucher:**
```lua
voucher = {
    id,                -- Identificador unico (6 chars)
    name,              -- Nome descritivo
    code,              -- Codigo secreto para ativacao
    mac,               -- MAC do dispositivo (nil se nao ativado)
    duration_m,        -- Duracao em minutos (nil = permanente)
    mod_counter,       -- Contador de modificacoes
    creation_date,     -- Timestamp de criacao
    activation_date,   -- Timestamp de ativacao
    activation_deadline, -- Prazo limite para ativacao
    invalidation_date, -- Timestamp de invalidacao
    author_node        -- Hostname do no criador
}
```

**Metodos do Voucher (closure):**
- `tostring()` - Representacao string do voucher
- `expiration_date()` - Calcula data de expiracao
- `is_active()` - Verifica se esta ativo
- `is_invalidated()` - Verifica se foi invalidado
- `is_expired()` - Verifica se expirou
- `is_activable()` - Verifica se pode ser ativado
- `status()` - Retorna status: 'available', 'active', 'expired', 'invalidated'

**Funcoes Principais:**

| Funcao | Descricao | Retorno |
|--------|-----------|---------|
| `init(cfg)` | Inicializa modulo, carrega DB, faz pruning automatico | void |
| `add(obj)` | Adiciona novo voucher | voucher ou nil, errmsg |
| `create(basename, qty, duration_m, deadline)` | Cria multiplos vouchers | lista de {id, code} |
| `get_by_id(id)` | Busca voucher por ID | voucher ou nil |
| `activate(code, mac)` | Ativa voucher com MAC | voucher ou false |
| `deactivate(id)` | Desativa voucher | voucher |
| `invalidate(id)` | Invalida voucher (soft delete) | voucher |
| `remove_locally(id)` | Remove do DB local | true ou nil, errmsg |
| `is_mac_authorized(mac)` | Verifica se MAC esta autorizado | boolean |
| `is_activable(code)` | Verifica se codigo e ativavel | voucher ou false |
| `should_be_pruned(voucher)` | Verifica se deve ser removido | boolean |
| `rename(id, new_name)` | Renomeia voucher | voucher |
| `list()` | Lista todos vouchers formatados | lista de vouchers |
| `get_authorized_macs()` | Lista MACs autorizados | lista de MACs |
| `gen_code()` | Gera codigo aleatorio | string (6 chars uppercase) |

---

#### `/usr/lib/lua/voucher/store.lua`

**Proposito:** Persistencia de vouchers em arquivos JSON.

**Imports:**
```lua
local fs = require("nixio.fs")
local json = require("luci.jsonc")
local hooks = require('voucher.hooks')
local utils = require("voucher.utils")
```

**Funcoes:**

| Funcao | Descricao |
|--------|-----------|
| `load_db(db_path, voucher_init)` | Carrega todos `.json` do diretorio |
| `add_voucher(db_path, voucher, voucher_init)` | Salva voucher em arquivo JSON |
| `remove_voucher(db_path, voucher)` | Remove arquivo e registra em removed.txt |

**Formato do arquivo:** `{db_path}/{voucher_id}.json`

---

#### `/usr/lib/lua/voucher/config.lua`

**Proposito:** Carrega configuracoes do UCI.

**Configuracoes carregadas:**
```lua
config = {
    db_path,               -- Caminho da base de vouchers
    hooksDir,              -- Diretorio de hooks
    prune_expired_for_days -- Dias para manter vouchers expirados
}
```

---

#### `/usr/lib/lua/voucher/utils.lua`

**Proposito:** Utilitarios para manipulacao de IPs, MACs e URLs.

**Imports:**
```lua
local nixio = require('nixio')
local lhttp = require('lucihttp')
```

**Funcoes:**

| Funcao | Descricao |
|--------|-----------|
| `log(...)` | Wrapper para syslog |
| `getIpv4AndMac(ip_address)` | Obtem IPv4 e MAC de um IP (via ARP ou ip neigh) |
| `urldecode_params(url, tbl)` | Parseia query string |
| `urlencode(value)` | Codifica URL |
| `urldecode(value)` | Decodifica URL |

**Nota:** Para IPv6, usa `ip neigh` em vez de `ip neighbor` (corrigido nesta branch).

---

#### `/usr/lib/lua/voucher/functools.lua`

**Proposito:** Funcoes utilitarias de programacao funcional.

**Funcoes:**

| Funcao | Descricao |
|--------|-----------|
| `curry(func, num_args)` | Currying de funcoes |
| `reverse(...)` | Inverte ordem de argumentos |
| `map(func, tbl)` | Map sobre tabela |
| `filter(func, tbl)` | Filtra tabela |
| `search(func, tbl)` | Busca em tabela |

---

#### `/usr/lib/lua/voucher/hooks.lua`

**Proposito:** Sistema de **hooks** para eventos.

**Eventos disponiveis:**
- `db_change` - Quando a base de vouchers muda
- `start` - Quando o pirania inicia
- `stop` - Quando o pirania para

**Funcionamento:** Executa todos os scripts em `{hooksDir}/{action}/` em background.

---

#### `/usr/lib/lua/voucher/cgi_handlers.lua`

**Proposito:** Handlers para requisicoes CGI de vouchers.

**Imports:**
```lua
local vouchera = require('voucher.vouchera')
local utils = require('voucher.utils')
```

**Funcoes:**

| Funcao | Descricao |
|--------|-----------|
| `preactivate_voucher()` | Pre-ativacao: valida codigo, redireciona para info ou ativa |
| `activate_voucher()` | Ativacao final: associa MAC ao voucher |

---

#### `/usr/lib/lua/portal/portal.lua`

**Proposito:** Configuracao e estado do portal cativo.

**Imports:**
```lua
local utils = require('lime.utils')
local config = require('lime.config')
local shared_state = require("shared-state")
local read_for_access = require("read_for_access.read_for_access")
```

**Funcoes:**

| Funcao | Descricao |
|--------|-----------|
| `get_config()` | Retorna {activated, with_vouchers} |
| `set_config(activated, with_vouchers)` | Configura e inicia/para captive-portal |
| `get_page_content()` | Obtem conteudo do portal (shared-state ou local) |
| `set_page_content(...)` | Define conteudo do portal (via shared-state) |
| `get_authorized_macs()` | Lista MACs autorizados (voucher ou read_for_access) |
| `update_captive_portal(daemonized)` | Atualiza nftables |

**Nota:** O `update_captive_portal` redireciona stdout/stderr para `/dev/null` para evitar erro 502 Bad Gateway (corrigido nesta branch).

---

#### `/usr/lib/lua/read_for_access/read_for_access.lua`

**Proposito:** Modo de acesso sem voucher (**Read For Access**).

**Arquivo de MACs:** `/tmp/pirania/read_for_access/auth_macs`

**Formato:** `MAC TIMESTAMP_EXPIRACAO`

**Funcoes:**

| Funcao | Descricao |
|--------|-----------|
| `set_workdir(workdir)` | Define diretorio de trabalho |
| `authorize_mac(mac)` | Autoriza MAC por tempo definido em config |
| `get_authorized_macs()` | Lista MACs nao expirados |

**Nota:** Tambem redireciona stdout/stderr para `/dev/null` no `captive-portal update` (corrigido nesta branch).

---

### Configuracao UCI

#### `/etc/config/pirania`

```
config base_config 'base_config'
    option enabled '0'                    # Portal ativo
    option prune_expired_for_days '30'    # Dias para manter expirados
    option portal_domain 'thisnode.info'  # Dominio do portal
    option url_auth '/portal/auth.html'   # Pagina de autenticacao
    option url_authenticated '/portal/authenticated.html'
    option url_info '/portal/info.html'
    option url_fail '/portal/fail.html'
    option db_path '/etc/pirania/vouchers/'
    option hooks_path '/etc/pirania/hooks/'
    option append_nft_rules '0'           # (nao usado atualmente)
    option with_vouchers '0'              # Modo voucher ativo
    list allowlist_ipv4 '10.0.0.0/8'      # IPs sempre permitidos
    list allowlist_ipv4 '172.16.0.0/12'
    list allowlist_ipv4 '192.168.0.0/16'
    list allowlist_ipv6 'fc00::/7'
    list allowlist_ipv6 'fe80::/64'
    list allowlist_ipv6 '2a00:1508:0a00::/40'
    list catch_interfaces 'br-lan'        # Interfaces a capturar
    list catch_bridged_interfaces 'wlan0-ap'

config access_mode 'read_for_access'
    option url_portal '/portal/read_for_access.html'
    option duration_m '15'                # Duracao do acesso em minutos
```

---

### API ubus/RPCD

**Arquivo:** `/usr/libexec/rpcd/pirania`

**Metodos disponiveis:**

| Metodo | Parametros | Descricao |
|--------|------------|-----------|
| `get_portal_config` | - | Retorna configuracao do portal |
| `set_portal_config` | activated, with_vouchers | Configura portal |
| `show_url` | - | Retorna URL do portal |
| `change_url` | url | Altera URL do portal |
| `add_vouchers` | name, qty, duration_m, deadline, permanent | Cria vouchers |
| `list_vouchers` | - | Lista vouchers |
| `rename` | id, name | Renomeia voucher |
| `invalidate` | id | Invalida voucher |
| `get_portal_page_content` | - | Obtem conteudo do portal |
| `set_portal_page_content` | title, main_text, logo, link_title, link_url, background_color | Define conteudo |

**ACL:** `/usr/share/rpcd/acl.d/pirania.json`
- `unauthenticated`: acesso a `show_url`, `get_portal_page_content`
- `lime-app`: acesso a `show_url`, `get_portal_config`, `get_portal_page_content`
- `root`: acesso total

---

## Fluxos de Uso

### Fluxo: Usuario com Voucher (com JavaScript)

```
1. Usuario conecta no WiFi
2. Tenta acessar http://example.com
3. nftables redireciona para porta 59080
4. pirania-uhttpd roda /www/pirania-redirect/redirect
5. Redirect 302 para http://thisnode.info/portal/auth.html?prev=...
6. Usuario entra codigo do voucher
7. Form envia GET para /cgi-bin/pirania/preactivate_voucher?voucher=CODE&nojs=false
8. preactivate_voucher valida codigo
9. Se valido: Redirect 302 para /portal/info.html?voucher=CODE
10. info.html mostra informacoes e countdown de 15s
11. Apos countdown, form envia para /cgi-bin/pirania/activate_voucher
12. activate_voucher:
    - Obtem MAC do cliente via ARP
    - Chama vouchera.activate(code, mac)
    - Atualiza nftables (captive-portal update)
    - Dispara hook db_change (sincroniza com rede)
13. Redirect para URL original ou /portal/authenticated.html
```

> **Termos:** nftables | uhttpd | Redirect 302 | thisnode.info | CGI | MAC | ARP | hook

### Fluxo: Usuario sem Voucher (Read For Access)

```
1-5. Mesmo que acima, mas redirect vai para /portal/read_for_access.html
6. Pagina mostra countdown de 15s
7. Apos countdown, form envia para /cgi-bin/pirania/authorize_mac
8. authorize_mac:
    - Obtem MAC do cliente
    - Salva em /tmp/pirania/read_for_access/auth_macs
    - Atualiza nftables (captive-portal update)
9. Redirect para URL original
10. Apos duration_m (15min por padrao), MAC e removido da lista
```

> **Termos:** MAC | nftables | CGI

---

## Mapa de Dependencias

```
vouchera.lua
├── voucher/store.lua
│   ├── nixio.fs
│   ├── luci.jsonc
│   ├── voucher/hooks.lua
│   └── voucher/utils.lua
├── voucher/config.lua
│   └── uci
├── lime.utils
├── portal/portal.lua
│   ├── lime.utils
│   ├── lime.config
│   ├── shared-state
│   └── read_for_access/read_for_access.lua
└── voucher/hooks.lua
    ├── voucher/config.lua
    └── nixio.fs

voucher/cgi_handlers.lua
├── voucher/vouchera.lua
└── voucher/utils.lua
    ├── nixio
    └── lucihttp

read_for_access/cgi_handlers.lua
├── voucher/utils.lua
├── read_for_access/read_for_access.lua
├── portal/portal.lua
└── lime.config

pirania (rpcd)
├── ubus
├── luci.jsonc
├── uci
├── voucher/vouchera.lua
├── lime.utils
├── lime.config
└── portal/portal.lua
```

---

## Diferencas da Versao Anterior (iptables → nftables)

| Aspecto | Versao Antiga (iptables) | Versao Nova (nftables) |
|---------|--------------------------|------------------------|
| Firewall | iptables, ip6tables, ebtables | nftables |
| Sets | ipset | nft sets nativos |
| Tabelas | Multiplas (mangle, nat, filter) | Tabela unica `inet pirania` |
| HTTPS | Rejeitado | Dropped (bloqueado) |
| Dependencias | ip6tables-mod-nat, ipset | nftables |
| Init start | Nao iniciava servicos | Inicia pirania-dnsmasq e pirania-uhttpd |
| Bug 502 | Presente | Corrigido (redirect stdout/stderr) |

---

## Resumo das Portas

| Porta | Servico | Descricao |
|-------|---------|-----------|
| 59053 | DNS (dnsmasq) | DNS que resolve tudo para portal |
| 59080 | HTTP (uhttpd) | Redireciona para pagina de autenticacao |
| 80 | HTTP (uhttpd principal) | Serve paginas do portal |
| 443 | HTTPS | Bloqueado para MACs nao autorizados |

---

## Dependencias do Pacote (Makefile)

```makefile
DEPENDS:=+nftables +shared-state +shared-state-pirania \
    +uhttpd-mod-lua +lime-system +luci-lib-jsonc \
    +liblucihttp-lua +luci-lib-nixio +libubus-lua +libuci-lua
```

**Nota:** A versao nftables depende do pacote `nftables`; `ip6tables-mod-nat` e `ipset` nao sao mais necessarios.

---

## Testes

Os testes estao em `/packages/pirania/tests/` e usam **busted** (framework de testes Lua).

| Arquivo | Cobertura |
|---------|-----------|
| `test_vouchera.lua` | Criacao, ativacao, invalidacao, pruning de vouchers |
| `test_cgi_handlers.lua` | Handlers de voucher CGI |
| `test_pirania_rpcd.lua` | API ubus |
| `test_portal.lua` | Configuracao do portal |
| `test_read_for_access.lua` | Modo sem voucher |
| `test_redirect.lua` | Redirecionamento HTTP |

---

## Possiveis Melhorias para o Hackathon

1. **Remover dependencias antigas** - `ip6tables-mod-nat` e `ipset` nao sao mais necessarios
2. **Melhor UX mobile** - Paginas do portal nao sao totalmente responsivas
3. **Suporte a HTTPS** - Atualmente so HTTP (HTTPS e bloqueado)
4. **Dashboard de administracao** - Interface web para gerenciar vouchers
5. **Metricas de uso** - Logs de ativacoes, tempo de uso
6. **Vouchers QR Code** - Gerar QR codes para vouchers
7. **Notificacoes** - Avisar quando voucher esta prestes a expirar
8. **Rate limiting** - Limitar velocidade por voucher (usando nftables meters)
9. **Integracao com pagamento** - Venda automatica de vouchers
10. **Captive portal detection** - Melhor suporte a deteccao automatica (RFC 8910)
11. **Usar `nft flush set`** - Para MACs tambem, em vez de so adicionar
12. **Filtro por interface** - `catch_bridged_interfaces` configurado mas nao usado nas regras
