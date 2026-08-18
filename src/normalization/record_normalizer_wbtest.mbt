///|
test "record normalizer applies domain rules and preserves non-target fields" {
  let record = @core.Record::new("r1")
  record.set_field("name", @core.StringVal("  ALICE  SMITH  "))
  record.set_field("phone", @core.StringVal("+86 138-1234-5678"))
  record.set_field("score", @core.DoubleVal(9.5))
  let audit = normalize_record(record, [
    FieldRule::new("name", Lowercase),
    FieldRule::new("phone", PhoneDigits),
  ])
  assert_eq(record.get_string("name"), "alice smith")
  assert_eq(record.get_string("phone"), "+8613812345678")
  assert_eq(record.get_double("score"), 9.5)
  assert_eq(audit.length(), 2)
  assert_true(audit[0].changed)
}

///|
test "record normalizer is idempotent and handles missing fields" {
  let record = @core.Record::new("r2")
  record.set_field(
    "company",
    @core.StringVal(" 北京天工创新科技有限公司 "),
  )
  let rules = [FieldRule::new("company", Company)]
  let first = normalize_record(record, rules)
  let second = normalize_record(record, rules)
  assert_true(first[0].changed)
  assert_eq(second[0].normalized, record.get_string("company"))
  assert_true(
    normalize_record(record, [FieldRule::new("missing", Lowercase)])[0].skipped,
  )
}

///|
test "normalizer enumerates rule vocabulary" {
  assert_true(NormalizationRule::supported().length() >= 6)
}
