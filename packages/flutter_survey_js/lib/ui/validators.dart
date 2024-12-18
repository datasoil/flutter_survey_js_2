import 'package:flutter_survey_js/flutter_survey_js.dart';
import 'package:flutter_survey_js_model/flutter_survey_js_model.dart' as s;
import 'package:reactive_forms/reactive_forms.dart';

/// Validator that requires the control have a non-empty value.
class NonEmptyValidator extends Validator<dynamic> {
  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    final error = <String, dynamic>{ValidationMessage.required: true};
    final v = control.value;
    if (v == null) {
      return error;
    } else if (v is String) {
      return v.trim().isEmpty ? error : null;
    } else if (v is List) {
      return v.isEmpty ? error : null;
    } else if (v is Map<String, Object?>) {
      return removeEmptyField(v).isEmpty ? error : null;
    } else if (v is Map) {
      return v.isEmpty ? error : null;
    }
    return null;
  }
}

class MaxValidator<T> extends Validator<dynamic> {
  final T max;

  /// Constructs the instance of the validator.
  ///
  /// The argument [max] must not be null.
  const MaxValidator(this.max) : super();

  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    final error = {
      ValidationMessage.max: <String, dynamic>{
        'max': max,
        'actual': control.value,
      },
    };

    assert(control.value is Comparable<dynamic>?);

    final comparableValue = control.value as Comparable<dynamic>?;
    return comparableValue == null || comparableValue.compareTo(max) <= 0
        ? null
        : error;
  }
}

class MinValidator<T> extends Validator<dynamic> {
  final T min;

  /// Constructs the instance of the validator.
  ///
  /// The argument [min] must not be null.
  const MinValidator(this.min) : super();

  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    final error = {
      ValidationMessage.min: <String, dynamic>{
        'min': min,
        'actual': control.value,
      },
    };

    assert(control.value is Comparable<dynamic>?);

    final comparableValue = control.value as Comparable<dynamic>?;
    return comparableValue == null || comparableValue.compareTo(min) >= 0
        ? null
        : error;
  }
}

List<Validator> questionToValidators(s.Question question) {
  final res = <Validator>[];
  if (question.isRequired == true) {
    res.add(NonEmptyValidator());
  }
  if (question is s.Text) {
    if (question.min?.oneOf.value.tryCastToNum() != null) {
      res.add(MinValidator(question.min!.oneOf.value.tryCastToNum()));
    }
    if (question.max?.oneOf.value.tryCastToNum() != null) {
      res.add(MaxValidator(question.max!.oneOf.value.tryCastToNum()));
    }
  }

  final validators = question.validators?.map((p) => p.realValidator).toList();
  if (validators != null) {
    for (var value in validators) {
      if (value is s.Numericvalidator) {
        res.add(Validators.number(allowNull: true));
        if (value.maxValue != null) {
          res.add(MaxValidator(value.maxValue));
        }
        if (value.minValue != null) {
          res.add(MinValidator(value.minValue));
        }
      }
      if (value is s.Textvalidator) {
        if (value.maxLength != null) {
          res.add(Validators.maxLength(value.maxLength!.toInt()));
        }
        if (value.minLength != null) {
          res.add(Validators.minLength(value.minLength!.toInt()));
        }
        if (value.allowDigits != null) {
          res.add(Validators.delegate((control) {
            if (control.value is String) {
              if (!value.allowDigits! &&
                  (control.value as String).contains('.')) {
                return {'allowDigits': value.allowDigits};
              }
            }
            return null;
          }));
        }
      }

      if (value is s.Answercountvalidator) {
        if (value.maxCount != null) {
          res.add(Validators.maxLength(value.maxCount!.toInt()));
        }
        if (value.minCount != null) {
          res.add(Validators.minLength(value.minCount!.toInt()));
        }
      }
      if (value is s.Regexvalidator) {
        if (value.regex != null) {
          res.add(Validators.pattern(value.regex!));
        }
      }
      if (value is s.Emailvalidator) {
        res.add(Validators.email);
      }
      if (value is s.Expressionvalidator) {}
    }
  }
  return res;
}
