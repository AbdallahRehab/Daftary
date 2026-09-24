import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/education_article.dart';
import '../../domain/entities/education_category.dart';

/// Thrown when a category/article id is not part of the bundled content.
class EducationContentNotFoundException implements Exception {
  const EducationContentNotFoundException(this.message);

  final String message;

  @override
  String toString() => 'EducationContentNotFoundException: $message';
}

/// Thrown when a bundled content asset is missing or malformed.
class EducationContentFormatException implements Exception {
  const EducationContentFormatException(this.message);

  final String message;

  @override
  String toString() => 'EducationContentFormatException: $message';
}

/// Loads the educational content bundled as JSON assets under
/// `lib/features/financial_education/data/content/{en,ar}/` (research.md
/// Decision 1). Nothing here touches the network or the database.
///
/// The [AssetBundle] is injected (production: `rootBundle`, via
/// `RegisterModule`) so tests can serve a small deterministic fixture.
@lazySingleton
class BundledEducationContentDataSource {
  BundledEducationContentDataSource(this._bundle);

  final AssetBundle _bundle;

  static const String contentRoot =
      'lib/features/financial_education/data/content';
  static const Set<String> supportedLanguageCodes = {'en', 'ar'};
  static const String fallbackLanguageCode = 'en';

  /// Content ids are file names, so anything outside this alphabet is
  /// rejected before it can reach an asset path.
  static final RegExp _idPattern = RegExp(r'^[a-z0-9_]+$');

  final Map<String, List<EducationCategory>> _categoriesCache = {};
  final Map<String, EducationArticle> _articleCache = {};

  /// The content tree actually used for [languageCode]: itself when
  /// supported, otherwise English.
  static String resolveLanguage(String languageCode) =>
      supportedLanguageCodes.contains(languageCode)
      ? languageCode
      : fallbackLanguageCode;

  Future<List<EducationCategory>> loadCategories(String languageCode) async {
    final language = resolveLanguage(languageCode);
    final cached = _categoriesCache[language];
    if (cached != null) return cached;

    final path = '$contentRoot/$language/categories.json';
    final decoded = await _loadJson(path);
    if (decoded is! List) {
      throw EducationContentFormatException('$path is not a JSON array');
    }
    final categories = List<EducationCategory>.unmodifiable(
      decoded.map((raw) => _categoryFromJson(raw, path)),
    );
    _categoriesCache[language] = categories;
    return categories;
  }

  Future<EducationCategory> loadCategory(
    String categoryId,
    String languageCode,
  ) async {
    final categories = await loadCategories(languageCode);
    for (final category in categories) {
      if (category.id == categoryId) return category;
    }
    throw EducationContentNotFoundException('Unknown category "$categoryId"');
  }

  Future<EducationArticle> loadArticle(
    String articleId,
    String languageCode,
  ) async {
    final language = resolveLanguage(languageCode);
    final cacheKey = '$language/$articleId';
    final cached = _articleCache[cacheKey];
    if (cached != null) return cached;

    // An article only exists if some category lists it — this keeps
    // "unknown id" (not found) distinct from "listed but unreadable"
    // (a content-authoring bug).
    final categories = await loadCategories(language);
    final isListed =
        _idPattern.hasMatch(articleId) &&
        categories.any((category) => category.articleIds.contains(articleId));
    if (!isListed) {
      throw EducationContentNotFoundException('Unknown article "$articleId"');
    }

    final path = '$contentRoot/$language/articles/$articleId.json';
    final article = _articleFromJson(await _loadJson(path), path);
    _articleCache[cacheKey] = article;
    return article;
  }

  Future<Object?> _loadJson(String path) async {
    final String raw;
    try {
      raw = await _bundle.loadString(path, cache: false);
    } catch (error) {
      throw EducationContentFormatException('Could not load $path: $error');
    }
    try {
      return jsonDecode(raw);
    } on FormatException catch (error) {
      throw EducationContentFormatException('Invalid JSON in $path: $error');
    }
  }

  EducationCategory _categoryFromJson(Object? raw, String path) {
    final json = _asMap(raw, path);
    return EducationCategory(
      id: _string(json, 'id', path),
      title: _string(json, 'title', path),
      shortDescription: _string(json, 'shortDescription', path),
      articleIds: List.unmodifiable(_stringList(json, 'articleIds', path)),
    );
  }

  EducationArticle _articleFromJson(Object? raw, String path) {
    final json = _asMap(raw, path);
    final sections = json['bodySections'];
    if (sections is! List) {
      throw EducationContentFormatException('$path: bodySections missing');
    }
    return EducationArticle(
      id: _string(json, 'id', path),
      categoryId: _string(json, 'categoryId', path),
      title: _string(json, 'title', path),
      shortDescription: _string(json, 'shortDescription', path),
      bodySections: List.unmodifiable(
        sections.map((rawSection) {
          final section = _asMap(rawSection, path);
          final heading = section['heading'];
          if (heading != null && heading is! String) {
            throw EducationContentFormatException('$path: bad heading');
          }
          return ArticleSection(
            heading: heading as String?,
            paragraphs: List.unmodifiable(
              _stringList(section, 'paragraphs', path),
            ),
          );
        }),
      ),
    );
  }

  Map<String, Object?> _asMap(Object? raw, String path) {
    if (raw is Map<String, Object?>) return raw;
    throw EducationContentFormatException('$path: expected a JSON object');
  }

  String _string(Map<String, Object?> json, String key, String path) {
    final value = json[key];
    if (value is String) return value;
    throw EducationContentFormatException('$path: "$key" must be a string');
  }

  List<String> _stringList(Map<String, Object?> json, String key, String path) {
    final value = json[key];
    if (value is List && value.every((item) => item is String)) {
      return value.cast<String>();
    }
    throw EducationContentFormatException('$path: "$key" must be strings');
  }
}
