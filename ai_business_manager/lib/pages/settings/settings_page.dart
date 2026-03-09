import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/branch_provider.dart';
import '../../models/branch.dart';
import '../../providers/ai_settings_provider.dart';
import '../../services/ai_service.dart';
import '../../services/auth_service.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class SettingsPage extends HookConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branch = ref.watch(branchProvider);
    final branchNotifier = ref.read(branchProvider.notifier);
    final branches = ref.watch(branchesListProvider);
    final apiKey = ref.watch(aiSettingsProvider);
    final apiKeyController = useTextEditingController(text: apiKey ?? '');

    // Update controller if provider changes (e.g. on build)
    useEffect(() {
      if (apiKey != null && apiKeyController.text != apiKey) {
        apiKeyController.text = apiKey;
      }
      return null;
    }, [apiKey]);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
          tooltip: 'Back to Dashboard',
        ),
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
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
                        if (branch?.id == b.id) {
                          branchNotifier.clearActiveBranch();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Branch deselected')),
                          );
                        } else {
                          branchNotifier.setActiveBranch(b);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Switched to ${b.name} Branch'),
                            ),
                          );
                        }
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
          const SizedBox(height: 24),
          const SizedBox(height: 24),
          // AI Assistant Settings (Master User Only)
          if (ref.watch(authServiceProvider).currentUser?.email ==
              'parthimech1993@gmail.com') ...[
            const Text(
              'AI Assistant Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Gemini API Key',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enter your Google AI Studio API key to enable the Accurate RAG Assistant.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: apiKeyController,
                      decoration: InputDecoration(
                        labelText: 'API Key',
                        hintText: 'AIzaSy...',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.save),
                          onPressed: () async {
                            await ref
                                .read(aiSettingsProvider.notifier)
                                .setApiKey(apiKeyController.text.trim());
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'AI API Key saved successfully',
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 8),
                    if (apiKey != null && apiKey.isNotEmpty) ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final aiService = ref.read(aiServiceProvider);
                                final response = await aiService.askQuestion(
                                  "Hello, are you working correctly? Answer with 'Yes, connection verified.' and nothing else.",
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(response)),
                                  );
                                }
                              },
                              icon: const Icon(Icons.bolt, size: 16),
                              label: const Text('Test AI Connection'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () async {
                          await ref
                              .read(aiSettingsProvider.notifier)
                              .clearApiKey();
                          apiKeyController.clear();
                        },
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text('Clear Saved Key'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
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
