import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'bookings.dart';
import 'staff_auth.dart';

// One comment a patient left on the feedback page.
class PatientFeedback {
  PatientFeedback({
    required this.rating,
    required this.type,
    required this.comment,
    required this.date,
    this.name = '',
    this.ref = '',
    this.published = false,
    this.id = '',
  });

  // Firestore document id (set when the comment is saved).
  String id;

  // Stars, 1 to 5.
  final int rating;
  final TransportType type;
  final String comment;
  final DateTime date;
  // Optional: the patient may leave these empty.
  final String name;
  final String ref;
  // True when staff chose to show this comment on the homepage.
  bool published;
}

// Keeps feedback in sync with the "feedback" collection in Firestore and
// tells the screens when something changes. Visitors only see comments
// staff published; signed-in staff see all of them.
class FeedbackStore extends ChangeNotifier {
  FeedbackStore() {
    staffAuth.addListener(_listen);
    _listen();
  }

  final _db = FirebaseFirestore.instance.collection('feedback');
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  final List<PatientFeedback> items = [];

  // Loads the comments this visitor may see and keeps them updated.
  void _listen() {
    _sub?.cancel();
    final query = staffAuth.isStaff
        ? _db.orderBy('date', descending: true)
        : _db.where('published', isEqualTo: true);
    _sub = query.snapshots().listen(
      (snap) {
        items
          ..clear()
          ..addAll(snap.docs.map(_fromDoc))
          // Newest first.
          ..sort((a, b) => b.date.compareTo(a.date));
        notifyListeners();
      },
      onError: (Object e) => debugPrint('Loading feedback failed: $e'),
    );
  }

  // Comments staff approved for the homepage, newest first.
  List<PatientFeedback> get published =>
      items.where((f) => f.published).toList();

  // Average star rating of all comments (0 when there are none).
  double get averageRating => items.isEmpty
      ? 0
      : items.map((f) => f.rating).reduce((a, b) => a + b) / items.length;

  // Adds a new comment from the feedback page and saves it.
  void add(PatientFeedback feedback) {
    final doc = _db.doc();
    feedback.id = doc.id;
    items.insert(0, feedback);
    notifyListeners();
    _write(() => doc.set({
          'rating': feedback.rating,
          'type': feedback.type.name,
          'comment': feedback.comment,
          'date': Timestamp.fromDate(feedback.date),
          'name': feedback.name,
          'ref': feedback.ref,
          'published': feedback.published,
        }));
  }

  // Shows or hides a comment on the homepage.
  void setPublished(PatientFeedback feedback, bool value) {
    feedback.published = value;
    notifyListeners();
    _write(() => _db.doc(feedback.id).update({'published': value}));
  }

  // Deletes a comment (e.g. spam).
  void remove(PatientFeedback feedback) {
    items.remove(feedback);
    notifyListeners();
    _write(() => _db.doc(feedback.id).delete());
  }

  Future<void> _write(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      debugPrint('Saving feedback failed: $e');
    }
  }

  // Turns a saved Firestore document back into a PatientFeedback.
  static PatientFeedback _fromDoc(
          QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
      PatientFeedback(
        id: doc.id,
        rating: doc['rating'] as int,
        type: TransportType.values.byName(doc['type'] as String),
        comment: doc['comment'] as String? ?? '',
        date: (doc['date'] as Timestamp).toDate(),
        name: doc['name'] as String? ?? '',
        ref: doc['ref'] as String? ?? '',
        published: doc['published'] as bool? ?? false,
      );

  @override
  void dispose() {
    staffAuth.removeListener(_listen);
    _sub?.cancel();
    super.dispose();
  }
}

// The one feedback store for the whole app.
final feedbackStore = FeedbackStore();
