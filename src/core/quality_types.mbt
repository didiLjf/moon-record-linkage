///|
/// Severity of a data-quality or pipeline diagnostic.
pub(all) enum IssueSeverity {
  Info
  Warning
  Error
} derive(Debug, Eq)

///|
/// A precise, machine-readable validation finding.
pub struct ValidationIssue {
  code : String
  field : String
  message : String
  severity : IssueSeverity
} derive(Debug, Eq)

///|
/// Create a validation finding without exposing mutable implementation state.
pub fn ValidationIssue::new(
  code : String,
  field : String,
  message : String,
  severity : IssueSeverity,
) -> ValidationIssue {
  { code, field, message, severity }
}

///|
/// Aggregate statistics for one field in a dataset.
pub struct FieldProfile {
  name : String
  field_type : String
  total_count : Int
  present_count : Int
  null_count : Int
  distinct_count : Int
} derive(Debug, Eq)

///|
/// Read-only summary of the shape and identity quality of a dataset.
pub struct DatasetProfile {
  record_count : Int
  distinct_id_count : Int
  duplicate_id_count : Int
  field_profiles : Array[FieldProfile]
  source_counts : Map[String, Int]
} derive(Debug)

///|
/// Return the fraction of distinct IDs that occur more than once.
pub fn DatasetProfile::duplicate_rate(self : DatasetProfile) -> Double {
  if self.distinct_id_count == 0 {
    0.0
  } else {
    self.duplicate_id_count.to_double() / self.distinct_id_count.to_double()
  }
}

///|
/// Return the fraction of rows that have a non-empty identifier.
pub fn DatasetProfile::id_completeness(self : DatasetProfile) -> Double {
  if self.record_count == 0 {
    0.0
  } else {
    self.distinct_id_count.to_double() / self.record_count.to_double()
  }
}
