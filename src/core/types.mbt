// Core Type Definitions for MoonBit Record Linkage Engine

///|
pub(all) enum FieldValue {
  StringVal(String)
  IntVal(Int)
  DoubleVal(Double)
  DateVal(String)
  GeoVal(Double, Double)
  ArrayVal(Array[String])
  NullVal
} derive(Debug, Eq)

///|
pub(all) enum FieldType {
  Text
  Numeric
  Date
  Geo
  ArrayText
} derive(Debug, Eq)

///|
pub struct SchemaField {
  name : String
  field_type : FieldType
  required : Bool
} derive(Debug, Eq)

///|
pub struct Schema {
  fields : Array[SchemaField]
} derive(Debug, Eq)

///|
pub struct Record {
  id : String
  attributes : Map[String, FieldValue]
  source : String
  timestamp : Int64
} derive(Debug, Eq)

///|
pub(all) enum MatchStatus {
  Match
  PossibleMatch
  NonMatch
} derive(Debug, Eq)

///|
pub struct MatchPair {
  record_a : Record
  record_b : Record
  score : Double
  status : MatchStatus
  field_scores : Map[String, Double]
} derive(Debug, Eq)

///|
pub struct EntityCluster {
  cluster_id : String
  records : Array[Record]
  canonical_record : Record
  confidence : Double
} derive(Debug, Eq)

///|
pub(all) enum RecordLinkageError {
  InvalidSchema(String)
  MissingField(String)
  TypeMismatch(String)
  PipelineError(String)
  ExporterError(String)
} derive(Debug, Eq)

///|
pub fn Record::new(
  id : String,
  source? : String = "default",
  timestamp? : Int64 = 0L,
) -> Record {
  { id, attributes: Map([]), source, timestamp }
}

///|
pub fn Record::set_field(
  self : Record,
  name : String,
  value : FieldValue,
) -> Unit {
  self.attributes.set(name, value)
}

///|
pub fn Record::get_field(self : Record, name : String) -> FieldValue {
  match self.attributes.get(name) {
    Some(val) => val
    None => NullVal
  }
}

///|
pub fn Record::get_string(self : Record, name : String) -> String {
  match self.get_field(name) {
    StringVal(s) => s
    IntVal(i) => i.to_string()
    DoubleVal(d) => d.to_string()
    DateVal(dt) => dt
    _ => ""
  }
}

///|
pub fn Record::get_double(self : Record, name : String) -> Double {
  match self.get_field(name) {
    DoubleVal(d) => d
    IntVal(i) => i.to_double()
    _ => 0.0
  }
}

///|
pub fn Record::get_geo(self : Record, name : String) -> (Double, Double) {
  match self.get_field(name) {
    GeoVal(lat, lon) => (lat, lon)
    _ => (0.0, 0.0)
  }
}

///|
pub fn FieldValue::is_null(self : FieldValue) -> Bool {
  match self {
    NullVal => true
    StringVal(s) => s.is_empty()
    ArrayVal(arr) => arr.is_empty()
    _ => false
  }
}

///|
pub fn FieldValue::to_str(self : FieldValue) -> String {
  match self {
    StringVal(s) => s
    IntVal(i) => i.to_string()
    DoubleVal(d) => d.to_string()
    DateVal(dt) => dt
    GeoVal(lat, lon) => "\{lat},\{lon}"
    ArrayVal(arr) => {
      let sb = StringBuilder(size_hint=64)
      for i = 0; i < arr.length(); i = i + 1 {
        if i > 0 {
          sb.write_char(';')
        }
        sb.write_string(arr[i])
      }
      sb.to_string()
    }
    NullVal => ""
  }
}

///|
pub fn Schema::new() -> Schema {
  { fields: [] }
}

///|
pub fn Schema::add_field(
  self : Schema,
  name : String,
  field_type : FieldType,
  required? : Bool = false,
) -> Unit {
  self.fields.push({ name, field_type, required })
}

///|
pub fn Schema::validate(
  self : Schema,
  record : Record,
) -> Result[Unit, RecordLinkageError] {
  for f in self.fields {
    let val = record.get_field(f.name)
    if f.required && val.is_null() {
      return Err(MissingField("Required field missing: " + f.name))
    }
  }
  Ok(())
}

///|
pub fn MatchPair::new(
  record_a : Record,
  record_b : Record,
  score : Double,
  status : MatchStatus,
) -> MatchPair {
  { record_a, record_b, score, status, field_scores: Map([]) }
}

///|
pub fn MatchPair::set_field_score(
  self : MatchPair,
  field : String,
  score : Double,
) -> Unit {
  self.field_scores.set(field, score)
}

///|
pub fn EntityCluster::new(
  cluster_id : String,
  canonical_record : Record,
  confidence? : Double = 1.0,
) -> EntityCluster {
  { cluster_id, records: [], canonical_record, confidence }
}

///|
pub fn EntityCluster::add_record(self : EntityCluster, record : Record) -> Unit {
  self.records.push(record)
}
