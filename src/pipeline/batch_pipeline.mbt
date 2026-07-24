// Batch Linkage Pipeline: links two datasets or deduplicates a single dataset.
// Composes: blocking -> comparison -> scoring -> clustering.

///|
pub struct BatchLinkageResult {
  match_pairs : Array[@core.MatchPair]
  possible_pairs : Array[@core.MatchPair]
  clusters : Array[@core.EntityCluster]
  metrics : @core.EvaluationMetrics
  mut candidate_pair_count : Int
} derive(Debug)

///|
pub fn BatchLinkageResult::new() -> BatchLinkageResult {
  {
    match_pairs: [],
    possible_pairs: [],
    clusters: [],
    metrics: @core.EvaluationMetrics::new(),
    candidate_pair_count: 0,
  }
}

///|
pub struct BatchPipeline {
  config : @core.LinkageConfig
  record_lookup : Map[String, @core.Record]
} derive(Debug)

///|
pub fn BatchPipeline::new(config : @core.LinkageConfig) -> BatchPipeline {
  { config, record_lookup: Map([]) }
}

///|
fn BatchPipeline::build_lookup(
  self : BatchPipeline,
  records : Array[@core.Record],
) -> Unit {
  for r in records {
    self.record_lookup.set(r.id, r)
  }
}

///|
/// Generate candidate pairs using the configured blocking strategies.
fn BatchPipeline::get_candidate_pairs(
  self : BatchPipeline,
  records_a : Array[@core.Record],
  records_b : Array[@core.Record],
) -> Array[(String, String)] {
  if self.config.blocking_strategies.is_empty() {
    // No blocking: full Cartesian product
    let pairs : Array[(String, String)] = []
    for ra in records_a {
      for rb in records_b {
        pairs.push((ra.id, rb.id))
      }
    }
    return pairs
  }
  // Use first configured blocking strategy
  let strategy = self.config.blocking_strategies[0]
  match strategy {
    @core.StandardBlocking(fields) => {
      let idx_a = @blocking.BlockingIndex::new(fields)
      let idx_b = @blocking.BlockingIndex::new(fields)
      idx_a.build_from(records_a)
      idx_b.build_from(records_b)
      @blocking.cross_match_pairs(idx_a, idx_b)
    }
    @core.SortedNeighborhood(field, window) => {
      let snm = @blocking.SNMBlocker::new(field, window_size=window)
      snm.cross_candidate_pairs(records_a, records_b)
    }
    @core.LocalitySensitiveHashing(field, num_hashes, bands) => {
      let lsh = @blocking.LSHBlocker::new(field, num_hashes~, num_bands=bands)
      let all_records = []
      for r in records_a {
        all_records.push(r)
      }
      for r in records_b {
        all_records.push(r)
      }
      lsh.candidate_pairs(all_records)
    }
    _ => {
      // Default: standard blocking by first field comparison
      let field_name = if !self.config.field_comparisons.is_empty() {
        self.config.field_comparisons[0].field_name
      } else {
        "id"
      }
      let idx_a = @blocking.BlockingIndex::new([field_name])
      let idx_b = @blocking.BlockingIndex::new([field_name])
      idx_a.build_from(records_a)
      idx_b.build_from(records_b)
      @blocking.cross_match_pairs(idx_a, idx_b)
    }
  }
}

///|
/// Score a single candidate pair using field comparisons.
fn BatchPipeline::score_pair(
  self : BatchPipeline,
  rec_a : @core.Record,
  rec_b : @core.Record,
) -> @core.MatchPair {
  let field_scores : Map[String, Double] = Map([])
  let mut weighted_sum = 0.0
  let mut total_weight = 0.0
  for fc in self.config.field_comparisons {
    let val_a = rec_a.get_string(fc.field_name)
    let val_b = rec_b.get_string(fc.field_name)
    let sim = if val_a.is_empty() || val_b.is_empty() {
      0.0
    } else {
      calculate_similarity_score(val_a, val_b, fc.metric)
    }
    field_scores.set(fc.field_name, sim)
    weighted_sum = weighted_sum + sim * fc.weight
    total_weight = total_weight + fc.weight
  }
  let composite = if total_weight > 0.0 {
    weighted_sum / total_weight
  } else {
    0.0
  }
  let status = if composite >= self.config.thresholds.match_threshold {
    @core.Match
  } else if composite >= self.config.thresholds.non_match_threshold {
    @core.PossibleMatch
  } else {
    @core.NonMatch
  }
  let pair = @core.MatchPair::new(rec_a, rec_b, composite, status)
  for entry in field_scores {
    pair.set_field_score(entry.0, entry.1)
  }
  pair
}

///|
/// Run the full batch linkage pipeline: records_a vs records_b.
pub fn BatchPipeline::run_link(
  self : BatchPipeline,
  records_a : Array[@core.Record],
  records_b : Array[@core.Record],
) -> BatchLinkageResult {
  self.build_lookup(records_a)
  self.build_lookup(records_b)
  let result = BatchLinkageResult::new()
  let candidate_pairs = self.get_candidate_pairs(records_a, records_b)
  result.candidate_pair_count = candidate_pairs.length()
  let graph = @graph.EntityGraph::new()
  for ra in records_a {
    graph.add_record(ra.id)
  }
  for rb in records_b {
    graph.add_record(rb.id)
  }
  for pair in candidate_pairs {
    match (self.record_lookup.get(pair.0), self.record_lookup.get(pair.1)) {
      (Some(ra), Some(rb)) => {
        let match_pair = self.score_pair(ra, rb)
        match match_pair.status {
          @core.Match => {
            result.match_pairs.push(match_pair)
            graph.add_match(pair.0, pair.1, match_pair.score, threshold=0.5)
          }
          @core.PossibleMatch => result.possible_pairs.push(match_pair)
          @core.NonMatch => ()
        }
      }
      _ => ()
    }
  }
  let components = graph.clusters()
  let merger = @graph.CanonicalMerger::new()
  let mut cluster_idx = 0
  for entry in components {
    let root = entry.0
    let members = entry.1
    let canonical = match self.record_lookup.get(root) {
      Some(r) => r
      None => @core.Record::new(root)
    }
    let cluster = @core.EntityCluster::new(
      "cluster-" + cluster_idx.to_string(),
      canonical,
    )
    for mid in members {
      match self.record_lookup.get(mid) {
        Some(r) => cluster.add_record(r)
        None => ()
      }
    }
    let _ = merger
    result.clusters.push(cluster)
    cluster_idx = cluster_idx + 1
  }
  result
}

///|
/// Run deduplication on a single dataset.
pub fn BatchPipeline::run_dedup(
  self : BatchPipeline,
  records : Array[@core.Record],
) -> BatchLinkageResult {
  self.build_lookup(records)
  let result = BatchLinkageResult::new()
  let idx = @blocking.BlockingIndex::new(
    if !self.config.field_comparisons.is_empty() {
      [self.config.field_comparisons[0].field_name]
    } else {
      ["id"]
    },
  )
  idx.build_from(records)
  let candidate_pairs = idx.candidate_pairs()
  result.candidate_pair_count = candidate_pairs.length()
  let graph = @graph.EntityGraph::new()
  for r in records {
    graph.add_record(r.id)
  }
  for pair in candidate_pairs {
    match (self.record_lookup.get(pair.0), self.record_lookup.get(pair.1)) {
      (Some(ra), Some(rb)) => {
        let match_pair = self.score_pair(ra, rb)
        match match_pair.status {
          @core.Match => {
            result.match_pairs.push(match_pair)
            graph.add_match(pair.0, pair.1, match_pair.score, threshold=0.5)
          }
          @core.PossibleMatch => result.possible_pairs.push(match_pair)
          @core.NonMatch => ()
        }
      }
      _ => ()
    }
  }
  result
}

///|
/// Compute similarity for a given metric type.
fn calculate_similarity_score(
  a : String,
  b : String,
  metric : @core.MetricType,
) -> Double {
  match metric {
    @core.ExactMatch => if a == b { 1.0 } else { 0.0 }
    @core.JaroWinkler => @similarity.jaro_winkler(a, b)
    @core.Levenshtein => @similarity.levenshtein_similarity(a, b)
    @core.DamerauLevenshtein => @similarity.damerau_levenshtein_similarity(a, b)
    @core.JaccardNgram(n) => {
      let chars_a = a.to_array()
      let chars_b = b.to_array()
      let n_a = chars_a.length()
      let n_b = chars_b.length()
      if n_a < n || n_b < n {
        if a == b {
          1.0
        } else {
          0.0
        }
      } else {
        @similarity.ngram_jaccard(a, b, n~)
      }
    }
    @core.PhoneticSoundex => {
      let sim = @similarity.jaro_winkler(a, b)
      if sim >= 0.85 {
        1.0
      } else {
        sim
      }
    }
    @core.PhoneticMetaphone => {
      let sim = @similarity.jaro_winkler(a, b)
      if sim >= 0.85 {
        1.0
      } else {
        sim
      }
    }
    _ => @similarity.jaro_winkler(a, b)
  }
}
