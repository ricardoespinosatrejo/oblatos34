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
    echo "<p><strong>Necesitas agregar este registro TXT en tu DNS:</strong></p>";
    echo "<pre style='background:#f0f0f0;padding:10px;border:1px solid #ccc;'>v=spf1 mx a ip4:TU_IP_SERVIDOR ~all</pre>";
    echo "<p><small>Reemplaza TU_IP_SERVIDOR con la IP de tu servidor SMTP. Contacta a tu proveedor de hosting para agregarlo.</small></p>";
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
    echo "<p>DKIM requiere configuración en el servidor de correo. Contacta a tu proveedor de hosting.</p>";
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
    echo "<pre style='background:#f0f0f0;padding:10px;border:1px solid #ccc;'>v=DMARC1; p=none; rua=mailto:contacto-app@zumuradigital.com</pre>";
    echo "<p><small>Este es un registro básico. 'p=none' significa que no bloquea emails, solo monitorea.</small></p>";
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

