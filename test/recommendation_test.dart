import 'package:flutter_test/flutter_test.dart';
import 'package:study_doc_manager/cloud/recommendationEngine.dart';

final _now = DateTime.utc(2026, 1, 1);

RecItem _item(String id, List<String> tags,
        {String owner = 'other', int views = 0, int ageDays = 10}) =>
    RecItem(
      id: id,
      ownerId: owner,
      title: id,
      tags: tags,
      viewCount: views,
      createdAt: _now.subtract(Duration(days: ageDays)),
    );

List<Recommendation> _rec(
  List<RecItem> candidates, {
  List<RecItem> owned = const [],
  List<RecItem> viewed = const [],
  List<String> fav = const [],
  int limit = 10,
}) =>
    RecommendationEngine.recommend(
      userId: 'me',
      owned: owned,
      viewed: viewed,
      candidates: candidates,
      favoriteTags: fav,
      limit: limit,
      now: _now,
    );

void main() {
  test('chuẩn hóa tag', () {
    expect(RecommendationEngine.normalizeTag('  Flutter   Căn  Bản '),
        'flutter căn bản');
    expect(
        RecommendationEngine.normalizeTags(['A', ' a ', '', 'b']), ['a', 'b']);
  });

  test('trọng số profile', () {
    final p = RecommendationEngine.buildProfile(
      owned: [_item('o', ['Dart', 'x'], owner: 'me')],
      viewed: [_item('v', ['dart'])],
      favoriteTags: ['Firebase'],
    );
    // dart=2.5, x=1, firebase=2 -> chuẩn hóa theo 2.5
    expect(p['dart'], closeTo(1.0, 1e-9));
    expect(p['x'], closeTo(0.4, 1e-9));
    expect(p['firebase'], closeTo(0.8, 1e-9));
  });

  test('tài liệu trùng tag xếp trên không trùng', () {
    final r = _rec(
      [_item('no', ['java'], views: 5), _item('yes', ['dart'])],
      fav: ['dart'],
    );
    expect(r.first.item.id, 'yes');
    expect(r.first.matchedTags, ['dart']);
    expect(r.first.reason, 'Trùng tag: #dart');
  });

  test('loại tài liệu của mình và đã sở hữu', () {
    final mine = _item('m', ['dart'], owner: 'me');
    final r = _rec(
      [mine, _item('same-id', ['dart']), _item('ok', ['dart'])],
      owned: [_item('same-id', ['dart'], owner: 'me')],
    );
    expect(r.map((e) => e.item.id), ['ok']);
  });

  test('cold start dùng độ phổ biến', () {
    final r = _rec([
      _item('low', ['a'], views: 1),
      _item('high', ['b'], views: 100),
    ]);
    expect(r.first.item.id, 'high');
    expect(r.every((e) => e.reason == 'Phổ biến'), isTrue);
  });

  test('tôn trọng limit và bổ sung tài liệu phổ biến', () {
    final c = [
      for (var i = 0; i < 5; i++) _item('m$i', ['dart']),
      for (var i = 0; i < 5; i++) _item('p$i', ['zzz'], views: 10),
    ];
    final three = _rec(c, fav: ['dart'], limit: 3);
    expect(three.length, 3);
    expect(three.every((e) => e.matchedTags.isNotEmpty), isTrue);
    final filled = _rec(c, fav: ['dart'], limit: 8);
    expect(filled.length, 8);
    expect(filled.where((e) => e.matchedTags.isEmpty).length, 3);
  });

  test('hòa điểm xác định: createdAt mới hơn rồi id', () {
    final r = _rec([
      _item('b', [], ageDays: 5),
      _item('a', [], ageDays: 5),
      _item('c', [], ageDays: 1),
    ]);
    expect(r.map((e) => e.item.id), ['c', 'a', 'b']);
  });

  test('tài liệu đã xem làm tăng điểm', () {
    final cands = [_item('f', ['flutter']), _item('d', ['dart'])];
    final base = _rec(cands, fav: ['flutter', 'dart']);
    expect((base.first.score - base.last.score).abs(), lessThan(1e-9));
    final boosted = _rec(
      cands,
      fav: ['flutter'],
      viewed: [_item('v', ['dart']), _item('w', ['dart'])],
    );
    expect(boosted.first.item.id, 'd');
  });
}
