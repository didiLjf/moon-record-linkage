// Canonical Record Merger: select or generate the canonical record
// for an entity cluster using various conflict resolution strategies.

///|
pub enum MergeStrategy {
  HighestConfidence
  MajorityVote
  MostRecent
  FirstRecord
} derive(Debug, Eq)

///|
pub struct CanonicalMerger {
  strategy : MergeStrategy
} derive(Debug, Eq)

///|
pub fn CanonicalMerger::new(
  strategy? : MergeStrategy = HighestConfidence,
) -> CanonicalMerger {
  { strategy, }
}

///|
/// Select the canonical record from a cluster given the merge strategy.
/// pair_scores maps record_id to its average score in the cluster.
pub fn CanonicalMerger::select_canonical(
  self : CanonicalMerger,
  records : Array[@core.Record],
  pair_scores? : Map[String, Double] = Map([]),
) -> @core.Record {
  if records.is_empty() {
    return @core.Record::new("empty-canonical")
  }
  match self.strategy {
    FirstRecord => records[0]
    HighestConfidence => {
      let mut best = records[0]
      let mut best_score = match pair_scores.get(records[0].id) {
        Some(s) => s
        None => 0.0
      }
      for i = 1; i < records.length(); i = i + 1 {
        let s = match pair_scores.get(records[i].id) {
          Some(sc) => sc
          None => 0.0
        }
        if s > best_score {
          best_score = s
          best = records[i]
        }
      }
      best
    }
    MostRecent => {
      let mut best = records[0]
      let mut best_ts = records[0].timestamp
      for i = 1; i < records.length(); i = i + 1 {
        if records[i].timestamp > best_ts {
          best_ts = records[i].timestamp
          best = records[i]
        }
      }
      best
    }
    MajorityVote => {
      // For each field, find the most common value
      let canonical = @core.Record::new(
        "canonical-" + records[0].id,
        source="merged",
        timestamp=records[0].timestamp,
      )
      // Collect all field names
      let all_fields : Map[String, Bool] = Map([])
      for rec in records {
        for entry in rec.attributes {
          all_fields.set(entry.0, true)
        }
      }
      for field_entry in all_fields {
        let fname = field_entry.0
        let freq : Map[String, Int] = Map([])
        for rec in records {
          let val = rec.get_string(fname)
          if !val.is_empty() {
            match freq.get(val) {
              Some(c) => freq.set(val, c + 1)
              None => freq.set(val, 1)
            }
          }
        }
        let mut best_val = ""
        let mut best_cnt = 0
        for fe in freq {
          if fe.1 > best_cnt {
            best_cnt = fe.1
            best_val = fe.0
          }
        }
        if !best_val.is_empty() {
          canonical.set_field(fname, @core.StringVal(best_val))
        }
      }
      canonical
    }
  }
}

///|
/// Merge a list of @core.EntityCluster objects using the canonical merger.
pub fn CanonicalMerger::merge_clusters(
  self : CanonicalMerger,
  clusters : Array[@core.EntityCluster],
  pair_scores? : Map[String, Double] = Map([]),
) -> Array[@core.EntityCluster] {
  let result : Array[@core.EntityCluster] = []
  for cluster in clusters {
    let canonical = self.select_canonical(cluster.records, pair_scores~)
    let merged = @core.EntityCluster::new(
      cluster.cluster_id,
      canonical,
      confidence=cluster.confidence,
    )
    for r in cluster.records {
      merged.add_record(r)
    }
    result.push(merged)
  }
  result
}
