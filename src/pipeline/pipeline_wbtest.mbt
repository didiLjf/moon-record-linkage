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
