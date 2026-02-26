# TODO - partes nao implementadas ou sem efeito

Este arquivo lista pontos encontrados no codigo do Pirania que parecem nao implementados, legados ou sem efeito hoje.

## Itens

1) Regras por interface (catch_interfaces / catch_bridged_interfaces)
- Configuracao existe em `packages/pirania/files/etc/config/pirania`.
- Em `packages/pirania/files/usr/bin/captive-portal` a variavel `catch_bridged_interfaces` e lida, mas nao e usada para filtrar regras nftables.
- Resultado: a captura nao e limitada por interface, apesar das opcoes no UCI.

2) Opcao append_nft_rules
- Configuracao existe em `packages/pirania/files/etc/config/pirania`.
- Em `packages/pirania/files/usr/bin/captive-portal` a logica de `append_nft_rules` esta comentada.
- Resultado: a opcao nao tem efeito (regras sao sempre adicionadas com `nft add rule`).

3) portal_url via ubus/rpcd
- O ubus exposto em `packages/pirania/files/usr/libexec/rpcd/pirania` implementa `show_url` e `change_url` para `pirania.base_config.portal_url`.
- Essa chave nao aparece no arquivo UCI (`packages/pirania/files/etc/config/pirania`) e nao e usada pelo redirecionamento do portal.
- Resultado: a API parece legada ou sem efeito real no fluxo do portal.

4) CGI `client_ip` legado
- `packages/pirania/files/www/cgi-bin/pirania/client_ip` depende de modulos `voucher.logic` e `voucher.db`.
- Esses modulos nao existem em `packages/pirania/files/usr/lib/lua/voucher/`.
- Resultado: o endpoint parece quebrado/legado e nao faz parte do fluxo atual.

5) Hooks sem scripts no pacote
- `packages/pirania/files/usr/lib/lua/voucher/hooks.lua` executa scripts em `hooks_path`.
- O pacote nao inclui scripts sob `/etc/pirania/hooks/`.
- Resultado: o mecanismo de hooks existe, mas vem vazio neste pacote.
