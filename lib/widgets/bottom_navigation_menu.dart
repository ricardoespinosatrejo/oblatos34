import 'package:flutter/material.dart';

class BottomNavigationMenu extends StatelessWidget {
  final VoidCallback? onCenterTap;
  
  const BottomNavigationMenu({Key? key, this.onCenterTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 98,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/menu/menu-barra.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(context, 'm-icono1.png', 'Caja\nOblatos', '/caja'),
          _buildNavItem(context, 'm-icono2.png', 'Agentes\nCambio', '/agentes-cambio'),
          _buildCenterNavItem('m-icono3.png'),
          _buildNavItem(context, 'm-icono4.png', 'Eventos', '/eventos'),
          _buildNavItem(context, 'm-icono5.png', 'Video\nBlog', '/video-blog'),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, String iconPath, String label, String? route, {bool isCenter = false}) {
    return GestureDetector(
      onTap: route != null ? () => Navigator.pushNamed(context, route) : null,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: isCenter ? 68 : 25,
            height: isCenter ? 68 : 25,
            decoration: isCenter ? BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Color(0xFFFF1744),
                  Color(0xFFE91E63),
                ],
              ),
              border: Border.all(color: Colors.black, width: 1),
            ) : null,
            child: isCenter ? Center(
              child: Image.asset(
                'assets/images/menu/$iconPath',
                width: 24,
                height: 24,
                color: Colors.white,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.home, color: Colors.white, size: 24);
                },
              ),
            ) : Image.asset(
              'assets/images/menu/$iconPath',
              width: 8,
              height: 8,
              color: Colors.white,
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.home, color: Colors.white, size: 24);
              },
            ),
          ),
          if (!isCenter && label.isNotEmpty) ...[
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Gotham Rounded',
                fontSize: 10,
                fontWeight: FontWeight.w400,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCenterNavItem(String iconPath) {
    return Transform.translate(
      offset: Offset(-6, -14),
      child: GestureDetector(
        onTap: onCenterTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0xFFFF1744),
                    Color(0xFFE91E63),
                  ],
                ),
                border: Border.all(color: Colors.black, width: 1),
              ),
              child: Center(
                child: Image.asset(
                  'assets/images/menu/$iconPath',
                  width: 24,
                  height: 24,
                  color: Colors.white,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.home, color: Colors.white, size: 24);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
