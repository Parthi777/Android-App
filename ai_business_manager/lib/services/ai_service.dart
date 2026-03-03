import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AIService {
  // In a real application, DO NOT hardcode this or ship it in the app bundle.
  // It should be fetched from a secure remote config or backend.
  // For this prototype, we'll establish the structure.
  static const String _apiKey = 'AIzaSyDXMf2uF_M5L9zLI5tiw_BwH6uE9aoUR-0';
  late final GenerativeModel _model;

  AIService() {
    _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey);
  }

  Future<String> askQuestion(String prompt, {String? contextData}) async {
    try {
      if (_apiKey == 'YOUR_GEMINI_API_KEY') {
        // Return mock response if API key is not configured
        await Future.delayed(const Duration(seconds: 1));
        return "I am your AI Business Assistant. Please configure a valid Gemini API key in `ai_service.dart` to enable real insights based on your Google Sheets data.";
      }

      final fullPrompt = StringBuffer();
      fullPrompt.writeln(
        "You are a helpful AI Business Assistant for a dealership. Answer the user's question based strictly on the provided context data. If the answer is not in the data, say you don't know.",
      );

      if (contextData != null && contextData.isNotEmpty) {
        fullPrompt.writeln("\n--- CONTEXT DATA ---");
        fullPrompt.writeln(contextData);
        fullPrompt.writeln("--------------------\n");
      }

      fullPrompt.writeln("User Question: $prompt");

      final content = [Content.text(fullPrompt.toString())];
      final response = await _model.generateContent(content);

      return response.text ?? "Sorry, I could not generate a response.";
    } catch (e) {
      return "Error: $e";
    }
  }
}

final aiServiceProvider = Provider<AIService>((ref) {
  return AIService();
});
