///|
test "field lineage tracks source coverage and missingness" {
  let crm = Record::new("r1", source="crm")
  crm.set_field("name", StringVal("Alice"))
  let erp = Record::new("r2", source="erp")
  erp.set_field("name", StringVal("Alice"))
  erp.set_field("phone", StringVal("138"))
  let report = build_lineage([crm, erp])
  assert_eq(report.record_count, 2)
  assert_eq(report.source_count, 2)
  assert_eq(report.fields.length(), 2)
  assert_eq(report.fields[0].source_count, 2)
  assert_eq(report.fields[0].missing_count, 0)
  assert_eq(report.fields[1].missing_count, 1)
}

///|
test "field lineage is empty-safe" {
  let report = build_lineage([])
  assert_eq(report.record_count, 0)
  assert_eq(report.source_count, 0)
  assert_true(report.fields.is_empty())
}
