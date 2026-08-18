///|
/// Explain which records supported each selected canonical field value.
pub fn canonical_evidence(
  records : Array[@core.Record],
  canonical : @core.Record,
) -> Array[CanonicalEvidence] {
  let evidence : Array[CanonicalEvidence] = []
  for entry in canonical.attributes {
    let field_name = entry.0
    let selected_value = canonical.get_string(field_name)
    if selected_value.is_empty() {
      continue
    }
    let mut support_count = 0
    let mut non_empty_count = 0
    let sources : Map[String, Bool] = Map([])
    for record in records {
      let value = record.get_string(field_name)
      if !value.is_empty() {
        non_empty_count = non_empty_count + 1
        sources.set(record.source, true)
        if value == selected_value {
          support_count = support_count + 1
        }
      }
    }
    let confidence = if non_empty_count == 0 {
      0.0
    } else {
      support_count.to_double() / non_empty_count.to_double()
    }
    evidence.push({
      field_name,
      selected_value,
      support_count,
      non_empty_count,
      source_count: sources.length(),
      confidence,
    })
  }
  evidence
}
