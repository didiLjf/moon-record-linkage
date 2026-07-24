// JSON Exporter: serializes records, match pairs, entity clusters, and linkage metrics to JSON format.

///|
/// Escape special JSON characters in a string.
pub fn escape_json_string(s : String) -> String {
  let chars = s.to_array()
  let sb = StringBuilder(size_hint=chars.length() + 8)
  sb.write_char('"')
  for ch in chars {
    match ch {
      '"' => sb.write_string("\\\"")
      '\\' => sb.write_string("\\\\")
      '\n' => sb.write_string("\\n")
      '\r' => sb.write_string("\\r")
      '\t' => sb.write_string("\\t")
      _ => sb.write_char(ch)
    }
  }
  sb.write_char('"')
  sb.to_string()
}

///|
/// Convert a Record object to JSON string representation.
pub fn record_to_json(record : @core.Record) -> String {
  let sb = StringBuilder(size_hint=256)
  sb.write_string("{\"id\":")
  sb.write_string(escape_json_string(record.id))
  sb.write_string(",\"source\":")
  sb.write_string(escape_json_string(record.source))
  sb.write_string(",\"timestamp\":")
  sb.write_string(record.timestamp.to_string())
  sb.write_string(",\"attributes\":{")
  let mut first = true
  for entry in record.attributes {
    if !first {
      sb.write_char(',')
    }
    first = false
    sb.write_string(escape_json_string(entry.0))
    sb.write_char(':')
    sb.write_string(escape_json_string(entry.1.to_str()))
  }
  sb.write_string("}}")
  sb.to_string()
}

///|
/// Convert an array of Records to a JSON array string.
pub fn records_to_json(records : Array[@core.Record]) -> String {
  let sb = StringBuilder(size_hint=records.length() * 200)
  sb.write_char('[')
  for i = 0; i < records.length(); i = i + 1 {
    if i > 0 {
      sb.write_char(',')
    }
    sb.write_string(record_to_json(records[i]))
  }
  sb.write_char(']')
  sb.to_string()
}

///|
/// Convert a MatchPair to JSON.
pub fn match_pair_to_json(pair : @core.MatchPair) -> String {
  let sb = StringBuilder(size_hint=300)
  sb.write_string("{\"record_a\":")
  sb.write_string(escape_json_string(pair.record_a.id))
  sb.write_string(",\"record_b\":")
  sb.write_string(escape_json_string(pair.record_b.id))
  sb.write_string(",\"score\":")
  sb.write_string(pair.score.to_string())
  sb.write_string(",\"status\":")
  let status_str = match pair.status {
    @core.Match => "\"MATCH\""
    @core.PossibleMatch => "\"POSSIBLE_MATCH\""
    @core.NonMatch => "\"NON_MATCH\""
  }
  sb.write_string(status_str)
  sb.write_string(",\"field_scores\":{")
  let mut first = true
  for entry in pair.field_scores {
    if !first {
      sb.write_char(',')
    }
    first = false
    sb.write_string(escape_json_string(entry.0))
    sb.write_char(':')
    sb.write_string(entry.1.to_string())
  }
  sb.write_string("}}")
  sb.to_string()
}

///|
/// Convert an EntityCluster to JSON.
pub fn entity_cluster_to_json(cluster : @core.EntityCluster) -> String {
  let sb = StringBuilder(size_hint=500)
  sb.write_string("{\"cluster_id\":")
  sb.write_string(escape_json_string(cluster.cluster_id))
  sb.write_string(",\"confidence\":")
  sb.write_string(cluster.confidence.to_string())
  sb.write_string(",\"canonical_record\":")
  sb.write_string(record_to_json(cluster.canonical_record))
  sb.write_string(",\"member_ids\":[")
  for i = 0; i < cluster.records.length(); i = i + 1 {
    if i > 0 {
      sb.write_char(',')
    }
    sb.write_string(escape_json_string(cluster.records[i].id))
  }
  sb.write_string("]}")
  sb.to_string()
}

///|
/// Convert BatchLinkageResult to a comprehensive JSON summary.
pub fn linkage_result_to_json(result : @pipeline.BatchLinkageResult) -> String {
  let sb = StringBuilder(size_hint=1024)
  sb.write_string("{\"candidate_pair_count\":")
  sb.write_string(result.candidate_pair_count.to_string())
  sb.write_string(",\"match_count\":")
  sb.write_string(result.match_pairs.length().to_string())
  sb.write_string(",\"possible_match_count\":")
  sb.write_string(result.possible_pairs.length().to_string())
  sb.write_string(",\"cluster_count\":")
  sb.write_string(result.clusters.length().to_string())
  sb.write_string(",\"match_pairs\":[")
  for i = 0; i < result.match_pairs.length(); i = i + 1 {
    if i > 0 {
      sb.write_char(',')
    }
    sb.write_string(match_pair_to_json(result.match_pairs[i]))
  }
  sb.write_string("],\"clusters\":[")
  for i = 0; i < result.clusters.length(); i = i + 1 {
    if i > 0 {
      sb.write_char(',')
    }
    sb.write_string(entity_cluster_to_json(result.clusters[i]))
  }
  sb.write_string("]}")
  sb.to_string()
}
