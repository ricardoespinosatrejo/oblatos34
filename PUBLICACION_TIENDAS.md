# Guía para publicar PlayCoop en Google Play y App Store

Este documento indica **qué archivos entregar** a la empresa que tiene las cuentas de desarrollador y **qué debe hacer cada tienda** para publicar la app.

---

## Resumen rápido

| Tienda        | Archivo principal que deben recibir | Dónde está |
|---------------|--------------------------------------|------------|
| **Google Play** | `app-release.aab` (Android App Bundle) | `build/app/outputs/bundle/release/app-release.aab` |
| **Apple App Store** | Código fuente **o** solo el archivo **.ipa** (si tú generas el IPA con su certificado; ver opciones sin dar código más abajo) | Ver sección Apple |

---

## 1. Google Play Store

### Archivos que debe recibir la empresa

1. **Android App Bundle (obligatorio)**  
   - Ruta: **`build/app/outputs/bundle/release/app-release.aab`**  
   - Es el formato que Google exige para subir apps nuevas.  
   - Tamaño aproximado: ~157 MB.  
   - La app ya está firmada con la configuración actual del proyecto (`android/key.properties`).  
   - Si la empresa va a usar **Play App Signing**, pueden subir este AAB y Google lo re-firmará con la clave de Play. Si van a firmar ellos, necesitarían que les pases también la keystore (o generar un AAB sin firmar y que ellos firmen; en ese caso habría que ajustar el proyecto).

2. **Opcional: APK de release** (para pruebas o distribución fuera de Play)  
   - Ruta: **`build/app/outputs/flutter-apk/app-release.apk`**  
   - No es necesario para publicar en Play, pero puede servir para pruebas internas.

### Qué debe hacer la empresa en Google Play Console

- Crear la aplicación (si no existe) con el **nombre** y **paquete** que usen (actualmente `com.playcoop.app`).
- Subir el archivo **`app-release.aab`** en la pestaña “Producción” (o “Prueba interna/cerrada”) → “Crear nueva versión” → adjuntar el AAB.
- Completar la **ficha de la tienda**:
  - Título corto y descripción larga.
  - **URL del aviso de privacidad** (recomendable que sea una página pública, por ejemplo: `https://playcoop.com.mx/aviso-privacidad` con el mismo texto que está en la app; contacto: privacidad@playcoop.com.mx).
  - Clasificación de contenido (formulario en la consola).
  - **Capturas de pantalla** (móvil y, si aplica, tablet): mínimo las que pida la consola para cada tipo de dispositivo.
  - **Ícono** de la app (alta resolución según requisitos de Play).
  - **Gráfico de funciones** (feature graphic) si lo pide la consola.
- Configurar **Play App Signing** si no lo tienen (recomendado); así Google gestiona la firma de producción.
- Enviar la versión a revisión cuando todo esté completo.

### Datos técnicos actuales del proyecto (por si los piden)

- **Application ID (paquete):** `com.playcoop.app`  
- **Versión:** 1.0.0 (versionName) / 1 (versionCode) — definido en `pubspec.yaml` como `1.0.0+1`.  
- **minSdk / targetSdk:** los que define Flutter por defecto en el proyecto (revisar en `android/app/build.gradle.kts` si necesitan el número exacto).

---

## 2. Apple App Store

### Situación del build en esta máquina

- En esta Mac se generó el **archive** de Xcode (`Runner.xcarchive`) pero **no** el archivo **.ipa** listo para subir a App Store Connect, porque hace falta un certificado **“iOS Distribution”** y un perfil de aprovisionamiento de tipo **App Store** asociados a la **cuenta de Apple Developer de la empresa**.
- Por tanto, la publicación en Apple la debe hacer quien tenga esa cuenta (o acceso al equipo de desarrollo en App Store Connect).

### Opción A: La empresa tiene Mac y Xcode (recomendada)

Entregar a la empresa:

1. **Código fuente completo** del proyecto (por ejemplo, el repositorio Git o un ZIP del proyecto Flutter).
2. **Archivo del archive** (opcional pero útil):  
   - Ruta: **`build/ios/archive/Runner.xcarchive`**  
   - Es una carpeta; deben comprimirla en un `.zip` para enviarla.  
   - En Xcode pueden abrir este archive con “Window → Organizer” o arrastrando el `.xcarchive`; luego, con **su** equipo y certificado de distribución, exportar el IPA para “App Store Connect”.

Pasos para ellos:

1. Abrir el proyecto en Xcode: en la carpeta del proyecto, abrir **`ios/Runner.xcworkspace`** (no el `.xcodeproj`).
2. En Xcode: **Signing & Capabilities** del target **Runner**:
   - Seleccionar **su** Team (cuenta de Apple Developer).
   - Dejar “Automatically manage signing” activado para que Xcode cree/use el perfil de “App Store” y el certificado “iOS Distribution”.
3. **Product → Archive** (con un dispositivo genérico o “Any iOS Device”).
4. En el **Organizer**, seleccionar el archive → **Distribute App** → **App Store Connect** → seguir el asistente (upload).
5. En [App Store Connect](https://appstoreconnect.apple.com) crear la app (si no existe), subir el build que acaban de enviar y completar la ficha (nombre, descripción, capturas, privacidad, etc.).

### Opción B: La empresa solo va a subir el build (sin tocar código)

Si prefieren no abrir el proyecto y solo subir un IPA:

- Quien tenga certificado “iOS Distribution” y perfil de App Store (en esta Mac o en la de la empresa) debe:
  1. Abrir en Xcode el archive: **`build/ios/archive/Runner.xcarchive`**.
  2. En Organizer → **Distribute App** → **App Store Connect** y exportar/subir con su cuenta.
- Si en esta Mac no hay certificado de distribución, habría que hacer ese paso en una Mac donde sí esté instalado el certificado de la empresa.

---

### Opciones SIN darles el código fuente (solo tú generas el IPA)

Si **no** quieres entregar archivos editables (código fuente) y prefieres que ellos solo reciban el archivo listo para subir:

| Opción | Qué hace la empresa | Qué haces tú | Resultado |
|--------|----------------------|---------------|------------|
| **C. Te pasan certificado + perfil** | Te envían el certificado iOS Distribution (archivo .p12) y el perfil de aprovisionamiento (.mobileprovision) para el Bundle ID de la app. | Instalas el .p12 y el perfil en tu Mac, generas el IPA con Flutter/Xcode y les envías **solo el archivo .ipa**. | Ellos suben el .ipa a App Store Connect. Nunca ven tu código. |
| **D. Te agregan a su equipo Apple Developer** | Te invitan a su equipo en [developer.apple.com](https://developer.apple.com) (tu Apple ID como desarrollador). | En tu Mac abres el proyecto, en Xcode eliges su Team y firmas con “Automatically manage signing”. Generas el IPA y les envías **solo el .ipa**. | Ellos suben el .ipa. No necesitan pasarte el certificado; tú firmas con el equipo. |

**Sí, pueden pasarte su certificado “iOS Distribution”** (y el perfil de aprovisionamiento). Así tú generas el IPA en tu Mac sin que ellos tengan acceso al código. Detalle abajo.

---

### Cómo usar el certificado que te pasen (Opción C)

Si la empresa te envía su **certificado iOS Distribution** y el **perfil de aprovisionamiento**:

1. **Lo que te deben enviar**
   - **Certificado en formato .p12** (exportado desde el Llavero en una Mac con su cuenta, incluyendo la clave privada), con una contraseña que te indiquen.
   - **Perfil de aprovisionamiento** (archivo .mobileprovision) de tipo **App Store** o **App Store Distribution**, para el **Bundle ID** que use la app (en este proyecto: **`com.playcoop.app`**). Lo descargan en [developer.apple.com](https://developer.apple.com) → Certificates, Identifiers & Profiles → Profiles.

2. **En tu Mac**
   - **Instalar el .p12:** Doble clic en el archivo .p12 → introducir la contraseña que te dieron → se agrega al Llavero (Keychain Access). Asegúrate de que el certificado “iPhone Distribution” o “Apple Distribution” aparezca en “login” o “System”.
   - **Instalar el perfil:** Doble clic en el .mobileprovision → se instala (aparece en Xcode → Settings → Accounts → [su cuenta] → Manage Certificates / en el Organizer).

3. **Generar el IPA**
   - Abre el proyecto Flutter en tu Mac.
   - En Xcode abre **`ios/Runner.xcworkspace`**.
   - En el target **Runner** → **Signing & Capabilities**: desmarca “Automatically manage signing”, elige el **perfil** que te pasaron (debe coincidir con el Bundle ID `oblatos`) y asegúrate de que Xcode use el certificado de distribución que instalaste.
   - Desde terminal: `flutter build ipa` (o en Xcode: Product → Archive, luego Distribute App → App Store Connect).
   - El .ipa quedará en **`build/ios/ipa/`** (o en el Organizer si usaste Archive).

4. **Entregar**
   - Envías a la empresa **solo el archivo .ipa**. Ellos lo suben con la app [Transporter](https://apps.apple.com/app/transporter/id1450874784) o desde Xcode → Organizer → Distribute App, a su cuenta de App Store Connect.

**Importante:** El **Bundle ID** del perfil debe ser exactamente el que tiene la app (ahora mismo **`com.playcoop.app`**). Si la empresa ya tiene registrada la app con otro Bundle ID, tendrás que cambiar el Bundle ID del proyecto para que coincida y que te pasen un perfil para ese ID (o ellos te confirman qué Bundle ID usar).

---

### Qué debe tener listo la empresa en App Store Connect

- **Nombre de la app**, idioma, categoría.
- **Descripción** y palabras clave.
- **URL de aviso de privacidad** (pública), por ejemplo: `https://playcoop.com.mx/aviso-privacidad`.
- **Capturas de pantalla** para los tamaños que pida Apple (iPhone 6.7", 6.5", 5.5", iPad si aplica, etc.).
- **Ícono** (sin transparencia, tamaños indicados por Apple).
- **Versión y build:** actualmente 1.0.0 (1) — debe coincidir con lo que tenga el IPA/archive.
- **Bundle ID:** en el proyecto actual está como **`com.playcoop.app`** (en `ios/Runner.xcodeproj` y en la configuración de Xcode). Si la empresa usa otro, tendrán que cambiarlo en Xcode y volver a archivar.

### Nota sobre el ícono de arranque (launch screen)

Al generar el archive apareció el aviso:

- “Launch image is set to the default placeholder icon. Replace with unique launch image.”

Recomendación: antes de publicar, sustituir en el proyecto el launch screen / launch image por uno con la identidad de PlayCoop (instrucciones en [Flutter iOS deploy](https://flutter.dev/to/ios-deploy)). No bloquea la subida, pero evita que se vea el placeholder en producción.

---

## 3. Checklist común para ambas tiendas

- [ ] **Aviso de privacidad en web:** una URL pública (ej. `https://playcoop.com.mx/aviso-privacidad`) con el texto que ya está en la app y contacto privacidad@playcoop.com.mx.
- [ ] **Capturas de pantalla** en los tamaños y cantidades que pida cada tienda.
- [ ] **Ícono** en alta resolución según requisitos de Google y Apple.
- [ ] **Descripción** y, en su caso, “feature graphic” (Google) y metadata en App Store Connect (Apple).
- [ ] **Clasificación de contenido / edad** según las políticas de cada tienda.

---

## 4. Dónde están los archivos en este proyecto

```
oblatos34/
├── build/
│   ├── app/outputs/
│   │   ├── bundle/release/
│   │   │   └── app-release.aab          ← Entregar para Google Play
│   │   └── flutter-apk/
│   │       └── app-release.apk          ← Opcional (pruebas)
│   └── ios/archive/
│       └── Runner.xcarchive             ← Para Apple (abrir en Xcode con su cuenta)
├── android/
│   └── key.properties                   ← Configuración de firma Android (guardar de forma segura)
└── PUBLICACION_TIENDAS.md               ← Esta guía
```

---

## 5. Contacto y soporte

- **Privacidad / datos personales:** privacidad@playcoop.com.mx  
- **Versión de la app:** 1.0.0 (build 1)  
- **Nombre mostrado en la app:** PlayCoop  

Si la empresa necesita cambiar el Application ID (Android), Bundle ID (iOS), nombre de la app o versión, se puede hacer en el código y volver a generar el AAB y/o el archive siguiendo los mismos comandos (`flutter build appbundle --release` y `flutter build ipa` o Archive en Xcode).
