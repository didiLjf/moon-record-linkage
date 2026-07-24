// Hybrid Scorer: combines probabilistic FS weights with rule-based matches
// and fuzzy similarity scores into a unified composite score.

///|
pub struct FieldScorerConfig {
  field_name : String
  weight : Double
  agreement_threshold : Double
} derive(Debug, Eq)

///|
pub fn FieldScorerConfig::new(
  field_name : String,
  weight? : Double = 1.0,
  agreement_threshold? : Double = 0.8,
) -> FieldScorerConfig {
  { field_name, weight, agreement_threshold }
}

///|
pub struct HybridScorer {
  field_configs : Array[FieldScorerConfig]
  fs_model : FellegiSunterModel
  rule_set : RuleSet
  rule_weight : Double
  fs_weight : Double
  fuzzy_weight : Double
} derive(Debug)

///|
pub fn HybridScorer::new(
  fs_model : FellegiSunterModel,
  rule_set : RuleSet,
  rule_weight? : Double = 0.2,
  fs_weight? : Double = 0.5,
  fuzzy_weight? : Double = 0.3,
) -> HybridScorer {
  {
    field_configs: [],
    fs_model,
    rule_set,
    rule_weight,
    fs_weight,
    fuzzy_weight,
  }
}

///|
pub fn HybridScorer::add_field(
  self : HybridScorer,
  config : FieldScorerConfig,
) -> Unit {
  self.field_configs.push(config)
}

///|
/// Compute the composite score for a pair of records.
/// Returns a (total_score, MatchPair) tuple.
pub fn HybridScorer::score_pair(
  self : HybridScorer,
  record_a : @core.Record,
  record_b : @core.Record,
) -> @core.MatchPair {
  // 1. Compute per-field similarities
  let ctx = RuleContext::new(record_a, record_b)
  let agreements : Array[Bool] = []
  let mut fuzzy_score = 0.0
  let mut total_weight = 0.0
  for fc in self.field_configs {
    let val_a = record_a.get_string(fc.field_name)
    let val_b = record_b.get_string(fc.field_name)
    let sim = if val_a.is_empty() || val_b.is_empty() {
      0.0
    } else {
      @similarity.jaro_winkler(val_a, val_b)
    }
    ctx.set_similarity(fc.field_name, sim)
    agreements.push(sim >= fc.agreement_threshold)
    fuzzy_score = fuzzy_score + sim * fc.weight
    total_weight = total_weight + fc.weight
  }
  let norm_fuzzy = if total_weight > 0.0 {
    fuzzy_score / total_weight
  } else {
    0.0
  }
  // 2. FS model weight
  let fs_raw = self.fs_model.compute_weight(agreements)
  // Normalize FS weight to [0, 1] with a sigmoid-like function
  let fs_norm = 1.0 / (1.0 + double_exp_model(-fs_raw / 3.0))
  // 3. Rule match score
  let rule_score = if self.rule_set.evaluate(ctx) { 1.0 } else { 0.0 }
  // 4. Composite score
  let composite = self.rule_weight * rule_score +
    self.fs_weight * fs_norm +
    self.fuzzy_weight * norm_fuzzy
  // 5. Determine match status
  let status = if composite >= 0.8 {
    @core.Match
  } else if composite >= 0.5 {
    @core.PossibleMatch
  } else {
    @core.NonMatch
  }
  let pair = @core.MatchPair::new(record_a, record_b, composite, status)
  for fc in self.field_configs {
    let sim = ctx.get_similarity(fc.field_name)
    pair.set_field_score(fc.field_name, sim)
  }
  pair
}

///|
fn double_exp_model(x : Double) -> Double {
  if x > 15.0 {
    return 3269446.0
  }
  if x < -15.0 {
    return 0.00000030
  }
  let x2 = x * x
  let x3 = x2 * x
  let x4 = x3 * x
  let x5 = x4 * x
  let x6 = x5 * x
  1.0 + x + x2 / 2.0 + x3 / 6.0 + x4 / 24.0 + x5 / 120.0 + x6 / 720.0
}
