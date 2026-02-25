<?php
session_start();

// Proteger el panel: solo accesible si hay sesión de admin
if (empty($_SESSION['is_admin'])) {
    // Si no hay sesión, redirigir a la página de login (puede ser este mismo archivo si lo abres directo)
    // Aquí dejamos que el frontend maneje el login, pero evitamos que se cargue contenido sensible
    // Si prefieres, puedes redirigir a otra ruta:
    // header('Location: admin_panel_login.html');
    // exit;
}
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Panel de Administración - Oblatos34</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: #f5f5f5;
            height: 100vh;
            overflow: hidden;
        }

        .login-container {
            background: white;
            padding: 40px;
            border-radius: 15px;
            box-shadow: 0 15px 35px rgba(0, 0, 0, 0.1);
            width: 100%;
            max-width: 400px;
            text-align: center;
            position: fixed;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            z-index: 1000;
        }

        .admin-layout {
            display: none;
            height: 100vh;
            background: #f5f5f5;
        }

        .admin-layout.show {
            display: flex;
        }

        .sidebar {
            width: 280px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px;
            overflow-y: auto;
            box-shadow: 2px 0 10px rgba(0, 0, 0, 0.1);
            transition: transform 0.3s ease;
        }

        .sidebar.mobile-hidden {
            transform: translateX(-100%);
        }

        .sidebar-header {
            text-align: center;
            margin-bottom: 30px;
            padding-bottom: 20px;
            border-bottom: 1px solid rgba(255, 255, 255, 0.2);
        }

        .sidebar-header h1 {
            font-size: 1.8em;
            margin-bottom: 10px;
        }

        .sidebar-header p {
            opacity: 0.8;
            font-size: 0.9em;
        }

        .menu-item {
            display: block;
            padding: 15px 20px;
            margin: 8px 0;
            background: rgba(255, 255, 255, 0.1);
            border-radius: 8px;
            color: white;
            text-decoration: none;
            transition: all 0.3s;
            cursor: pointer;
            border: none;
            width: 100%;
            text-align: left;
            font-size: 16px;
        }

        .menu-item:hover {
            background: rgba(255, 255, 255, 0.2);
            transform: translateX(5px);
        }

        .menu-item.active {
            background: rgba(255, 255, 255, 0.3);
            font-weight: bold;
        }

        .logout-btn {
            background: linear-gradient(135deg, #ff6b6b 0%, #ee5a24 100%);
            margin-top: 30px;
            font-weight: bold;
        }

        .logout-btn:hover {
            background: linear-gradient(135deg, #ff5252 0%, #d32f2f 100%);
        }

        .content-area {
            flex: 1;
            background: white;
            margin: 20px;
            border-radius: 10px;
            box-shadow: 0 5px 15px rgba(0, 0, 0, 0.1);
            overflow: hidden;
            position: relative;
        }

        .mobile-header {
            display: none;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 15px 20px;
            align-items: center;
            justify-content: space-between;
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            z-index: 100;
        }

        .hamburger-btn {
            background: none;
            border: none;
            color: white;
            font-size: 24px;
            cursor: pointer;
            padding: 5px;
            border-radius: 5px;
            transition: background-color 0.3s;
        }

        .hamburger-btn:hover {
            background: rgba(255, 255, 255, 0.1);
        }

        .mobile-title {
            font-size: 1.2em;
            font-weight: bold;
        }

        .content-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px;
            font-size: 1.5em;
            font-weight: bold;
        }

        .content-frame {
            width: 100%;
            height: calc(100vh - 120px);
            border: none;
            background: white;
        }

        .mobile-overlay {
            display: none;
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: rgba(0, 0, 0, 0.5);
            z-index: 50;
        }

        .mobile-overlay.show {
            display: block;
        }

        h1 {
            color: #333;
            margin-bottom: 30px;
            font-size: 2.5em;
        }

        h2 {
            color: #555;
            margin-bottom: 20px;
            font-size: 1.8em;
        }

        .form-group {
            margin-bottom: 20px;
            text-align: left;
        }

        label {
            display: block;
            margin-bottom: 8px;
            color: #555;
            font-weight: 600;
        }

        input[type="text"], input[type="password"] {
            width: 100%;
            padding: 12px;
            border: 2px solid #ddd;
            border-radius: 8px;
            font-size: 16px;
            transition: border-color 0.3s;
        }

        input[type="text"]:focus, input[type="password"]:focus {
            outline: none;
            border-color: #667eea;
        }

        .btn {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 12px 30px;
            border: none;
            border-radius: 8px;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            transition: transform 0.3s;
            text-decoration: none;
            display: inline-block;
            margin: 10px;
        }

        .btn:hover {
            transform: translateY(-2px);
        }

        .error-message {
            background: #ff6b6b;
            color: white;
            padding: 10px;
            border-radius: 6px;
            margin-bottom: 20px;
            display: none;
        }

        @media (max-width: 768px) {
            .admin-layout {
                flex-direction: row;
            }
            
            .sidebar {
                position: fixed;
                top: 0;
                left: 0;
                height: 100vh;
                width: 280px;
                z-index: 60;
                transform: translateX(-100%);
            }
            
            .sidebar.mobile-show {
                transform: translateX(0);
            }
            
            .mobile-header {
                display: flex;
            }
            
            .content-header {
                margin-top: 60px;
            }
            
            .content-area {
                margin: 10px;
                margin-top: 70px;
            }
            
            .content-frame {
                height: calc(100vh - 180px);
            }
            
            h1 {
                font-size: 2em;
            }
        }
    </style>
</head>
<body>
    <!-- Pantalla de Login -->
    <div class="login-container" id="loginContainer">
        <h1>🔐 Panel de Administración</h1>
        <h2>Oblatos34</h2>
        
        <div class="error-message" id="errorMessage">
            Usuario o contraseña incorrectos
        </div>
        
        <form id="loginForm">
            <div class="form-group">
                <label for="username">Usuario:</label>
                <input type="text" id="username" name="username" required>
            </div>
            
            <div class="form-group">
                <label for="password">Contraseña:</label>
                <input type="password" id="password" name="password" required>
            </div>
            
            <button type="submit" class="btn">Iniciar Sesión</button>
        </form>
    </div>

    <!-- Panel de Administración con Menú Lateral -->
    <div class="admin-layout" id="adminLayout">
        <!-- Overlay para móvil -->
        <div class="mobile-overlay" id="mobileOverlay" onclick="toggleMobileMenu()"></div>
        
        <!-- Sidebar -->
        <div class="sidebar" id="sidebar">
            <div class="sidebar-header">
                <h1>🎛️ Admin Panel</h1>
                <p>Oblatos34</p>
            </div>
            
            <button class="menu-item" onclick="loadPage('usuarios_fixed_final.html', 'Usuarios Registrados de la APP')">
                🏆 Usuarios Registrados de la APP
            </button>
            
            <button class="menu-item" onclick="loadPage('usuario_ranking_completo.html', 'Ranking de uso de la App')">
                📊 Ranking de uso de la App
            </button>
            
            <button class="menu-item" onclick="loadPage('game_ranking_working.html', 'Ranking del Juego')">
                🎮 Ranking del Juego
            </button>
            
            <button class="menu-item" onclick="loadPage('https://zumuradigital.com/app-oblatos-login/trivias_cms.php', 'Actualizar Trivia')">
                🎯 Actualizar Trivia
            </button>
            
            <button class="menu-item" onclick="loadPage('racha_ranking.html', 'Ranking de Racha Diaria')">
                🏆 Ranking de Racha Diaria
            </button>
            
            <button class="menu-item" onclick="loadPage('admin_eventos.html', 'Administración de Eventos')">
                📅 Administración de Eventos
            </button>
            
            <button class="menu-item logout-btn" onclick="logout()">
                🚪 Cerrar Sesión
            </button>
        </div>

        <!-- Área de Contenido -->
        <div class="content-area">
            <!-- Header móvil con menú hamburguesa -->
            <div class="mobile-header">
                <button class="hamburger-btn" onclick="toggleMobileMenu()">
                    ☰
                </button>
                <div class="mobile-title" id="mobileTitle">Panel de Administración</div>
                <div></div> <!-- Espaciador -->
            </div>
            
            <div class="content-header" id="contentHeader">
                Bienvenido al Panel de Administración
            </div>
            <iframe class="content-frame" id="contentFrame" src="about:blank"></iframe>
        </div>
    </div>

    <script>
        // Manejar el submit del formulario de login llamando al PHP
        document.getElementById('loginForm').addEventListener('submit', async function(e) {
            e.preventDefault();
            
            const username = document.getElementById('username').value;
            const password = document.getElementById('password').value;

            try {
                const response = await fetch('admin_login.php', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ username, password })
                });

                const data = await response.json();

                if (response.ok && data.success) {
                    // Login exitoso
                    document.getElementById('loginContainer').style.display = 'none';
                    document.getElementById('adminLayout').classList.add('show');
                    
                    // Guardar sesión en localStorage solo como comodidad de UI
                    localStorage.setItem('adminLoggedIn', 'true');
                    localStorage.setItem('adminLoginTime', new Date().getTime());
                    
                    // Cargar página por defecto
                    loadPage('usuarios_fixed_final.html', 'Usuarios Registrados de la APP');
                } else {
                    throw new Error(data.message || 'Credenciales inválidas');
                }
            } catch (err) {
                console.error('Error en login:', err);
                document.getElementById('errorMessage').style.display = 'block';
                setTimeout(() => {
                    document.getElementById('errorMessage').style.display = 'none';
                }, 3000);
            }
        });

        function logout() {
            // Limpiar sesión del lado del cliente
            localStorage.removeItem('adminLoggedIn');
            localStorage.removeItem('adminLoginTime');
            document.getElementById('adminLayout').classList.remove('show');
            document.getElementById('loginContainer').style.display = 'block';
            document.getElementById('loginForm').reset();
            
            // Limpiar iframe
            document.getElementById('contentFrame').src = 'about:blank';
            document.getElementById('contentHeader').textContent = 'Bienvenido al Panel de Administración';
            document.getElementById('mobileTitle').textContent = 'Panel de Administración';
            
            // Cerrar menú móvil si está abierto
            closeMobileMenu();
        }

        function loadPage(url, title) {
            // Actualizar el título del header
            document.getElementById('contentHeader').textContent = title;
            document.getElementById('mobileTitle').textContent = title;
            
            // Cargar la página en el iframe
            document.getElementById('contentFrame').src = url;
            
            // Actualizar el estado activo del menú
            const menuItems = document.querySelectorAll('.menu-item');
            menuItems.forEach(item => {
                item.classList.remove('active');
                if (item.onclick.toString().includes(url)) {
                    item.classList.add('active');
                }
            });
            
            // Cerrar menú móvil si está abierto
            if (window.innerWidth <= 768) {
                closeMobileMenu();
            }
        }

        function toggleMobileMenu() {
            const sidebar = document.getElementById('sidebar');
            const overlay = document.getElementById('mobileOverlay');
            
            if (sidebar.classList.contains('mobile-show')) {
                closeMobileMenu();
            } else {
                openMobileMenu();
            }
        }

        function openMobileMenu() {
            const sidebar = document.getElementById('sidebar');
            const overlay = document.getElementById('mobileOverlay');
            
            sidebar.classList.add('mobile-show');
            overlay.classList.add('show');
            document.body.style.overflow = 'hidden';
        }

        function closeMobileMenu() {
            const sidebar = document.getElementById('sidebar');
            const overlay = document.getElementById('mobileOverlay');
            
            sidebar.classList.remove('mobile-show');
            overlay.classList.remove('show');
            document.body.style.overflow = 'auto';
        }

        // Detectar cambios de tamaño de ventana
        window.addEventListener('resize', function() {
            if (window.innerWidth > 768) {
                closeMobileMenu();
            }
        });

        // Verificar si ya está logueado al cargar la página (cliente)
        window.addEventListener('load', function() {
            const isLoggedIn = localStorage.getItem('adminLoggedIn');
            const loginTime = localStorage.getItem('adminLoginTime');
            
            // Verificar si la sesión no ha expirado (24 horas)
            if (isLoggedIn && loginTime) {
                const currentTime = new Date().getTime();
                const sessionDuration = 24 * 60 * 60 * 1000; // 24 horas en milisegundos
                
                if (currentTime - parseInt(loginTime) < sessionDuration) {
                    document.getElementById('loginContainer').style.display = 'none';
                    document.getElementById('adminLayout').classList.add('show');
                    
                    // Cargar página por defecto
                    loadPage('usuarios_fixed_final.html', 'Usuarios Registrados de la APP');
                } else {
                    // Sesión expirada
                    localStorage.removeItem('adminLoggedIn');
                    localStorage.removeItem('adminLoginTime');
                }
            }
        });

        // Cerrar sesión automáticamente después de 24 horas (solo cliente)
        setInterval(function() {
            const loginTime = localStorage.getItem('adminLoginTime');
            if (loginTime) {
                const currentTime = new Date().getTime();
                const sessionDuration = 24 * 60 * 60 * 1000;
                
                if (currentTime - parseInt(loginTime) >= sessionDuration) {
                    logout();
                }
            }
        }, 60000); // Verificar cada minuto
    </script>
</body>
</html>

