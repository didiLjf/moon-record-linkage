///|
pub fn plan_summary(
  plan : CandidatePlan,
  left_count~ : Int,
  right_count~ : Int,
) -> String {
  "raw=" +
  plan.raw_pair_count.to_string() +
  " unique=" +
  plan.deduplicated_pair_count.to_string() +
  " returned=" +
  plan.pairs.length().to_string() +
  " reduction=" +
  plan.reduction_ratio(left_count, right_count).to_string() +
  " truncated=" +
  plan.truncated.to_string()
}

///|
pub fn candidate_plan_to_markdown(
  plan : CandidatePlan,
  left_count~ : Int,
  right_count~ : Int,
) -> String {
  let sb = StringBuilder(size_hint=512)
  sb.write_string("| Candidate Plan | Value |\n|---|---:|\n")
  sb.write_string("| Raw pairs | " + plan.raw_pair_count.to_string() + " |\n")
  sb.write_string(
    "| Unique pairs | " + plan.deduplicated_pair_count.to_string() + " |\n",
  )
  sb.write_string(
    "| Returned pairs | " + plan.pairs.length().to_string() + " |\n",
  )
  sb.write_string(
    "| Reduction | " +
    plan.reduction_ratio(left_count, right_count).to_string() +
    " |\n",
  )
  sb.write_string("| Truncated | " + plan.truncated.to_string() + " |\n")
  sb.to_string()
}
