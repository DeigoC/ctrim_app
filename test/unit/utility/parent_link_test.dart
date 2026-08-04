import 'package:flutter_test/flutter_test.dart';

import 'package:ctrim_app/utility/parent_link.dart';

void main() {
  group('ParentLink.wouldCreateCycle', () {
    final children = <String, List<String>>{
      'season': ['meeting-a', 'meeting-b'],
      'meeting-a': ['nested'],
      'meeting-b': <String>[],
      'nested': <String>[],
      'other': <String>[],
    };

    List<String> childrenOf(String id) => children[id] ?? const <String>[];

    test('null parent never cycles', () {
      expect(
        ParentLink.wouldCreateCycle(
          postId: 'meeting-a',
          newParentId: null,
          childrenOf: childrenOf,
        ),
        isFalse,
      );
    });

    test('self as parent is a cycle', () {
      expect(
        ParentLink.wouldCreateCycle(
          postId: 'meeting-a',
          newParentId: 'meeting-a',
          childrenOf: childrenOf,
        ),
        isTrue,
      );
    });

    test('direct child as parent is a cycle', () {
      expect(
        ParentLink.wouldCreateCycle(
          postId: 'season',
          newParentId: 'meeting-a',
          childrenOf: childrenOf,
        ),
        isTrue,
      );
    });

    test('descendant as parent is a cycle', () {
      expect(
        ParentLink.wouldCreateCycle(
          postId: 'season',
          newParentId: 'nested',
          childrenOf: childrenOf,
        ),
        isTrue,
      );
    });

    test('unrelated post as parent is fine', () {
      expect(
        ParentLink.wouldCreateCycle(
          postId: 'meeting-a',
          newParentId: 'other',
          childrenOf: childrenOf,
        ),
        isFalse,
      );
    });

    test('ancestor as parent is fine', () {
      expect(
        ParentLink.wouldCreateCycle(
          postId: 'nested',
          newParentId: 'season',
          childrenOf: childrenOf,
        ),
        isFalse,
      );
    });
  });
}
