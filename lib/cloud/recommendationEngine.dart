import 'dart:math' as math;

/// Tài liệu rút gọn dùng cho gợi ý (thuần Dart, không phụ thuộc Flutter/Supabase).
class RecItem {
  final String id;
  final String ownerId;
  final String title;
  final List<String> tags;
  final int viewCount;
  final DateTime createdAt;

  const RecItem({
    required this.id,
    required this.ownerId,
    required this.title,
    this.tags = const [],
    this.viewCount = 0,
    required this.createdAt,
  });
}

/// Kết quả gợi ý: tài liệu, điểm, tag trùng và lý do hiển thị.
class Recommendation {
  final RecItem item;
  final double score;
  final List<String> matchedTags;
  final String reason;

  const Recommendation({
    required this.item,
    required this.score,
    required this.matchedTags,
    required this.reason,
  });
}

class RecommendationEngine {
  static const double _wContent = 0.7;
  static const double _wPopularity = 0.2;
  static const double _wFreshness = 0.1;
  static const double _wColdPopularity = 0.7;
  static const double _wColdFreshness = 0.3;

  /// Chuẩn hóa tag: trim, chữ thường, gộp khoảng trắng (giữ nguyên dấu tiếng Việt).
  static String normalizeTag(String tag) =>
      tag.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  /// Chuẩn hóa danh sách tag: bỏ rỗng và trùng, giữ thứ tự xuất hiện.
  static List<String> normalizeTags(Iterable<String> tags) {
    final seen = <String>{};
    final out = <String>[];
    for (final t in tags) {
      final n = normalizeTag(t);
      if (n.isNotEmpty && seen.add(n)) out.add(n);
    }
    return out;
  }

  /// Hồ sơ sở thích: +1.0 mỗi tài liệu sở hữu, +1.5 mỗi tài liệu đã xem,
  /// +2.0 mỗi tag yêu thích; sau đó chuẩn hóa để trọng số lớn nhất = 1.
  static Map<String, double> buildProfile({
    required List<RecItem> owned,
    required List<RecItem> viewed,
    List<String> favoriteTags = const [],
  }) {
    final raw = <String, double>{};
    void add(Iterable<String> tags, double w) {
      for (final t in normalizeTags(tags)) {
        raw[t] = (raw[t] ?? 0) + w;
      }
    }

    for (final d in owned) {
      add(d.tags, 1.0);
    }
    for (final d in viewed) {
      add(d.tags, 1.5);
    }
    add(favoriteTags, 2.0);

    if (raw.isEmpty) return {};
    final maxW = raw.values.reduce(math.max);
    return {for (final e in raw.entries) e.key: e.value / maxW};
  }

  /// Gợi ý tài liệu cho [userId]. Loại tài liệu của chính mình và đã nằm trong [owned].
  /// Sắp xếp điểm giảm dần, hòa điểm thì createdAt mới hơn, rồi theo id.
  static List<Recommendation> recommend({
    required String userId,
    required List<RecItem> owned,
    required List<RecItem> viewed,
    required List<RecItem> candidates,
    List<String> favoriteTags = const [],
    int limit = 10,
    DateTime? now,
  }) {
    if (limit <= 0) return [];
    final clock = now ?? DateTime.now();
    final ownedIds = owned.map((d) => d.id).toSet();
    final pool = candidates
        .where((c) => c.ownerId != userId && !ownedIds.contains(c.id))
        .toList();
    if (pool.isEmpty) return [];

    final profile = buildProfile(
        owned: owned, viewed: viewed, favoriteTags: favoriteTags);
    final maxViews = pool.map((c) => c.viewCount).reduce(math.max);
    final cold = profile.isEmpty;

    // Điểm nội dung thô (kiểu cosine) và tag trùng cho từng ứng viên.
    final contents = <double>[];
    final matches = <List<String>>[];
    for (final c in pool) {
      final tags = normalizeTags(c.tags);
      final m = tags.where(profile.containsKey).toList()
        ..sort((a, b) {
          final d = profile[b]!.compareTo(profile[a]!);
          return d != 0 ? d : a.compareTo(b);
        });
      matches.add(m);
      var sum = 0.0;
      for (final t in m) {
        sum += profile[t]!;
      }
      contents.add(tags.isEmpty ? 0.0 : sum / math.sqrt(tags.length));
    }
    final maxContent = contents.reduce(math.max);

    final scored = <Recommendation>[];
    for (var i = 0; i < pool.length; i++) {
      final c = pool[i];
      final pop = _popularity(c.viewCount, maxViews);
      final fresh = _freshness(c.createdAt, clock);
      final double score;
      final String reason;
      if (cold) {
        score = _wColdPopularity * pop + _wColdFreshness * fresh;
        reason = 'Phổ biến';
      } else {
        final content = maxContent > 0 ? contents[i] / maxContent : 0.0;
        score = _wContent * content + _wPopularity * pop + _wFreshness * fresh;
        reason = matches[i].isNotEmpty
            ? 'Trùng tag: ${matches[i].map((t) => '#$t').join(', ')}'
            : (pop >= fresh ? 'Phổ biến' : 'Mới đăng');
      }
      scored.add(Recommendation(
        item: c,
        score: score,
        matchedTags: matches[i],
        reason: reason,
      ));
    }

    scored.sort((a, b) {
      final s = b.score.compareTo(a.score);
      if (s != 0) return s;
      final t = b.item.createdAt.compareTo(a.item.createdAt);
      return t != 0 ? t : a.item.id.compareTo(b.item.id);
    });

    // Có hồ sơ: chỉ giữ ứng viên trùng tag nếu đủ `limit`, ngược lại bổ sung bằng
    // ứng viên phổ biến (đã được xếp sau nhờ điểm thấp hơn).
    if (!cold) {
      final matched = scored.where((r) => r.matchedTags.isNotEmpty).toList();
      if (matched.length >= limit) return matched.take(limit).toList();
    }
    return scored.take(limit).toList();
  }

  // Độ phổ biến log-scale trong [0,1].
  static double _popularity(int views, int maxViews) {
    if (maxViews <= 0) return 0.0;
    return math.log(1 + math.max(views, 0)) / math.log(1 + maxViews);
  }

  // Độ mới giảm theo hàm mũ, bán rã ~30 ngày.
  static double _freshness(DateTime createdAt, DateTime now) {
    final days = math.max(0.0, now.difference(createdAt).inSeconds / 86400.0);
    return math.exp(-days / 30);
  }
}
