/// Server rows in the shape `sync_pull` and `sync_push` return them
/// (`to_jsonb` of the cloud tables): snake_case, money as JSON numbers,
/// `owner_id` and `revision` included.
library;

const _owner = '00000000-0000-4000-8000-000000000001';
const _t0 = '2026-01-01T00:00:00.000Z';

Map<String, Object?> personRow(
  String id, {
  String name = 'Person',
  bool archived = false,
  int revision = 1,
  String? deletedAt,
}) => {
  'owner_id': _owner,
  'id': id,
  'revision': revision,
  'name': name,
  'normalized_name': name.toLowerCase(),
  'phone_number': null,
  'relationship_tag': null,
  'notes': null,
  'is_archived': archived,
  'client_created_at': _t0,
  'client_updated_at': _t0,
  'server_created_at': _t0,
  'server_updated_at': _t0,
  'deleted_at': deletedAt,
};

Map<String, Object?> transactionRow(
  String id, {
  required String personId,
  int amount = 1500,
  int revision = 2,
  String? note,
  String? deletedAt,
}) => {
  'owner_id': _owner,
  'id': id,
  'revision': revision,
  'idempotency_key': 'key-$id',
  'person_id': personId,
  'amount_minor': amount,
  'currency_code': 'EGP',
  'direction': 'given',
  'kind': 'initialExchange',
  'occurred_at': '2026-01-02T10:00:00.000Z',
  'occurred_on': '2026-01-02',
  'tz_offset_minutes': 0,
  'note': note,
  'edited_at': null,
  'deleted_at': deletedAt,
  'client_created_at': _t0,
  'client_updated_at': _t0,
};

Map<String, Object?> categoryRow(
  String id, {
  String name = 'Category',
  String type = 'expense',
  String icon = 'rent',
  bool isDefault = false,
  bool archived = false,
  int revision = 1,
  String? deletedAt,
}) => {
  'owner_id': _owner,
  'id': id,
  'revision': revision,
  'name': name,
  'normalized_name': name.toLowerCase(),
  'type': type,
  'icon_key': icon,
  'is_default': isDefault,
  'is_archived': archived,
  'client_created_at': _t0,
  'client_updated_at': _t0,
  'deleted_at': deletedAt,
};

Map<String, Object?> entryRow(
  String id, {
  required String categoryId,
  int amount = 2500,
  int revision = 2,
  String? deletedAt,
}) => {
  'owner_id': _owner,
  'id': id,
  'revision': revision,
  'idempotency_key': 'key-$id',
  'category_id': categoryId,
  'type': 'expense',
  'amount_minor': amount,
  'currency_code': 'EGP',
  'occurred_at': '2026-01-03T10:00:00.000Z',
  'occurred_on': '2026-01-03',
  'tz_offset_minutes': 0,
  'note': null,
  'edited_at': null,
  'deleted_at': deletedAt,
  'client_created_at': _t0,
  'client_updated_at': _t0,
};

Map<String, Object?> rateRow(
  String currency,
  String relative, {
  int micros = 50000000,
  int revision = 1,
  String? deletedAt,
}) => {
  'owner_id': _owner,
  'id': 'rate_${currency}_$relative',
  'revision': revision,
  'currency_code': currency,
  'relative_to_currency_code': relative,
  'rate_micros': micros,
  'client_created_at': _t0,
  'client_updated_at': _t0,
  'deleted_at': deletedAt,
};
