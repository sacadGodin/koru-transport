import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../lang.dart';
import 'staff_auth.dart';

// The topics a visitor can pick in the contact form.
enum ContactTopic { booking, change, shuttle, other }

extension ContactTopicText on ContactTopic {
  String label(BuildContext context) => switch (this) {
        ContactTopic.booking =>
          context.t('Question about a booking', 'Rezervasyon hakkında soru'),
        ContactTopic.change =>
          context.t('Change or cancel a booking', 'Değişiklik veya iptal'),
        ContactTopic.shuttle => context.t('Free bus', 'Ücretsiz servis'),
        ContactTopic.other => context.t('Other', 'Diğer'),
      };
}

// One message sent with the contact form.
class ContactMessage {
  ContactMessage({
    required this.id,
    required this.name,
    required this.reply,
    required this.topic,
    required this.reference,
    required this.message,
    required this.date,
    this.handled = false,
  });

  final String id;
  final String name;
  // Phone number or email to answer to.
  final String reply;
  final ContactTopic topic;
  // Booking reference (may be empty).
  final String reference;
  final String message;
  final DateTime date;
  // True when staff have answered it.
  bool handled;
}

// Contact form messages in the "messages" collection in Firestore.
// Visitors can only send new ones; signed-in staff read them (newest first)
// and mark them as answered.
class MessageStore extends ChangeNotifier {
  MessageStore() {
    staffAuth.addListener(_listen);
    _listen();
  }

  final _db = FirebaseFirestore.instance.collection('messages');
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  final List<ContactMessage> items = [];

  // Messages nobody has answered yet.
  int get open => items.where((m) => !m.handled).length;

  void _listen() {
    _sub?.cancel();
    _sub = null;
    items.clear();
    notifyListeners();
    if (!staffAuth.isStaff) return;
    _sub = _db.orderBy('date', descending: true).snapshots().listen(
      (snap) {
        items
          ..clear()
          ..addAll(snap.docs.map(_fromDoc));
        notifyListeners();
      },
      onError: (Object e) => debugPrint('Loading messages failed: $e'),
    );
  }

  // Saves a message from the contact form. Throws if it could not be saved.
  Future<void> send({
    required String name,
    required String reply,
    required ContactTopic topic,
    required String reference,
    required String message,
  }) {
    return _db.add({
      'name': name,
      'reply': reply,
      'topic': topic.name,
      'reference': reference,
      'message': message,
      'date': FieldValue.serverTimestamp(),
      'handled': false,
    });
  }

  // Marks a message as answered (or not).
  Future<void> setHandled(ContactMessage m, bool value) async {
    m.handled = value;
    notifyListeners();
    try {
      await _db.doc(m.id).update({'handled': value});
    } catch (e) {
      debugPrint('Saving message ${m.id} failed: $e');
    }
  }

  // Deletes a message (e.g. spam).
  Future<void> remove(ContactMessage m) async {
    items.remove(m);
    notifyListeners();
    try {
      await _db.doc(m.id).delete();
    } catch (e) {
      debugPrint('Deleting message ${m.id} failed: $e');
    }
  }

  static ContactMessage _fromDoc(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    return ContactMessage(
      id: doc.id,
      name: d['name'] as String? ?? '',
      reply: d['reply'] as String? ?? '',
      topic: ContactTopic.values.asNameMap()[d['topic']] ?? ContactTopic.other,
      reference: d['reference'] as String? ?? '',
      message: d['message'] as String? ?? '',
      // Just sent: the server time is filled in a moment later.
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      handled: d['handled'] as bool? ?? false,
    );
  }

  @override
  void dispose() {
    staffAuth.removeListener(_listen);
    _sub?.cancel();
    super.dispose();
  }
}

// The one message store for the whole app.
final messageStore = MessageStore();
