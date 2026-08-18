///|
fn field_type_name(field_type : FieldType) -> String {
  match field_type {
    Text => "text"
    Numeric => "numeric"
    Date => "date"
    Geo => "geo"
    ArrayText => "array_text"
  }
}

///|
fn value_type_matches(value : FieldValue, expected : FieldType) -> Bool {
  match (value, expected) {
    (StringVal(_), Text) => true
    (IntVal(_), Numeric) => true
    (DoubleVal(_), Numeric) => true
    (DateVal(_), Date) => true
    (GeoVal(_, _), Geo) => true
    (ArrayVal(_), ArrayText) => true
    _ => false
  }
}

///|
fn invalid_geo(value : FieldValue) -> Bool {
  match value {
    GeoVal(latitude, longitude) =>
      latitude < -90.0 ||
      latitude > 90.0 ||
      longitude < -180.0 ||
      longitude > 180.0
    _ => false
  }
}

///|
/// Validate a record against its schema and report every independent issue.
pub fn validate_record(
  schema : Schema,
  record : Record,
) -> Array[ValidationIssue] {
  let issues : Array[ValidationIssue] = []
  if record.id.is_empty() {
    issues.push(
      ValidationIssue::new(
        "missing_id",
        "id",
        "record identifier must not be empty",
        Error,
      ),
    )
  }
  for field in schema.fields {
    let value = record.get_field(field.name)
    if field.required && value.is_null() {
      issues.push(
        ValidationIssue::new(
          "missing_required_field",
          field.name,
          "required field is missing or empty",
          Error,
        ),
      )
    } else if !value.is_null() && !value_type_matches(value, field.field_type) {
      issues.push(
        ValidationIssue::new(
          "field_type_mismatch",
          field.name,
          "expected " + field_type_name(field.field_type),
          Error,
        ),
      )
    } else if !value.is_null() && invalid_geo(value) {
      issues.push(
        ValidationIssue::new(
          "invalid_geo_coordinate",
          field.name,
          "latitude or longitude is outside its legal range",
          Error,
        ),
      )
    }
  }
  issues
}

///|
/// Validate all records and add a duplicate-ID finding for each repeated ID.
pub fn validate_dataset(
  schema : Schema,
  records : Array[Record],
) -> Array[ValidationIssue] {
  let issues : Array[ValidationIssue] = []
  let id_counts : Map[String, Int] = Map([])
  for record in records {
    for issue in validate_record(schema, record) {
      issues.push(issue)
    }
    if !record.id.is_empty() {
      match id_counts.get(record.id) {
        Some(count) => id_counts.set(record.id, count + 1)
        None => id_counts.set(record.id, 1)
      }
    }
  }
  for entry in id_counts {
    if entry.1 > 1 {
      issues.push(
        ValidationIssue::new(
          "duplicate_id",
          "id",
          "identifier appears " + entry.1.to_string() + " times: " + entry.0,
          Warning,
        ),
      )
    }
  }
  issues
}
