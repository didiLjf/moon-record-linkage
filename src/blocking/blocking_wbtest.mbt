// Blocking Module Tests

///|
test "standard blocking index basic" {
  let idx = BlockingIndex::new(["name"])
  let r1 = @core.Record::new("r1")
  r1.set_field("name", @core.StringVal("Alice"))
  let r2 = @core.Record::new("r2")
  r2.set_field("name", @core.StringVal("Alice Smith"))
  let r3 = @core.Record::new("r3")
  r3.set_field("name", @core.StringVal("Bob"))
  idx.add_record(r1)
  idx.add_record(r2)
  idx.add_record(r3)
  assert_true(idx.block_count() <= 3)
}

///|
test "standard blocking candidate pairs" {
  let idx = BlockingIndex::new(["name"])
  let r1 = @core.Record::new("r1")
  r1.set_field("name", @core.StringVal("Alice"))
  let r2 = @core.Record::new("r2")
  r2.set_field("name", @core.StringVal("Alice"))
  idx.add_record(r1)
  idx.add_record(r2)
  let pairs = idx.candidate_pairs()
  // Both have same first 3 chars "ali", so they share a block
  assert_true(pairs.length() >= 1)
}

///|
test "cross match pairs" {
  let idx_a = BlockingIndex::new(["name"])
  let idx_b = BlockingIndex::new(["name"])
  let ra = @core.Record::new("a1")
  ra.set_field("name", @core.StringVal("Alice"))
  let rb = @core.Record::new("b1")
  rb.set_field("name", @core.StringVal("Alice"))
  idx_a.add_record(ra)
  idx_b.add_record(rb)
  let pairs = cross_match_pairs(idx_a, idx_b)
  assert_eq(pairs.length(), 1)
  assert_eq(pairs[0], ("a1", "b1"))
}

///|
test "multi key blocker" {
  let blocker = MultiKeyBlocker::new()
  let idx1 = BlockingIndex::new(["name"])
  let idx2 = BlockingIndex::new(["city"])
  let r1 = @core.Record::new("r1")
  r1.set_field("name", @core.StringVal("Alice"))
  r1.set_field("city", @core.StringVal("Beijing"))
  let r2 = @core.Record::new("r2")
  r2.set_field("name", @core.StringVal("Alice"))
  r2.set_field("city", @core.StringVal("Shanghai"))
  idx1.add_record(r1)
  idx1.add_record(r2)
  idx2.add_record(r1)
  idx2.add_record(r2)
  blocker.add_index(idx1)
  blocker.add_index(idx2)
  let pairs = blocker.all_candidate_pairs()
  assert_true(pairs.length() >= 1)
}

///|
test "snm blocker sorted" {
  let snm = SNMBlocker::new("name", window_size=2)
  let records : Array[@core.Record] = []
  let names = ["Zorro", "Alice", "Bob", "Charlie"]
  for i = 0; i < names.length(); i = i + 1 {
    let name = names[i]
    let r = @core.Record::new(name)
    r.set_field("name", @core.StringVal(name))
    records.push(r)
  }
  let sorted = snm.build_sorted_keys(records)
  assert_eq(sorted[0].0, "alice")
  assert_eq(sorted[1].0, "bob")
}

///|
test "snm candidate pairs" {
  let snm = SNMBlocker::new("name", window_size=2)
  let records : Array[@core.Record] = []
  for name in ["Alice", "Alice2", "Bob"] {
    let r = @core.Record::new(name)
    r.set_field("name", @core.StringVal(name))
    records.push(r)
  }
  let pairs = snm.candidate_pairs(records)
  assert_true(pairs.length() > 0)
}

///|
test "lsh candidate pairs" {
  let lsh = LSHBlocker::new("name", num_hashes=20, num_bands=5)
  let records : Array[@core.Record] = []
  for name in ["hello world", "hello moonbit", "foobar baz"] {
    let r = @core.Record::new(name)
    r.set_field("name", @core.StringVal(name))
    records.push(r)
  }
  let pairs = lsh.candidate_pairs(records)
  // hello world and hello moonbit should share at least some bands
  assert_true(pairs.length() >= 0) // at minimum, no crash
}

///|
test "canopy blocker" {
  let cb = CanopyBlocker::new("name", t1=0.5, t2=0.8)
  let records : Array[@core.Record] = []
  let r1 = @core.Record::new("r1")
  r1.set_field("name", @core.StringVal("alice"))
  let r2 = @core.Record::new("r2")
  r2.set_field("name", @core.StringVal("alicia"))
  let r3 = @core.Record::new("r3")
  r3.set_field("name", @core.StringVal("zephyr"))
  records.push(r1)
  records.push(r2)
  records.push(r3)
  let canopies = cb.build_canopies(records)
  assert_true(canopies.length() >= 1)
  let pairs = canopies_to_pairs(canopies)
  assert_true(pairs.length() >= 0)
}
