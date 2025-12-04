// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'treatment_guide.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

TreatmentGuide _$TreatmentGuideFromJson(Map<String, dynamic> json) {
  return _TreatmentGuide.fromJson(json);
}

/// @nodoc
mixin _$TreatmentGuide {
  String get plantId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  List<GuideStep> get steps => throw _privateConstructorUsedError;
  Map<String, String> get schedule => throw _privateConstructorUsedError;
  int get totalSteps => throw _privateConstructorUsedError;
  int get estimatedTotalTime => throw _privateConstructorUsedError;

  /// Serializes this TreatmentGuide to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TreatmentGuide
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TreatmentGuideCopyWith<TreatmentGuide> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TreatmentGuideCopyWith<$Res> {
  factory $TreatmentGuideCopyWith(
    TreatmentGuide value,
    $Res Function(TreatmentGuide) then,
  ) = _$TreatmentGuideCopyWithImpl<$Res, TreatmentGuide>;
  @useResult
  $Res call({
    String plantId,
    String title,
    List<GuideStep> steps,
    Map<String, String> schedule,
    int totalSteps,
    int estimatedTotalTime,
  });
}

/// @nodoc
class _$TreatmentGuideCopyWithImpl<$Res, $Val extends TreatmentGuide>
    implements $TreatmentGuideCopyWith<$Res> {
  _$TreatmentGuideCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TreatmentGuide
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? plantId = null,
    Object? title = null,
    Object? steps = null,
    Object? schedule = null,
    Object? totalSteps = null,
    Object? estimatedTotalTime = null,
  }) {
    return _then(
      _value.copyWith(
            plantId: null == plantId
                ? _value.plantId
                : plantId // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            steps: null == steps
                ? _value.steps
                : steps // ignore: cast_nullable_to_non_nullable
                      as List<GuideStep>,
            schedule: null == schedule
                ? _value.schedule
                : schedule // ignore: cast_nullable_to_non_nullable
                      as Map<String, String>,
            totalSteps: null == totalSteps
                ? _value.totalSteps
                : totalSteps // ignore: cast_nullable_to_non_nullable
                      as int,
            estimatedTotalTime: null == estimatedTotalTime
                ? _value.estimatedTotalTime
                : estimatedTotalTime // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TreatmentGuideImplCopyWith<$Res>
    implements $TreatmentGuideCopyWith<$Res> {
  factory _$$TreatmentGuideImplCopyWith(
    _$TreatmentGuideImpl value,
    $Res Function(_$TreatmentGuideImpl) then,
  ) = __$$TreatmentGuideImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String plantId,
    String title,
    List<GuideStep> steps,
    Map<String, String> schedule,
    int totalSteps,
    int estimatedTotalTime,
  });
}

/// @nodoc
class __$$TreatmentGuideImplCopyWithImpl<$Res>
    extends _$TreatmentGuideCopyWithImpl<$Res, _$TreatmentGuideImpl>
    implements _$$TreatmentGuideImplCopyWith<$Res> {
  __$$TreatmentGuideImplCopyWithImpl(
    _$TreatmentGuideImpl _value,
    $Res Function(_$TreatmentGuideImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TreatmentGuide
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? plantId = null,
    Object? title = null,
    Object? steps = null,
    Object? schedule = null,
    Object? totalSteps = null,
    Object? estimatedTotalTime = null,
  }) {
    return _then(
      _$TreatmentGuideImpl(
        plantId: null == plantId
            ? _value.plantId
            : plantId // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        steps: null == steps
            ? _value._steps
            : steps // ignore: cast_nullable_to_non_nullable
                  as List<GuideStep>,
        schedule: null == schedule
            ? _value._schedule
            : schedule // ignore: cast_nullable_to_non_nullable
                  as Map<String, String>,
        totalSteps: null == totalSteps
            ? _value.totalSteps
            : totalSteps // ignore: cast_nullable_to_non_nullable
                  as int,
        estimatedTotalTime: null == estimatedTotalTime
            ? _value.estimatedTotalTime
            : estimatedTotalTime // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TreatmentGuideImpl implements _TreatmentGuide {
  _$TreatmentGuideImpl({
    required this.plantId,
    required this.title,
    required final List<GuideStep> steps,
    required final Map<String, String> schedule,
    this.totalSteps = 0,
    this.estimatedTotalTime = 0,
  }) : _steps = steps,
       _schedule = schedule;

  factory _$TreatmentGuideImpl.fromJson(Map<String, dynamic> json) =>
      _$$TreatmentGuideImplFromJson(json);

  @override
  final String plantId;
  @override
  final String title;
  final List<GuideStep> _steps;
  @override
  List<GuideStep> get steps {
    if (_steps is EqualUnmodifiableListView) return _steps;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_steps);
  }

  final Map<String, String> _schedule;
  @override
  Map<String, String> get schedule {
    if (_schedule is EqualUnmodifiableMapView) return _schedule;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_schedule);
  }

  @override
  @JsonKey()
  final int totalSteps;
  @override
  @JsonKey()
  final int estimatedTotalTime;

  @override
  String toString() {
    return 'TreatmentGuide(plantId: $plantId, title: $title, steps: $steps, schedule: $schedule, totalSteps: $totalSteps, estimatedTotalTime: $estimatedTotalTime)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TreatmentGuideImpl &&
            (identical(other.plantId, plantId) || other.plantId == plantId) &&
            (identical(other.title, title) || other.title == title) &&
            const DeepCollectionEquality().equals(other._steps, _steps) &&
            const DeepCollectionEquality().equals(other._schedule, _schedule) &&
            (identical(other.totalSteps, totalSteps) ||
                other.totalSteps == totalSteps) &&
            (identical(other.estimatedTotalTime, estimatedTotalTime) ||
                other.estimatedTotalTime == estimatedTotalTime));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    plantId,
    title,
    const DeepCollectionEquality().hash(_steps),
    const DeepCollectionEquality().hash(_schedule),
    totalSteps,
    estimatedTotalTime,
  );

  /// Create a copy of TreatmentGuide
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TreatmentGuideImplCopyWith<_$TreatmentGuideImpl> get copyWith =>
      __$$TreatmentGuideImplCopyWithImpl<_$TreatmentGuideImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$TreatmentGuideImplToJson(this);
  }
}

abstract class _TreatmentGuide implements TreatmentGuide {
  factory _TreatmentGuide({
    required final String plantId,
    required final String title,
    required final List<GuideStep> steps,
    required final Map<String, String> schedule,
    final int totalSteps,
    final int estimatedTotalTime,
  }) = _$TreatmentGuideImpl;

  factory _TreatmentGuide.fromJson(Map<String, dynamic> json) =
      _$TreatmentGuideImpl.fromJson;

  @override
  String get plantId;
  @override
  String get title;
  @override
  List<GuideStep> get steps;
  @override
  Map<String, String> get schedule;
  @override
  int get totalSteps;
  @override
  int get estimatedTotalTime;

  /// Create a copy of TreatmentGuide
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TreatmentGuideImplCopyWith<_$TreatmentGuideImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

GuideStep _$GuideStepFromJson(Map<String, dynamic> json) {
  return _GuideStep.fromJson(json);
}

/// @nodoc
mixin _$GuideStep {
  int get step => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  int get durationMinutes => throw _privateConstructorUsedError;
  List<String> get materials => throw _privateConstructorUsedError;
  String? get imageUrl => throw _privateConstructorUsedError;
  String get tips => throw _privateConstructorUsedError;
  bool get isCompleted => throw _privateConstructorUsedError;

  /// Serializes this GuideStep to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GuideStep
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GuideStepCopyWith<GuideStep> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GuideStepCopyWith<$Res> {
  factory $GuideStepCopyWith(GuideStep value, $Res Function(GuideStep) then) =
      _$GuideStepCopyWithImpl<$Res, GuideStep>;
  @useResult
  $Res call({
    int step,
    String title,
    String description,
    int durationMinutes,
    List<String> materials,
    String? imageUrl,
    String tips,
    bool isCompleted,
  });
}

/// @nodoc
class _$GuideStepCopyWithImpl<$Res, $Val extends GuideStep>
    implements $GuideStepCopyWith<$Res> {
  _$GuideStepCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GuideStep
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? step = null,
    Object? title = null,
    Object? description = null,
    Object? durationMinutes = null,
    Object? materials = null,
    Object? imageUrl = freezed,
    Object? tips = null,
    Object? isCompleted = null,
  }) {
    return _then(
      _value.copyWith(
            step: null == step
                ? _value.step
                : step // ignore: cast_nullable_to_non_nullable
                      as int,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
            durationMinutes: null == durationMinutes
                ? _value.durationMinutes
                : durationMinutes // ignore: cast_nullable_to_non_nullable
                      as int,
            materials: null == materials
                ? _value.materials
                : materials // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            imageUrl: freezed == imageUrl
                ? _value.imageUrl
                : imageUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            tips: null == tips
                ? _value.tips
                : tips // ignore: cast_nullable_to_non_nullable
                      as String,
            isCompleted: null == isCompleted
                ? _value.isCompleted
                : isCompleted // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$GuideStepImplCopyWith<$Res>
    implements $GuideStepCopyWith<$Res> {
  factory _$$GuideStepImplCopyWith(
    _$GuideStepImpl value,
    $Res Function(_$GuideStepImpl) then,
  ) = __$$GuideStepImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int step,
    String title,
    String description,
    int durationMinutes,
    List<String> materials,
    String? imageUrl,
    String tips,
    bool isCompleted,
  });
}

/// @nodoc
class __$$GuideStepImplCopyWithImpl<$Res>
    extends _$GuideStepCopyWithImpl<$Res, _$GuideStepImpl>
    implements _$$GuideStepImplCopyWith<$Res> {
  __$$GuideStepImplCopyWithImpl(
    _$GuideStepImpl _value,
    $Res Function(_$GuideStepImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GuideStep
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? step = null,
    Object? title = null,
    Object? description = null,
    Object? durationMinutes = null,
    Object? materials = null,
    Object? imageUrl = freezed,
    Object? tips = null,
    Object? isCompleted = null,
  }) {
    return _then(
      _$GuideStepImpl(
        step: null == step
            ? _value.step
            : step // ignore: cast_nullable_to_non_nullable
                  as int,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        durationMinutes: null == durationMinutes
            ? _value.durationMinutes
            : durationMinutes // ignore: cast_nullable_to_non_nullable
                  as int,
        materials: null == materials
            ? _value._materials
            : materials // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        imageUrl: freezed == imageUrl
            ? _value.imageUrl
            : imageUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        tips: null == tips
            ? _value.tips
            : tips // ignore: cast_nullable_to_non_nullable
                  as String,
        isCompleted: null == isCompleted
            ? _value.isCompleted
            : isCompleted // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$GuideStepImpl implements _GuideStep {
  _$GuideStepImpl({
    required this.step,
    required this.title,
    required this.description,
    this.durationMinutes = 0,
    final List<String> materials = const [],
    this.imageUrl,
    this.tips = '',
    this.isCompleted = false,
  }) : _materials = materials;

  factory _$GuideStepImpl.fromJson(Map<String, dynamic> json) =>
      _$$GuideStepImplFromJson(json);

  @override
  final int step;
  @override
  final String title;
  @override
  final String description;
  @override
  @JsonKey()
  final int durationMinutes;
  final List<String> _materials;
  @override
  @JsonKey()
  List<String> get materials {
    if (_materials is EqualUnmodifiableListView) return _materials;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_materials);
  }

  @override
  final String? imageUrl;
  @override
  @JsonKey()
  final String tips;
  @override
  @JsonKey()
  final bool isCompleted;

  @override
  String toString() {
    return 'GuideStep(step: $step, title: $title, description: $description, durationMinutes: $durationMinutes, materials: $materials, imageUrl: $imageUrl, tips: $tips, isCompleted: $isCompleted)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GuideStepImpl &&
            (identical(other.step, step) || other.step == step) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.durationMinutes, durationMinutes) ||
                other.durationMinutes == durationMinutes) &&
            const DeepCollectionEquality().equals(
              other._materials,
              _materials,
            ) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.tips, tips) || other.tips == tips) &&
            (identical(other.isCompleted, isCompleted) ||
                other.isCompleted == isCompleted));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    step,
    title,
    description,
    durationMinutes,
    const DeepCollectionEquality().hash(_materials),
    imageUrl,
    tips,
    isCompleted,
  );

  /// Create a copy of GuideStep
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GuideStepImplCopyWith<_$GuideStepImpl> get copyWith =>
      __$$GuideStepImplCopyWithImpl<_$GuideStepImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GuideStepImplToJson(this);
  }
}

abstract class _GuideStep implements GuideStep {
  factory _GuideStep({
    required final int step,
    required final String title,
    required final String description,
    final int durationMinutes,
    final List<String> materials,
    final String? imageUrl,
    final String tips,
    final bool isCompleted,
  }) = _$GuideStepImpl;

  factory _GuideStep.fromJson(Map<String, dynamic> json) =
      _$GuideStepImpl.fromJson;

  @override
  int get step;
  @override
  String get title;
  @override
  String get description;
  @override
  int get durationMinutes;
  @override
  List<String> get materials;
  @override
  String? get imageUrl;
  @override
  String get tips;
  @override
  bool get isCompleted;

  /// Create a copy of GuideStep
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GuideStepImplCopyWith<_$GuideStepImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DiseaseGuide _$DiseaseGuideFromJson(Map<String, dynamic> json) {
  return _DiseaseGuide.fromJson(json);
}

/// @nodoc
mixin _$DiseaseGuide {
  String get diseaseName => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  List<GuideStep> get steps => throw _privateConstructorUsedError;
  List<String> get preventiveMeasures => throw _privateConstructorUsedError;
  List<String> get recommendedTreatments => throw _privateConstructorUsedError;

  /// Serializes this DiseaseGuide to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DiseaseGuide
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DiseaseGuideCopyWith<DiseaseGuide> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DiseaseGuideCopyWith<$Res> {
  factory $DiseaseGuideCopyWith(
    DiseaseGuide value,
    $Res Function(DiseaseGuide) then,
  ) = _$DiseaseGuideCopyWithImpl<$Res, DiseaseGuide>;
  @useResult
  $Res call({
    String diseaseName,
    String title,
    String description,
    List<GuideStep> steps,
    List<String> preventiveMeasures,
    List<String> recommendedTreatments,
  });
}

/// @nodoc
class _$DiseaseGuideCopyWithImpl<$Res, $Val extends DiseaseGuide>
    implements $DiseaseGuideCopyWith<$Res> {
  _$DiseaseGuideCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DiseaseGuide
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? diseaseName = null,
    Object? title = null,
    Object? description = null,
    Object? steps = null,
    Object? preventiveMeasures = null,
    Object? recommendedTreatments = null,
  }) {
    return _then(
      _value.copyWith(
            diseaseName: null == diseaseName
                ? _value.diseaseName
                : diseaseName // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
            steps: null == steps
                ? _value.steps
                : steps // ignore: cast_nullable_to_non_nullable
                      as List<GuideStep>,
            preventiveMeasures: null == preventiveMeasures
                ? _value.preventiveMeasures
                : preventiveMeasures // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            recommendedTreatments: null == recommendedTreatments
                ? _value.recommendedTreatments
                : recommendedTreatments // ignore: cast_nullable_to_non_nullable
                      as List<String>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DiseaseGuideImplCopyWith<$Res>
    implements $DiseaseGuideCopyWith<$Res> {
  factory _$$DiseaseGuideImplCopyWith(
    _$DiseaseGuideImpl value,
    $Res Function(_$DiseaseGuideImpl) then,
  ) = __$$DiseaseGuideImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String diseaseName,
    String title,
    String description,
    List<GuideStep> steps,
    List<String> preventiveMeasures,
    List<String> recommendedTreatments,
  });
}

/// @nodoc
class __$$DiseaseGuideImplCopyWithImpl<$Res>
    extends _$DiseaseGuideCopyWithImpl<$Res, _$DiseaseGuideImpl>
    implements _$$DiseaseGuideImplCopyWith<$Res> {
  __$$DiseaseGuideImplCopyWithImpl(
    _$DiseaseGuideImpl _value,
    $Res Function(_$DiseaseGuideImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DiseaseGuide
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? diseaseName = null,
    Object? title = null,
    Object? description = null,
    Object? steps = null,
    Object? preventiveMeasures = null,
    Object? recommendedTreatments = null,
  }) {
    return _then(
      _$DiseaseGuideImpl(
        diseaseName: null == diseaseName
            ? _value.diseaseName
            : diseaseName // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        steps: null == steps
            ? _value._steps
            : steps // ignore: cast_nullable_to_non_nullable
                  as List<GuideStep>,
        preventiveMeasures: null == preventiveMeasures
            ? _value._preventiveMeasures
            : preventiveMeasures // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        recommendedTreatments: null == recommendedTreatments
            ? _value._recommendedTreatments
            : recommendedTreatments // ignore: cast_nullable_to_non_nullable
                  as List<String>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$DiseaseGuideImpl implements _DiseaseGuide {
  _$DiseaseGuideImpl({
    required this.diseaseName,
    required this.title,
    required this.description,
    required final List<GuideStep> steps,
    required final List<String> preventiveMeasures,
    required final List<String> recommendedTreatments,
  }) : _steps = steps,
       _preventiveMeasures = preventiveMeasures,
       _recommendedTreatments = recommendedTreatments;

  factory _$DiseaseGuideImpl.fromJson(Map<String, dynamic> json) =>
      _$$DiseaseGuideImplFromJson(json);

  @override
  final String diseaseName;
  @override
  final String title;
  @override
  final String description;
  final List<GuideStep> _steps;
  @override
  List<GuideStep> get steps {
    if (_steps is EqualUnmodifiableListView) return _steps;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_steps);
  }

  final List<String> _preventiveMeasures;
  @override
  List<String> get preventiveMeasures {
    if (_preventiveMeasures is EqualUnmodifiableListView)
      return _preventiveMeasures;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_preventiveMeasures);
  }

  final List<String> _recommendedTreatments;
  @override
  List<String> get recommendedTreatments {
    if (_recommendedTreatments is EqualUnmodifiableListView)
      return _recommendedTreatments;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_recommendedTreatments);
  }

  @override
  String toString() {
    return 'DiseaseGuide(diseaseName: $diseaseName, title: $title, description: $description, steps: $steps, preventiveMeasures: $preventiveMeasures, recommendedTreatments: $recommendedTreatments)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DiseaseGuideImpl &&
            (identical(other.diseaseName, diseaseName) ||
                other.diseaseName == diseaseName) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality().equals(other._steps, _steps) &&
            const DeepCollectionEquality().equals(
              other._preventiveMeasures,
              _preventiveMeasures,
            ) &&
            const DeepCollectionEquality().equals(
              other._recommendedTreatments,
              _recommendedTreatments,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    diseaseName,
    title,
    description,
    const DeepCollectionEquality().hash(_steps),
    const DeepCollectionEquality().hash(_preventiveMeasures),
    const DeepCollectionEquality().hash(_recommendedTreatments),
  );

  /// Create a copy of DiseaseGuide
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DiseaseGuideImplCopyWith<_$DiseaseGuideImpl> get copyWith =>
      __$$DiseaseGuideImplCopyWithImpl<_$DiseaseGuideImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DiseaseGuideImplToJson(this);
  }
}

abstract class _DiseaseGuide implements DiseaseGuide {
  factory _DiseaseGuide({
    required final String diseaseName,
    required final String title,
    required final String description,
    required final List<GuideStep> steps,
    required final List<String> preventiveMeasures,
    required final List<String> recommendedTreatments,
  }) = _$DiseaseGuideImpl;

  factory _DiseaseGuide.fromJson(Map<String, dynamic> json) =
      _$DiseaseGuideImpl.fromJson;

  @override
  String get diseaseName;
  @override
  String get title;
  @override
  String get description;
  @override
  List<GuideStep> get steps;
  @override
  List<String> get preventiveMeasures;
  @override
  List<String> get recommendedTreatments;

  /// Create a copy of DiseaseGuide
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DiseaseGuideImplCopyWith<_$DiseaseGuideImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

GuideProgress _$GuideProgressFromJson(Map<String, dynamic> json) {
  return _GuideProgress.fromJson(json);
}

/// @nodoc
mixin _$GuideProgress {
  String get guideId => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  int get currentStep => throw _privateConstructorUsedError;
  List<int> get completedSteps => throw _privateConstructorUsedError;
  bool get isCompleted => throw _privateConstructorUsedError;
  DateTime? get lastUpdated => throw _privateConstructorUsedError;

  /// Serializes this GuideProgress to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GuideProgress
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GuideProgressCopyWith<GuideProgress> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GuideProgressCopyWith<$Res> {
  factory $GuideProgressCopyWith(
    GuideProgress value,
    $Res Function(GuideProgress) then,
  ) = _$GuideProgressCopyWithImpl<$Res, GuideProgress>;
  @useResult
  $Res call({
    String guideId,
    String userId,
    int currentStep,
    List<int> completedSteps,
    bool isCompleted,
    DateTime? lastUpdated,
  });
}

/// @nodoc
class _$GuideProgressCopyWithImpl<$Res, $Val extends GuideProgress>
    implements $GuideProgressCopyWith<$Res> {
  _$GuideProgressCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GuideProgress
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? guideId = null,
    Object? userId = null,
    Object? currentStep = null,
    Object? completedSteps = null,
    Object? isCompleted = null,
    Object? lastUpdated = freezed,
  }) {
    return _then(
      _value.copyWith(
            guideId: null == guideId
                ? _value.guideId
                : guideId // ignore: cast_nullable_to_non_nullable
                      as String,
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            currentStep: null == currentStep
                ? _value.currentStep
                : currentStep // ignore: cast_nullable_to_non_nullable
                      as int,
            completedSteps: null == completedSteps
                ? _value.completedSteps
                : completedSteps // ignore: cast_nullable_to_non_nullable
                      as List<int>,
            isCompleted: null == isCompleted
                ? _value.isCompleted
                : isCompleted // ignore: cast_nullable_to_non_nullable
                      as bool,
            lastUpdated: freezed == lastUpdated
                ? _value.lastUpdated
                : lastUpdated // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$GuideProgressImplCopyWith<$Res>
    implements $GuideProgressCopyWith<$Res> {
  factory _$$GuideProgressImplCopyWith(
    _$GuideProgressImpl value,
    $Res Function(_$GuideProgressImpl) then,
  ) = __$$GuideProgressImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String guideId,
    String userId,
    int currentStep,
    List<int> completedSteps,
    bool isCompleted,
    DateTime? lastUpdated,
  });
}

/// @nodoc
class __$$GuideProgressImplCopyWithImpl<$Res>
    extends _$GuideProgressCopyWithImpl<$Res, _$GuideProgressImpl>
    implements _$$GuideProgressImplCopyWith<$Res> {
  __$$GuideProgressImplCopyWithImpl(
    _$GuideProgressImpl _value,
    $Res Function(_$GuideProgressImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GuideProgress
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? guideId = null,
    Object? userId = null,
    Object? currentStep = null,
    Object? completedSteps = null,
    Object? isCompleted = null,
    Object? lastUpdated = freezed,
  }) {
    return _then(
      _$GuideProgressImpl(
        guideId: null == guideId
            ? _value.guideId
            : guideId // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        currentStep: null == currentStep
            ? _value.currentStep
            : currentStep // ignore: cast_nullable_to_non_nullable
                  as int,
        completedSteps: null == completedSteps
            ? _value._completedSteps
            : completedSteps // ignore: cast_nullable_to_non_nullable
                  as List<int>,
        isCompleted: null == isCompleted
            ? _value.isCompleted
            : isCompleted // ignore: cast_nullable_to_non_nullable
                  as bool,
        lastUpdated: freezed == lastUpdated
            ? _value.lastUpdated
            : lastUpdated // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$GuideProgressImpl implements _GuideProgress {
  _$GuideProgressImpl({
    required this.guideId,
    required this.userId,
    this.currentStep = 1,
    final List<int> completedSteps = const [],
    this.isCompleted = false,
    this.lastUpdated,
  }) : _completedSteps = completedSteps;

  factory _$GuideProgressImpl.fromJson(Map<String, dynamic> json) =>
      _$$GuideProgressImplFromJson(json);

  @override
  final String guideId;
  @override
  final String userId;
  @override
  @JsonKey()
  final int currentStep;
  final List<int> _completedSteps;
  @override
  @JsonKey()
  List<int> get completedSteps {
    if (_completedSteps is EqualUnmodifiableListView) return _completedSteps;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_completedSteps);
  }

  @override
  @JsonKey()
  final bool isCompleted;
  @override
  final DateTime? lastUpdated;

  @override
  String toString() {
    return 'GuideProgress(guideId: $guideId, userId: $userId, currentStep: $currentStep, completedSteps: $completedSteps, isCompleted: $isCompleted, lastUpdated: $lastUpdated)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GuideProgressImpl &&
            (identical(other.guideId, guideId) || other.guideId == guideId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.currentStep, currentStep) ||
                other.currentStep == currentStep) &&
            const DeepCollectionEquality().equals(
              other._completedSteps,
              _completedSteps,
            ) &&
            (identical(other.isCompleted, isCompleted) ||
                other.isCompleted == isCompleted) &&
            (identical(other.lastUpdated, lastUpdated) ||
                other.lastUpdated == lastUpdated));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    guideId,
    userId,
    currentStep,
    const DeepCollectionEquality().hash(_completedSteps),
    isCompleted,
    lastUpdated,
  );

  /// Create a copy of GuideProgress
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GuideProgressImplCopyWith<_$GuideProgressImpl> get copyWith =>
      __$$GuideProgressImplCopyWithImpl<_$GuideProgressImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GuideProgressImplToJson(this);
  }
}

abstract class _GuideProgress implements GuideProgress {
  factory _GuideProgress({
    required final String guideId,
    required final String userId,
    final int currentStep,
    final List<int> completedSteps,
    final bool isCompleted,
    final DateTime? lastUpdated,
  }) = _$GuideProgressImpl;

  factory _GuideProgress.fromJson(Map<String, dynamic> json) =
      _$GuideProgressImpl.fromJson;

  @override
  String get guideId;
  @override
  String get userId;
  @override
  int get currentStep;
  @override
  List<int> get completedSteps;
  @override
  bool get isCompleted;
  @override
  DateTime? get lastUpdated;

  /// Create a copy of GuideProgress
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GuideProgressImplCopyWith<_$GuideProgressImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
