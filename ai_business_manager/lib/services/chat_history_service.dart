import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

class ChatMessage {
  final String query;
  final String response;
  final String? branchId;
  final DateTime createdAt;

  ChatMessage({
    required this.query,
    required this.response,
    this.branchId,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      query: json['query'] as String,
      response: json['response'] as String,
      branchId: json['branch_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class ChatHistoryService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> saveMessage({
    required String query,
    required String response,
    String? branchId,
    String? userId,
  }) async {
    try {
      await _supabase.from('dhaara_mobile_app').insert({
        'query': query,
        'response': response,
        'branch_id': branchId,
        'user_id': userId,
      });
      debugPrint("ChatHistoryService: Message saved to Supabase.");
    } catch (e) {
      debugPrint("ChatHistoryService ERROR: $e");
    }
  }

  Future<List<ChatMessage>> getRecentHistory({int limit = 50}) async {
    try {
      final response = await _supabase
          .from('dhaara_mobile_app')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((json) => ChatMessage.fromJson(json as Map<String, dynamic>))
          .toList()
          .reversed
          .toList();
    } catch (e) {
      debugPrint("ChatHistoryService FETCH ERROR: $e");
      return [];
    }
  }
}

final chatHistoryServiceProvider = Provider<ChatHistoryService>((ref) {
  return ChatHistoryService();
});
