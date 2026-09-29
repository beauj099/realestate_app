import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realworth/features/property_report/data/models/address_suggestion.dart';
import 'package:realworth/features/property_report/presentation/widgets/address_search_field.dart';

AddressSuggestion _s(
  SuggestionKind kind,
  String title,
  double rank, {
  String? key,
}) => AddressSuggestion(
  kind: kind,
  title: title,
  streetName: kind == SuggestionKind.area ? '' : title,
  suburb: '',
  city: '',
  province: '',
  country: 'South Africa',
  rank: rank,
  key: key ?? '${kind.name} $title',
);

void main() {
  group('mergeSuggestions', () {
    test('streets and areas that match as well alternate', () {
      final list = mergeSuggestions(
        [
          _s(SuggestionKind.street, 'Bosman Street', 92),
          _s(SuggestionKind.street, 'Bosman Avenue', 92),
        ],
        [
          _s(SuggestionKind.area, 'Bosmont', 92),
          _s(SuggestionKind.street, 'Bosmansdam Road', 92),
        ],
      );
      expect(list.map((s) => s.kind), [
        SuggestionKind.street,
        SuggestionKind.area,
        SuggestionKind.street,
        SuggestionKind.street,
      ]);
    });

    test('a clearly better area leads', () {
      final list = mergeSuggestions(
        [_s(SuggestionKind.street, 'Heldervue Street', 92)],
        [_s(SuggestionKind.area, 'Heldervue', 96)],
      );
      expect(list.first.title, 'Heldervue');
    });

    test('keeps the better of the same place from both searches', () {
      final list = mergeSuggestions(
        [_s(SuggestionKind.property, '10 Bosman Street', 118, key: 'k')],
        [_s(SuggestionKind.street, '10 Bosman Street', 84, key: 'k')],
      );
      expect(list, hasLength(1));
      expect(list.single.kind, SuggestionKind.property);
    });

    test('at most six rows and two areas; weak matches dropped', () {
      final list = mergeSuggestions(
        [
          for (var i = 0; i < 8; i++)
            _s(SuggestionKind.street, 'Street $i', 92),
        ],
        [
          for (var i = 0; i < 4; i++) _s(SuggestionKind.area, 'Area $i', 92),
          _s(SuggestionKind.street, 'Far off', 40),
        ],
      );
      expect(list, hasLength(6));
      expect(list.where((s) => s.isArea), hasLength(2));
      expect(list.any((s) => s.title == 'Far off'), isFalse);
    });

    test('reads the API answer', () {
      final s = AddressSuggestion.fromJson({
        'label': 'Unit 5, 12 Main Road, Kalk Bay',
        'kind': 'property',
        'title': 'Unit 5, 12 Main Road',
        'subtitle': 'Kalk Bay, Cape Town',
        'unit': '5',
        'streetNumber': '12',
        'streetName': 'Main Road',
        'suburb': 'Kalk Bay',
        'city': 'Cape Town',
        'province': 'Western Cape',
        'country': 'South Africa',
        'erf': '123',
        'numberVerified': true,
        'source': 'City records',
        'rank': 110,
        'key': 'place 12 main road kalk bay',
      });
      expect(s.isProperty, isTrue);
      expect(s.unit, '5');
      expect(s.subtitle, 'Kalk Bay, Cape Town');
    });
  });

  test('bolds the typed start of each word', () {
    const normal = TextStyle();
    const bold = TextStyle(fontWeight: FontWeight.bold);
    final spans = highlightTyped('10 Bosman Street', '10 bosm', normal, bold);
    expect(spans.where((s) => s.style == bold).map((s) => s.text), [
      '10',
      'Bosm',
    ]);
    expect(spans.map((s) => s.text).join(), '10 Bosman Street');
  });
}
