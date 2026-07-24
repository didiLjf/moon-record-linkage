// Model Module Tests

///|
test "fs field params log weight" {
  let params = FSFieldParams::new("name", m_prob=0.9, u_prob=0.1)
  let lw = params.log_weight()
  // log2(0.9/0.1) = log2(9) ≈ 3.17
  assert_true(lw > 3.0 && lw < 3.5)
}

///|
test "fs model classification" {
  let model = FellegiSunterModel::new()
  let p1 = FSFieldParams::new("name", m_prob=0.9, u_prob=0.1)
  let p2 = FSFieldParams::new("dob", m_prob=0.95, u_prob=0.05)
  model.add_field(p1)
  model.add_field(p2)
  // Both fields agree = high weight
  let w_match = model.compute_weight([true, true])
  assert_true(w_match > 3.0)
  let status_match = model.classify(w_match)
  assert_eq(status_match, @core.Match)
  // Both fields disagree = low weight
  let w_non = model.compute_weight([false, false])
  let status_non = model.classify(w_non)
  assert_eq(status_non, @core.NonMatch)
}

///|
test "fs em training runs" {
  let model = FellegiSunterModel::new()
  let p1 = FSFieldParams::new("name")
  let p2 = FSFieldParams::new("city")
  model.add_field(p1)
  model.add_field(p2)
  let data : Array[Array[Bool]] = [
    [true, true],
    [true, false],
    [false, false],
    [true, true],
    [false, true],
  ]
  model.em_train(data, max_iterations=10)
  // After training, m and u should be in valid range
  assert_true(
    model.field_params[0].m_prob > 0.0 && model.field_params[0].m_prob < 1.0,
  )
  assert_true(
    model.field_params[0].u_prob > 0.0 && model.field_params[0].u_prob < 1.0,
  )
}

///|
test "rule engine field equal" {
  let ra = @core.Record::new("a")
  ra.set_field("name", @core.StringVal("Alice"))
  let rb = @core.Record::new("b")
  rb.set_field("name", @core.StringVal("Alice"))
  let ctx = RuleContext::new(ra, rb)
  let rule = Atom(FieldEqual("name"))
  assert_true(eval_rule(rule, ctx))
  // Different values
  let rc = @core.Record::new("c")
  rc.set_field("name", @core.StringVal("Bob"))
  let ctx2 = RuleContext::new(ra, rc)
  assert_true(!eval_rule(rule, ctx2))
}

///|
test "rule engine compound and" {
  let ra = @core.Record::new("a")
  ra.set_field("name", @core.StringVal("Alice"))
  ra.set_field("city", @core.StringVal("Beijing"))
  let rb = @core.Record::new("b")
  rb.set_field("name", @core.StringVal("Alice"))
  rb.set_field("city", @core.StringVal("Beijing"))
  let ctx = RuleContext::new(ra, rb)
  let rule = Combine(And, [Atom(FieldEqual("name")), Atom(FieldEqual("city"))])
  assert_true(eval_rule(rule, ctx))
}

///|
test "rule engine not" {
  let ra = @core.Record::new("a")
  ra.set_field("name", @core.StringVal("Alice"))
  let rb = @core.Record::new("b")
  rb.set_field("name", @core.StringVal("Bob"))
  let ctx = RuleContext::new(ra, rb)
  let rule = Not(Atom(FieldEqual("name")))
  assert_true(eval_rule(rule, ctx))
}

///|
test "hybrid scorer score pair" {
  let fs_model = FellegiSunterModel::new()
  fs_model.add_field(FSFieldParams::new("name"))
  let rule_set = RuleSet::new()
  let scorer = HybridScorer::new(fs_model, rule_set)
  scorer.add_field(FieldScorerConfig::new("name", weight=1.0))
  let ra = @core.Record::new("a")
  ra.set_field("name", @core.StringVal("Alice Smith"))
  let rb = @core.Record::new("b")
  rb.set_field("name", @core.StringVal("Alice Smith"))
  let pair = scorer.score_pair(ra, rb)
  assert_true(pair.score > 0.5)
}

///|
test "hybrid scorer different records" {
  let fs_model = FellegiSunterModel::new()
  fs_model.add_field(FSFieldParams::new("name"))
  let rule_set = RuleSet::new()
  let scorer = HybridScorer::new(fs_model, rule_set)
  scorer.add_field(FieldScorerConfig::new("name", weight=1.0))
  let ra = @core.Record::new("a")
  ra.set_field("name", @core.StringVal("Alice"))
  let rb = @core.Record::new("b")
  rb.set_field("name", @core.StringVal("Zephyr"))
  let pair = scorer.score_pair(ra, rb)
  assert_true(pair.score < 0.8)
}
