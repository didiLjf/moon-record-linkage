///|
pub struct SchemaInferenceReport {
  record_count : Int
  field_count : Int
  required_field_count : Int
  nullable_field_count : Int
  warnings : Array[String]
} derive(Debug, Eq)

///|
pub struct SchemaInferenceResult {
  schema : Schema
  report : SchemaInferenceReport
} derive(Debug)

///|
fn inferred_type(value : FieldValue) -> FieldType {
  match value {
    StringVal(_) => Text
    IntVal(_) => Numeric
    DoubleVal(_) => Numeric
    DateVal(_) => Date
    GeoVal(_, _) => Geo
    ArrayVal(_) => ArrayText
    NullVal => Text
  }
}

///|
fn inferred_type_name(value : FieldValue) -> String {
  match inferred_type(value) {
    Text => "text"
    Numeric => "numeric"
    Date => "date"
    Geo => "geo"
    ArrayText => "array_text"
  }
}

///|
/// Infer a useful schema from observed values while reporting sparse or mixed fields.
pub fn infer_schema(
  records : Array[Record],
  required_ratio? : Double = 1.0,
) -> SchemaInferenceResult {
  let ratio = if required_ratio < 0.0 {
    0.0
  } else if required_ratio > 1.0 {
    1.0
  } else {
    required_ratio
  }
  let field_names : Array[String] = []
  let seen : Map[String, Bool] = Map([])
  for record in records {
    for entry in record.attributes {
      if !seen.contains(entry.0) {
        seen.set(entry.0, true)
        field_names.push(entry.0)
      }
    }
  }
  let schema = Schema::new()
  let warnings : Array[String] = []
  let mut required_field_count = 0
  let mut nullable_field_count = 0
  for field_name in field_names {
    let mut present_count = 0
    let mut chosen_type : FieldType = Text
    let mut chosen_type_name = "text"
    for record in records {
      match record.attributes.get(field_name) {
        Some(value) if !value.is_null() => {
          present_count = present_count + 1
          if present_count == 1 {
            chosen_type = inferred_type(value)
            chosen_type_name = inferred_type_name(value)
          } else if inferred_type_name(value) != chosen_type_name {
            warnings.push("mixed field type for " + field_name)
          }
        }
        _ => ()
      }
    }
    let required = if records.is_empty() {
      false
    } else {
      present_count.to_double() / records.length().to_double() >= ratio
    }
    if required {
      required_field_count = required_field_count + 1
    } else {
      nullable_field_count = nullable_field_count + 1
    }
    schema.add_field(field_name, chosen_type, required~)
  }
  {
    schema,
    report: {
      record_count: records.length(),
      field_count: schema.fields.length(),
      required_field_count,
      nullable_field_count,
      warnings,
    },
  }
}
