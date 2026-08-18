///|
test "paged linker processes every left record exactly once" {
  let config = @core.LinkageConfig::new("paged")
  config.add_blocking(@core.StandardBlocking(["name"]))
  config.add_field_comparison("name", @core.ExactMatch)
  let left : Array[@core.Record] = []
  let right : Array[@core.Record] = []
  for i = 0; i < 5; i = i + 1 {
    let a = @core.Record::new("a" + i.to_string())
    a.set_field("name", @core.StringVal(i.to_string() + "-name"))
    left.push(a)
    let b = @core.Record::new("b" + i.to_string())
    b.set_field("name", @core.StringVal(i.to_string() + "-name"))
    right.push(b)
  }
  let paged = run_paged_link(config, left, right, page_size=2)
  assert_eq(paged.page_count, 3)
  assert_eq(paged.processed_left_records, 5)
  assert_eq(paged.result.match_pairs.length(), 5)
  assert_eq(paged.result.candidate_pair_count, 5)
}

///|
test "paged linker handles empty input and invalid page size" {
  let config = @core.LinkageConfig::new("empty-paged")
  config.add_field_comparison("name", @core.ExactMatch)
  let empty = run_paged_link(config, [], [], page_size=2)
  assert_eq(empty.page_count, 0)
  let invalid = run_paged_link(config, [], [], page_size=0)
  assert_eq(invalid.page_count, 0)
}
