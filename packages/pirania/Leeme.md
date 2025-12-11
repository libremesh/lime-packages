![PIRANHA](https://i.imgur.com/kHWUNOu.png)

## Una solución de portal cautivo con pines (tickets, vouchers) para redes comunitarias 

Esta herramienta le permite, a quienes administran una red, manejar un sistema de pines para acceder a internet. Puede ser utilizada en una comunidad para distribuir el costo de acceso en una red compartida, ya que el pin habilita el acceso durante una fracción de tiempo. 

Adicionalmente puede ser utilizada sin pines, cuando lo que se quiere es simplemente mostrar información sobre la red a las personas usuarias sin gestionar pines de acceso.
## Caracteristícas

Estas son las características implementadas hasta ahora:
* Corre directamente desde el router OpenWrt. No requiere hardware extra
* La administración se hace desde [Lime-App](https://github.com/libremesh/lime-app/)
* Cuenta con una interfaz de línea de comandos para listar, crear y eliminar pines
* La base de datos de pines se comparte entre todos los nodos de la red.
* El contenido del portal (logo, título, texto principal, etc) se distribuye entre los nodos de la red.


## Requisitos previos

Este software corre sobre la distribución OpenWrt (ya que utiliza [UCI](https://openwrt.org/docs/techref/uci) para su configuración). Los paquetes `nftables, liblucihttp0, liblucihttp-lua, uhttpd, uhttpd-mod-lua, uhttpd-mod-ubus` deben estar instalados.

Los dispositivos (Android, iOS, PC) no deben tener habilitada la función MAC aleatoria; de lo contrario, la autenticación de la dirección MAC no funcionará.
Esta configuración se puede cambiar [al conectarse a la red](https://imgur.com/a/4bjBWJQ) o después de conectarse, [yendo a la configuración de la red wifi](https://imgur.com/a/qGpHS4b).

## Instalar

  * Agregar la fuente de libremesh a opkg
  * `opkg install pirania`

# Cómo funciona

Utiliza las reglas de iptables para filtrar el tráfico hacia fuera de la red mesh.

## Vista general de la jerarquía y funciones de los archivos

La siguiente lista tiene como objetivo explicar qué funcionalidad de Pirania está en qué archivo, para poder estudiarla, entenderla y modificarla.

--

* `/etc/config/pirania` es la configuración UCI
* `/etc/pirania/vouchers/` (ruta por defecto) contiene la base de datos de pines
* `/etc/init.d/pirania-uhttpd` arranca un uhttpd en el puerto 59080 que responde a cualquier solicitud redireccionando a una URL predeterminada    

* `/usr/lib/lua/voucher/` contiene bibliotecas lua que son utilizadas por /usr/bin/voucher
* `/usr/bin/voucher``/usr/bin/voucher` es una interfaz de línea de comandos (CLI) que maneja una base de datos (que incluye funciones de muestra como `show_active, show_authorized_macs, add, activate, deactivate e is_mac_authorized)`
* `/usr/bin/captive-portal` configura las reglas de iptables para la captura de tráfico

* `/usr/libexec/rpcd/pirania` ubus de pirania (utilizada por el frontend web)
* `/usr/share/rpcd/acl.d/pirania.json` Lista de control de accesos (ACL) para la API de pirania
* `/etc/shared-state/publishers/shared-state-publish_vouchers` inserta la base de datos local de pines dentro de la base compartida `shared-state`
* `/etc/shared-state/hooks/pirania/generate_vouchers` trae la base de pines actualizados y nuevos pines desde `shared-state` hacia la base de datos local
* `/usr/lib/lua/read_for_access` contiene la librería que usa `/usr/lib/lua/portal` para manejar el modo "leer para acceder" (es decir, sin vouchers)
### Captura de tráfico

`/usr/bin/captive-portal` configura las reglas de iptables para captura de tráfico.
Crea un grupo de reglas que se aplican a tres grupos de direcciones IPs (usando el módulo ipset de iptables) habilitados:
* `pirania-auth-macs`: la lista de mac autorizadas. comienza vacía.
* `pirania-allowlist-ipv4`: contiene los miembros de clientes permitidos `allowlist` en el archivo de configuración (`10.0.0.0/8`, `192.168.0.0/16`, `172.16.0.0/12``172.16.0.0/12`)
* `pirania-allowlist-ipv6`: lo mismo que la lista anterior pero para ipv6

Reglas:
* los paquetes DNS que no vienen desde el conjunto de ipsets permitidos se redirigen hacia el portal cautivo DNS en el puerto 59053
* los paquetes HTTP que no vienen desde el conjunto de ipsets permitidos se redirigen hacia el portal cautivo HTTP en el puerto 59053
* los paquetes que entran dentro de los tres conjuntos ipsets son permitidos
* el resto de paquetes son rechazados (se descarta el paquete y da una respuesta de error al cliente)

### Flujo HTTP

`/etc/init.d/pirania-uhttpd` arranca un servidor HTTP (uhttpd) en el puerto 59080 que responde cualquier solicitud redireccionando a una URL predefinida.
 - En caso de que el uso de vouchers esté activado: `pirania.base_config.url_auth`.
 - En caso contrario: `pirania.read_for_access.url_portal`
Esto lo hace el siguiente script lua `/www/pirania-redirect/redirect`. Como ambas configs apuntan a recursos del nodo y la ip del nodo está en la `allowlist` (http://minodo.info/portal/... por defecto) entonces el servidor HTTP "normal" que escucha en el puerto 80 responderá luego del redireccionamiento.

El flujo, con uso de vouchers es:
* navegas hacia una ip no permitida, por ejemplo: `http://orignal.org/baz/?foo=bar`
* se redirecciona la solicitud con un código HTTP 302 donde puedes poner el pin para entrar: `http://minodo.info/cgi-bin/portal/auth.html?prev=http%3A%2F%2Foriginal.org%2Fbaz%2F%3Ffoo%3Dbar`
* agregas el pin (elpinsecreto) en una caja de texto, y envías la solicitud `GET` a `http://minodo.info/cgi-bin/pirania/preactivate_voucher?voucher=elpinsecreto&prev=http%3A%2F%2Foriginal.org%2Fbaz%2F%3Ffoo%3Dbar`
* El script preactivate_voucher ejecuta dos acciones diferentes, dependiendo del soporte javascript:

    * Si `nojs=true` entonces el pin se activa y se asocia con la MAC del cliente (tomada de la tabla ARP con su IP). Si la activación es exitosa se redirige hacia `url_authenticated`.
    * Si `nojs=false` se verifica la validez del pin (si es un pin válido y sin usar). Si el pin es válido se redirige a la página INFO del portal (`pirania.base_config.url_info`) que se activa con el pin como parámetro URL. INFO muestra la información actualizada de la comunidad y hay un tiempo durante el cual se debe esperar antes de que se permita el acceso (esto se hace con JS). Cuando el contador llega a 0 se puede hacer clic para continuar. Se redirige entonces hacia `http://minodo.info/cgi-bin/pirania/activate_voucher?voucher=elpinsecreto`. El script `activate_voucher` activa el pin y luego redirige hacia `url_authenticated`. Si el pin falla, se redireccionará hacia `http://minodo.info/cgi-bin/portal/fail.html` que es idéntico a `auth.html` pero con un mensaje de error.

El flujo sin uso de vouchers es:
* navegas hacia una ip no permitida, por ejemplo: `http://original.org/baz/?foo=bar`
* se redirecciona la solicitud con un código HTTP 302 a: `http://minodo.info/cgi-bin/portal/read_for_access.html?prev=http%3A%2F%2Foriginal.org%2Fbaz%2F%3Ffoo%3Dbar`
* Allí en caso de tener soporte para js, se muestra un contador de 15 segundos y cuando llega a 0 puedes hacer click en un botón que hace una request GET a: `http://minodo.info/cgi-bin/pirania/authorize_mac?prev=http%3A%2F%2Foriginal.org%2Fbaz%2F%3Ffoo%3Dbar`.
Y en caso de éxito (lo esperable) eres redirigido a la `prev` url.
* En caso de no tener soporte para js, el botón se muestra directamente,
y en caso de éxito eres redirigido a `url_authenticated`, pues no se incluye la información de la url previa.
### API de ubus

* `enable()` -> llama a `captive-portal start` y lo habilita en `/etc/config/pirania`
* `disable()` -> llama a `captive-portal stop` y lo deshabilita en `/etc/config/pirania`
* `show_url()` -> devuelve la configuración `pirania.base_config.portal_url` (del archivo `/etc/config/pirania`)
* `change_url(url)` -> cambia la configuración `pirania.base_config.portal_url`
* ...

### Interfaz de línea de comandos

#### Mostrar todos los pines

`voucher list` 

#### Crear un pin

`voucher add NOMBRE DURACION-MINUTOS FECHA-LIMITE-ACTIVACION`


#### Mostrar pines activos

`voucher list_active`

#### Activar un pin

`voucher activate CONTRASEÑA MAC`

#### Desactivar un pin

* `voucher deactivate ID`

### Sesión de ejemplo de una sesión donde se utiliza

Aclaración: normalmente el paso de activación se realiza desde el navegador web por la persona
que utiliza el pin y no desde la terminal como se muestra a continuación.

```
$ voucher list
$ voucher add san-notebook 60
Q3TJZS	san-notebook	ZRJUXN	xx:xx:xx:xx:xx:xx	Wed Sep  8 23:47:40 2021	60	           -            	1
$ voucher list
Q3TJZS	san-notebook	ZRJUXN	xx:xx:xx:xx:xx:xx	Wed Sep  8 23:47:40 2021	60	           -            	1
$ voucher list_active
$ voucher activate ZRJUXN 00:11:22:33:44:55
Voucher activated!
$ voucher list
Q3TJZS	san-notebook	ZRJUXN	00:11:22:33:44:55	Wed Sep  8 23:47:40 2021	60	Thu Sep  9 00:48:33 2021	2

$ voucher list_active
Q3TJZS	san-notebook	ZRJUXN	00:11:22:33:44:55	Wed Sep  8 23:47:40 2021	60	Thu Sep  9 00:48:33 2021	2

$ voucher deactivate Q3TJZS
ok
$ voucher list_active
$ voucher list
Q3TJZS	san-notebook	ZRJUXN	xx:xx:xx:xx:xx:xx	Wed Sep  8 23:47:40 2021	60	           -            	3
```
