import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const _Sidebar(),
          Expanded(
            child: Container(
              color: const Color(0xFFF7F7FA),
              child: Column(
                children: [
                  const _TopBar(),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: child,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            'Vinted Inventory Assistant',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Spacer(),
          if (user != null)
            Text(
              user.email ?? '',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          const SizedBox(width: 16),
          OutlinedButton.icon(
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.symmetric(vertical: 24),
      color: const Color(0xFF0F172A),
      child: Column(
        children: [
          const Text(
            'Vinted\nInventory Assistant',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 18,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          _NavItem(label: 'Dashboard', route: '/'),
          _NavItem(label: 'Items', route: '/items'),
          _NavItem(label: 'Purchase History', route: '/purchases'),
          _NavItem(label: 'Stock', route: '/stock'),
          _NavItem(label: 'Sales', route: '/sales'),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Inventory management for Vinted sellers.',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.label, required this.route});

  final String label;
  final String route;

  @override
  Widget build(BuildContext context) {
    final isActive = GoRouterState.of(context).uri.toString() == route;
    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          color: isActive ? Colors.white : const Color(0xFFCBD5F5),
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      onTap: () => context.go(route),
    );
  }
}
