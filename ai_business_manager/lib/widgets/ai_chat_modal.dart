import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../services/ai_service.dart';
import '../providers/stats_provider.dart';
import '../providers/data_providers.dart';

class AIChatModal extends HookConsumerWidget {
  const AIChatModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiService = ref.read(aiServiceProvider);

    // We watch statsProvider to provide context to the AI
    final dashboardStats = ref.watch(dashboardStatsProvider);
    final soldAsync = ref.watch(soldProvider);
    final stockAsync = ref.watch(stockProvider);

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

      // Add user message to UI
      messages.value = [
        ...messages.value,
        {'role': 'user', 'text': text},
      ];
      textController.clear();
      isLoading.value = true;
      scrollToBottom();

      // Gather context
      final soldCount = soldAsync.value?.length ?? 0;
      final stockItems = stockAsync.value ?? [];
      final availableStock = stockItems
          .where((s) => s.status.toLowerCase() == 'available')
          .length;
      final blockedStock = stockItems
          .where((s) => s.status.toLowerCase() == 'blocked')
          .length;

      final enqRatio = dashboardStats.totalEnquiries > 0
          ? (dashboardStats.totalBookings / dashboardStats.totalEnquiries) * 100
          : 0.0;

      final retRatio = dashboardStats.totalBookings > 0
          ? (soldCount / dashboardStats.totalBookings) * 100
          : 0.0;

      String contextData =
          '''
Active Branch KPIs:
- Total Enquiries: ${dashboardStats.totalEnquiries}
- Total Bookings: ${dashboardStats.totalBookings}
- Total Sold: $soldCount
- Available Stock: $availableStock
- Blocked Stock: $blockedStock
- Enquiry to Booking Ratio: ${enqRatio.toStringAsFixed(1)}%
- Booking to Retail Ratio: ${retRatio.toStringAsFixed(1)}%
''';

      // Send to AI Service
      final responseText = await aiService.askQuestion(
        text,
        contextData: contextData,
      );

      // Add AI response to UI
      messages.value = [
        ...messages.value,
        {'role': 'ai', 'text': responseText},
      ];
      isLoading.value = false;
      scrollToBottom();
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
