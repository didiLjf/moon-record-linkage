///|
fn pair_key(left_id : String, right_id : String) -> String {
  left_id + "##" + right_id
}

///|
fn full_cartesian(
  records_a : Array[@core.Record],
  records_b : Array[@core.Record],
) -> Array[(String, String)] {
  let pairs : Array[(String, String)] = []
  for left in records_a {
    for right in records_b {
      pairs.push((left.id, right.id))
    }
  }
  pairs
}

///|
fn cross_filter(
  pairs : Array[(String, String)],
  left_ids : Map[String, Bool],
  right_ids : Map[String, Bool],
) -> Array[(String, String)] {
  let result : Array[(String, String)] = []
  for pair in pairs {
    if left_ids.contains(pair.0) && right_ids.contains(pair.1) {
      result.push(pair)
    } else if left_ids.contains(pair.1) && right_ids.contains(pair.0) {
      result.push((pair.1, pair.0))
    }
  }
  result
}

///|
fn strategy_pairs(
  strategy : @core.BlockingStrategy,
  records_a : Array[@core.Record],
  records_b : Array[@core.Record],
  left_ids : Map[String, Bool],
  right_ids : Map[String, Bool],
) -> (String, Array[(String, String)]) {
  match strategy {
    @core.StandardBlocking(fields) => {
      let index_a = BlockingIndex::new(fields)
      let index_b = BlockingIndex::new(fields)
      index_a.build_from(records_a)
      index_b.build_from(records_b)
      (
        "standard[" + fields.join(",") + "]",
        cross_match_pairs(index_a, index_b),
      )
    }
    @core.SortedNeighborhood(field, window) => {
      let blocker = SNMBlocker::new(field, window_size=window)
      (
        "sorted_neighborhood",
        blocker.cross_candidate_pairs(records_a, records_b),
      )
    }
    @core.CanopyClustering(field, t1, t2) => {
      let blocker = CanopyBlocker::new(field, t1~, t2~)
      let all : Array[@core.Record] = []
      for record in records_a {
        all.push(record)
      }
      for record in records_b {
        all.push(record)
      }
      let pairs = canopies_to_pairs(blocker.build_canopies(all))
      ("canopy", cross_filter(pairs, left_ids, right_ids))
    }
    @core.LocalitySensitiveHashing(field, hashes, bands) => {
      let blocker = LSHBlocker::new(field, num_hashes=hashes, num_bands=bands)
      let all : Array[@core.Record] = []
      for record in records_a {
        all.push(record)
      }
      for record in records_b {
        all.push(record)
      }
      let pairs = blocker.candidate_pairs(all)
      ("lsh", cross_filter(pairs, left_ids, right_ids))
    }
    @core.CompositeBlocking(children) => {
      let merged : Array[(String, String)] = []
      for child in children {
        let (_, pairs) = strategy_pairs(
          child, records_a, records_b, left_ids, right_ids,
        )
        for pair in pairs {
          merged.push(pair)
        }
      }
      ("composite", merged)
    }
  }
}

///|
fn add_origin(
  pair_map : Map[String, CandidatePair],
  pair : (String, String),
  origin : String,
  keep_empty_keys : Bool,
) -> Bool {
  if !keep_empty_keys && (pair.0.is_empty() || pair.1.is_empty()) {
    return false
  }
  let key = pair_key(pair.0, pair.1)
  match pair_map.get(key) {
    Some(existing) =>
      if !existing.origins.contains(origin) {
        existing.origins.push(origin)
      }
    None =>
      pair_map.set(key, { left_id: pair.0, right_id: pair.1, origins: [origin] })
  }
  true
}

///|
fn build_plan(
  strategy_outputs : Array[(String, Array[(String, String)])],
  mode : PlanMode,
  options : PlannerOptions,
) -> CandidatePlan {
  let mut raw_pair_count = 0
  for output in strategy_outputs {
    raw_pair_count = raw_pair_count + output.1.length()
  }
  let pair_map : Map[String, CandidatePair] = Map([])
  let strategy_counts : Map[String, Int] = Map([])
  let chosen : Array[(String, Array[(String, String)])] = []
  match mode {
    Union =>
      for output in strategy_outputs {
        chosen.push(output)
      }
    Intersection =>
      if !strategy_outputs.is_empty() {
        chosen.push(strategy_outputs[0])
      }
    Fallback =>
      for output in strategy_outputs {
        if output.1.length() > 0 {
          chosen.push(output)
          break
        }
      }
  }
  if mode is Intersection && !strategy_outputs.is_empty() {
    let occurrence : Map[String, Int] = Map([])
    for output in strategy_outputs {
      let seen_in_strategy : Map[String, Bool] = Map([])
      for pair in output.1 {
        let key = pair_key(pair.0, pair.1)
        if !seen_in_strategy.contains(key) {
          seen_in_strategy.set(key, true)
          match occurrence.get(key) {
            Some(count) => occurrence.set(key, count + 1)
            None => occurrence.set(key, 1)
          }
        }
      }
    }
    let required = strategy_outputs.length()
    for output in strategy_outputs {
      for pair in output.1 {
        let key = pair_key(pair.0, pair.1)
        if occurrence.get(key) is Some(count) && count == required {
          let _ = add_origin(pair_map, pair, output.0, options.keep_empty_keys)
        }
      }
    }
  } else {
    for output in chosen {
      let mut retained = 0
      for pair in output.1 {
        if add_origin(pair_map, pair, output.0, options.keep_empty_keys) {
          retained = retained + 1
        }
      }
      strategy_counts.set(output.0, retained)
    }
  }
  if mode is Intersection {
    for pair in pair_map {
      strategy_counts.set("intersection", pair.1.origins.length())
    }
  }
  let pairs : Array[CandidatePair] = []
  let mut truncated = false
  for entry in pair_map {
    if options.max_pairs == 0 || pairs.length() < options.max_pairs {
      pairs.push(entry.1)
    } else {
      truncated = true
    }
  }
  {
    pairs,
    strategy_counts,
    raw_pair_count,
    deduplicated_pair_count: pair_map.length(),
    truncated,
  }
}

///|
/// Plan and explain candidate pairs from all configured blocking strategies.
pub fn plan_candidates(
  records_a : Array[@core.Record],
  records_b : Array[@core.Record],
  strategies : Array[@core.BlockingStrategy],
  options~ : PlannerOptions,
) -> CandidatePlan {
  let left_ids : Map[String, Bool] = Map([])
  let right_ids : Map[String, Bool] = Map([])
  for record in records_a {
    left_ids.set(record.id, true)
  }
  for record in records_b {
    right_ids.set(record.id, true)
  }
  if strategies.is_empty() {
    return build_plan(
      [("cartesian", full_cartesian(records_a, records_b))],
      options.mode,
      options,
    )
  }
  let outputs : Array[(String, Array[(String, String)])] = []
  for strategy in strategies {
    outputs.push(
      strategy_pairs(strategy, records_a, records_b, left_ids, right_ids),
    )
  }
  build_plan(outputs, options.mode, options)
}
