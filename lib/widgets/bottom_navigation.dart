import 'package:flutter/material.dart';

class BottomNavigation extends StatelessWidget {
  final String currentRoute;

  const BottomNavigation({
    Key? key,
    required this.currentRoute,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFE91E63),
            Color(0xFF9C27B0),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(
            context,
            icon: Icons.home,
            label: 'Inicio',
            route: '/home',
            isActive: currentRoute == '/home',
          ),
          _buildNavItem(
            context,
            icon: Icons.account_balance,
            label: 'Caja',
            route: '/caja',
            isActive: currentRoute == '/caja',
          ),
          _buildNavItem(
            context,
            icon: Icons.people,
            label: 'Cooperación',
            route: '/poder-cooperacion',
            isActive: currentRoute == '/poder-cooperacion',
          ),
          _buildNavItem(
            context,
            icon: Icons.school,
            label: 'Aprender',
            route: '/aprendiendo-cooperativa',
            isActive: currentRoute == '/aprendiendo-cooperativa',
          ),
          _buildNavItem(
            context,
            icon: Icons.change_circle,
            label: 'Cambio',
            route: '/agentes-cambio',
            isActive: currentRoute == '/agentes-cambio',
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: () {
        if (route != currentRoute) {
          Navigator.pushReplacementNamed(context, route);
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isActive ? Colors.white : Colors.white70,
            size: 24,
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white70,
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

