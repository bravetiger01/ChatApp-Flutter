// services/message_cache.dart
//
// Singleton that prefetches the last 30 messages for each chatId so
// ChatScreen can render immediately without a loading spinner.

import 'package:cloud_firestore/cloud_firestore.dart';

/// A single cached message: the document ID plus its raw field map.
class CachedMessage {
  final String id;
  final Map<String, dynamic> data;
  const CachedMessage(this.id, this.data);
}

class MessageCache {
  // Singleton
  MessageCache._();
  static final MessageCache instance = MessageCache._();

  // chatId → list ordered descending (newest first), matching Firestore query order
  final Map<String, List<CachedMessage>> _cache = {};

  // Tracks in-flight fetches so we never fire the same chatId twice
  final Set<String> _inFlight = {};

  static const int _limit = 30;

  // ── Public API ────────────────────────────────────────────────

  /// Returns the cached message list for [chatId], or null if not cached yet.
  List<CachedMessage>? get(String chatId) => _cache[chatId];

  /// Fetches the last [_limit] messages for [chatId] and caches them.
  /// Safe to call multiple times — duplicate calls while a fetch is in
  /// progress are silently ignored.
  Future<void> prefetch(String chatId) async {
    if (_cache.containsKey(chatId) || _inFlight.contains(chatId)) return;
    _inFlight.add(chatId);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(_limit)
          .get(const GetOptions(source: Source.serverAndCache));

      _cache[chatId] = snap.docs
          .map((d) => CachedMessage(d.id, d.data()))
          .toList();
    } catch (_) {
      // Silently swallow — cache miss is fine, ChatScreen degrades gracefully
    } finally {
      _inFlight.remove(chatId);
    }
  }

  /// Called by ChatScreen when the live Firestore stream delivers data.
  /// Keeps the cache in sync so the next cold-open of the same chat is instant.
  void updateFromDocs(String chatId, List<QueryDocumentSnapshot> docs) {
    _cache[chatId] =
        docs.take(_limit).map((d) => CachedMessage(d.id, d.data() as Map<String, dynamic>)).toList();
  }

  /// Removes a chatId from the cache (e.g. on logout).
  void invalidate(String chatId) => _cache.remove(chatId);

  /// Clears the entire cache (call on sign-out).
  void clear() {
    _cache.clear();
    _inFlight.clear();
  }
}
