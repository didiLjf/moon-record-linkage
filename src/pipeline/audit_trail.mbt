///|
pub struct PipelineAuditEvent {
  stage : String
  message : String
  units : Int
} derive(Debug, Eq)

///|
pub fn PipelineAuditEvent::new(
  stage : String,
  message : String,
  units : Int,
) -> PipelineAuditEvent {
  { stage, message, units: if units < 0 { 0 } else { units } }
}

///|
pub struct AuditTrail {
  run_id : String
  events : Array[PipelineAuditEvent]
} derive(Debug)

///|
pub fn AuditTrail::new(run_id : String) -> AuditTrail {
  { run_id, events: [] }
}

///|
pub fn AuditTrail::record(
  self : AuditTrail,
  event : PipelineAuditEvent,
) -> Unit {
  self.events.push(event)
}

///|
pub fn AuditTrail::length(self : AuditTrail) -> Int {
  self.events.length()
}

///|
pub fn AuditTrail::count_stage(self : AuditTrail, stage : String) -> Int {
  let mut count = 0
  for event in self.events {
    if event.stage == stage {
      count = count + 1
    }
  }
  count
}

///|
pub fn AuditTrail::events_for(
  self : AuditTrail,
  stage : String,
) -> Array[PipelineAuditEvent] {
  let result : Array[PipelineAuditEvent] = []
  for event in self.events {
    if event.stage == stage {
      result.push(event)
    }
  }
  result
}

///|
pub fn AuditTrail::total_units(self : AuditTrail) -> Int {
  let mut total = 0
  for event in self.events {
    total = total + event.units
  }
  total
}

///|
pub fn AuditTrail::render(self : AuditTrail) -> String {
  let sb = StringBuilder(size_hint=256)
  sb.write_string(
    "run=" + self.run_id + " events=" + self.events.length().to_string() + "\n",
  )
  for event in self.events {
    sb.write_string(
      event.stage +
      " units=" +
      event.units.to_string() +
      " " +
      event.message +
      "\n",
    )
  }
  sb.to_string()
}
