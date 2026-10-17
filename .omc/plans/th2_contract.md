# TH2 contract — shared by all agents

Project: Flutter app `study_doc_manager` at C:\Workin\mobile_th1_qly_hoc_tap. Vietnamese UI strings.
Code style: camelCase file names (e.g. `supabaseDocumentService.dart`), StatefulWidget + setState, Navigator 1.0,
no state-management package. Match existing comment density (Vietnamese comments OK). Do NOT create git branches,
do NOT commit. Deps already in pubspec: flutter_map ^8.3.2, latlong2 ^0.10.1, geolocator ^14.0.1,
firebase_messaging ^16.7.0, supabase_flutter, firebase_*. Do not edit pubspec.yaml.

Architecture: Firebase = Authentication (Google) + Cloud Messaging (FCM). Supabase = Postgres DB + Storage (bucket `documents`).
Supabase identity: client sends header `x-user-id` (Firebase UID) — see lib/cloud/supabaseBootstrap.dart; SQL fn
`current_app_user_id()` reads it. Also add header `x-user-email` so `current_app_user_email()` works.

## DB (file: supabase/th2_migration.sql — idempotent, runs in Supabase SQL editor)
documents: + tags text[] not null default '{}', + location_name text, + latitude double precision,
           + longitude double precision, + is_public boolean not null default false, + view_count int not null default 0
document_permissions: + expires_at timestamptz null
users: + fcm_token text
new table borrow_requests(id uuid pk default gen_random_uuid(), document_id uuid fk documents on delete cascade,
  requester_id text, requester_email text, owner_id text, status text check in
  ('pending','approved','rejected','returned','cancelled') default 'pending', message text, due_date timestamptz,
  created_at timestamptz default now(), responded_at timestamptz)
new table document_views(id bigserial pk, document_id uuid fk cascade, user_id text, viewed_at timestamptz default now())
rpc record_document_view(p_document_id uuid) security definer: insert view + increment view_count
Storage bucket `documents` (public read), policies allowing anon insert/select/delete on bucket_id='documents'.

## Dart models/services (lib/cloud/supabaseDocumentService.dart) — exact public API
SupabaseDocument gains: `List<String> tags`, `String? locationName`, `double? latitude`, `double? longitude`,
  `bool isPublic`, `int viewCount`, getter `bool get hasLocation`.
enum BorrowStatus { pending, approved, rejected, returned, cancelled } with `String get label` (Vietnamese) and
  `static BorrowStatus parse(String)`.
class BorrowRequest { id, documentId, documentTitle (String, from join or ''), requesterId, requesterEmail, ownerId,
  BorrowStatus status, String message, DateTime? dueDate, DateTime createdAt, DateTime? respondedAt; fromMap }
SupabaseDocumentService (existing constructor kept) new/extended methods:
  getDocuments(...) existing + optional `List<String> tags = const []` filter (docs containing ALL tags)
  Future<List<SupabaseDocument>> getPublicDocuments({String searchQuery = '', List<String> tags = const []}) // others' public docs
  Future<List<String>> getAllTags()  // distinct, sorted, from own+shared+public docs
  createDocument(...) existing + named optional: tags, locationName, latitude, longitude, isPublic.
    File upload goes to Supabase Storage bucket `documents` path `{uid}/{timestamp}_{safeName}`, file_url = public URL;
    fallback to existing behaviour if storage fails.
  updateDocument(...) existing + named optional: tags, locationName, latitude, longitude, isPublic
  Future<void> recordView(String documentId)
  Future<List<String>> getViewedDocumentIds({int limit = 50})
  Future<BorrowRequest> requestBorrow(SupabaseDocument doc, {String message = '', DateTime? dueDate})
  Future<List<BorrowRequest>> getIncomingBorrowRequests()   // owner_id = me
  Future<List<BorrowRequest>> getOutgoingBorrowRequests()   // requester_id = me
  Future<void> approveBorrow(BorrowRequest r)  // status approved + upsert viewer permission (expires_at = dueDate)
  Future<void> rejectBorrow(BorrowRequest r)
  Future<void> returnBorrow(BorrowRequest r)   // status returned + delete permission for requester email
  Future<void> cancelBorrow(BorrowRequest r)
  Future<void> saveFcmToken(String token)

## Recommendation (lib/cloud/recommendationEngine.dart) — pure Dart, no Flutter/Supabase imports
class RecItem { String id; String ownerId; String title; List<String> tags; int viewCount; DateTime createdAt; }
class Recommendation { RecItem item; double score; List<String> matchedTags; String reason; }
class RecommendationEngine {
  static Map<String,double> buildProfile({required List<RecItem> owned, required List<RecItem> viewed, List<String> favoriteTags = const []})
  static List<Recommendation> recommend({required String userId, required List<RecItem> owned, required List<RecItem> viewed,
     required List<RecItem> candidates, List<String> favoriteTags = const [], int limit = 10})
}

## Notifications (lib/cloud/notificationService.dart)
class NotificationService {
  static Future<void> initialize()   // FCM permission, token, onMessage; safe no-op if Firebase not ready
  static String? fcmToken;
  static Stream<AppNotification> get stream;   // merged FCM foreground + Supabase realtime broadcast
  static Future<void> listenForUser(String userId)   // subscribe Supabase realtime broadcast channel `notify:{userId}`
  static Future<void> sendToUser(String userId, {required String title, required String body, Map<String,dynamic> data = const {}})
}
class AppNotification { String title; String body; Map<String,dynamic> data; DateTime receivedAt; }

## Widgets
lib/widgets/tagInput.dart: `TagInput({required List<String> tags, required ValueChanged<List<String>> onChanged, List<String> suggestions = const []})`
  plus `TagChips({required List<String> tags, ValueChanged<String>? onTap, Set<String> selected = const {}})`
lib/pages/locationPickerPage.dart: `LocationPickerPage({LatLng? initial, String? initialName})` pops `PickedLocation{LatLng point; String name}`
lib/widgets/documentMapView.dart: `DocumentMapView({required List<MapMarkerData> markers, ValueChanged<MapMarkerData>? onTap})`
  `class MapMarkerData { String id; String title; String subtitle; LatLng point; }`
Default map center: Hanoi (21.0285, 105.8542). Tiles: OpenStreetMap `https://tile.openstreetmap.org/{z}/{x}/{y}.png`
with userAgentPackageName 'com.studydoc.study_doc_manager'.
