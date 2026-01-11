# API

## *Odoo*

Esta documentación detalla la interacción con el API de Odoo utilizando el estándar JSON-2 introducido en la versión 19, que es el estándar actual y la versión de Odoo que Dékuple utiliza.

El documento debería ser suficiente para trabajar con el API de Odoo. De todos modos, si se necesita más documentación, la documentación oficial se encuentra en:

* [https://www.odoo.com/documentation/19.0/developer/reference/external\_api.html](https://www.odoo.com/documentation/19.0/developer/reference/external_api.html) \- el sitio web público de documentación de Odoo  
* [https://odoo.dekuple.es/doc](https://odoo.dekuple.es/doc) \- La documentación de todas las tablas y atributos de nuestra propia instancia.

# 1\. Servidores y Entornos

Disponemos de dos entornos activos. Es fundamental diferenciar el uso de cada uno:

| Entorno | BASE\_URL | Notas |
| :---- | :---- | :---- |
| Producción | https://odoo.dekuple.es | Datos reales. No usar para pruebas de escritura. |
| Staging | https://dekuple-odoo-staging-26757321.dev.odoo.com | La URL de Staging cambia cada vez que el entorno se reconstruye (el ID numérico varía) |

**Importante**: Los datos de Staging son una copia de Producción. Cualquier cambio realizado en Staging no afectará a los datos reales, pero permite hacer pruebas con datos reales.

# 2\. Autenticación

Odoo 19 utiliza autenticación mediante **API Keys**.

Sólo tenemos configurada una única API Key, que es la misma para ambos entornos (ya que Staging es una copia de los datos de Producción). La API Key que tenemos es la correspondiente al usuario Rodrigo Serrano, y está almacenada en Bitwarden.

Creo que un mismo usuario de Odoo (actualmente sólo tenemos tres usuarios en Odoo: Carlos, Gema y Rodrigo) podría tener varias API Key distintas configuradas.

El API Key debe incluirse en cada request, en la cabecera, como un Bearer token.

# 3\. Anatomía y ejemplo de una request

A diferencia de las APIs REST tradicionales donde el método HTTP (GET, POST, DELETE) define la acción, en Odoo **todas las peticiones son POST** y la acción se define en la URL.

## **Estructura de la URL**

{BASE\_URL}/json/2/{modelo}/{método}

Más abajo se detallan los modelos y métodos que usaremos comunmente.

## **Cabeceras Obligatorias**

\`Content-Type: application/json\`

\`Authorization: Bearer \<API\_KEY\>\`

## **Ejemplo**

Usa este comando para verificar que tu conexión y API Key funcionan (este ejemplo hace una búsqueda en la tabla “res.users”, que es la tabla de usuarios de la instancia de Odoo):

```shell
curl -X POST https://<BASE_URL>/json/2/res.users/search_read \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <TU_API_KEY_DESDE_BITWARDEN>" \
  -d '{
    "domain": [],
    "fields": ["name", "login"],
    "limit": 1
  }'
```

# 4\. Métodos Principales (CRUD)

El API de Odoo es básicamente un interfaz CRUD a las tablas de la base de datos de Odoo. Las tablas más más típicas son \`res.partner\` (clientes/contactos), \`product.product\` (productos) y \`account.move\` (facturas).

## **Leer registros (`search_read`)**

Se utiliza para buscar, en una tabla, un registro por un campo concreto (conceptualmente similar a `find_by` en Rails), y obtener los datos de los registros encontrados. El “payload” se construye como sigue:

\`\`\`json

// POST /json/2/res.partner/search\_read

{

    "domain": \[\["is\_company", "=", true\]\], // Filtro (opcional)

    "fields": \["name", "email", "phone"\],   // Campos a devolver (opcional)

    "limit": 5                              // Paginación (opcional)

}

\`\`\`

## **Crear registros (\`create\`)**

El método \`create\` siempre recibe una lista de diccionarios bajo la clave \`vals\_list\`.

\`\`\`json

// POST /json/2/res.partner/create

{

    "vals\_list": \[

        {

            "name": "Nuevo Cliente SL",

            "email": "contacto@cliente.es"

        }

    \]

}

\`\`\`

## **C. Actualizar registros (\`write\`)**

Requiere una lista de IDs y un diccionario con los campos a cambiar.

\`\`\`json

// POST /json/2/res.partner/write

{

    "ids": \[9\],

    "vals": {

        "phone": "+34 900 000 000"

    }

}

\`\`\`

# 5\. Números "Mágicos" (Relaciones One2Many / Many2Many)

Para campos relacionales (como las líneas de una factura), Odoo utiliza una sintaxis especial basada en listas de comandos. Estos son los más comunes:

\* \*\*\`\[0, 0, {valores}\]\`\*\*: Crea un nuevo registro relacionado desde cero.

\* \*\*\`\[4, ID, 0\]\`\*\*: Enlaza un registro que ya existe mediante su ID.

\* \*\*\`\[6, 0, \[IDs\]\]\`\*\*: Reemplaza todos los enlaces actuales por esta lista de IDs.

\*\*Ejemplo de creación de factura con líneas:\*\*

\`\`\`json

{

    "vals\_list": \[{

        "move\_type": "out\_invoice",

        "partner\_id": 9,

        "invoice\_line\_ids": \[

            \[0, 0, { "product\_id": 2, "quantity": 1, "price\_unit": 100.0 }\]

        \]

    }\]

}

\`\`\`

# 6\. Tablas y acciones

## **Planes analíticos**

En Odoo tenemos dados de alta los planes analíticos siguientes:

* ID 1: Proyectos  
* ID 2: Centros de coste

## **Cuentas analíticas (`account.analytic.account`)**

### **Atributos principales**

La lista completa de todos los atributos disponibles en las cuentas analíticas puede obtenerse ejecutando `curl -s -X POST https://dekuple-odoo-staging-26757321.dev.odoo.com/json/2/account.analytic.account/read -H "Content-Type: application/json" -H "Authorization: Bearer xxxxxxxxxx" -d '{ "ids": 92 }' | jq`, o leyendo la documentación en [https://dekuple-odoo-staging-26757321.dev.odoo.com/doc/account.analytic.account](https://dekuple-odoo-staging-26757321.dev.odoo.com/doc/account.analytic.account) . En esta sección se resumen los atributos principales, que son con los que se trabajará.

| Atributo | Nombre en interfaz web | Tipo | Descripción |
| :---- | :---- | :---- | :---- |
| active | Activo | boolean | ¿Quizá se pone a “false” cuando se archiva la cuenta analítica? Ej: true |
| code | Referencia (Reference) | char | El código o identificador interno de la cuenta analítica. Ej: “MAADLDIS” |
| display\_name | Nombre para mostrar | char | En el formulario de creación en el interfaz web no aparece, tiene pinta de que se construye automáticamente a partir de los campos code y name. Ej: “\[MAADLDIS\] Mags & Col Discount ADL” |
| id | ID | integer | Identificador único Ej: 92 |
| name | Cuenta analítica (Analytic Account) | char NOT NULL | Al crear una nueva cuenta analítica en el interfaz web, este es el nombre de la cuenta, el campo que tiene el “font” más grande. Ej: “Mags & Col Discount ADL” |
| plan\_id | Plan | FK hacia account.analytic.plan, NOT NULL | El plan analítico al que pertenece esta cuenta analítica, es obligatorio rellenarlo al crear la cuenta. Ej.: \[2, “Centro costes”\] |

### **Ver los detalles de una cuenta analítica, por referencia**

(Si se buscase por ID, y no por referencia, se utilizaría el método read, no el método search\_read)

curl \-s \-X POST https://dekuple-odoo-staging-26757321.dev.odoo.com/json/2/account.analytic.account/search\_read \-H "Content-Type: application/json" \-H "Authorization: Bearer xxxxxxxxxx" \-d '{ "domain": \[\["code", "=", "MAADLDIS"\]\] }' | jq

La respuesta es un array, y cada elemento del array es un hash con los atributos.

## **Proyectos (`project.project`)**

### **Buscar un proyecto y leer sus atributos**

Para "destripar" un proyecto y ver exactamente qué valores tiene en esos campos, usaremos el método \`read\`. Es la mejor forma de obtener una plantilla real.

\*\*Sustituye \`ID\_DEL\_PROYECTO\` por el ID de un proyecto que ya sepas que está bien configurado:\*\*

```shell
curl -s -X POST https://dekuple-odoo-staging-26757321.dev.odoo.com/json/2/project.project/read \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer TU_API_KEY" \
  -d '{
    "ids": [ID_DEL_PROYECTO]
  }'
```

\*(Si quieres ver \*\*todos\*\* los campos disponibles, simplemente elimina la línea de \`"fields": \[...\]\` del JSON).\*

\---

\#\#\# 3\. Cómo interpretar la respuesta

Cuando ejecutes el comando anterior, recibirás algo parecido a esto:

\`\`\`json

\[

  {

    "id": 123,

    "display\_name": "Proyecto Marketing 2025",

    "account\_id": \[45, "C.A. Proyecto Marketing"\],

    "auto\_account\_id": \[45, "C.A. Proyecto Marketing"\],

    "x\_plan2\_id": \[12, "CECO \- Madrid"\]

  }

\]

\`\`\`

\*\*Lo que esto te dice:\*\*

1\. \*\*Formato Many2one\*\*: Odoo te devuelve una lista: \`\[ID, "Nombre"\]\`. Para tus peticiones de \*\*escritura/creación\*\*, solo te importa el \*\*número (ID)\*\*.

2\. \*\*Relación\*\*: Si ves que \`account\_id\` y \`auto\_account\_id\` tienen el mismo ID, ya sabes que debes rellenar ambos con el mismo valor al crear uno nuevo.

3\. \*\*Centro de Costes\*\*: El ID que aparezca en \`x\_plan2\_id\` es el que deberás usar para asignar el centro de costes en tus automatizaciones.

\---

\#\#\# 4\. Ejemplo actualizado para Crear un Proyecto

Basándome en tu imagen, el comando de creación ahora sería así de preciso:

\`\`\`bash

curl \-s \-X POST https://odoo.dekuple.es/json/2/project.project/create \\

  \-H "Content-Type: application/json" \\

  \-H "Authorization: Bearer TU\_API\_KEY" \\

  \-d '{

    "vals\_list": \[

      {

        "name": "Proyecto API Test",

        "account\_id": 45,

        "auto\_account\_id": 45,

        "x\_plan2\_id": 12

      }

    \]

  }'

\`\`\`

\*\*Sugerencia:\*\* Ejecuta primero el \`read\` sobre un proyecto existente que te guste cómo está configurado. Si me pegas aquí el JSON de respuesta que te devuelva Odoo (borrando datos sensibles si quieres), puedo darte el comando \`create\` exacto para replicarlo.

### **Crear un nuevo proyecto**

Al crear un nuevo proyecto, es necesario asociarlo con la cuenta analítica correspondiente a ese proyecto: el proyecto tiene un campo llamado `analytic_account_id` que apunta al registro de la cuenta analítica.

Aquí tienes los dos escenarios posibles:

\#\#\# Escenario A: El Proyecto se vincula a una Cuenta Analítica ya existente

Este es el método más limpio. Primero obtienes el ID de la cuenta analítica (usando \`search\_read\` como vimos antes) y luego creas el proyecto.

\*\*Comando cURL:\*\*

\`\`\`bash

curl \-s \-X POST https://odoo.dekuple.es/json/2/project.project/create \\

  \-H "Content-Type: application/json" \\

  \-H "X-Odoo-Database: 18.BASE" \\

  \-H "Authorization: Bearer TU\_API\_KEY" \\

  \-d '{

    "vals\_list": \[

      {

        "name": "Nombre del Nuevo Proyecto",

        "partner\_id": ID\_CLIENTE,

        "analytic\_account\_id": ID\_CUENTA\_ANALITICA

      }

    \]

  }'

\`\`\`

\---

\#\#\# Escenario B: Crear la Cuenta Analítica "al vuelo"

Si quieres que Odoo cree la cuenta analítica al mismo tiempo que el proyecto (usando la potencia del ORM), puedes usar la sintaxis de creación de registros relacionados. Sin embargo, dado que \`analytic\_account\_id\` es un campo \*\*Many2one\*\*, la API JSON-2 prefiere recibir un ID.

Si necesitas crear ambos de golpe, la mejor práctica es:

1\. Crear la Cuenta Analítica en \`account.analytic.account\`.

2\. Usar el ID devuelto para crear el Proyecto.

\*\*Paso 1: Crear Cuenta Analítica\*\*

\`\`\`bash

\# POST /json/2/account.analytic.account/create

{

    "vals\_list": \[{

        "name": "Cuenta Analítica: Proyecto X",

        "plan\_id": ID\_DEL\_PLAN\_PROYECTOS // El plan analítico que mencionaste

    }\]

}

\`\`\`

\*\*Paso 2: Crear Proyecto\*\* (usando el ID del paso anterior).

\---

\#\#\# Detalles Técnicos que debes conocer

1\. \*\*El Plan Analítico\*\*: Mencionaste que los proyectos están "replicados" en un plan. En Odoo 19, las cuentas analíticas deben pertenecer a un \*\*Plan\*\* (\`account.analytic.plan\`). Asegúrate de incluir el \`plan\_id\` correcto al crear la cuenta analítica para que aparezca en la sección adecuada de tus informes.

2\. \*\*Configuración Automática\*\*: En muchas instalaciones de Odoo, al crear un proyecto desde la interfaz, Odoo crea automáticamente la cuenta analítica. Sin embargo, \*\*por API este automatismo no siempre se dispara\*\* de la misma forma que en el cliente web. Ser explícito enviando el \`analytic\_account\_id\` es la única forma de asegurar la asociación al 100%.

3\. \*\*Campos adicionales\*\*: Puedes añadir otros campos útiles al crear el proyecto, como:

\* \`allow\_billable\`: \`true\` (si vas a facturar horas).

\* \`label\_tasks\`: "Tareas" o "Hitos" (nombre de las tareas en este proyecto).

\#\#\# Resumen para tu documentación:

\* \*\*Modelo del Proyecto\*\*: \`project.project\`

\* \*\*Modelo Analítico\*\*: \`account.analytic.account\`

\* \*\*Campo de unión\*\*: \`analytic\_account\_id\` (en el modelo de proyecto).

¿Te gustaría que te ayude a construir una consulta para listar todos los Planes Analíticos disponibles y así saber qué \`plan\_id\` usar para tus proyectos?

## **Asientos contables y facturas (`account.move`)**

### **Introducción**

Odoo, internamente, no diferencia entre un asiento contable manual, una factura de cliente, o una factura de proveedor: todos ellos son registros en la tabla `account.move`. El tipo de asiento se diferencia gracias al atributo `move_type`, un atributo de tipo enum que puede tomar cualquiera de los siguientes valores:

* `entry`	\- Asiento contable  
* `in_invoice` \- Factura de proveedor  
* `in_receipt` \- Recibo de compra  
* `in_refund` \- Factura rectificativa de proveedor  
* `out_invoice` \- Factura de cliente  
* `out_receipt` \- Recibo de ventas  
* `out_refund` \- Factura rectificativa de cliente

Los tipos `in_receipt` y `out_receipt` nosotros no los usaremos, están pensados para transacciones en cash (ventas de una cafetería, y compras pequeñas en efectivo con la caja de la empresa).

### **Atributos principales**

| Atributo | Nombre en interfaz web | Tipo | Descripción |
| :---- | :---- | :---- | :---- |
| auto\_post | Contabilizar automáticamente | selection, NOT NULL | Creo que sirve para indicar si el asiento debe contabilizarse automáticamente, en vez de dejarse como borrador, indicando en qué momento se contabilizará. Debe tomar uno de los valores siguientes: at\_date \- En fecha monthly \- Mensualmente no \- No quarterly \- Trimestralmente yearly \- Anualmente |
| currency\_id | Moneda | FK hacia res.currency, NOT NULL | Moneda del asiento |
| date | Fecha | date | Fecha del asiento o de la factura |
| journal\_id | Diario | FK hacia account.journal, NOT NULL | Diario en el que se almacenará el asiento |
| move\_type | Tipo | selection, NOT NULL | Ver Introducción. |
| state | Estado | selection, NOT NULL | Puede tomar los siguientes valores: cancel- Cancelado draft- Borrador posted- Publicado |

### **Crear y contabilizar una factura de proveedor**

Hay que realizar dos pasos. La API de Odoo está diseñada para que el método `create` se encargue únicamente de la creación del registro (en estado "Borrador") y el método `action_post` se encargue de validarlo (contabilizarlo).
