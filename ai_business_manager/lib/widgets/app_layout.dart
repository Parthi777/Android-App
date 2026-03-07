import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../providers/branch_provider.dart';
import 'ai_chat_modal.dart';

class AppLayout extends ConsumerWidget {
  final Widget child;

  const AppLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isWideScreen = MediaQuery.of(context).size.width >= 800;
    final activeBranch = ref.watch(branchProvider);

    return Scaffold(
      appBar: isWideScreen
          ? null
          : AppBar(
              toolbarHeight: 90,
              centerTitle: true,
              leading: Builder(
                builder: (BuildContext context) {
                  return IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).openAppDrawerTooltip,
                  );
                },
              ),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Dhaara',
                    style: GoogleFonts.pacifico(
                      fontSize: 28,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  if (activeBranch != null)
                    Text(
                      activeBranch.name,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
              actions: [const SizedBox(width: 8)],
            ),
      drawer: isWideScreen ? null : const AppDrawer(),
      body: Row(
        children: [
          if (isWideScreen) const AppNavRail(),
          Expanded(child: child),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showAIChatModal(context);
        },
        child: const Icon(Icons.smart_toy),
      ),
    );
  }
}

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeBranch = ref.watch(branchProvider);
    final branches = ref.watch(branchesListProvider);
    final branchNotifier = ref.read(branchProvider.notifier);

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 8.0,
                top: 24.0,
                bottom: 8.0,
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dhaara',
                        style: GoogleFonts.pacifico(
                          fontSize: 28,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      if (activeBranch != null)
                        Text(
                          activeBranch.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    color: Colors.grey,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Branch dropdown – only when more than one branch is configured
            if (branches.length > 1)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.2),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 4.0,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: activeBranch?.id,
                      icon: Icon(
                        Icons.swap_horiz_rounded,
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      ),
                      hint: const Text('Select Branch'),
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      items: branches.map((b) {
                        return DropdownMenuItem<String>(
                          value: b.id,
                          child: Row(
                            children: [
                              Icon(
                                Icons.store_rounded,
                                size: 16,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  b.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (selectedId) {
                        final selected = branches.firstWhere(
                          (b) => b.id == selectedId,
                        );
                        branchNotifier.setActiveBranch(selected);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Switched to ${selected.name}'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 8),

            // Menu Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _MenuItem(
                    icon: Icons.dashboard,
                    title: 'Dashboard',
                    route: '/dashboard',
                    isSelected:
                        ModalRoute.of(context)?.settings.name == '/dashboard',
                  ),
                  ExpansionTile(
                    leading: Icon(Icons.point_of_sale, color: Colors.grey[600]),
                    title: Text(
                      'Sales',
                      style: TextStyle(color: Colors.grey[800]),
                    ),
                    iconColor: Theme.of(context).primaryColor,
                    childrenPadding: const EdgeInsets.only(left: 16.0),
                    children: [
                      _MenuItem(
                        icon: Icons.question_answer_outlined,
                        title: 'Enquiry',
                        route: '/sales/enquiry',
                      ),
                      _MenuItem(
                        icon: Icons.book_online_outlined,
                        title: 'Bookings',
                        route: '/sales/bookings',
                      ),
                      _MenuItem(
                        icon: Icons.sell_outlined,
                        title: 'Sold',
                        route: '/sales/sold',
                      ),
                    ],
                  ),
                  _MenuItem(
                    icon: Icons.inventory,
                    title: 'Stock',
                    route: '/stock',
                  ),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 8),
                  _MenuItem(
                    icon: Icons.settings,
                    title: 'Settings',
                    route: '/settings',
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text(
                      'Log out',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 0,
                    ),
                    onTap: () async {
                      await ref.read(authServiceProvider).signOut();
                      if (context.mounted) context.go('/auth');
                    },
                  ),
                ],
              ),
            ),
            // Profile Footer
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.grey[200],
                    child: const Icon(Icons.person, color: Colors.grey),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'User Admin',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'admin@dhaara.com',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String route;
  final bool isSelected;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.route,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Theme.of(context).primaryColor : Colors.grey[600],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey[800],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      onTap: () {
        Navigator.pop(context); // Close Drawer
        context.go(route);
      },
      shape: isSelected
          ? const RoundedRectangleBorder(
              borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
              side: BorderSide(color: Colors.transparent),
            )
          : null,
      tileColor: isSelected
          ? Theme.of(context).primaryColor.withOpacity(0.05)
          : null,
    );
  }
}

class AppNavRail extends StatelessWidget {
  const AppNavRail({super.key});

  @override
  Widget build(BuildContext context) {
    // Current route to highlight correct rail destination
    final location = GoRouterState.of(context).uri.path;
    int selectedIndex = 0;
    if (location.startsWith('/sales')) selectedIndex = 1;
    if (location.startsWith('/stock')) selectedIndex = 2;
    if (location.startsWith('/settings')) selectedIndex = 3;

    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: (idx) {
        switch (idx) {
          case 0:
            context.go('/dashboard');
            break;
          case 1:
            // For the rail, clicking Sales might default to enquiry
            context.go('/sales/enquiry');
            break;
          case 2:
            context.go('/stock');
            break;
          case 3:
            context.go('/settings');
            break;
        }
      },
      labelType: NavigationRailLabelType.all,
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.dashboard),
          label: Text('Dashboard'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.point_of_sale),
          label: Text('Sales'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.inventory),
          label: Text('Stock'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings),
          label: Text('Settings'),
        ),
      ],
    );
  }
}
