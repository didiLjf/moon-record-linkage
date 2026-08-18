///|
/// A collection of validation issues accumulated during one operation.
pub struct DiagnosticReport {
  issues : Array[ValidationIssue]
} derive(Debug)

///|
pub fn DiagnosticReport::new() -> DiagnosticReport {
  { issues: [] }
}

///|
pub fn DiagnosticReport::add(
  self : DiagnosticReport,
  issue : ValidationIssue,
) -> Unit {
  self.issues.push(issue)
}

///|
pub fn DiagnosticReport::add_many(
  self : DiagnosticReport,
  issues : Array[ValidationIssue],
) -> Unit {
  for issue in issues {
    self.add(issue)
  }
}

///|
pub fn DiagnosticReport::error_count(self : DiagnosticReport) -> Int {
  let mut count = 0
  for issue in self.issues {
    if issue.severity is Error {
      count = count + 1
    }
  }
  count
}

///|
pub fn DiagnosticReport::warning_count(self : DiagnosticReport) -> Int {
  let mut count = 0
  for issue in self.issues {
    if issue.severity is Warning {
      count = count + 1
    }
  }
  count
}

///|
pub fn DiagnosticReport::is_valid(self : DiagnosticReport) -> Bool {
  self.error_count() == 0
}

///|
pub fn DiagnosticReport::render(self : DiagnosticReport) -> String {
  let sb = StringBuilder(size_hint=64 + self.issues.length() * 32)
  sb.write_string("errors=" + self.error_count().to_string())
  sb.write_string(" warnings=" + self.warning_count().to_string())
  for issue in self.issues {
    sb.write_string(
      "\n[" + issue.code + "] " + issue.field + ": " + issue.message,
    )
  }
  sb.to_string()
}
