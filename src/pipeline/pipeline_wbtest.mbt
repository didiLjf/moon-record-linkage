// Pipeline Module Tests

///|
test "batch pipeline basic link" {
  let cfg = @core.LinkageConfig::new("test-linkage")
  cfg.add_field_comparison("name", @core.JaroWinkler, weight=1.0)
  let pipe = BatchPipeline::new(cfg)
  let r1 = @core.Record::new("a1")
  r1.set_field("name", @core.StringVal("Alice Smith"))
  let r2 = @core.Record::new("b1")
  r2.set_field("name", @core.StringVal("Alice Smith"))
  let res = pipe.run_link([r1], [r2])
  assert_eq(res.match_pairs.length(), 1)
  assert_eq(res.match_pairs[0].record_a.id, "a1")
  assert_eq(res.match_pairs[0].record_b.id, "b1")
}

///|
test "batch pipeline non-matching" {
  let cfg = @core.LinkageConfig::new("test-non-matching")
  cfg.add_field_comparison("name", @core.JaroWinkler, weight=1.0)
  let pipe = BatchPipeline::new(cfg)
  let r1 = @core.Record::new("a1")
  r1.set_field("name", @core.StringVal("Alice Smith"))
  let r2 = @core.Record::new("b1")
  r2.set_field("name", @core.StringVal("Bob Jones"))
  let res = pipe.run_link([r1], [r2])
  assert_eq(res.match_pairs.length(), 0)
}

///|
test "batch pipeline deduplication" {
  let cfg = @core.LinkageConfig::new("test-dedup")
  cfg.add_field_comparison("name", @core.JaroWinkler, weight=1.0)
  let pipe = BatchPipeline::new(cfg)
  let r1 = @core.Record::new("r1")
  r1.set_field("name", @core.StringVal("Charlie Brown"))
  let r2 = @core.Record::new("r2")
  r2.set_field("name", @core.StringVal("Charlie Brown"))
  let res = pipe.run_dedup([r1, r2])
  assert_eq(res.match_pairs.length(), 1)
}

///|
test "batch pipeline uses the union of configured blockers" {
  let cfg = @core.LinkageConfig::new("multi-blocking")
  cfg.add_blocking(@core.StandardBlocking(["city"]))
  cfg.add_blocking(@core.StandardBlocking(["name"]))
  cfg.add_field_comparison("name", @core.ExactMatch, weight=1.0)
  let left_one = @core.Record::new("a1")
  left_one.set_field("name", @core.StringVal("Alice"))
  left_one.set_field("city", @core.StringVal("Beijing"))
  let left_two = @core.Record::new("a2")
  left_two.set_field("name", @core.StringVal("Alice"))
  left_two.set_field("city", @core.StringVal("Shanghai"))
  let right_one = @core.Record::new("b1")
  right_one.set_field("name", @core.StringVal("Alice"))
  right_one.set_field("city", @core.StringVal("Beijing"))
  let right_two = @core.Record::new("b2")
  right_two.set_field("name", @core.StringVal("Bob"))
  right_two.set_field("city", @core.StringVal("Shanghai"))
  let result = BatchPipeline::new(cfg).run_link([left_one, left_two], [
    right_one, right_two,
  ])
  assert_eq(result.candidate_pair_count, 3)
  assert_eq(result.match_pairs.length(), 2)
}
