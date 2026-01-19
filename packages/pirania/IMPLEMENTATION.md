# IMPLEMENTATION - itens faltando ou quebrados

Este documento responde: **quais itens precisam ser implementados para o Pirania funcionar como esperado** e detalha o que falta em cada um.

Resumo rapido:

- **Para o portal funcionar no basico (voucher e/ou ler-para-acesso):** nada aqui e obrigatorio.
- **Para cumprir o que a configuracao promete ou para compatibilidade com integracoes antigas:** os itens abaixo precisam de implementacao ou ajuste.

---

## 1) Regras por interface (catch_interfaces / catch_bridged_interfaces)

**Status atual:** configuracao existe, mas nao e aplicada nas regras nftables.

**Onde esta o problema:**

- `packages/pirania/files/etc/config/pirania` define `catch_interfaces` e `catch_bridged_interfaces`.
- `packages/pirania/files/usr/bin/captive-portal` le `catch_bridged_interfaces` mas nao usa no nftables.

**Impacto:**

- O portal captura trafego de todas as interfaces, mesmo quando o UCI define quais interfaces deveriam ser capturadas.
- Quem configura isso espera limitar a captura apenas para interfaces especificas.

**O que implementar:**

Opcoes possiveis (escolher uma abordagem consistente):

1) **Aplicar filtro diretamente nas regras** (mais simples):
   - Criar um set `pirania-catch-ifaces` (tipo `ifname`).
   - Carregar interfaces de `catch_interfaces` e/ou `catch_bridged_interfaces` no set.
   - Adicionar `iifname @pirania-catch-ifaces` nas regras de redirect (DNS/HTTP/HTTPS).

2) **Separar o fluxo com `jump`** (mais limpo para manter):
   - Criar um chain principal e um chain `pirania_capture`.
   - No chain principal, fazer `jump` para `pirania_capture` apenas se `iifname` estiver no set.
   - Colocar as regras DNS/HTTP/HTTPS no chain `pirania_capture`.

**Decisao de semantica:**

- Definir se `catch_interfaces` e `catch_bridged_interfaces` somam ou se um sobrescreve o outro.
- Documentar claramente no README e no UCI.

**Criterio de pronto (aceitacao):**

- Se a interface nao estiver na lista, o trafego nao passa pelas regras do Pirania.
- Se estiver, o comportamento continua o mesmo de hoje.

---

## 2) Opcao append_nft_rules

**Status atual:** opcao existe, mas a logica esta comentada e o comportamento nao muda.

**Onde esta o problema:**

- `packages/pirania/files/etc/config/pirania` tem `append_nft_rules`.
- `packages/pirania/files/usr/bin/captive-portal` tem codigo comentado para decidir entre add/insert.
- O script sempre recria a tabela, entao **append vs insert nao faz diferenca**.

**Impacto:**

- Quem tenta usar `append_nft_rules` nao ve efeito algum.
- A opcao passa a ser enganosa.

**O que implementar (duas possibilidades):**

A) **Remover a opcao** (se ela nao faz sentido no desenho atual).

B) **Tornar a opcao funcional** (mais trabalho):

- Parar de apagar a tabela inteira a cada start/update.
- Se `append_nft_rules=0`, inserir regras no inicio do chain (ex.: `nft insert rule ... position 0`).
- Se `append_nft_rules=1`, adicionar regras no fim (`nft add rule ...`).
- Garantir que as regras de Pirania nao sejam duplicadas (verificar antes de inserir).

**Criterio de pronto (aceitacao):**

- Ao alternar a opcao, a ordem de regras muda e o efeito e observavel.
- Documentacao atualizada explicando quando usar.

---

## 3) portal_url via ubus/rpcd

**Status atual:** API existe, mas a configuracao `portal_url` nao aparece no UCI e nao e usada pelo fluxo real.

**Onde esta o problema:**

- `packages/pirania/files/usr/libexec/rpcd/pirania` expoe `show_url` e `change_url` para `pirania.base_config.portal_url`.
- Essa chave nao existe em `packages/pirania/files/etc/config/pirania`.
- O redirecionamento real usa `portal_domain` + `url_auth`/`url_portal`.

**Impacto:**

- Ferramentas que usam `show_url/change_url` nao conseguem alterar o comportamento real do portal.

**O que implementar (escolher um caminho):**

A) **Remover a API legacy** (se nao e usada).

B) **Reativar `portal_url`** (compatibilidade retro):

- Adicionar `option portal_url` no UCI.
- Atualizar `packages/pirania/files/www/pirania-redirect/redirect` para usar `portal_url` quando definido.
- Definir prioridade clara: `portal_url` sobrescreve `portal_domain + url_*` ou apenas complementa.

C) **Migrar API para o modelo atual**:

- Substituir `show_url/change_url` por getters/setters de `portal_domain` + `url_auth`/`url_portal`.
- Manter nomes antigos mas implementar dentro da nova logica, se houver dependencia de compatibilidade.

**Criterio de pronto (aceitacao):**

- Alterar via ubus reflete no redirect do portal.
- UCI e README documentam o comportamento final.

---

## 4) CGI `client_ip` legado

**Status atual:** endpoint referenciado no pacote, mas depende de modulos que nao existem.

**Onde esta o problema:**

- `packages/pirania/files/www/cgi-bin/pirania/client_ip` usa `voucher.logic` e `voucher.db`, que nao existem.

**Impacto:**

- O endpoint esta quebrado se for chamado.
- Pode gerar erros 500 e confundir integracoes antigas.

**O que implementar:**

A) **Atualizar para as bibliotecas atuais**:

- Trocar para `voucher.utils` e `voucher.vouchera`.
- Usar `utils.getIpv4AndMac(os.getenv('REMOTE_ADDR'))`.
- Determinar `valid` com `portal.get_authorized_macs()` ou `vouchera.is_mac_authorized` (dependendo de `with_vouchers`).
- Manter o mesmo formato JSON: `{ ip, mac, valid }`.

B) **Remover o endpoint** se nao houver consumo real.

**Criterio de pronto (aceitacao):**

- O CGI responde JSON valido com `ip`, `mac`, `valid`.
- Nao depende de modulos inexistentes.

---

## 5) Hooks para sincronizacao de vouchers

**Status atual:** o mecanismo existe no Pirania, mas o pacote nao inclui scripts de hook.

**Contexto:**

- `packages/pirania/files/usr/lib/lua/voucher/hooks.lua` executa scripts em `hooks_path`.
- O `hooks_path` default e `/etc/pirania/hooks/`.
- O pacote `shared-state-pirania` (dependencia declarada) costuma prover os scripts reais.

**Impacto:**

- Se `shared-state-pirania` nao estiver instalado ou nao configurar hooks, os vouchers nao sao sincronizados entre nos.
- O portal funciona, mas os vouchers ficam locais.

**O que implementar (se a sincronizacao for esperada):**

- Garantir que o pacote `shared-state-pirania` instale scripts em `/etc/pirania/hooks/`.
- Confirmar que o `hooks_path` do UCI aponta para esse local.
- Documentar claramente essa dependencia no README.

**Criterio de pronto (aceitacao):**

- Ao criar/invalidar voucher em um no, a mudanca aparece nos demais (via shared-state).

---

## O que e realmente necessario para o Pirania funcionar

**Funciona no basico sem implementar nada acima**, porque:

- O portal captura trafego com nftables e redireciona corretamente.
- O modo voucher e o modo ler-para-acesso funcionam.

Os itens acima sao **complementos esperados** por configuracoes, integracoes ou uso legado. Se a expectativa do projeto inclui esses comportamentos, eles precisam de implementacao.
