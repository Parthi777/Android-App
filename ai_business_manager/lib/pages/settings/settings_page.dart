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

    final branches = ref.watch(branchesListProvider);

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
                  ...branches.map(
                    (b) => ListTile(
                      title: Text(b.name),
                      subtitle: Text(
                        'ID: ${b.googleSheetId.length > 8 ? '${b.googleSheetId.substring(0, 8)}...' : b.googleSheetId}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (branch?.id == b.id)
                            const Icon(Icons.check_circle, color: Colors.green),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              ref
                                  .read(branchesListProvider.notifier)
                                  .removeBranch(b.id);
                            },
                          ),
                        ],
                      ),
                      onTap: () {
                        branchNotifier.setActiveBranch(b);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Switched to ${b.name} Branch'),
                          ),
                        );
                      },
                    ),
                  ),
                  if (branches.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Text('No branches configured. Add one below.'),
                    ),
                  const Divider(),
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (context) => const _AddBranchDialog(),
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

class _AddBranchDialog extends ConsumerStatefulWidget {
  const _AddBranchDialog();
  @override
  ConsumerState<_AddBranchDialog> createState() => _AddBranchDialogState();
}

class _AddBranchDialogState extends ConsumerState<_AddBranchDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _sheetIdController = TextEditingController();
  final _enquiryGidController = TextEditingController();
  final _bookingGidController = TextEditingController();
  final _soldGidController = TextEditingController();
  final _stockGidController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _sheetIdController.dispose();
    _enquiryGidController.dispose();
    _bookingGidController.dispose();
    _soldGidController.dispose();
    _stockGidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 32,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add New Branch',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Branch Name'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _sheetIdController,
                decoration: const InputDecoration(
                  labelText: 'Master Google Sheet ID',
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _enquiryGidController,
                decoration: const InputDecoration(
                  labelText: 'Enquiry Sheet Tab GID',
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _bookingGidController,
                decoration: const InputDecoration(
                  labelText: 'Bookings Sheet Tab GID',
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _soldGidController,
                decoration: const InputDecoration(
                  labelText: 'Sold Sheet Tab GID',
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _stockGidController,
                decoration: const InputDecoration(
                  labelText: 'Stock Sheet Tab GID',
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final newBranch = Branch(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          name: _nameController.text,
                          googleSheetId: _sheetIdController.text,
                          enquirySheetGid: _enquiryGidController.text,
                          bookingSheetGid: _bookingGidController.text,
                          soldSheetGid: _soldGidController.text,
                          stockSheetGid: _stockGidController.text,
                        );
                        ref
                            .read(branchesListProvider.notifier)
                            .addBranch(newBranch);
                        Navigator.of(context).pop();
                      }
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
