///|
pub struct FieldLineage {
  field_name : String
  source_count : Int
  present_count : Int
  missing_count : Int
  distinct_value_count : Int
  source_values : Map[String, Int]
} derive(Debug)

///|
pub struct LineageReport {
  record_count : Int
  source_count : Int
  fields : Array[FieldLineage]
} derive(Debug)

///|
/// Record which sources contribute and omit each field in a dataset.
pub fn build_lineage(records : Array[Record]) -> LineageReport {
  let sources : Map[String, Bool] = Map([])
  let names : Array[String] = []
  let seen_names : Map[String, Bool] = Map([])
  for record in records {
    sources.set(record.source, true)
    for entry in record.attributes {
      if !seen_names.contains(entry.0) {
        seen_names.set(entry.0, true)
        names.push(entry.0)
      }
    }
  }
  let fields : Array[FieldLineage] = []
  for field_name in names {
    let field_sources : Map[String, Bool] = Map([])
    let values : Map[String, Bool] = Map([])
    let mut present = 0
    let mut missing = 0
    for record in records {
      match record.attributes.get(field_name) {
        Some(value) if !value.is_null() => {
          present = present + 1
          field_sources.set(record.source, true)
          values.set(value.to_str(), true)
        }
        _ => missing = missing + 1
      }
    }
    let source_values : Map[String, Int] = Map([])
    for source in field_sources {
      let mut count = 0
      for record in records {
        if record.source == source.0 && !record.get_field(field_name).is_null() {
          count = count + 1
        }
      }
      source_values.set(source.0, count)
    }
    fields.push({
      field_name,
      source_count: field_sources.length(),
      present_count: present,
      missing_count: missing,
      distinct_value_count: values.length(),
      source_values,
    })
  }
  { record_count: records.length(), source_count: sources.length(), fields }
}
