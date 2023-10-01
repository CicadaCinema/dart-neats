// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shapes.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PackageShape _$PackageShapeFromJson(Map<String, dynamic> json) =>
    PackageShape._allFields(
      name: json['name'] as String,
      version: _versionFromJson(json['version'] as Object),
      libraries: (json['libraries'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(
            Uri.parse(k), LibraryShape.fromJson(e as Map<String, dynamic>)),
      ),
    );

Map<String, dynamic> _$PackageShapeToJson(PackageShape instance) =>
    <String, dynamic>{
      'name': instance.name,
      'version': _versionToJson(instance.version),
      'libraries':
          instance.libraries.map((k, e) => MapEntry(k.toString(), e.toJson())),
    };

LibraryShape _$LibraryShapeFromJson(Map<String, dynamic> json) =>
    LibraryShape._allFields(
      uri: Uri.parse(json['uri'] as String),
      imports: (json['imports'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(
            k,
            (e as Map<String, dynamic>).map(
              (k, e) => MapEntry(Uri.parse(k),
                  NamespaceFilter.fromJson(e as Map<String, dynamic>)),
            )),
      ),
      exports: (json['exports'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(
            Uri.parse(k), NamespaceFilter.fromJson(e as Map<String, dynamic>)),
      ),
      definedShapes: (json['definedShapes'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, LibraryMemberShape.fromJson(e as Map<String, dynamic>)),
      ),
    );

Map<String, dynamic> _$LibraryShapeToJson(LibraryShape instance) =>
    <String, dynamic>{
      'uri': instance.uri.toString(),
      'imports': instance.imports.map((k, e) =>
          MapEntry(k, e.map((k, e) => MapEntry(k.toString(), e.toJson())))),
      'exports':
          instance.exports.map((k, e) => MapEntry(k.toString(), e.toJson())),
      'definedShapes':
          instance.definedShapes.map((k, e) => MapEntry(k, e.toJson())),
    };

NamespaceShowFilter _$NamespaceShowFilterFromJson(Map<String, dynamic> json) =>
    NamespaceShowFilter(
      (json['show'] as List<dynamic>).map((e) => e as String).toSet(),
    );

Map<String, dynamic> _$NamespaceShowFilterToJson(
        NamespaceShowFilter instance) =>
    <String, dynamic>{
      'show': instance.show.toList(),
    };

NamespaceHideFilter _$NamespaceHideFilterFromJson(Map<String, dynamic> json) =>
    NamespaceHideFilter(
      (json['hide'] as List<dynamic>).map((e) => e as String).toSet(),
    );

Map<String, dynamic> _$NamespaceHideFilterToJson(
        NamespaceHideFilter instance) =>
    <String, dynamic>{
      'hide': instance.hide.toList(),
    };

FunctionShape _$FunctionShapeFromJson(Map<String, dynamic> json) =>
    FunctionShape(
      name: json['name'] as String,
      positionalParameters: (json['positionalParameters'] as List<dynamic>)
          .map((e) =>
              PositionalParameterShape.fromJson(e as Map<String, dynamic>))
          .toList(),
      namedParameters: (json['namedParameters'] as List<dynamic>)
          .map((e) => NamedParameterShape.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$FunctionShapeToJson(FunctionShape instance) =>
    <String, dynamic>{
      'name': instance.name,
      'positionalParameters':
          instance.positionalParameters.map((e) => e.toJson()).toList(),
      'namedParameters':
          instance.namedParameters.map((e) => e.toJson()).toList(),
    };

EnumShape _$EnumShapeFromJson(Map<String, dynamic> json) => EnumShape(
      name: json['name'] as String,
    );

Map<String, dynamic> _$EnumShapeToJson(EnumShape instance) => <String, dynamic>{
      'name': instance.name,
    };

ClassShape _$ClassShapeFromJson(Map<String, dynamic> json) => ClassShape(
      name: json['name'] as String,
    );

Map<String, dynamic> _$ClassShapeToJson(ClassShape instance) =>
    <String, dynamic>{
      'name': instance.name,
    };

MixinShape _$MixinShapeFromJson(Map<String, dynamic> json) => MixinShape(
      name: json['name'] as String,
    );

Map<String, dynamic> _$MixinShapeToJson(MixinShape instance) =>
    <String, dynamic>{
      'name': instance.name,
    };

ExtensionShape _$ExtensionShapeFromJson(Map<String, dynamic> json) =>
    ExtensionShape(
      name: json['name'] as String,
    );

Map<String, dynamic> _$ExtensionShapeToJson(ExtensionShape instance) =>
    <String, dynamic>{
      'name': instance.name,
    };

FunctionTypeAliasShape _$FunctionTypeAliasShapeFromJson(
        Map<String, dynamic> json) =>
    FunctionTypeAliasShape(
      name: json['name'] as String,
    );

Map<String, dynamic> _$FunctionTypeAliasShapeToJson(
        FunctionTypeAliasShape instance) =>
    <String, dynamic>{
      'name': instance.name,
    };

ClassTypeAliasShape _$ClassTypeAliasShapeFromJson(Map<String, dynamic> json) =>
    ClassTypeAliasShape(
      name: json['name'] as String,
    );

Map<String, dynamic> _$ClassTypeAliasShapeToJson(
        ClassTypeAliasShape instance) =>
    <String, dynamic>{
      'name': instance.name,
    };

VariableShape _$VariableShapeFromJson(Map<String, dynamic> json) =>
    VariableShape(
      name: json['name'] as String,
      hasGetter: json['hasGetter'] as bool,
      hasSetter: json['hasSetter'] as bool,
    );

Map<String, dynamic> _$VariableShapeToJson(VariableShape instance) =>
    <String, dynamic>{
      'name': instance.name,
      'hasGetter': instance.hasGetter,
      'hasSetter': instance.hasSetter,
    };

PositionalParameterShape _$PositionalParameterShapeFromJson(
        Map<String, dynamic> json) =>
    PositionalParameterShape(
      isOptional: json['isOptional'] as bool,
    );

Map<String, dynamic> _$PositionalParameterShapeToJson(
        PositionalParameterShape instance) =>
    <String, dynamic>{
      'isOptional': instance.isOptional,
    };

NamedParameterShape _$NamedParameterShapeFromJson(Map<String, dynamic> json) =>
    NamedParameterShape(
      name: json['name'] as String,
      isRequired: json['isRequired'] as bool,
    );

Map<String, dynamic> _$NamedParameterShapeToJson(
        NamedParameterShape instance) =>
    <String, dynamic>{
      'name': instance.name,
      'isRequired': instance.isRequired,
    };
