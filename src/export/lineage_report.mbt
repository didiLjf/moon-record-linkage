///|
fn lineage_json_quote(value : String) -> String {
  "\"" +
  value.replace(old="\\", new="\\\\").replace(old="\"", new="\\\"") +
  "\""
}

///|
/// Export field provenance and missingness as machine-readable JSON.
pub fn lineage_report_to_json(report : @core.LineageReport) -> String {
  let sb = StringBuilder(size_hint=512)
  sb.write_string(
    "{\"record_count\":" +
    report.record_count.to_string() +
    ",\"source_count\":" +
    report.source_count.to_string() +
    ",\"fields\":[",
  )
  for i, field in report.fields {
    if i > 0 {
      sb.write_char(',')
    }
    sb.write_string(
      "{\"name\":" +
      lineage_json_quote(field.field_name) +
      ",\"source_count\":" +
      field.source_count.to_string() +
      ",\"present_count\":" +
      field.present_count.to_string() +
      ",\"missing_count\":" +
      field.missing_count.to_string() +
      ",\"distinct_value_count\":" +
      field.distinct_value_count.to_string() +
      ",\"sources\":[",
    )
    let source_index = 0
    for source_count in field.source_values {
      if source_index > 0 {
        sb.write_char(',')
      }
      sb.write_string(
        "{\"source\":" +
        lineage_json_quote(source_count.0) +
        ",\"present_count\":" +
        source_count.1.to_string() +
        "}",
      )
    }
    sb.write_string("]}")
  }
  sb.write_string("]}")
  sb.to_string()
}

///|
/// Export one row per field for warehouse ingestion.
pub fn lineage_report_to_csv(report : @core.LineageReport) -> String {
  let sb = StringBuilder(size_hint=256)
  sb.write_string(
    "field,source_count,present_count,missing_count,distinct_value_count\n",
  )
  for field in report.fields {
    sb.write_string(
      escape_csv_field(field.field_name) +
      "," +
      field.source_count.to_string() +
      "," +
      field.present_count.to_string() +
      "," +
      field.missing_count.to_string() +
      "," +
      field.distinct_value_count.to_string() +
      "\n",
    )
  }
  sb.to_string()
}

///|
/// Render lineage as a compact review table suitable for acceptance reports.
pub fn lineage_report_to_markdown(report : @core.LineageReport) -> String {
  let sb = StringBuilder(size_hint=512)
  sb.write_string("# Field lineage\n\n")
  sb.write_string(
    "records: " +
    report.record_count.to_string() +
    ", sources: " +
    report.source_count.to_string() +
    "\n\n",
  )
  sb.write_string("| field | sources | present | missing | distinct |\n")
  sb.write_string("| --- | ---: | ---: | ---: | ---: |\n")
  for field in report.fields {
    sb.write_string(
      "| " +
      field.field_name +
      " | " +
      field.source_count.to_string() +
      " | " +
      field.present_count.to_string() +
      " | " +
      field.missing_count.to_string() +
      " | " +
      field.distinct_value_count.to_string() +
      " |\n",
    )
  }
  sb.to_string()
}
