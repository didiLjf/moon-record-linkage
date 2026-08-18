///|
/// Operational summary of scored candidate pairs.
pub struct ResultAnalysis {
  total_pairs : Int
  matches : Int
  possible_matches : Int
  non_matches : Int
  high_confidence_count : Int
  average_score : Double
  minimum_score : Double
  maximum_score : Double
} derive(Debug, Eq)

///|
pub fn analyze_match_pairs(
  pairs : Array[@core.MatchPair],
  high_confidence_threshold? : Double = 0.9,
) -> ResultAnalysis {
  let threshold = if high_confidence_threshold < 0.0 {
    0.0
  } else if high_confidence_threshold > 1.0 {
    1.0
  } else {
    high_confidence_threshold
  }
  let mut matches = 0
  let mut possible_matches = 0
  let mut non_matches = 0
  let mut high_confidence_count = 0
  let mut total_score = 0.0
  let mut minimum_score = 1.0
  let mut maximum_score = 0.0
  for pair in pairs {
    match pair.status {
      @core.Match => matches = matches + 1
      @core.PossibleMatch => possible_matches = possible_matches + 1
      @core.NonMatch => non_matches = non_matches + 1
    }
    if pair.score >= threshold {
      high_confidence_count = high_confidence_count + 1
    }
    total_score = total_score + pair.score
    if pair.score < minimum_score {
      minimum_score = pair.score
    }
    if pair.score > maximum_score {
      maximum_score = pair.score
    }
  }
  let total_pairs = pairs.length()
  {
    total_pairs,
    matches,
    possible_matches,
    non_matches,
    high_confidence_count,
    average_score: if total_pairs == 0 {
      0.0
    } else {
      total_score / total_pairs.to_double()
    },
    minimum_score: if total_pairs == 0 {
      0.0
    } else {
      minimum_score
    },
    maximum_score: if total_pairs == 0 {
      0.0
    } else {
      maximum_score
    },
  }
}

///|
pub fn ResultAnalysis::status_rate(
  self : ResultAnalysis,
  count : Int,
) -> Double {
  if self.total_pairs == 0 {
    0.0
  } else {
    count.to_double() / self.total_pairs.to_double()
  }
}

///|
/// Serialize the analysis for dashboards and downstream acceptance tooling.
pub fn result_analysis_to_json(analysis : ResultAnalysis) -> String {
  "{\"total_pairs\":" +
  analysis.total_pairs.to_string() +
  ",\"matches\":" +
  analysis.matches.to_string() +
  ",\"possible_matches\":" +
  analysis.possible_matches.to_string() +
  ",\"non_matches\":" +
  analysis.non_matches.to_string() +
  ",\"high_confidence_count\":" +
  analysis.high_confidence_count.to_string() +
  ",\"average_score\":" +
  analysis.average_score.to_string() +
  ",\"minimum_score\":" +
  analysis.minimum_score.to_string() +
  ",\"maximum_score\":" +
  analysis.maximum_score.to_string() +
  "}"
}

///|
pub fn result_analysis_to_text(analysis : ResultAnalysis) -> String {
  "pairs=" +
  analysis.total_pairs.to_string() +
  " matches=" +
  analysis.matches.to_string() +
  " possible=" +
  analysis.possible_matches.to_string() +
  " non_matches=" +
  analysis.non_matches.to_string() +
  " high_confidence=" +
  analysis.high_confidence_count.to_string() +
  " average_score=" +
  analysis.average_score.to_string()
}
