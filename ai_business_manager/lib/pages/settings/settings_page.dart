import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/theme_provider.dart';
import '../../providers/branch_provider.dart';
import '../../models/branch.dart';

class SettingsPage extends HookConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);
    final branch = ref.watch(branchProvider);
    final branchNotifier = ref.read(branchProvider.notifier);

    // Using a future provider state checking workaround to get the list of branches if available.
    // In a full implementation, we would have a branchesListProvider.

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Theme Settings
          const Text(
            'Appearance',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.system,
                      label: Text('System'),
                      icon: Icon(Icons.brightness_auto),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.light,
                      label: Text('Light'),
                      icon: Icon(Icons.light_mode),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.dark,
                      label: Text('Dark'),
                      icon: Icon(Icons.nightlight_round),
                    ),
                  ],
                  selected: <ThemeMode>{themeMode},
                  onSelectionChanged: (Set<ThemeMode> newSelection) {
                    themeNotifier.setThemeMode(newSelection.first);
                  },
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Branch Management
          const Text(
            'Branch Management',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Active Branch: ${branch?.name ?? "None Selected"}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text('Available Branches:'),
                  // TODO: Real implementation of fetching all configured branches.
                  // For now, we simulate branch change.
                  ListTile(
                    title: const Text('Dharani TVS - Main'),
                    subtitle: const Text('ID: 1abc...'),
                    trailing: branch?.id == '1'
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                    onTap: () {
                      final newBranch = Branch(
                        id: '1',
                        name: 'Dharani TVS - Main',
                        googleSheetId: 'dummy_sheet_id',
                        enquirySheetGid: '0',
                        bookingSheetGid: '1',
                        soldSheetGid: '2',
                        stockSheetGid: '3',
                      );
                      branchNotifier.setActiveBranch(newBranch);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Switched to Main Branch'),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        // TODO: Implement Add Branch functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Add Branch Coming Soon'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add New Branch Configuration'),
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
