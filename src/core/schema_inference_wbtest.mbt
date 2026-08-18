///|
test "schema inference derives field types and requiredness" {
  let first = Record::new("r1")
  first.set_field("name", StringVal("Alice"))
  first.set_field("age", IntVal(30))
  let second = Record::new("r2")
  second.set_field("name", StringVal("Bob"))
  let inferred = infer_schema([first, second], required_ratio=0.9)
  assert_eq(inferred.schema.fields.length(), 2)
  assert_eq(inferred.schema.fields[0].name, "name")
  assert_true(inferred.schema.fields[0].required)
  assert_eq(inferred.schema.fields[1].field_type, Numeric)
  assert_true(!inferred.schema.fields[1].required)
  assert_eq(inferred.report.field_count, 2)
}

///|
test "schema inference handles empty data and invalid ratio" {
  let empty = infer_schema([], required_ratio=0.5)
  assert_true(empty.schema.fields.is_empty())
  assert_eq(empty.report.record_count, 0)
  let clamped = infer_schema([Record::new("r1")], required_ratio=2.0)
  assert_eq(clamped.report.required_field_count, 0)
}
