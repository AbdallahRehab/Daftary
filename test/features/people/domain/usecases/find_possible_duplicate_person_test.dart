import 'package:daftary/features/people/domain/entities/person.dart';
import 'package:daftary/features/people/domain/usecases/find_possible_duplicate_person.dart';
import 'package:flutter_test/flutter_test.dart';

Person _person(String id, String name) {
  final now = DateTime(2026);
  return Person(
    id: id,
    name: name,
    isArchived: false,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  final findPossibleDuplicatePerson = const FindPossibleDuplicatePerson();

  group('FindPossibleDuplicatePerson', () {
    test('matches an exact name (case/whitespace-insensitive)', () {
      final existing = [_person('1', 'Ahmed Ali')];
      final matches = findPossibleDuplicatePerson('  ahmed   ali  ', existing);
      expect(matches, existing);
    });

    test('"Ahmed" matches existing "Ahmed Ali" (new is a prefix)', () {
      final existing = [_person('1', 'Ahmed Ali')];
      final matches = findPossibleDuplicatePerson('Ahmed', existing);
      expect(matches, existing);
    });

    test('"Ahmed Ali" matches existing "Ahmed" (existing is a prefix)', () {
      final existing = [_person('1', 'Ahmed')];
      final matches = findPossibleDuplicatePerson('Ahmed Ali', existing);
      expect(matches, existing);
    });

    test('matches a contained substring in either direction', () {
      final existing = [_person('1', 'Mohamed Ahmed Nasser')];
      final matches = findPossibleDuplicatePerson('Ahmed', existing);
      expect(matches, existing);
    });

    test('does not match an unrelated name', () {
      final existing = [_person('1', 'Sara Ibrahim')];
      final matches = findPossibleDuplicatePerson('Ahmed', existing);
      expect(matches, isEmpty);
    });

    test('returns every matching person, not just the first', () {
      final existing = [
        _person('1', 'Ahmed'),
        _person('2', 'Ahmed Ali'),
        _person('3', 'Sara'),
      ];
      final matches = findPossibleDuplicatePerson('Ahmed', existing);
      expect(matches.map((p) => p.id), containsAll(['1', '2']));
      expect(matches.map((p) => p.id), isNot(contains('3')));
    });

    test('an empty candidate name matches nothing', () {
      final existing = [_person('1', 'Ahmed')];
      expect(findPossibleDuplicatePerson('   ', existing), isEmpty);
    });
  });

  group('FindPossibleDuplicatePerson.normalize', () {
    test('lowercases and collapses whitespace', () {
      expect(
        FindPossibleDuplicatePerson.normalize('  Ahmed   Ali  '),
        'ahmed ali',
      );
    });
  });
}
