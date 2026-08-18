///|
fn evaluation_key(left_id : String, right_id : String) -> String {
  left_id + "##" + right_id
}

///|
/// Evaluate predicted cross-dataset links against a gold set.
pub fn evaluate_pairs(
  predicted : Array[(String, String)],
  gold : Array[GoldPair],
) -> PairEvaluationReport {
  let gold_map : Map[String, Bool] = Map([])
  for pair in gold {
    gold_map.set(evaluation_key(pair.left_id, pair.right_id), pair.actual_match)
  }
  let seen : Map[String, Bool] = Map([])
  let mut true_positives = 0
  let mut false_positives = 0
  for pair in predicted {
    let key = evaluation_key(pair.0, pair.1)
    if seen.contains(key) {
      continue
    }
    seen.set(key, true)
    match gold_map.get(key) {
      Some(true) => true_positives = true_positives + 1
      _ => false_positives = false_positives + 1
    }
  }
  let mut false_negatives = 0
  for gold_pair in gold {
    let key = evaluation_key(gold_pair.left_id, gold_pair.right_id)
    if gold_pair.actual_match && !seen.contains(key) {
      false_negatives = false_negatives + 1
    }
  }
  {
    true_positives,
    false_positives,
    false_negatives,
    candidate_count: predicted.length(),
    gold_count: gold.length(),
  }
}
