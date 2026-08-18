///|
fn profile_field_type(records : Array[Record], field_name : String) -> String {
  for record in records {
    match record.attributes.get(field_name) {
      Some(StringVal(_)) => return "text"
      Some(IntVal(_)) => return "numeric"
      Some(DoubleVal(_)) => return "numeric"
      Some(DateVal(_)) => return "date"
      Some(GeoVal(_, _)) => return "geo"
      Some(ArrayVal(_)) => return "array_text"
      Some(NullVal) => ()
      None => ()
    }
  }
  "unknown"
}

///|
fn collect_field_names(records : Array[Record]) -> Array[String] {
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
/// Build deterministic per-field and identity statistics without mutating records.
pub fn profile_dataset(records : Array[Record]) -> DatasetProfile {
  let id_counts : Map[String, Int] = Map([])
  let source_counts : Map[String, Int] = Map([])
  for record in records {
    match id_counts.get(record.id) {
      Some(count) => id_counts.set(record.id, count + 1)
      None => id_counts.set(record.id, 1)
    }
    match source_counts.get(record.source) {
      Some(count) => source_counts.set(record.source, count + 1)
      None => source_counts.set(record.source, 1)
    }
  }
  let mut duplicate_id_count = 0
  for entry in id_counts {
    if entry.1 > 1 {
      duplicate_id_count = duplicate_id_count + 1
    }
  }
  let field_profiles : Array[FieldProfile] = []
  for field_name in collect_field_names(records) {
    let values : Map[String, Bool] = Map([])
    let mut present_count = 0
    let mut null_count = 0
    for record in records {
      let value = record.get_field(field_name)
      if value.is_null() {
        null_count = null_count + 1
      } else {
        present_count = present_count + 1
        values.set(value.to_str(), true)
      }
    }
    field_profiles.push({
      name: field_name,
      field_type: profile_field_type(records, field_name),
      total_count: records.length(),
      present_count,
      null_count,
      distinct_count: values.length(),
    })
  }
  {
    record_count: records.length(),
    distinct_id_count: id_counts.length(),
    duplicate_id_count,
    field_profiles,
    source_counts,
  }
}
