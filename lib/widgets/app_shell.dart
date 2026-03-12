import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 900;
        final outerPadding = isMobile ? 12.0 : 24.0;
        final contentPadding = isMobile ? 16.0 : 24.0;

        return Scaffold(
          drawer: isMobile
              ? Drawer(
                  child: SafeArea(
                    child: _Sidebar(isDrawer: true),
                  ),
                )
              : null,
          body: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(1.0, -1.0),
                radius: 1.4,
                colors: [
                  Color(0xFFF5F3FF),
                  Color(0xFFF8FBFF),
                  Color(0xFFF6F7FB),
                ],
                stops: [0.0, 0.35, 1.0],
              ),
            ),
            child: isMobile
                ? SafeArea(
                    child: Padding(
                      padding: EdgeInsets.all(outerPadding),
                      child: Column(
                        children: [
                          const _TopBar(showMenuButton: true),
                          const SizedBox(height: 12),
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(contentPadding),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFDFDFE).withOpacity(0.95),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFEEF1FF)),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color.fromRGBO(37, 52, 95, 0.12),
                                    blurRadius: 32,
                                    offset: Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: child,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Row(
                    children: [
                      const _Sidebar(),
                      Expanded(
                        child: SafeArea(
                          child: Padding(
                            padding: EdgeInsets.all(outerPadding),
                            child: Column(
                              children: [
                                const _TopBar(),
                                const SizedBox(height: 16),
                                Expanded(
                                  child: Container(
                                    padding: EdgeInsets.all(contentPadding),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFDFDFE).withOpacity(0.95),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: const Color(0xFFEEF1FF)),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color.fromRGBO(37, 52, 95, 0.12),
                                          blurRadius: 32,
                                          offset: Offset(0, 12),
                                        ),
                                      ],
                                    ),
                                    child: child,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({this.showMenuButton = false});

  final bool showMenuButton;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = Supabase.instance.client.auth.currentUser;
    final isCompact = MediaQuery.sizeOf(context).width < 700;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showMenuButton) ...[
                IconButton(
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  icon: const Icon(Icons.menu_rounded),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Reseller Command Center', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 2),
                    Text(
                      'Track stock, purchases, and sales in one place.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: isCompact ? WrapAlignment.start : WrapAlignment.end,
            children: [
              if (user != null && user.email != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person, size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: isCompact ? 190 : 260),
                        child: Text(
                          user.email!,
                          style: theme.textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
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
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({this.isDrawer = false});

  final bool isDrawer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: isDrawer ? double.infinity : 260,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1F1B45),
            Color(0xFF252F5F),
            Color(0xFF1F2937),
          ],
          stops: [0.0, 0.6, 1.0],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Inventory Workspace',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              shrinkWrap: true,
              children: const [
                _NavItem(label: 'Dashboard', route: '/', icon: Icons.home_outlined),
                _NavItem(label: 'Items', route: '/items', icon: Icons.inventory_2_outlined),
                _NavItem(label: 'Purchase History', route: '/purchase-history', icon: Icons.history),
                _NavItem(label: 'Stock', route: '/stock', icon: Icons.storage_outlined),
                _NavItem(label: 'Sales', route: '/sales', icon: Icons.shopping_cart_outlined),
              ],
            ),
          ),
          Text(
            'Inventory, stock, purchases, and sales in one workspace.',
            style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFFE5E7EB)),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.label, required this.route, required this.icon});

  final String label;
  final String route;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = GoRouterState.of(context).uri.toString() == route;
    final color = isActive ? Colors.white : const Color(0xFFE5E7EB);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: isActive ? Colors.white.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => context.go(route),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                        color: color,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
