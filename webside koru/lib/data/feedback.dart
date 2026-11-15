import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../lang.dart';
import 'bookings.dart';
import 'staff_auth.dart';

// Parts of the service a patient can say their comment is about.
enum FeedbackAspect { punctuality, driver, vehicle, safety, booking, assistance }

extension FeedbackAspectText on FeedbackAspect {
  String label(BuildContext context) => switch (this) {
        FeedbackAspect.punctuality =>
          context.t('Punctuality', 'Zamanında gelme'),
        FeedbackAspect.driver =>
          context.t('Driver courtesy', 'Sürücünün nezaketi'),
        FeedbackAspect.vehicle =>
          context.t('Vehicle comfort & cleanliness', 'Araç konforu ve temizliği'),
        FeedbackAspect.safety => context.t('Safe driving', 'Güvenli sürüş'),
        FeedbackAspect.booking =>
          context.t('Booking & communication', 'Rezervasyon ve iletişim'),
        FeedbackAspect.assistance =>
          context.t('Help getting in and out', 'Binerken ve inerken yardım'),
      };

  IconData get icon => switch (this) {
        FeedbackAspect.punctuality => Icons.schedule,
        FeedbackAspect.driver => Icons.emoji_people_outlined,
        FeedbackAspect.vehicle => Icons.airline_seat_recline_extra_outlined,
        FeedbackAspect.safety => Icons.health_and_safety_outlined,
        FeedbackAspect.booking => Icons.support_agent_outlined,
        FeedbackAspect.assistance => Icons.accessible_forward_outlined,
      };
}

// One comment a patient left on the feedback page.
class PatientFeedback {
  PatientFeedback({
    required this.rating,
    required this.type,
    required this.comment,
    required this.date,
    this.name = '',
    this.ref = '',
    this.aspects = const [],
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
  // Parts of the service the comment is about (may be empty).
  final List<FeedbackAspect> aspects;
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

  // Saves a new comment from the feedback page. Works without signing in
  // (patients use it). Returns false if it could not be saved, e.g. no
  // internet, so the page can ask the patient to try again.
  Future<bool> add(PatientFeedback feedback) async {
    final doc = _db.doc();
    feedback.id = doc.id;
    try {
      await doc.set({
        'rating': feedback.rating,
        'type': feedback.type.name,
        'comment': feedback.comment,
        'date': Timestamp.fromDate(feedback.date),
        'name': feedback.name,
        'ref': feedback.ref,
        'aspects': [for (final a in feedback.aspects) a.name],
        'published': false,
      }).timeout(const Duration(seconds: 15));
      return true;
    } catch (e) {
      debugPrint('Saving feedback failed: $e');
      return false;
    }
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
        aspects: [
          for (final name in (doc.data()['aspects'] as List? ?? const []))
            if (FeedbackAspect.values.asNameMap()[name] case final a?) a,
        ],
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
