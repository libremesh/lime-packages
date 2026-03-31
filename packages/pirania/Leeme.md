![PIRANHA](https://i.imgur.com/kHWUNOu.png)

## Solución de portal cautivo con pines (vouchers) para redes comunitarias

Esta herramienta permite a quien administra una red gestionar un sistema de pines para acceder a internet.

Puede ser utilizada en una comunidad que desea compartir una conexión a internet donde las personas usuarias pagan una fracción cada una, pero se necesita el pago de todas. Los pines permiten controlar los pagos mediante el control del acceso a internet.

Adicionalmente, el uso de pines puede desactivarse para utilizar el portal cautivo solamente para mostrar información valiosa a las personas visitantes de la red.

## Características

Estas son las características implementadas:
  * Corre directamente desde el router OpenWrt: no requiere hardware extra
  * Integra su administración con Ubus y LiMe App
  * Cuenta con una interfaz de línea de comandos para listar, crear y eliminar pines
  * La base de datos de pines se comparte entre todos los nodos de la red
  * El contenido del portal (logo, título, texto principal, etc) se distribuye entre los nodos de la red
  * Puede utilizarse sin pines (modo "leer para acceder")
  * Tranca Redes: control de acceso programado de segunda capa que restringe las MACs autorizadas a categorías específicas de destinos durante las horas configuradas

## Requisitos previos

Este software asume que será ejecutado en una distribución OpenWrt (ya que utiliza UCI para su configuración). Necesita el paquete `nftables` instalado (provee el comando `nft` y los módulos del kernel necesarios).

## Instalar

  * agregar la fuente de software de libremesh a opkg
  * opkg install pirania

## Interfaz de línea de comandos

`epoc` se expresa en formato [Unix Timestamp](https://en.wikipedia.org/wiki/Unix_time). Puedes usar una herramienta como [unixtimestamp.com](https://www.unixtimestamp.com/) para obtener una fecha en el formato correcto.

### `captive-portal start`

Inicia pirania. Si quieres que pirania se active automáticamente usa: `uci set pirania.base_config.enabled=1 && uci commit`

### `captive-portal stop`

Detiene pirania. Si quieres que pirania deje de activarse automáticamente usa: `uci set pirania.base_config.enabled=0 && uci commit`

### `voucher list`

Lista todos los pines.

### `voucher list_active`

Lista todos los pines actualmente activos.

### `voucher list_expired`

Lista todos los pines expirados.

### `voucher list_available`

Lista todos los pines disponibles para activación.

### `voucher add`

Crea un nuevo pin. Este pin comenzará desactivado y no vinculado a ningún dispositivo.

Parámetros:
- `name`: un nombre utilizado para identificar el pin
- `duration-m`: duración del pin en minutos. Si no se proporciona un valor se creará un pin permanente.
  La duración toma efecto cuando el pin es activado.
- `activation-deadline`: después de esta fecha (unix time) el pin no puede ser activado.

Opciones:
- `--unrestricted` o `-u`: crea un pin sin restricciones que evita las limitaciones de Tranca Redes.
- `--duration` o `-d`: especifica la duración en minutos (alternativa al argumento posicional).
- `--deadline`: especifica la fecha límite de activación (alternativa al argumento posicional).

Para crear un pin de 60 minutos:
`voucher add mi-pin 60`

Para crear un pin permanente sin restricciones:
`voucher add mi-pin --unrestricted`

### `voucher activate`

Activa un pin, asignándole una dirección MAC. Después de la activación, el dispositivo con esta dirección
MAC tendrá acceso a internet.

Parámetros:
- `secret-code`: la contraseña del pin.
- `mac`: la dirección MAC del dispositivo que tendrá acceso.

Ej: `voucher activate miclave 00:11:22:33:44:55`

### `voucher deactivate`

Desactiva un pin del `ID` especificado.

Parámetros:
- `ID`: una cadena utilizada para identificar el pin.

Ej: `voucher deactivate Qzt3WF`

### `voucher invalidate`

Invalida un pin (eliminación suave). El pin permanece en la base de datos hasta ser purgado.

Parámetros:
- `ID`: una cadena utilizada para identificar el pin.

Ej: `voucher invalidate Qzt3WF`

### `voucher is_mac_authorized`

Verifica si una dirección MAC específica está autorizada.

Parámetros:
- `mac`: la dirección MAC de un dispositivo

Ej: `voucher is_mac_authorized d0:82:7a:49:e2:37`

### `voucher show_authorized_macs`

Muestra las direcciones MAC de todos los pines actualmente activos.

## Ejemplo de uso por línea de comandos

```
$ voucher list
$ voucher add san-notebook 60
Q3TJZS	san-notebook	ZRJUXN	xx:xx:xx:xx:xx:xx	Wed Sep  8 23:47:40 2021	60	           -            	1	normal
$ voucher list
Q3TJZS	san-notebook	ZRJUXN	xx:xx:xx:xx:xx:xx	Wed Sep  8 23:47:40 2021	60	           -            	1	normal
$ voucher list_active
$ voucher activate ZRJUXN 00:11:22:33:44:55
Voucher activated!
$ voucher list
Q3TJZS	san-notebook	ZRJUXN	00:11:22:33:44:55	Wed Sep  8 23:47:40 2021	60	Thu Sep  9 00:48:33 2021	2	normal

$ voucher list_active
Q3TJZS	san-notebook	ZRJUXN	00:11:22:33:44:55	Wed Sep  8 23:47:40 2021	60	Thu Sep  9 00:48:33 2021	2	normal

$ voucher deactivate Q3TJZS
ok
$ voucher list_active
$ voucher list
Q3TJZS	san-notebook	ZRJUXN	xx:xx:xx:xx:xx:xx	Wed Sep  8 23:47:40 2021	60	           -            	3	normal
```

## Cómo funciona

Utiliza reglas de nftables para filtrar las conexiones entrantes fuera de la red mesh.

## Vista general de la jerarquía y funciones de los archivos

```
files/
    /etc/config/pirania es la configuración UCI
    /etc/pirania/vouchers/ (ruta por defecto) contiene la base de datos de pines
    /etc/init.d/pirania-uhttpd arranca un uhttpd en el puerto 59080 que responde a cualquier solicitud redireccionando a una URL predeterminada

    /usr/lib/lua/voucher/ contiene bibliotecas lua utilizadas por /usr/bin/voucher
    /usr/bin/voucher es una interfaz de línea de comandos (CLI) para gestionar la base de datos (tiene funciones list, list_active, show_authorized_macs, add, activate, deactivate e is_mac_authorized)
    /usr/bin/captive-portal configura las reglas de nftables para la captura de tráfico

    /usr/libexec/rpcd/pirania API de ubus de pirania (utilizada por el frontend web)
    /usr/share/rpcd/acl.d/pirania.json Lista de control de accesos (ACL) para la API de ubus de pirania

    /etc/shared-state/publishers/shared-state-publish_vouchers inserta la base de datos local de pines dentro de shared-state
    /etc/shared-state/hooks/pirania/generate_vouchers trae los pines actualizados y nuevos desde shared-state hacia la base de datos local

    /usr/lib/lua/read_for_access contiene la librería utilizada por
    /usr/lib/lua/portal para gestionar el acceso en modo "leer para acceder" (es decir, sin pines)

    /usr/bin/tranca-redes-scheduler evalúa la programación de Tranca Redes y activa/desactiva el estado
```

## API de ubus

* `get_portal_config` -> devuelve la configuración del portal (activated, with_vouchers)
* `set_portal_config(activated, with_vouchers)` -> configura e inicia/detiene el portal
* `add_vouchers(name, qty, duration_m, activation_deadline, permanent, unrestricted)` -> crea pines
* `list_vouchers` -> lista todos los pines
* `rename(id, name)` -> renombra un pin
* `invalidate(id)` -> invalida un pin
* `get_portal_page_content` -> devuelve el contenido de la página del portal (título, texto, logo, etc.)
* `set_portal_page_content(...)` -> establece el contenido de la página del portal

## Bajo el capó

### Captura de tráfico
`/usr/bin/captive-portal` configura las reglas de nftables para capturar el tráfico.
Crea un conjunto de reglas y nft sets nativos:
* pirania-auth-macs: las MACs autorizadas van en este conjunto. Comienza vacío.
* pirania-allowlist-ipv4: con los miembros de la lista permitida en el archivo de configuración (10.0.0.0/8, 192.168.0.0/16, 172.16.0.0/12)
* pirania-allowlist-ipv6: lo mismo que ipv4 pero para ipv6

La captura de tráfico se aplica a las interfaces configuradas:
* `catch_interfaces`: interfaces L3 para coincidencia directa en nftables
* `catch_bridged_interfaces`: interfaces L2 puenteadas (ej. Wi-Fi AP) para marcado en la familia bridge

Reglas:
* los paquetes DNS que no provienen de los conjuntos permitidos se redirigen al DNS del portal cautivo en el puerto 59053
* los paquetes HTTP que no provienen de los conjuntos permitidos se redirigen al HTTP del portal cautivo en el puerto 59080
* los paquetes de los conjuntos permitidos son aceptados
* el resto de los paquetes son rechazados (se descarta el paquete y se envía un error al cliente)

### Flujo HTTP

`/etc/init.d/pirania-uhttpd` arranca un servidor HTTP (uhttpd) en el puerto 59080 que responde a cualquier solicitud redireccionando a una URL predeterminada.
 - En caso de que el uso de pines esté activado: `pirania.base_config.url_auth`.
 - En caso contrario: `pirania.read_for_access.url_portal`
Esto lo realiza el script lua `/www/pirania-redirect/redirect`. Como ambas URLs están en el rango de IPs permitidas (http://thisnode.info/portal/ por defecto) entonces el servidor HTTP "normal" que escucha en el puerto 80 responderá luego del redireccionamiento.

El flujo con uso de pines es:
* navegas hacia una IP no permitida, por ejemplo: `http://orignal.org/baz/?foo=bar`
* se redirecciona con un código 302 donde puedes ingresar el pin: `http://thisnode.info/cgi-bin/portal/auth.html?prev=http%3A%2F%2Foriginal.org%2Fbaz%2F%3Ffoo%3Dbar`
* al enviar el formulario se realiza un GET a `http://thisnode.info/cgi-bin/pirania/preactivate_voucher?voucher=codigosecreto&prev=http%3A%2F%2Foriginal.org%2Fbaz%2F%3Ffoo%3Dbar`
* El script preactivate_voucher hace dos cosas diferentes dependiendo del soporte javascript:
    * Si nojs=true entonces el pin se activa con la MAC del cliente (tomada de la tabla ARP con su IP). Si la activación es exitosa se redirige a `url_authenticated`.
    * Si nojs=false se verifica si el pin sería válido (hay un pin sin usar y válido con ese código). Si sería válido entonces se redirige a la página INFO del portal (`pirania.base_config.url_info`) con el código del pin como parámetro URL. INFO muestra la información actualizada de la comunidad y hay un tiempo que debes esperar antes de poder continuar (esto se hace con JS). Cuando el contador llega a 0 puedes hacer clic en continuar. Esto redirige a `http://thisnode.info/cgi-bin/pirania/activate_voucher?voucher=codigosecreto`. El script `activate_voucher` realiza la activación del pin y luego redirige a `url_authenticated`. Si el código falla se redirige a `http://thisnode.info/cgi-bin/portal/fail.html` que es idéntico a auth.html pero con un mensaje de error.

El flujo sin uso de pines (modo "leer para acceder") es:
* navegas hacia una IP no permitida, por ejemplo: `http://orignal.org/baz/?foo=bar`
* se redirecciona con un código 302 a: `http://thisnode.info/cgi-bin/portal/read_for_access.html?prev=http%3A%2F%2Foriginal.org%2Fbaz%2F%3Ffoo%3Dbar`
* Una vez allí, si el cliente tiene soporte JS se muestra un contador de 15 segundos y cuando llega a 0 la persona puede hacer clic en continuar, lo cual envía una solicitud GET a `http://thisnode.info/cgi-bin/pirania/authorize_mac?prev=http%3A%2F%2Foriginal.org%2Fbaz%2F%3Ffoo%3Dbar`
lo cual redirigirá a la URL `prev`.
* Si el cliente no tiene soporte JS, el botón se habilita inmediatamente, y al hacer clic en continuar se redirige a `url_authenticated`.

### Tranca Redes

Tranca Redes es un modo de control de acceso de segunda capa que puede restringir el acceso a internet durante horas programadas. Cuando está activo:
* Las MACs autorizadas solo pueden alcanzar destinos en las listas permitidas de categorías configuradas
* Las personas con pines sin restricciones evitan completamente las limitaciones de Tranca
* Las MACs no autorizadas permanecen bloqueadas como de costumbre

La configuración está en `/etc/config/pirania` bajo la sección `tranca_redes`:
* `enabled`: habilita/deshabilita Tranca Redes
* `start_time`/`end_time`: horario en formato HH:MM (soporta cruce de medianoche)
* `days`: qué días de la semana Tranca está activo
* `allowlist_category`: referencia a secciones de categorías con fuentes de URLs IPv4

El programador (`/usr/bin/tranca-redes-scheduler`) se ejecuta vía cron cada minuto para evaluar el horario.
