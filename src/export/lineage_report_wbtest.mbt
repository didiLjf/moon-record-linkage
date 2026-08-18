///|
test "lineage report exports preserve field coverage" {
  let left = @core.Record::new("l1", source="crm")
  left.set_field("name", @core.StringVal("Alice"))
  let right = @core.Record::new("r1", source="billing")
  right.set_field("name", @core.StringVal("Alice"))
  right.set_field("email", @core.StringVal("alice@example.com"))
  let report = @core.build_lineage([left, right])
  let json = lineage_report_to_json(report)
  let csv = lineage_report_to_csv(report)
  let markdown = lineage_report_to_markdown(report)
  assert_true(json.contains("\"record_count\":2"))
  assert_true(json.contains("\"name\""))
  assert_true(csv.contains("field,source_count"))
  assert_true(csv.contains("email"))
  assert_true(markdown.contains("| name |"))
}
