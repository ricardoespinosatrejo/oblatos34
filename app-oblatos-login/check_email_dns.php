<?php
/**
 * Verificador de configuración DNS para emails
 * Verifica SPF, DKIM y DMARC para mejorar la entrega a Gmail
 * Accede desde: https://zumuradigital.com/app-oblatos-login/check_email_dns.php
 */

header('Content-Type: text/html; charset=utf-8');

$domain = 'zumuradigital.com';

echo "<h2>Verificación DNS para $domain</h2>";
echo "<p>Estos registros ayudan a que Gmail y otros proveedores confíen en tus emails.</p>";

// Verificar SPF
echo "<h3>1. Registro SPF (Sender Policy Framework)</h3>";
$spfRecords = dns_get_record($domain, DNS_TXT);
$spfFound = false;
foreach ($spfRecords as $record) {
    if (isset($record['txt']) && (stripos($record['txt'], 'v=spf1') !== false)) {
        echo "<p style='color:green'><strong>✓ SPF encontrado:</strong></p>";
        echo "<pre style='background:#f0f0f0;padding:10px;border:1px solid #ccc;'>" . htmlspecialchars($record['txt']) . "</pre>";
        $spfFound = true;
        break;
    }
}
if (!$spfFound) {
    echo "<p style='color:red'><strong>✗ No se encontró registro SPF</strong></p>";
    
    // Intentar obtener la IP del servidor SMTP automáticamente
    $smtpHost = 'smtp.zumuradigital.com';
    $smtpIP = gethostbyname($smtpHost);
    $serverIP = $_SERVER['SERVER_ADDR'] ?? '';
    
    // Si smtp.zumuradigital.com no resuelve, usar la IP del servidor actual
    if ($smtpIP === $smtpHost) {
        $smtpIP = $serverIP ?: 'TU_IP_SERVIDOR';
    }
    
    echo "<p><strong>Necesitas agregar este registro TXT en tu DNS:</strong></p>";
    
    // Mostrar diferentes opciones según lo que tengamos
    if ($smtpIP && $smtpIP !== 'TU_IP_SERVIDOR') {
        echo "<pre style='background:#f0f0f0;padding:10px;border:1px solid #ccc;'>v=spf1 mx a ip4:$smtpIP ~all</pre>";
        echo "<p><small>IP detectada del servidor: <strong>$smtpIP</strong></small></p>";
    } else {
        echo "<pre style='background:#f0f0f0;padding:10px;border:1px solid #ccc;'>v=spf1 mx a ip4:TU_IP_SERVIDOR ~all</pre>";
        echo "<p><small>Reemplaza TU_IP_SERVIDOR con la IP de tu servidor SMTP.</small></p>";
    }
    
    echo "<div style='background:#fff3cd;padding:15px;border-left:4px solid #ffc107;margin:15px 0;'>";
    echo "<h4 style='margin-top:0'>📋 Cómo agregar el registro SPF:</h4>";
    echo "<ol style='margin-bottom:0;'>";
    echo "<li><strong>Accede al panel de control DNS</strong> de tu dominio (cPanel, Cloudflare, Google Domains, etc.)</li>";
    echo "<li><strong>Busca la sección de registros DNS</strong> o \"Zona DNS\"</li>";
    echo "<li><strong>Agrega un nuevo registro TXT</strong> con estos valores:<ul>";
    echo "<li><strong>Nombre/Host:</strong> @ (o dejarlo vacío, o poner el dominio raíz)</li>";
    echo "<li><strong>Tipo:</strong> TXT</li>";
    echo "<li><strong>Valor/Contenido:</strong> <code>v=spf1 mx a ip4:$smtpIP ~all</code></li>";
    echo "<li><strong>TTL:</strong> 3600 (o el valor por defecto)</li>";
    echo "</ul></li>";
    echo "<li><strong>Guarda los cambios</strong></li>";
    echo "<li><strong>Espera 15 minutos a 48 horas</strong> para que se propague (generalmente 1-2 horas)</li>";
    echo "</ol>";
    echo "<p><strong>💡 Tip:</strong> Si no conoces la IP de tu servidor SMTP, contacta a tu proveedor de hosting (Zumura Digital).</p>";
    echo "<p><strong>🔍 Verificar:</strong> Puedes usar <a href='https://mxtoolbox.com/spf.aspx' target='_blank'>MXToolbox SPF Checker</a> para verificar después de agregarlo.</p>";
    echo "</div>";
}

// Verificar DKIM
echo "<h3>2. Registro DKIM (DomainKeys Identified Mail)</h3>";
$dkimRecords = dns_get_record('default._domainkey.' . $domain, DNS_TXT);
if (empty($dkimRecords)) {
    $dkimRecords = dns_get_record('*._domainkey.' . $domain, DNS_TXT);
}
if (!empty($dkimRecords)) {
    echo "<p style='color:green'><strong>✓ DKIM encontrado:</strong></p>";
    foreach ($dkimRecords as $record) {
        if (isset($record['txt'])) {
            echo "<pre style='background:#f0f0f0;padding:10px;border:1px solid #ccc;'>" . htmlspecialchars(substr($record['txt'], 0, 100)) . "...</pre>";
        }
    }
} else {
    echo "<p style='color:orange'><strong>⚠ DKIM no encontrado</strong></p>";
    echo "<div style='background:#fff3cd;padding:15px;border-left:4px solid #ffc107;margin:15px 0;'>";
    echo "<p><strong>¿Qué es DKIM?</strong></p>";
    echo "<p>DKIM firma digitalmente tus emails para verificar que son auténticos. Es muy importante para Gmail.</p>";
    echo "<p><strong>⚠️ Importante:</strong> DKIM requiere configuración en el servidor de correo. NO puedes agregarlo manualmente en DNS sin configuración previa.</p>";
    echo "<h4 style='margin-top:15px;margin-bottom:10px;'>📋 Qué hacer:</h4>";
    echo "<ol style='margin-bottom:0;'>";
    echo "<li><strong>Contacta a tu proveedor de hosting</strong> (Zumura Digital) y solicita que configuren DKIM para el dominio</li>";
    echo "<li>Tu proveedor te dará:</li>";
    echo "<ul>";
    echo "<li>Un selector (generalmente 'default' o 'mail')</li>";
    echo "<li>Una clave pública que se agregará como registro TXT</li>";
    echo "</ul>";
    echo "<li>El registro será algo como: <code>default._domainkey.zumuradigital.com</code> o <code>mail._domainkey.zumuradigital.com</code></li>";
    echo "<li>Una vez configurado, el registro aparecerá automáticamente aquí</li>";
    echo "</ol>";
    echo "<p><strong>💡 Nota:</strong> Mientras tanto, SPF y DMARC ayudarán con la entrega. DKIM es importante pero no crítico para empezar.</p>";
    echo "</div>";
}

// Verificar DMARC
echo "<h3>3. Registro DMARC (Domain-based Message Authentication)</h3>";
$dmarcRecords = dns_get_record('_dmarc.' . $domain, DNS_TXT);
$dmarcFound = false;
foreach ($dmarcRecords as $record) {
    if (isset($record['txt']) && (stripos($record['txt'], 'v=DMARC1') !== false)) {
        echo "<p style='color:green'><strong>✓ DMARC encontrado:</strong></p>";
        echo "<pre style='background:#f0f0f0;padding:10px;border:1px solid #ccc;'>" . htmlspecialchars($record['txt']) . "</pre>";
        $dmarcFound = true;
        break;
    }
}
if (!$dmarcFound) {
    echo "<p style='color:orange'><strong>⚠ DMARC no encontrado</strong></p>";
    echo "<p><strong>Puedes agregar este registro TXT en tu DNS:</strong></p>";
    
    // Mostrar diferentes formatos según el proveedor
    echo "<div style='background:#f0f0f0;padding:15px;margin:15px 0;border:1px solid #ccc;'>";
    echo "<p><strong>Formato estándar (prueba primero):</strong></p>";
    echo "<pre style='background:#fff;padding:10px;border:1px solid #999;'>v=DMARC1; p=none; rua=mailto:contacto-app@zumuradigital.com</pre>";
    echo "</div>";
    
    echo "<div style='background:#fff3cd;padding:15px;border-left:4px solid #ffc107;margin:15px 0;'>";
    echo "<h4 style='margin-top:0'>📋 Cómo agregar el registro DMARC:</h4>";
    echo "<ol style='margin-bottom:0;'>";
    echo "<li><strong>Accede al panel de control DNS</strong> de tu dominio (mismo panel donde agregaste SPF)</li>";
    echo "<li><strong>Busca la sección de registros DNS</strong> o \"Zona DNS\"</li>";
    echo "<li><strong>Agrega un nuevo registro TXT</strong> con estos valores:<ul>";
    echo "<li><strong>Nombre/Host:</strong> <code>_dmarc</code> (muy importante: debe empezar con guion bajo)</li>";
    echo "<li><strong>Tipo:</strong> TXT</li>";
    echo "<li><strong>Valor/Contenido:</strong> <code>v=DMARC1; p=none; rua=mailto:contacto-app@zumuradigital.com</code></li>";
    echo "<li><strong>TTL:</strong> 3600 (o el valor por defecto)</li>";
    echo "</ul></li>";
    echo "<li><strong>Guarda los cambios</strong></li>";
    echo "<li><strong>Espera 15 minutos a 2 horas</strong> para que se propague</li>";
    echo "</ol>";
    echo "</div>";
    
    echo "<div style='background:#f8d7da;padding:15px;border-left:4px solid #dc3545;margin:15px 0;'>";
    echo "<h4 style='margin-top:0'>❌ Si recibes error \"Record data is invalid\":</h4>";
    
    // Detectar si es nic.com basado en el dominio o mostrar instrucciones generales
    $isNicCom = stripos($_SERVER['HTTP_HOST'] ?? '', 'nic.com') !== false || stripos($domain, 'nic.com') !== false;
    
    if ($isNicCom) {
        echo "<div style='background:#fff;padding:10px;margin:10px 0;border:2px solid #007bff;'>";
        echo "<h5 style='margin-top:0;color:#007bff;'>🔵 Instrucciones específicas para nic.com:</h5>";
        echo "<p><strong>nic.com tiene requisitos específicos de formato. Prueba en este orden:</strong></p>";
        echo "<ol>";
        echo "<li><strong>Formato mínimo (RECOMENDADO primero):</strong></li>";
        echo "<pre style='background:#f0f0f0;padding:10px;border:1px solid #999;margin:5px 0;'>v=DMARC1;p=none</pre>";
        echo "<li><strong>Con reportes (sin espacios después de punto y coma):</strong></li>";
        echo "<pre style='background:#f0f0f0;padding:10px;border:1px solid #999;margin:5px 0;'>v=DMARC1;p=none;rua=mailto:contacto-app@zumuradigital.com</pre>";
        echo "<li><strong>Verifica que el campo Host/Nombre sea exactamente:</strong> <code>_dmarc</code> (con guion bajo, sin el dominio)</li>";
        echo "<li><strong>Verifica que el tipo sea:</strong> <code>TXT</code></li>";
        echo "</ol>";
        echo "<p><strong>⚠️ Errores comunes en nic.com:</strong></p>";
        echo "<ul>";
        echo "<li>❌ NO agregues espacios después del punto y coma</li>";
        echo "<li>❌ NO agregues comillas al valor</li>";
        echo "<li>❌ NO incluyas el dominio completo en el Host (solo <code>_dmarc</code>)</li>";
        echo "<li>✅ El valor debe ser exactamente: <code>v=DMARC1;p=none</code> (sin espacios, sin comillas)</li>";
        echo "</ul>";
        echo "</div>";
    }
    
    echo "<p><strong>Prueba estos formatos alternativos:</strong></p>";
    echo "<p><strong>Opción 1 - Sin espacios (RECOMENDADO para nic.com):</strong></p>";
    echo "<pre style='background:#fff;padding:10px;border:1px solid #999;'>v=DMARC1;p=none</pre>";
    echo "<p><strong>Opción 2 - Sin espacios con reportes:</strong></p>";
    echo "<pre style='background:#fff;padding:10px;border:1px solid #999;'>v=DMARC1;p=none;rua=mailto:contacto-app@zumuradigital.com</pre>";
    echo "<p><strong>Opción 3 - Con espacios (estándar):</strong></p>";
    echo "<pre style='background:#fff;padding:10px;border:1px solid #999;'>v=DMARC1; p=none</pre>";
    echo "<p><strong>Opción 4 - Solo versión (mínimo):</strong></p>";
    echo "<pre style='background:#fff;padding:10px;border:1px solid #999;'>v=DMARC1</pre>";
    echo "<p><strong>💡 Consejos específicos para nic.com:</strong></p>";
    echo "<ul>";
    echo "<li><strong>NO uses espacios</strong> después del punto y coma (usa <code>v=DMARC1;p=none</code> no <code>v=DMARC1; p=none</code>)</li>";
    echo "<li><strong>NO agregues comillas</strong> alrededor del valor</li>";
    echo "<li><strong>El Host debe ser solo:</strong> <code>_dmarc</code> (sin dominio, sin @)</li>";
    echo "<li><strong>Copia y pega exactamente</strong> sin espacios al inicio o final</li>";
    echo "<li><strong>Prueba primero la Opción 1</strong> (formato mínimo sin espacios)</li>";
    echo "</ul>";
    echo "<p><strong>Si ninguna funciona:</strong></p>";
    echo "<ul>";
    echo "<li>Contacta al soporte de nic.com: pueden tener validaciones específicas</li>";
    echo "<li>Verifica que no hay límites de longitud en el campo de texto</li>";
    echo "<li>Intenta agregar el registro desde la interfaz web de nic.com (no desde otra herramienta)</li>";
    echo "</ul>";
    echo "</div>";
    
    echo "<div style='background:#d1ecf1;padding:15px;border-left:4px solid #0c5460;margin:15px 0;'>";
    echo "<h4 style='margin-top:0'>¿Qué significa cada parte?</h4>";
    echo "<ul>";
    echo "<li><code>v=DMARC1</code> - Versión del protocolo DMARC (requerido)</li>";
    echo "<li><code>p=none</code> - Política: no bloquea emails, solo monitorea (recomendado para empezar)</li>";
    echo "<li><code>rua=mailto:contacto-app@zumuradigital.com</code> - Email donde recibirás reportes de entrega (opcional)</li>";
    echo "</ul>";
    echo "<p><strong>💡 Tips:</strong></p>";
    echo "<ul>";
    echo "<li>Puedes cambiar <code>p=none</code> a <code>p=quarantine</code> (poner en cuarentena) o <code>p=reject</code> (rechazar) cuando estés seguro de que todo funciona</li>";
    echo "<li>El email de reportes es opcional - puedes empezar solo con <code>v=DMARC1; p=none</code></li>";
    echo "</ul>";
    echo "<p><strong>🔍 Verificar:</strong> Después de agregarlo, vuelve a cargar esta página para verificar que se detectó correctamente.</p>";
    echo "</div>";
}

// Verificar MX
echo "<h3>4. Registros MX (Mail Exchange)</h3>";
$mxRecords = dns_get_record($domain, DNS_MX);
if (!empty($mxRecords)) {
    echo "<p style='color:green'><strong>✓ Registros MX encontrados:</strong></p>";
    foreach ($mxRecords as $record) {
        echo "<pre style='background:#f0f0f0;padding:10px;border:1px solid #ccc;'>" . htmlspecialchars($record['target']) . " (Prioridad: " . $record['pri'] . ")</pre>";
    }
} else {
    echo "<p style='color:red'><strong>✗ No se encontraron registros MX</strong></p>";
    
    echo "<div style='background:#f8d7da;padding:15px;border-left:4px solid #dc3545;margin:15px 0;'>";
    echo "<p><strong>¿Qué son los registros MX?</strong></p>";
    echo "<p>Los registros MX indican qué servidor recibe los emails enviados a tu dominio. Son necesarios para recibir correos, pero NO son estrictamente necesarios para ENVIAR correos.</p>";
    echo "<h4 style='margin-top:15px;margin-bottom:10px;'>📋 ¿Necesitas registros MX?</h4>";
    echo "<ul style='margin-bottom:10px;'>";
    echo "<li><strong>Si solo ENVÍAS emails</strong> (como recuperación de password): <strong>NO es crítico</strong>, pero ayuda con la reputación</li>";
    echo "<li><strong>Si RECIBES emails</strong> en tu dominio: <strong>SÍ es necesario</strong></li>";
    echo "</ul>";
    echo "<h4 style='margin-top:15px;margin-bottom:10px;'>🔧 Cómo agregar registros MX:</h4>";
    echo "<ol style='margin-bottom:0;'>";
    echo "<li><strong>Contacta a tu proveedor de hosting</strong> (Zumura Digital) para obtener los valores correctos</li>";
    echo "<li>Los registros MX típicamente tienen este formato:<ul>";
    echo "<li><strong>Nombre/Host:</strong> <code>@</code> o el dominio raíz</li>";
    echo "<li><strong>Tipo:</strong> MX</li>";
    echo "<li><strong>Prioridad:</strong> 10 (o el valor que te indique tu hosting)</li>";
    echo "<li><strong>Valor/Destino:</strong> <code>mail.zumuradigital.com</code> o <code>smtp.zumuradigital.com</code> (tu hosting te dirá el valor correcto)</li>";
    echo "</ul></li>";
    echo "<li>Puede haber múltiples registros MX con diferentes prioridades</li>";
    echo "</ol>";
    echo "<p><strong>💡 Nota:</strong> Si solo usas el servidor SMTP para ENVIAR emails (como en tu app), los registros MX no son estrictamente necesarios para la funcionalidad de envío, pero pueden ayudar con la reputación del dominio.</p>";
    echo "<p><strong>⚠️ Importante:</strong> NO agregues registros MX sin consultar primero con tu proveedor de hosting, ya que pueden afectar la recepción de correos.</p>";
    echo "</div>";
}

echo "<hr>";
echo "<h3>Recomendaciones para mejorar la entrega a Gmail:</h3>";
echo "<ol>";
echo "<li><strong>SPF:</strong> Es el más importante. Asegúrate de tenerlo configurado correctamente.</li>";
echo "<li><strong>DKIM:</strong> Ayuda mucho con Gmail. Contacta a tu hosting para configurarlo.</li>";
echo "<li><strong>DMARC:</strong> Opcional pero recomendado para monitorear la entrega.</li>";
echo "<li><strong>Reputación:</strong> Envía emails solo a usuarios que lo soliciten (no spam).</li>";
echo "<li><strong>Contenido:</strong> Evita palabras comunes de spam en el asunto y cuerpo.</li>";
echo "</ol>";

echo "<p><strong>Nota:</strong> Los cambios en DNS pueden tardar hasta 48 horas en propagarse.</p>";
echo "<p><small>Herramientas útiles para verificar: <a href='https://mxtoolbox.com/spf.aspx' target='_blank'>MXToolbox</a> | <a href='https://www.mail-tester.com/' target='_blank'>Mail Tester</a></small></p>";
?>



