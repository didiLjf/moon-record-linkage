///|
/// A field that has multiple non-empty values inside one entity cluster.
pub struct FieldConflict {
  field_name : String
  values : Array[String]
  record_ids : Array[String]
  distinct_value_count : Int
} derive(Debug, Eq)

///|
pub struct ConflictReport {
  checked_records : Int
  conflicts : Array[FieldConflict]
} derive(Debug)

///|
pub struct CanonicalEvidence {
  field_name : String
  selected_value : String
  support_count : Int
  non_empty_count : Int
  source_count : Int
  confidence : Double
} derive(Debug, Eq)
