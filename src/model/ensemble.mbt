///|
pub struct ModelComponent {
  name : String
  config : @core.LinkageConfig
  weight : Double
} derive(Debug)

///|
pub struct EnsembleDecision {
  score : Double
  status : @core.MatchStatus
  component_scores : Array[(String, Double)]
  disagreement : Double
  reason : String
} derive(Debug)

///|
pub struct EnsembleScorer {
  components : Array[ModelComponent]
} derive(Debug)

///|
pub fn EnsembleScorer::new() -> EnsembleScorer {
  { components: [] }
}

///|
pub fn EnsembleScorer::add_model(
  self : EnsembleScorer,
  name : String,
  config : @core.LinkageConfig,
  weight? : Double = 1.0,
) -> Unit {
  self.components.push({
    name,
    config,
    weight: if weight < 0.0 {
      0.0
    } else {
      weight
    },
  })
}

///|
fn ensemble_status(score : Double) -> @core.MatchStatus {
  if score >= 0.85 {
    @core.Match
  } else if score >= 0.45 {
    @core.PossibleMatch
  } else {
    @core.NonMatch
  }
}

///|
/// Aggregate several independently configured scorers and measure their spread.
pub fn EnsembleScorer::decide(
  self : EnsembleScorer,
  left : @core.Record,
  right : @core.Record,
) -> EnsembleDecision {
  let scores : Array[(String, Double)] = []
  let mut weighted_sum = 0.0
  let mut total_weight = 0.0
  for component in self.components {
    let score = explain_pair(component.config, left, right).composite_score
    scores.push((component.name, score))
    if component.weight > 0.0 {
      weighted_sum = weighted_sum + score * component.weight
      total_weight = total_weight + component.weight
    }
  }
  let score = if total_weight == 0.0 {
    0.0
  } else {
    weighted_sum / total_weight
  }
  let mut spread = 0.0
  if !scores.is_empty() {
    let mut min_score = scores[0].1
    let mut max_score = scores[0].1
    for item in scores {
      if item.1 < min_score {
        min_score = item.1
      }
      if item.1 > max_score {
        max_score = item.1
      }
    }
    spread = max_score - min_score
  }
  {
    score,
    status: ensemble_status(score),
    component_scores: scores,
    disagreement: spread,
    reason: "ensemble components=" + self.components.length().to_string(),
  }
}
