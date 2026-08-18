///|
test "quality validation reports required and type errors" {
  let schema = Schema::new()
  schema.add_field("name", Text, required=true)
  schema.add_field("age", Numeric, required=true)
  let record = Record::new("r1")
  record.set_field("age", StringVal("not-a-number"))
  let issues = validate_record(schema, record)
  assert_eq(issues.length(), 2)
  assert_eq(issues[0].code, "missing_required_field")
  assert_eq(issues[1].code, "field_type_mismatch")
}

///|
test "quality validation handles valid geo and empty values" {
  let schema = Schema::new()
  schema.add_field("location", Geo, required=true)
  let record = Record::new("r2")
  record.set_field("location", GeoVal(31.2, 121.5))
  let issues = validate_record(schema, record)
  assert_true(issues.is_empty())
  let empty = Record::new("")
  let empty_issues = validate_record(schema, empty)
  assert_true(empty_issues.length() >= 2)
}

///|
test "quality profile counts missing, distinct and duplicate ids" {
  let a = Record::new("a", source="crm")
  a.set_field("name", StringVal("Alice"))
  let b = Record::new("a", source="erp")
  b.set_field("name", StringVal("Alice"))
  let c = Record::new("c", source="crm")
  c.set_field("name", StringVal("Bob"))
  let profile = profile_dataset([a, b, c])
  assert_eq(profile.record_count, 3)
  assert_eq(profile.distinct_id_count, 2)
  assert_eq(profile.duplicate_id_count, 1)
  assert_eq(profile.field_profiles.length(), 1)
  assert_eq(profile.field_profiles[0].present_count, 3)
  assert_eq(profile.field_profiles[0].distinct_count, 2)
  assert_eq(profile.source_counts.get("crm"), Some(2))
}

///|
test "quality profile handles empty datasets without division by zero" {
  let profile = profile_dataset([])
  assert_eq(profile.record_count, 0)
  assert_eq(profile.distinct_id_count, 0)
  assert_eq(profile.duplicate_rate(), 0.0)
  assert_true(profile.field_profiles.is_empty())
}

///|
test "diagnostics aggregate severity and render stable output" {
  let report = DiagnosticReport::new()
  report.add(ValidationIssue::new("missing", "name", "name is required", Error))
  report.add(ValidationIssue::new("empty", "city", "city is empty", Warning))
  assert_eq(report.error_count(), 1)
  assert_eq(report.warning_count(), 1)
  assert_true(report.render().has_prefix("errors=1"))
}

///|
test "linkage config validation rejects unsafe thresholds and weights" {
  let invalid_thresholds = LinkageConfig::default()
  invalid_thresholds.set_thresholds(0.4, 0.8)
  assert_true(validate_config(invalid_thresholds) is Err(PipelineError(_)))
  let invalid_weight = LinkageConfig::default()
  invalid_weight.add_field_comparison("name", JaroWinkler, weight=-1.0)
  assert_true(validate_config(invalid_weight) is Err(PipelineError(_)))
}

///|
test "linkage config validation accepts a complete configuration" {
  let config = LinkageConfig::default()
  config.add_blocking(StandardBlocking(["name"]))
  config.add_field_comparison("name", JaroWinkler, weight=1.0)
  config.set_thresholds(0.8, 0.4)
  assert_true(validate_config(config) is Ok(_))
}
