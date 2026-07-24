// CSV Exporter: exports linked record pairs and entity clusters to CSV format.

///|
/// Escape fields containing commas, quotes, or newlines for CSV compliance.
pub fn escape_csv_field(s : String) -> String {
  let chars = s.to_array()
  let mut needs_quote = false
  for ch in chars {
    if ch == ',' || ch == '"' || ch == '\n' || ch == '\r' {
      needs_quote = true
      break
    }
  }
  if !needs_quote {
    s
  } else {
    let sb = StringBuilder(size_hint=chars.length() + 8)
    sb.write_char('"')
    for ch in chars {
      if ch == '"' {
        sb.write_string("\"\"")
      } else {
        sb.write_char(ch)
      }
    }
    sb.write_char('"')
    sb.to_string()
  }
}

///|
/// Export match pairs to CSV format string.
/// Headers: record_a_id,record_b_id,score,status
pub fn match_pairs_to_csv(pairs : Array[@core.MatchPair]) -> String {
  let sb = StringBuilder(size_hint=pairs.length() * 64 + 64)
  sb.write_string("record_a_id,record_b_id,score,status\n")
  for pair in pairs {
    sb.write_string(escape_csv_field(pair.record_a.id))
    sb.write_char(',')
    sb.write_string(escape_csv_field(pair.record_b.id))
    sb.write_char(',')
    sb.write_string(pair.score.to_string())
    sb.write_char(',')
    let status_str = match pair.status {
      @core.Match => "MATCH"
      @core.PossibleMatch => "POSSIBLE_MATCH"
      @core.NonMatch => "NON_MATCH"
    }
    sb.write_string(status_str)
    sb.write_char('\n')
  }
  sb.to_string()
}

///|
/// Export entity clusters to CSV format string.
/// Headers: cluster_id,member_id,is_canonical
pub fn clusters_to_csv(clusters : Array[@core.EntityCluster]) -> String {
  let sb = StringBuilder(size_hint=clusters.length() * 128 + 64)
  sb.write_string("cluster_id,member_id,is_canonical\n")
  for cluster in clusters {
    let canonical_id = cluster.canonical_record.id
    for cluster_record in cluster.records {
      sb.write_string(escape_csv_field(cluster.cluster_id))
      sb.write_char(',')
      sb.write_string(escape_csv_field(cluster_record.id))
      sb.write_char(',')
      sb.write_string(
        if cluster_record.id == canonical_id {
          "true"
        } else {
          "false"
        },
      )
      sb.write_char('\n')
    }
  }
  sb.to_string()
}

///|
/// Export a dataset of records to CSV given field headers.
pub fn records_to_csv(
  records : Array[@core.Record],
  fields : Array[String],
) -> String {
  let sb = StringBuilder(size_hint=records.length() * 100 + 64)
  // Write header
  sb.write_string("id,source")
  for f in fields {
    sb.write_char(',')
    sb.write_string(escape_csv_field(f))
  }
  sb.write_char('\n')
  // Write data rows
  for rec in records {
    sb.write_string(escape_csv_field(rec.id))
    sb.write_char(',')
    sb.write_string(escape_csv_field(rec.source))
    for f in fields {
      sb.write_char(',')
      sb.write_string(escape_csv_field(rec.get_string(f)))
    }
    sb.write_char('\n')
  }
  sb.to_string()
}
