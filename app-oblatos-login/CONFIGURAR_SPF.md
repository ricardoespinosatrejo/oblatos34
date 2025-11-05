# 📧 Guía para Configurar Registro SPF en DNS

## ¿Qué es SPF?

SPF (Sender Policy Framework) es un registro DNS que ayuda a prevenir el spam y mejora la entrega de tus emails a Gmail, Outlook y otros proveedores.

## 🎯 Paso a Paso: Agregar Registro SPF

### Paso 1: Obtener la IP de tu Servidor SMTP

Primero necesitas saber la IP del servidor que envía tus emails. Puedes:

1. **Preguntarle a tu proveedor de hosting** (Zumura Digital)
2. **Verificar desde el script:** Visita `check_email_dns.php` - intentará detectarla automáticamente
3. **Usar comandos:** 
   ```bash
   nslookup smtp.zumuradigital.com
   # o
   dig smtp.zumuradigital.com +short
   ```

### Paso 2: Formato del Registro SPF

El registro SPF debe tener este formato:

```
v=spf1 mx a ip4:TU_IP_SERVIDOR ~all
```

**Ejemplo si tu IP es 192.168.1.100:**
```
v=spf1 mx a ip4:192.168.1.100 ~all
```

**¿Qué significa cada parte?**
- `v=spf1` - Versión del protocolo SPF
- `mx` - Permite el servidor MX del dominio
- `a` - Permite la IP del registro A del dominio
- `ip4:XXX.XXX.XXX.XXX` - Permite una IP específica (reemplaza con tu IP)
- `~all` - Los demás servidores fallan suavemente (recomendado para empezar)

### Paso 3: Agregar el Registro según tu Proveedor DNS

#### 🌐 **cPanel (Hosting compartido común)**

1. Accede a **cPanel**
2. Busca la sección **"Zona DNS"** o **"Advanced DNS Zone Editor"**
3. Selecciona el dominio `zumuradigital.com`
4. Busca si ya existe un registro TXT (puede estar vacío o con otro valor)
5. Si existe, edítalo. Si no existe, haz clic en **"Add Record"**
6. Completa:
   - **Name:** `@` o `zumuradigital.com` (o déjalo vacío)
   - **Type:** `TXT`
   - **TXT Data:** `v=spf1 mx a ip4:TU_IP_SERVIDOR ~all`
   - **TTL:** `3600` (o el valor por defecto)
7. Haz clic en **"Add Record"** o **"Save"**

#### ☁️ **Cloudflare**

1. Accede a tu cuenta de Cloudflare
2. Selecciona el dominio `zumuradigital.com`
3. Ve a **DNS** → **Records**
4. Busca si ya existe un registro TXT para `@`
5. Si existe, haz clic en **"Edit"**. Si no existe, haz clic en **"Add record"**
6. Completa:
   - **Type:** `TXT`
   - **Name:** `@` (o `zumuradigital.com`)
   - **Content:** `v=spf1 mx a ip4:TU_IP_SERVIDOR ~all`
   - **TTL:** `Auto` (o `3600`)
   - **Proxy status:** `DNS only` (no "Proxied")
7. Haz clic en **"Save"**

#### 🔷 **Google Domains / Google Workspace**

1. Accede a [Google Domains](https://domains.google.com)
2. Selecciona el dominio `zumuradigital.com`
3. Ve a **DNS** en el menú lateral
4. Desplázate hasta **"Custom resource records"**
5. Haz clic en **"Add record"**
6. Completa:
   - **Host name:** `@` (o déjalo vacío)
   - **Type:** `TXT`
   - **TTL:** `3600`
   - **Data:** `v=spf1 mx a ip4:TU_IP_SERVIDOR ~all`
7. Haz clic en **"Save"**

#### 📧 **Namecheap**

1. Accede a tu cuenta de Namecheap
2. Ve a **Domain List** → Selecciona `zumuradigital.com`
3. Haz clic en **"Advanced DNS"**
4. En la sección **"Host Records"**, busca registros TXT existentes
5. Si existe uno para `@`, edítalo. Si no, haz clic en **"Add New Record"**
6. Completa:
   - **Type:** `TXT Record`
   - **Host:** `@`
   - **Value:** `v=spf1 mx a ip4:TU_IP_SERVIDOR ~all`
   - **TTL:** `Automatic` (o `30 min`)
7. Haz clic en el checkmark para guardar

#### 🟦 **GoDaddy**

1. Accede a tu cuenta de GoDaddy
2. Ve a **My Products** → Selecciona el dominio
3. Haz clic en **DNS** → **Manage DNS**
4. En la sección **"Records"**, busca registros TXT
5. Si existe uno para `@`, haz clic en el lápiz para editarlo
6. Si no existe, haz clic en **"Add"**
7. Completa:
   - **Type:** `TXT`
   - **Name:** `@`
   - **Value:** `v=spf1 mx a ip4:TU_IP_SERVIDOR ~all`
   - **TTL:** `600` (10 minutos)
8. Haz clic en **"Save"**

#### 🐧 **DirectAdmin / Plesk**

1. Accede al panel de control
2. Busca **"DNS Management"** o **"DNS Settings"**
3. Selecciona el dominio `zumuradigital.com`
4. Busca registros TXT existentes
5. Agrega o edita el registro:
   - **Host:** `@` o vacío
   - **Type:** `TXT`
   - **Value:** `v=spf1 mx a ip4:TU_IP_SERVIDOR ~all`
   - **TTL:** `3600`
6. Guarda los cambios

### Paso 4: Verificar que Funcionó

Después de agregar el registro, espera **15 minutos a 2 horas** y verifica:

1. **Desde el script:** Visita `https://zumuradigital.com/app-oblatos-login/check_email_dns.php`
2. **Herramientas online:**
   - [MXToolbox SPF Checker](https://mxtoolbox.com/spf.aspx)
   - [Mail Tester](https://www.mail-tester.com/)
   - [SPF Record Checker](https://www.spf-record.com/)

### ⚠️ Notas Importantes

1. **Solo puede haber UN registro SPF por dominio.** Si ya existe uno, edítalo en lugar de crear uno nuevo.

2. **Si tienes múltiples servidores SMTP**, puedes combinar IPs:
   ```
   v=spf1 mx a ip4:192.168.1.100 ip4:192.168.1.101 ~all
   ```

3. **Si usas servicios externos** (como SendGrid, Mailgun, etc.), inclúyelos:
   ```
   v=spf1 mx a ip4:TU_IP include:sendgrid.net ~all
   ```

4. **Los valores de `~all`:**
   - `~all` - Fallo suave (recomendado para empezar)
   - `-all` - Fallo estricto (solo para cuando estés seguro)

5. **TTL (Time To Live):** Usa valores bajos (300-600) durante pruebas, y valores altos (3600+) en producción.

### 🆘 Solución de Problemas

**El registro no aparece después de agregarlo:**
- Espera más tiempo (hasta 48 horas en algunos casos)
- Verifica que guardaste correctamente
- Asegúrate de que solo hay UN registro SPF

**Error de sintaxis:**
- Verifica que no hay espacios extra
- Asegúrate de que la IP está correcta
- No uses comillas en el valor

**¿Necesitas ayuda?**
- Contacta a tu proveedor de hosting (Zumura Digital)
- Revisa los logs de error en `phpmailer_helper.php` con `debug => true`

---

**Última actualización:** Después de agregar el registro SPF, también considera configurar DKIM y DMARC para máxima seguridad.





