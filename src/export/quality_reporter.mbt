///|
fn json_quote(value : String) -> String {
  "\"" +
  value.replace(old="\\", new="\\\\").replace(old="\"", new="\\\"") +
  "\""
}

///|
fn status_label(status : @core.MatchStatus) -> String {
  match status {
    @core.Match => "MATCH"
    @core.PossibleMatch => "POSSIBLE"
    @core.NonMatch => "NON_MATCH"
  }
}

///|
pub fn dataset_profile_to_json(profile : @core.DatasetProfile) -> String {
  let sb = StringBuilder(size_hint=256)
  sb.write_string("{\"record_count\":" + profile.record_count.to_string())
  sb.write_string(
    ",\"distinct_id_count\":" + profile.distinct_id_count.to_string(),
  )
  sb.write_string(
    ",\"duplicate_id_count\":" + profile.duplicate_id_count.to_string(),
  )
  sb.write_string(",\"fields\":[")
  for i, field in profile.field_profiles {
    if i > 0 {
      sb.write_char(',')
    }
    sb.write_string(
      "{\"name\":" +
      json_quote(field.name) +
      ",\"type\":" +
      json_quote(field.field_type) +
      ",\"total_count\":" +
      field.total_count.to_string() +
      ",\"present_count\":" +
      field.present_count.to_string() +
      ",\"null_count\":" +
      field.null_count.to_string() +
      ",\"distinct_count\":" +
      field.distinct_count.to_string() +
      "}",
    )
  }
  sb.write_string("]}")
  sb.to_string()
}

///|
pub fn dataset_profile_to_csv(profile : @core.DatasetProfile) -> String {
  let sb = StringBuilder(size_hint=256)
  sb.write_string(
    "field,total_count,present_count,null_count,distinct_count,type\n",
  )
  for field in profile.field_profiles {
    sb.write_string(
      escape_csv_field(field.name) +
      "," +
      field.total_count.to_string() +
      "," +
      field.present_count.to_string() +
      "," +
      field.null_count.to_string() +
      "," +
      field.distinct_count.to_string() +
      "," +
      escape_csv_field(field.field_type) +
      "\n",
    )
  }
  sb.to_string()
}

///|
pub fn candidate_plan_to_json(plan : @blocking.CandidatePlan) -> String {
  let sb = StringBuilder(size_hint=256)
  sb.write_string(
    "{\"raw_pairs\":" +
    plan.raw_pair_count.to_string() +
    ",\"candidate_pairs\":" +
    plan.deduplicated_pair_count.to_string() +
    ",\"returned_pairs\":" +
    plan.pairs.length().to_string() +
    ",\"truncated\":" +
    plan.truncated.to_string() +
    ",\"pairs\":[",
  )
  for i, pair in plan.pairs {
    if i > 0 {
      sb.write_char(',')
    }
    sb.write_string(
      "{\"left_id\":" +
      json_quote(pair.left_id) +
      ",\"right_id\":" +
      json_quote(pair.right_id) +
      ",\"origins\":[" +
      pair.origins.map(fn(origin) { json_quote(origin) }).join(",") +
      "]}",
    )
  }
  sb.write_string("]}")
  sb.to_string()
}

///|
pub fn candidate_plan_to_csv(plan : @blocking.CandidatePlan) -> String {
  let sb = StringBuilder(size_hint=256)
  sb.write_string("left_id,right_id,origins\n")
  for pair in plan.pairs {
    sb.write_string(
      escape_csv_field(pair.left_id) +
      "," +
      escape_csv_field(pair.right_id) +
      "," +
      escape_csv_field(pair.origins.join("|")) +
      "\n",
    )
  }
  sb.to_string()
}

///|
pub fn score_explanation_to_text(
  explanation : @model.ScoreExplanation,
) -> String {
  let sb = StringBuilder(size_hint=256)
  sb.write_string("pair=" + explanation.pair_id + "\n")
  sb.write_string("composite=" + explanation.composite_score.to_string() + "\n")
  sb.write_string("status=" + status_label(explanation.status) + "\n")
  sb.write_string("reason=" + explanation.decision_reason + "\n")
  for contribution in explanation.field_contributions {
    sb.write_string(
      contribution.field_name +
      " raw=" +
      contribution.raw_score.to_string() +
      " weighted=" +
      contribution.weighted_score.to_string() +
      " missing=" +
      contribution.missing.to_string() +
      "\n",
    )
  }
  sb.to_string()
}

///|
pub fn score_explanation_to_json(
  explanation : @model.ScoreExplanation,
) -> String {
  let sb = StringBuilder(size_hint=256)
  sb.write_string(
    "{\"pair_id\":" +
    json_quote(explanation.pair_id) +
    ",\"composite_score\":" +
    explanation.composite_score.to_string() +
    ",\"status\":" +
    json_quote(status_label(explanation.status)) +
    ",\"field_contributions\":[",
  )
  for i, contribution in explanation.field_contributions {
    if i > 0 {
      sb.write_char(',')
    }
    sb.write_string(
      "{\"field\":" +
      json_quote(contribution.field_name) +
      ",\"raw_score\":" +
      contribution.raw_score.to_string() +
      ",\"weight\":" +
      contribution.weight.to_string() +
      ",\"weighted_score\":" +
      contribution.weighted_score.to_string() +
      ",\"missing\":" +
      contribution.missing.to_string() +
      "}",
    )
  }
  sb.write_string("]}")
  sb.to_string()
}
