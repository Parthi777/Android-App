import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_business_manager/providers/ai_settings_provider.dart';
import 'package:ai_business_manager/providers/branch_provider.dart';
import 'package:ai_business_manager/services/google_sheet_service.dart';
import 'package:ai_business_manager/models/sheet_data_models.dart';
import 'package:ai_business_manager/models/branch.dart';
import 'package:ai_business_manager/services/chat_history_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

class AIService {
  final Ref _ref;
  GenerativeModel? _model;
  String _lastUsedKey = '';
  String _lastUsedModel = '';

  AIService(this._ref);

  void _initModelIfNeeded() {
    final apiKey = _ref.read(aiSettingsProvider);
    const modelName = 'gemini-3-flash-preview';

    debugPrint(
      "AI Service: Initializing model. Key present: ${apiKey != null && apiKey.isNotEmpty}",
    );

    if (apiKey != null && apiKey.isNotEmpty) {
      if (apiKey != _lastUsedKey || modelName != _lastUsedModel) {
        debugPrint(
          "AI Service: Creating new GenerativeModel ($modelName) with key starting with: ${apiKey.substring(0, 5)}...",
        );
        _model = GenerativeModel(model: modelName, apiKey: apiKey);
        _lastUsedKey = apiKey;
        _lastUsedModel = modelName;
      }
    }
  }

  Future<String> buildBusinessContext({Branch? activeBranch}) async {
    debugPrint(
      "AI Service: Starting buildBusinessContext for branch: ${activeBranch?.name ?? 'All'}",
    );
    final branches = activeBranch != null
        ? [activeBranch]
        : _ref.read(branchesListProvider);
    if (branches.isEmpty) {
      debugPrint("AI Service: No branches configured.");
      return "No branches configured.";
    }

    final sheetService = _ref.read(googleSheetServiceProvider);
    final context = StringBuffer();
    context.writeln(
      "Dealership Network Data (Aggregated across ${branches.length} branches):",
    );

    for (var branch in branches) {
      context.writeln("\n--- Branch: ${branch.name} ---");

      try {
        // Fetch data for this branch
        final enquiryName = await sheetService.getSheetNameFromGid(
          branch.googleSheetId,
          branch.enquirySheetGid,
        );
        final bookingName = await sheetService.getSheetNameFromGid(
          branch.googleSheetId,
          branch.bookingSheetGid,
        );
        final soldName = await sheetService.getSheetNameFromGid(
          branch.googleSheetId,
          branch.soldSheetGid,
        );
        final stockName = await sheetService.getSheetNameFromGid(
          branch.googleSheetId,
          branch.stockSheetGid,
        );

        if (enquiryName != null) {
          final enquiries = await sheetService.fetchModelRows(
            branch.googleSheetId,
            enquiryName,
            (r) => Enquiry.fromRow(r),
          );
          context.writeln("Enquiries (${enquiries.length}):");
          for (var e in enquiries.take(20)) {
            // Limit to recent to save tokens/context
            context.writeln(
              "- ${DateFormat('yyyy-MM-dd').format(e.date)}: ${e.customerName} interested in ${e.modelInterested} (${e.status})",
            );
          }
        }

        if (bookingName != null) {
          final bookings = await sheetService.fetchModelRows(
            branch.googleSheetId,
            bookingName,
            (r) => Booking.fromRow(r),
          );
          context.writeln("Bookings (${bookings.length}):");
          for (var b in bookings.take(20)) {
            context.writeln(
              "- ${DateFormat('yyyy-MM-dd').format(b.bookingDate)}: ${b.customerName}, ${b.vehicleModel}, Amount: ${b.bookingAmount}",
            );
          }
        }

        if (soldName != null) {
          final sales = await sheetService.fetchModelRows(
            branch.googleSheetId,
            soldName,
            (r) => Sold.fromRow(r),
          );
          context.writeln("Sales (${sales.length}):");
          for (var s in sales.take(20)) {
            context.writeln(
              "- ${DateFormat('yyyy-MM-dd').format(s.saleDate)}: ${s.customerName} bought ${s.vehicleModel} for ${s.vehicleCost}",
            );
          }
        }

        if (stockName != null) {
          final stock = await sheetService.fetchModelRows(
            branch.googleSheetId,
            stockName,
            (r) => Stock.fromRow(r),
          );
          context.writeln("Current Stock (${stock.length} units total):");
          // Group stock by model for brevity
          final Map<String, int> modelCounts = {};
          for (var s in stock) {
            modelCounts[s.vehicleModel] =
                (modelCounts[s.vehicleModel] ?? 0) + 1;
          }
          modelCounts.forEach(
            (model, count) => context.writeln("- $model: $count units"),
          );
        }
      } catch (e) {
        context.writeln("Error fetching data for this branch: $e");
      }
    }

    return context.toString();
  }

  Future<String> askQuestion(
    String prompt, {
    String? contextData,
    Branch? activeBranch,
    String? userId,
  }) async {
    try {
      _initModelIfNeeded();

      if (_model == null) {
        return "Please configure a valid Gemini API key in Settings to enable the AI Business Assistant.";
      }

      final historyService = _ref.read(chatHistoryServiceProvider);
      final recentMessages = await historyService.getRecentHistory(limit: 50);

      final fullPrompt = StringBuffer();
      fullPrompt.writeln(
        "You are 'Dhaara' 🌟, a friendly and extremely concise RAG AI Assistant for this automotive business.",
      );
      fullPrompt.writeln(
        "REPLY RULES:\n1. SHORT & SIMPLE: Give only the necessary data. No long explanations.\n2. NO BOLDING: Use plain text only, NO markdown bolding like **text**.\n3. EXACT DATA: Provide only exact figures and names from the CONTEXT DATA below.\n4. SCOPE: Focus exclusively on the records of the selected branch provided in the context.\n5. LIMITS: Always stay mindful of token and rate limits. Keep responses compact. 📏\n6. GROUNDING: If data is missing, say: 'No records found for this query in the branch data.'",
      );

      if (recentMessages.isNotEmpty) {
        fullPrompt.writeln("\nRECENT CONVERSATION HISTORY (Last 50 turns):");
        for (var msg in recentMessages) {
          fullPrompt.writeln("User: ${msg.query}");
          fullPrompt.writeln("Dhaara: ${msg.response}");
        }
        fullPrompt.writeln("--- END HISTORY ---\n");
      }

      fullPrompt.writeln(
        "\nReference Date: ${DateFormat('yyyy-MM-dd').format(DateTime.now().toLocal())} 📅",
      );

      if (contextData != null && contextData.isNotEmpty) {
        fullPrompt.writeln("\nBRANCH CONTEXT DATA:");
        fullPrompt.writeln(contextData);
        fullPrompt.writeln("--- END DATA ---\n");
      }

      fullPrompt.writeln("User Query: $prompt");

      debugPrint(
        "AI Service: Sending prompt to Gemini. History turns: ${recentMessages.length}. Context length: ${contextData?.length ?? 0}",
      );
      final content = [Content.text(fullPrompt.toString())];
      final response = await _model!.generateContent(content);

      final responseText =
          response.text ??
          "I encountered an issue processing the data. Please try again.";

      // Save to Supabase for long-term memory
      await historyService.saveMessage(
        query: prompt,
        response: responseText,
        branchId: activeBranch?.id,
        userId: userId,
      );

      debugPrint("AI Service: Received response and saved to memory.");
      return responseText;
    } catch (e) {
      debugPrint("AI Service ERROR: $e");
      if (e.toString().contains('API_KEY_INVALID')) {
        return "The provided API key is invalid. Please check your settings.";
      }
      return "Assistant Error: $e";
    }
  }
}

final aiServiceProvider = Provider<AIService>((ref) {
  return AIService(ref);
});
