///|
test "audit trail records stable lifecycle events" {
  let trail = AuditTrail::new("run-1")
  trail.record(PipelineAuditEvent::new("validate", "records validated", 3))
  trail.record(PipelineAuditEvent::new("match", "pairs scored", 8))
  trail.record(PipelineAuditEvent::new("match", "pairs scored", 2))
  assert_eq(trail.length(), 3)
  assert_eq(trail.count_stage("match"), 2)
  assert_true(trail.render().has_prefix("run=run-1"))
}

///|
test "audit trail handles empty and stage filtering" {
  let trail = AuditTrail::new("empty")
  assert_true(trail.events_for("missing").is_empty())
  assert_eq(trail.total_units(), 0)
}
