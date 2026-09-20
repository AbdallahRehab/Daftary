import '../../../../core/database/app_database.dart';
import '../../domain/entities/person.dart';

/// Maps between the `drift` [PeopleData] row and the domain [Person] entity.
extension PersonMapper on PeopleData {
  Person toDomain() => Person(
    id: id,
    name: name,
    phoneNumber: phoneNumber,
    avatarPath: avatarPath,
    relationshipTag: relationshipTag,
    notes: notes,
    isArchived: isArchived,
    createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt),
  );
}
