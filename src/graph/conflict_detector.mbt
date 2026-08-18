///|
fn quality_field_names(records : Array[@core.Record]) -> Array[String] {
  let names : Array[String] = []
  let seen : Map[String, Bool] = Map([])
  for record in records {
    for entry in record.attributes {
      if !seen.contains(entry.0) {
        seen.set(entry.0, true)
        names.push(entry.0)
      }
    }
  }
  names
}

///|
/// Detect disagreements between non-empty normalized field values in a cluster.
pub fn detect_conflicts(records : Array[@core.Record]) -> ConflictReport {
  let conflicts : Array[FieldConflict] = []
  for field_name in quality_field_names(records) {
    let values : Map[String, Array[String]] = Map([])
    for record in records {
      let value = record.get_string(field_name)
      if !value.is_empty() {
        match values.get(value) {
          Some(ids) => ids.push(record.id)
          None => values.set(value, [record.id])
        }
      }
    }
    if values.length() > 1 {
      let distinct_values : Array[String] = []
      let record_ids : Array[String] = []
      for entry in values {
        distinct_values.push(entry.0)
        for id in entry.1 {
          record_ids.push(id)
        }
      }
      conflicts.push({
        field_name,
        values: distinct_values,
        record_ids,
        distinct_value_count: values.length(),
      })
    }
  }
  { checked_records: records.length(), conflicts }
}
