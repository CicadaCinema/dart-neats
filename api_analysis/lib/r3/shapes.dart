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

import 'package:pub_semver/pub_semver.dart';

class PackageShape {
  final String name;
  final Version version;
  final Map<Uri, LibraryShape> libraries = {};

  PackageShape({
    required this.name,
    required this.version,
  });

  Map<String, Object?> toJsonSummary() => {
        'libraries': libraries.values.map((l) => l.toJsonSummary()).toList(),
      };
}

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

  Map<String, Object?> toJsonSummary() => {
        'uri': uri,
        'exportedNames': exportedShapes.keys.toList(),
      };
}

/// A filter on an imported namespace in the form of `show ... hide ...`.
sealed class NamespaceFilter {
  NamespaceFilter();

  /// A filter that shows everything in a namespace.
  ///
  /// In other words a [NamespaceHideFilter] that doesn't hide anything.
  factory NamespaceFilter.everything() => NamespaceHideFilter({});

  /// A filter that shows nothing from a namespace.
  ///
  /// In other words a [NamespaceShowFilter] that doesn't show anything.
  factory NamespaceFilter.nothing() => NamespaceShowFilter({});

  /// Apply a further filter.
  NamespaceFilter applyFilter(NamespaceFilter other);

  /// Create a filter that represents both filters applied in parallel.
  NamespaceFilter mergeFilter(NamespaceFilter other);

  /// Is [symbol] visible once this filter is applied?
  bool isVisible(String symbol);

  /// `true`, if this filter is known to be empty.
  ///
  /// The filter might be empty when applied against a set of known symbols.
  /// This is only true, if it's trivial to determine that the filter is empty.
  bool get isTriviallyEmpty;
}

/// Filter on an imported/exported namespace on the form `show foo, bar, ...`
final class NamespaceShowFilter extends NamespaceFilter {
  final Set<String> show;

  NamespaceShowFilter(this.show);

  @override
  NamespaceFilter applyFilter(NamespaceFilter other) => switch (other) {
        (NamespaceShowFilter other) =>
          NamespaceShowFilter(show.intersection(other.show)),
        (NamespaceHideFilter other) =>
          NamespaceShowFilter(show.difference(other.hide)),
      };

  @override
  NamespaceFilter mergeFilter(NamespaceFilter other) => switch (other) {
        (NamespaceShowFilter other) =>
          NamespaceShowFilter(show.union(other.show)),
        (NamespaceHideFilter other) =>
          NamespaceHideFilter(other.hide.difference(show)),
      };

  @override
  bool isVisible(String symbol) => show.contains(symbol);

  @override
  bool get isTriviallyEmpty => show.isEmpty;
}

/// Filter on an imported/exported namespace on the form `hide foo, bar, ...`
final class NamespaceHideFilter extends NamespaceFilter {
  final Set<String> hide;

  NamespaceHideFilter(this.hide);

  @override
  NamespaceFilter applyFilter(NamespaceFilter other) => switch (other) {
        (NamespaceShowFilter other) =>
          NamespaceShowFilter(other.show.difference(hide)),
        (NamespaceHideFilter other) =>
          NamespaceHideFilter(hide.union(other.hide)),
      };

  @override
  NamespaceFilter mergeFilter(NamespaceFilter other) => switch (other) {
        (NamespaceShowFilter other) =>
          NamespaceHideFilter(hide.difference(other.show)),
        (NamespaceHideFilter other) =>
          NamespaceHideFilter(hide.intersection(other.hide)),
      };

  @override
  bool isVisible(String symbol) => !hide.contains(symbol);

  @override
  bool get isTriviallyEmpty => false;
}

sealed class LibraryMemberShape {
  final String name;

  LibraryMemberShape({
    required this.name,
  });

  bool equals(LibraryMemberShape other);
}

final class FunctionShape extends LibraryMemberShape {
  final List<PositionalParameterShape> positionalParameters;
  final List<NamedParameterShape> namedParameters;

  FunctionShape({
    required super.name,
    required this.positionalParameters,
    required this.namedParameters,
  });

  @override
  bool equals(LibraryMemberShape other) =>
      other is FunctionShape &&
      name == other.name &&
      positionalParameters.length == other.positionalParameters.length &&
      namedParameters.length == other.namedParameters.length &&
      positionalParameters.indexed
          .every((r) => r.$2.equals(other.positionalParameters[r.$1])) &&
      namedParameters.indexed
          .every((r) => r.$2.equals(other.namedParameters[r.$1]));
}

final class EnumShape extends LibraryMemberShape {
  EnumShape({required super.name});

  @override
  bool equals(LibraryMemberShape other) =>
      other is EnumShape && name == other.name;
}

final class ClassShape extends LibraryMemberShape {
  ClassShape({required super.name});

  @override
  bool equals(LibraryMemberShape other) =>
      other is ClassShape && name == other.name;
}

final class MixinShape extends LibraryMemberShape {
  MixinShape({required super.name});

  @override
  bool equals(LibraryMemberShape other) =>
      other is MixinShape && name == other.name;
}

final class ExtensionShape extends LibraryMemberShape {
  ExtensionShape({required super.name});

  @override
  bool equals(LibraryMemberShape other) =>
      other is ExtensionShape && name == other.name;
}

final class FunctionTypeAliasShape extends LibraryMemberShape {
  FunctionTypeAliasShape({required super.name});

  @override
  bool equals(LibraryMemberShape other) =>
      other is FunctionTypeAliasShape && name == other.name;
}

final class ClassTypeAliasShape extends LibraryMemberShape {
  ClassTypeAliasShape({required super.name});

  @override
  bool equals(LibraryMemberShape other) =>
      other is ClassTypeAliasShape && name == other.name;
}

final class VariableShape extends LibraryMemberShape {
  final bool hasGetter;
  final bool hasSetter;

  VariableShape({
    required super.name,
    required this.hasGetter,
    required this.hasSetter,
  });

  @override
  bool equals(LibraryMemberShape other) =>
      other is VariableShape &&
      name == other.name &&
      hasGetter == other.hasGetter &&
      hasSetter == other.hasSetter;
}

final class PositionalParameterShape {
  final bool isOptional;

  PositionalParameterShape({
    required this.isOptional,
  });

  bool equals(PositionalParameterShape other) => isOptional == other.isOptional;
}

final class NamedParameterShape {
  final String name;
  final bool isRequired;

  NamedParameterShape({
    required this.name,
    required this.isRequired,
  });

  bool equals(NamedParameterShape other) =>
      name == other.name && isRequired == other.isRequired;
}

extension LibraryMemberShapeGetters on LibraryMemberShape {
  bool get isPrivate => name.startsWith('_');
}
