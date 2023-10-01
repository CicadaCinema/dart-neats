// Copyright 2023 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

/// Intermediate data-structures for collection of data from an unresolved AST
/// inorder to eventually produce a `PackageOutline`.
library;

import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:pub_semver/pub_semver.dart';

part 'shapes.g.dart';

Version _versionFromJson(Object json) => Version.parse(json as String);
String _versionToJson(Version version) => version.canonicalizedVersion;

@JsonSerializable(explicitToJson: true, constructor: '_allFields')
class PackageShape {
  final String name;

  @JsonKey(fromJson: _versionFromJson, toJson: _versionToJson)
  final Version version;
  final Map<Uri, LibraryShape> libraries = {};

  PackageShape({
    required this.name,
    required this.version,
  });

  PackageShape._allFields({
    required this.name,
    required this.version,
    required Map<Uri, LibraryShape> libraries,
  }) {
    this.libraries.addAll(libraries);
  }

  factory PackageShape.fromJson(Map<String, dynamic> json) =>
      _$PackageShapeFromJson(json);

  Map<String, dynamic> toJson() => _$PackageShapeToJson(this);
}

@JsonSerializable(explicitToJson: true, constructor: '_allFields')
class LibraryShape {
  final Uri uri;

  /// Map from prefix to map from imported [Uri] to namespace filter applied.
  ///
  /// The empty prefix / key points to libraries imported without any prefix.
  final Map<String, Map<Uri, NamespaceFilter>> imports = {};
  final Map<Uri, NamespaceFilter> exports = {};

  /// Top-level elements defined in this library.
  final Map<String, LibraryMemberShape> definedShapes = {};

  /// Top-level elements exported from this library.
  ///
  /// This includes all shapes exported from `export` statements pointing to
  /// other libraries in this package.
  final Map<String, LibraryMemberShape> exportedShapes = {};

  /// Top-level elements imported into this library.
  ///
  /// For prefixed imports the key will include the prefix.
  /// This includes all shapes imported from `import` statements pointing to
  /// other libaries in this package.
  final Map<String, LibraryMemberShape> importedShapes = {};

  LibraryShape({required this.uri});

  LibraryShape._allFields({
    required this.uri,
    required Map<String, Map<Uri, NamespaceFilter>> imports,
    required Map<Uri, NamespaceFilter> exports,
    required Map<String, LibraryMemberShape> definedShapes,
  }) {
    this.imports.addAll(imports);
    this.exports.addAll(exports);
    this.definedShapes.addAll(definedShapes);
  }

  factory LibraryShape.fromJson(Map<String, dynamic> json) =>
      _$LibraryShapeFromJson(json);

  Map<String, dynamic> toJson() => _$LibraryShapeToJson(this);
}

/// A filter on an imported namespace in the form of `show ... hide ...`.
sealed class NamespaceFilter {
  const NamespaceFilter();

  /// A filter that shows everything in a namespace.
  ///
  /// In other words a [NamespaceHideFilter] that doesn't hide anything.
  factory NamespaceFilter.everything() => NamespaceHideFilter._everything();

  /// A filter that shows nothing from a namespace.
  ///
  /// In other words a [NamespaceShowFilter] that doesn't show anything.
  factory NamespaceFilter.nothing() => NamespaceShowFilter._nothing();

  /// Apply a further filter.
  ///
  /// This will only create a new [NamespaceFilter] object, if it's different
  /// from this and [other].
  NamespaceFilter applyFilter(NamespaceFilter other);

  /// Create a filter that represents both filters applied in parallel.
  ///
  /// This will only create a new [NamespaceFilter] object, if it's different
  /// from this and [other].
  NamespaceFilter mergeFilter(NamespaceFilter other);

  /// Is [symbol] visible once this filter is applied?
  bool isVisible(String symbol);

  /// `true`, if this filter is known to be empty.
  ///
  /// The filter might be empty when applied against a set of known symbols.
  /// This is only true, if it's trivial to determine that the filter is empty.
  bool get isTriviallyEmpty;

  factory NamespaceFilter.fromJson(Map<String, dynamic> json) {
    final filter = switch (json['filterKind']) {
      'show' => NamespaceShowFilter.fromJson(json),
      'hide' => NamespaceHideFilter.fromJson(json),
      _ => null,
    };
    if (filter == null) {
      throw StateError('Invalid filterKind.');
    }
    return filter;
  }

  Map<String, dynamic> _toJson();

  Map<String, dynamic> toJson() {
    final json = _toJson();
    json['filterKind'] = switch (this) {
      NamespaceShowFilter _ => 'show',
      NamespaceHideFilter _ => 'hide',
    };
    return json;
  }
}

/// Filter on an imported/exported namespace on the form `show foo, bar, ...`
@JsonSerializable(explicitToJson: true)
final class NamespaceShowFilter extends NamespaceFilter {
  Set<String> get show => UnmodifiableSetView(_show);
  final Set<String> _show;

  factory NamespaceShowFilter._nothing() => const NamespaceShowFilter._({});

  factory NamespaceShowFilter(Set<String> show) {
    if (show.isEmpty) {
      return NamespaceShowFilter._nothing();
    }
    return NamespaceShowFilter._(show);
  }
  const NamespaceShowFilter._(this._show);

  @override
  NamespaceFilter applyFilter(NamespaceFilter other) {
    switch (other) {
      case NamespaceShowFilter other:
        final intersection = _show.intersection(other._show);
        if (intersection.length == _show.length) {
          // If nothings are the same, then there is no need to create a new
          // NamespaceShowFilter object, we can just return this one!
          return this;
        }
        if (intersection.length == other._show.length) {
          return other;
        }
        return NamespaceShowFilter(intersection);
      case NamespaceHideFilter other:
        final difference = _show.difference(other._hide);
        if (difference.length == _show.length) {
          return this;
        }
        return NamespaceShowFilter(difference);
    }
  }

  @override
  NamespaceFilter mergeFilter(NamespaceFilter other) {
    switch (other) {
      case NamespaceShowFilter other:
        final union = _show.union(other._show);
        if (union.length == _show.length) {
          return this;
        }
        if (union.length == other.show.length) {
          return other;
        }
        return NamespaceShowFilter(union);
      case NamespaceHideFilter other:
        final difference = other._hide.difference(_show);
        if (difference.length == other._hide.length) {
          return other;
        }
        return NamespaceHideFilter(difference);
    }
  }

  @override
  bool isVisible(String symbol) => _show.contains(symbol);

  @override
  bool get isTriviallyEmpty => _show.isEmpty;

  factory NamespaceShowFilter.fromJson(Map<String, dynamic> json) =>
      _$NamespaceShowFilterFromJson(json);

  @override
  Map<String, dynamic> _toJson() => _$NamespaceShowFilterToJson(this);
}

/// Filter on an imported/exported namespace on the form `hide foo, bar, ...`
@JsonSerializable(explicitToJson: true)
final class NamespaceHideFilter extends NamespaceFilter {
  Set<String> get hide => UnmodifiableSetView(_hide);
  final Set<String> _hide;

  factory NamespaceHideFilter._everything() => const NamespaceHideFilter._({});

  factory NamespaceHideFilter(Set<String> hide) {
    if (hide.isEmpty) {
      return NamespaceHideFilter._everything();
    }
    return NamespaceHideFilter._(hide);
  }

  const NamespaceHideFilter._(this._hide);

  @override
  NamespaceFilter applyFilter(NamespaceFilter other) {
    switch (other) {
      case NamespaceShowFilter other:
        final difference = other._show.difference(_hide);
        if (difference.length == other._show.length) {
          return other;
        }
        return NamespaceShowFilter(difference);
      case NamespaceHideFilter other:
        final union = _hide.union(other._hide);
        if (union.length == _hide.length) {
          return this;
        }
        if (union.length == other._hide.length) {
          return other;
        }
        return NamespaceHideFilter(union);
    }
  }

  @override
  NamespaceFilter mergeFilter(NamespaceFilter other) {
    switch (other) {
      case NamespaceShowFilter other:
        final difference = _hide.difference(other._show);
        if (difference.length == _hide.length) {
          return this;
        }
        return NamespaceHideFilter(difference);
      case NamespaceHideFilter other:
        final intersection = _hide.intersection(other._hide);
        if (intersection.length == _hide.length) {
          return this;
        }
        if (intersection.length == other._hide.length) {
          return other;
        }
        return NamespaceHideFilter(intersection);
    }
  }

  @override
  bool isVisible(String symbol) => !_hide.contains(symbol);

  @override
  bool get isTriviallyEmpty => false;

  factory NamespaceHideFilter.fromJson(Map<String, dynamic> json) =>
      _$NamespaceHideFilterFromJson(json);

  @override
  Map<String, dynamic> _toJson() => _$NamespaceHideFilterToJson(this);
}

sealed class LibraryMemberShape {
  final String name;

  LibraryMemberShape({
    required this.name,
  });

  factory LibraryMemberShape.fromJson(Map<String, dynamic> json) {
    final member = switch (json['memberKind']) {
      'function' => FunctionShape.fromJson(json),
      'enum' => EnumShape.fromJson(json),
      'class' => ClassShape.fromJson(json),
      'mixin' => MixinShape.fromJson(json),
      'extension' => ExtensionShape.fromJson(json),
      'functionTypeAlias' => FunctionTypeAliasShape.fromJson(json),
      'classTypeAlias' => ClassTypeAliasShape.fromJson(json),
      'variable' => VariableShape.fromJson(json),
      _ => null,
    };
    if (member == null) {
      throw StateError('Invalid memberKind.');
    }
    return member;
  }

  Map<String, dynamic> _toJson();

  Map<String, dynamic> toJson() {
    final json = _toJson();
    json['memberKind'] = switch (this) {
      FunctionShape _ => 'function',
      EnumShape _ => 'enum',
      ClassShape _ => 'class',
      MixinShape _ => 'mixin',
      ExtensionShape _ => 'extension',
      FunctionTypeAliasShape _ => 'functionTypeAlias',
      ClassTypeAliasShape _ => 'classTypeAlias',
      VariableShape _ => 'variable',
    };
    return json;
  }
}

@JsonSerializable(explicitToJson: true)
final class FunctionShape extends LibraryMemberShape {
  final List<PositionalParameterShape> positionalParameters;
  final List<NamedParameterShape> namedParameters;

  FunctionShape({
    required super.name,
    required this.positionalParameters,
    required this.namedParameters,
  });

  factory FunctionShape.fromJson(Map<String, dynamic> json) =>
      _$FunctionShapeFromJson(json);

  @override
  Map<String, dynamic> _toJson() => _$FunctionShapeToJson(this);
}

@JsonSerializable(explicitToJson: true)
final class EnumShape extends LibraryMemberShape {
  EnumShape({required super.name});

  factory EnumShape.fromJson(Map<String, dynamic> json) =>
      _$EnumShapeFromJson(json);

  @override
  Map<String, dynamic> _toJson() => _$EnumShapeToJson(this);
}

@JsonSerializable(explicitToJson: true)
final class ClassShape extends LibraryMemberShape {
  ClassShape({required super.name});

  factory ClassShape.fromJson(Map<String, dynamic> json) =>
      _$ClassShapeFromJson(json);

  @override
  Map<String, dynamic> _toJson() => _$ClassShapeToJson(this);
}

@JsonSerializable(explicitToJson: true)
final class MixinShape extends LibraryMemberShape {
  MixinShape({required super.name});

  factory MixinShape.fromJson(Map<String, dynamic> json) =>
      _$MixinShapeFromJson(json);

  @override
  Map<String, dynamic> _toJson() => _$MixinShapeToJson(this);
}

@JsonSerializable(explicitToJson: true)
final class ExtensionShape extends LibraryMemberShape {
  ExtensionShape({required super.name});

  factory ExtensionShape.fromJson(Map<String, dynamic> json) =>
      _$ExtensionShapeFromJson(json);

  @override
  Map<String, dynamic> _toJson() => _$ExtensionShapeToJson(this);
}

@JsonSerializable(explicitToJson: true)
final class FunctionTypeAliasShape extends LibraryMemberShape {
  FunctionTypeAliasShape({required super.name});

  factory FunctionTypeAliasShape.fromJson(Map<String, dynamic> json) =>
      _$FunctionTypeAliasShapeFromJson(json);

  @override
  Map<String, dynamic> _toJson() => _$FunctionTypeAliasShapeToJson(this);
}

@JsonSerializable(explicitToJson: true)
final class ClassTypeAliasShape extends LibraryMemberShape {
  ClassTypeAliasShape({required super.name});

  factory ClassTypeAliasShape.fromJson(Map<String, dynamic> json) =>
      _$ClassTypeAliasShapeFromJson(json);

  @override
  Map<String, dynamic> _toJson() => _$ClassTypeAliasShapeToJson(this);
}

@JsonSerializable(explicitToJson: true)
final class VariableShape extends LibraryMemberShape {
  final bool hasGetter;
  final bool hasSetter;

  VariableShape({
    required super.name,
    required this.hasGetter,
    required this.hasSetter,
  });

  factory VariableShape.fromJson(Map<String, dynamic> json) =>
      _$VariableShapeFromJson(json);

  @override
  Map<String, dynamic> _toJson() => _$VariableShapeToJson(this);
}

@JsonSerializable(explicitToJson: true)
final class PositionalParameterShape {
  final bool isOptional;

  PositionalParameterShape({
    required this.isOptional,
  });

  factory PositionalParameterShape.fromJson(Map<String, dynamic> json) =>
      _$PositionalParameterShapeFromJson(json);
  Map<String, dynamic> toJson() => _$PositionalParameterShapeToJson(this);
}

@JsonSerializable(explicitToJson: true)
final class NamedParameterShape {
  final String name;
  final bool isRequired;

  NamedParameterShape({
    required this.name,
    required this.isRequired,
  });

  factory NamedParameterShape.fromJson(Map<String, dynamic> json) =>
      _$NamedParameterShapeFromJson(json);
  Map<String, dynamic> toJson() => _$NamedParameterShapeToJson(this);
}

extension LibraryMemberShapeGetters on LibraryMemberShape {
  bool get isPrivate => name.startsWith('_');
}
