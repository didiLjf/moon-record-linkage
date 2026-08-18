///|
fn decision_reason(status : @core.MatchStatus, score : Double) -> String {
  match status {
    @core.Match => "score " + score.to_string() + " reached match threshold"
    @core.PossibleMatch => "score " + score.to_string() + " is in review band"
    @core.NonMatch =>
      "score " + score.to_string() + " is below review threshold"
  }
}

///|
/// Explain the exact score used by the batch pipeline for one record pair.
pub fn explain_pair(
  config : @core.LinkageConfig,
  record_a : @core.Record,
  record_b : @core.Record,
) -> ScoreExplanation {
  let contributions : Array[FieldContribution] = []
  let missing_fields : Array[String] = []
  let mut weighted_sum = 0.0
  let mut total_weight = 0.0
  for field_config in config.field_comparisons {
    let left = record_a.get_field(field_config.field_name)
    let right = record_b.get_field(field_config.field_name)
    let missing = left.is_null() || right.is_null()
    let raw_score = if missing {
      missing_fields.push(field_config.field_name)
      if field_config.missing_value_penalty < 0.0 {
        0.0
      } else {
        field_config.missing_value_penalty
      }
    } else {
      compare_field_values(left, right, field_config.metric)
    }
    let effective_weight = if field_config.weight < 0.0 {
      0.0
    } else {
      field_config.weight
    }
    if effective_weight > 0.0 {
      weighted_sum = weighted_sum + raw_score * effective_weight
      total_weight = total_weight + effective_weight
    }
    contributions.push({
      field_name: field_config.field_name,
      raw_score,
      weight: effective_weight,
      weighted_score: raw_score * effective_weight,
      missing,
    })
  }
  let score = if total_weight == 0.0 {
    0.0
  } else {
    weighted_sum / total_weight
  }
  let status = if score >= config.thresholds.match_threshold {
    @core.Match
  } else if score >= config.thresholds.non_match_threshold {
    @core.PossibleMatch
  } else {
    @core.NonMatch
  }
  {
    pair_id: record_a.id + "->" + record_b.id,
    field_contributions: contributions,
    missing_fields,
    composite_score: score,
    status,
    decision_reason: decision_reason(status, score),
  }
}
