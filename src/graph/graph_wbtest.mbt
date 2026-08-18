// Graph Module Tests

///|
test "dsu basic operations" {
  let dsu = DSU::new()
  dsu.add("a")
  dsu.add("b")
  dsu.add("c")
  assert_true(!dsu.same_component("a", "b"))
  dsu.union("a", "b")
  assert_true(dsu.same_component("a", "b"))
  assert_true(!dsu.same_component("a", "c"))
}

///|
test "dsu path compression" {
  let dsu = DSU::new()
  dsu.union("a", "b")
  dsu.union("b", "c")
  dsu.union("c", "d")
  assert_true(dsu.same_component("a", "d"))
  assert_eq(dsu.find("a"), dsu.find("d"))
}

///|
test "dsu from pairs" {
  let pairs = [("a", "b"), ("b", "c"), ("d", "e")]
  let dsu = DSU::from_pairs(pairs)
  assert_true(dsu.same_component("a", "c"))
  assert_true(!dsu.same_component("a", "d"))
}

///|
test "dsu components" {
  let dsu = DSU::new()
  dsu.union("a", "b")
  dsu.union("c", "d")
  let comps = dsu.components()
  assert_eq(comps.length(), 2)
}

///|
test "entity graph clustering" {
  let graph = EntityGraph::new()
  graph.add_match("r1", "r2", 0.95, threshold=0.8)
  graph.add_match("r2", "r3", 0.88, threshold=0.8)
  graph.add_match("r4", "r5", 0.91, threshold=0.8)
  assert_true(graph.are_linked("r1", "r3"))
  assert_true(!graph.are_linked("r1", "r4"))
}

///|
test "entity graph cluster count" {
  let graph = EntityGraph::new()
  graph.add_record("a")
  graph.add_record("b")
  graph.add_record("c")
  graph.add_match("a", "b", 0.9, threshold=0.8)
  let count = graph.cluster_count()
  assert_eq(count, 2)
}

///|
test "canonical merger first record" {
  let merger = CanonicalMerger::new(strategy=FirstRecord)
  let r1 = @core.Record::new("r1")
  r1.set_field("name", @core.StringVal("Alice"))
  let r2 = @core.Record::new("r2")
  r2.set_field("name", @core.StringVal("Bob"))
  let canonical = merger.select_canonical([r1, r2])
  assert_eq(canonical.id, "r1")
}

///|
test "canonical merger most recent" {
  let merger = CanonicalMerger::new(strategy=MostRecent)
  let r1 = @core.Record::new("r1", timestamp=1000L)
  let r2 = @core.Record::new("r2", timestamp=2000L)
  let canonical = merger.select_canonical([r1, r2])
  assert_eq(canonical.id, "r2")
}

///|
test "canonical merger majority vote" {
  let merger = CanonicalMerger::new(strategy=MajorityVote)
  let r1 = @core.Record::new("r1")
  r1.set_field("city", @core.StringVal("Beijing"))
  let r2 = @core.Record::new("r2")
  r2.set_field("city", @core.StringVal("Beijing"))
  let r3 = @core.Record::new("r3")
  r3.set_field("city", @core.StringVal("Shanghai"))
  let canonical = merger.select_canonical([r1, r2, r3])
  assert_eq(canonical.get_string("city"), "Beijing")
}
