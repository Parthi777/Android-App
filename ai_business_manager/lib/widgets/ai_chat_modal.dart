import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../services/ai_service.dart';
import '../services/auth_service.dart';
import '../providers/branch_provider.dart';

class AIChatModal extends HookConsumerWidget {
  const AIChatModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // AI Service handle
    final aiService = ref.read(aiServiceProvider);

    final messages = useState<List<Map<String, String>>>([
      {
        'role': 'ai',
        'text':
            'Hello! I can help you analyze your business data. What would you like to know?',
      },
    ]);
    final isLoading = useState(false);
    final textController = useTextEditingController();
    final scrollController = useScrollController();

    void scrollToBottom() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }

    Future<void> sendMessage() async {
      final text = textController.text.trim();
      if (text.isEmpty) return;

      debugPrint("AIChatModal: sendMessage triggered with text: $text");

      // Add user message to UI
      messages.value = [
        ...messages.value,
        {'role': 'user', 'text': text},
      ];
      textController.clear();
      isLoading.value = true;
      scrollToBottom();

      try {
        debugPrint("AIChatModal: Aggregating context for active branch...");
        final activeBranch = ref.read(branchProvider);

        // Fetch data only for the selected branch as requested
        final contextData = await aiService.buildBusinessContext(
          activeBranch: activeBranch,
        );
        debugPrint("AIChatModal: Context built. Length: ${contextData.length}");

        // Step 2: Send to AI Service with branch-specific context and memory
        final userId = ref.read(authServiceProvider).currentUser?.uid;
        final responseText = await aiService.askQuestion(
          text,
          contextData: contextData,
          activeBranch: activeBranch,
          userId: userId,
        );
        debugPrint("AIChatModal: AI Response received.");

        // Add AI response to UI
        messages.value = [
          ...messages.value,
          {'role': 'ai', 'text': responseText},
        ];
      } catch (e) {
        messages.value = [
          ...messages.value,
          {
            'role': 'ai',
            'text':
                "I'm sorry, I encountered an error while processing your request: $e",
          },
        ];
      } finally {
        isLoading.value = false;
        scrollToBottom();
      }
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  'AI Business Assistant',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Chat Messages
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.value.length,
              itemBuilder: (context, index) {
                final msg = messages.value[index];
                final isUser = msg['role'] == 'user';

                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(16).copyWith(
                        bottomRight: Radius.circular(isUser ? 0 : 16),
                        bottomLeft: Radius.circular(isUser ? 16 : 0),
                      ),
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    child: Text(
                      msg['text'] ?? '',
                      style: TextStyle(
                        color: isUser
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(
                                context,
                              ).colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Loading Indicator
          if (isLoading.value)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: CircularProgressIndicator(),
            ),

          // Input Area
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: textController,
                    decoration: InputDecoration(
                      hintText: 'Ask about your business...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  mini: true,
                  onPressed: isLoading.value ? null : sendMessage,
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void showAIChatModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const AIChatModal(),
  );
}
