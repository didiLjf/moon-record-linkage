///|
/// Dataset-level quality indicators used before and after linkage runs.
pub struct QualitySummary {
  record_count : Int
  distinct_id_count : Int
  duplicate_id_count : Int
  source_count : Int
  field_count : Int
  missing_field_count : Int
  missing_field_rate : Double
  duplicate_id_rate : Double
  source_distribution : Map[String, Int]
} derive(Debug, Eq)

///|
pub struct QualityGateResult {
  accepted : Bool
  failures : Array[String]
} derive(Debug, Eq)

///|
pub fn QualityGateResult::failure_count(self : QualityGateResult) -> Int {
  self.failures.length()
}

///|
pub fn QualityGateResult::to_json(self : QualityGateResult) -> String {
  let sb = StringBuilder(size_hint=160)
  sb.write_string(
    "{\"accepted\":" + self.accepted.to_string() + ",\"failures\":[",
  )
  for i, failure in self.failures {
    if i > 0 {
      sb.write_char(',')
    }
    sb.write_string("\"" + failure + "\"")
  }
  sb.write_string("]}")
  sb.to_string()
}

///|
pub fn QualityGateResult::to_text(self : QualityGateResult) -> String {
  "accepted=" +
  self.accepted.to_string() +
  " failures=" +
  self.failures.join("; ")
}

///|
fn summary_source_distribution(records : Array[Record]) -> Map[String, Int] {
  let counts : Map[String, Int] = Map([])
  for record in records {
    match counts.get(record.source) {
      Some(value) => counts.set(record.source, value + 1)
      None => counts.set(record.source, 1)
    }
  }
  counts
}

///|
fn summary_field_count(records : Array[Record]) -> Int {
  let fields : Map[String, Bool] = Map([])
  for record in records {
    for entry in record.attributes {
      fields.set(entry.0, true)
    }
  }
  fields.length()
}

///|
fn summary_missing_count(records : Array[Record]) -> Int {
  let fields = summary_field_count(records)
  if records.length() == 0 || fields == 0 {
    return 0
  }
  let mut count = 0
  for record in records {
    for field_name in record.attributes.keys() {
      if record.get_field(field_name).is_null() {
        count = count + 1
      }
    }
  }
  count
}

///|
/// Build a deterministic quality summary without mutating input records.
pub fn quality_summary(records : Array[Record]) -> QualitySummary {
  let profile = profile_dataset(records)
  let source_distribution = summary_source_distribution(records)
  let field_count = summary_field_count(records)
  let missing_field_count = summary_missing_count(records)
  let total_cells = records.length() * field_count
  {
    record_count: profile.record_count,
    distinct_id_count: profile.distinct_id_count,
    duplicate_id_count: profile.duplicate_id_count,
    source_count: source_distribution.length(),
    field_count,
    missing_field_count,
    missing_field_rate: if total_cells == 0 {
      0.0
    } else {
      missing_field_count.to_double() / total_cells.to_double()
    },
    duplicate_id_rate: if records.length() == 0 {
      0.0
    } else {
      profile.duplicate_id_count.to_double() / records.length().to_double()
    },
    source_distribution,
  }
}

///|
pub fn QualitySummary::has_data(self : QualitySummary) -> Bool {
  self.record_count > 0
}

///|
pub fn QualitySummary::record_density(self : QualitySummary) -> Double {
  if self.source_count == 0 {
    0.0
  } else {
    self.record_count.to_double() / self.source_count.to_double()
  }
}

///|
pub fn QualitySummary::to_text(self : QualitySummary) -> String {
  "records=" +
  self.record_count.to_string() +
  " distinct_ids=" +
  self.distinct_id_count.to_string() +
  " duplicate_ids=" +
  self.duplicate_id_count.to_string() +
  " sources=" +
  self.source_count.to_string() +
  " fields=" +
  self.field_count.to_string() +
  " missing_rate=" +
  self.missing_field_rate.to_string() +
  " duplicate_rate=" +
  self.duplicate_id_rate.to_string()
}

///|
pub fn QualitySummary::to_json(self : QualitySummary) -> String {
  "{\"record_count\":" +
  self.record_count.to_string() +
  ",\"distinct_id_count\":" +
  self.distinct_id_count.to_string() +
  ",\"duplicate_id_count\":" +
  self.duplicate_id_count.to_string() +
  ",\"source_count\":" +
  self.source_count.to_string() +
  ",\"field_count\":" +
  self.field_count.to_string() +
  ",\"missing_field_count\":" +
  self.missing_field_count.to_string() +
  ",\"missing_field_rate\":" +
  self.missing_field_rate.to_string() +
  ",\"duplicate_id_rate\":" +
  self.duplicate_id_rate.to_string() +
  "}"
}

///|
pub fn QualitySummary::source_count_for(
  self : QualitySummary,
  source : String,
) -> Int {
  match self.source_distribution.get(source) {
    Some(count) => count
    None => 0
  }
}

///|
/// Return a stable CSV fragment for source-level operational dashboards.
pub fn QualitySummary::source_distribution_csv(self : QualitySummary) -> String {
  let sb = StringBuilder(size_hint=128)
  sb.write_string("source,record_count\n")
  for item in self.source_distribution {
    sb.write_string(item.0 + "," + item.1.to_string() + "\n")
  }
  sb.to_string()
}

///|
pub fn QualitySummary::to_csv(self : QualitySummary) -> String {
  let sb = StringBuilder(size_hint=256)
  sb.write_string("metric,value\n")
  sb.write_string("record_count," + self.record_count.to_string() + "\n")
  sb.write_string(
    "distinct_id_count," + self.distinct_id_count.to_string() + "\n",
  )
  sb.write_string(
    "duplicate_id_count," + self.duplicate_id_count.to_string() + "\n",
  )
  sb.write_string("source_count," + self.source_count.to_string() + "\n")
  sb.write_string("field_count," + self.field_count.to_string() + "\n")
  sb.write_string(
    "missing_field_rate," + self.missing_field_rate.to_string() + "\n",
  )
  sb.write_string(
    "duplicate_id_rate," + self.duplicate_id_rate.to_string() + "\n",
  )
  sb.to_string()
}

///|
pub fn QualitySummary::source_distribution_markdown(
  self : QualitySummary,
) -> String {
  let sb = StringBuilder(size_hint=128)
  sb.write_string("| source | records |\n| --- | ---: |\n")
  for item in self.source_distribution {
    sb.write_string("| " + item.0 + " | " + item.1.to_string() + " |\n")
  }
  sb.to_string()
}

///|
pub fn QualitySummary::to_markdown(self : QualitySummary) -> String {
  let sb = StringBuilder(size_hint=256)
  sb.write_string("| metric | value |\n| --- | ---: |\n")
  sb.write_string("| records | " + self.record_count.to_string() + " |\n")
  sb.write_string(
    "| distinct IDs | " + self.distinct_id_count.to_string() + " |\n",
  )
  sb.write_string(
    "| duplicate IDs | " + self.duplicate_id_count.to_string() + " |\n",
  )
  sb.write_string("| sources | " + self.source_count.to_string() + " |\n")
  sb.write_string("| fields | " + self.field_count.to_string() + " |\n")
  sb.write_string(
    "| missing rate | " + self.missing_field_rate.to_string() + " |\n",
  )
  sb.write_string(
    "| duplicate rate | " + self.duplicate_id_rate.to_string() + " |\n",
  )
  sb.to_string()
}

///|
pub fn QualitySummary::risk_level(self : QualitySummary) -> String {
  if self.missing_field_rate > 0.5 || self.duplicate_id_rate > 0.2 {
    "high"
  } else if self.missing_field_rate > 0.2 || self.duplicate_id_rate > 0.05 {
    "medium"
  } else {
    "low"
  }
}

///|
/// Combine missingness and duplicate rates into a bounded quality score.
pub fn QualitySummary::quality_score(self : QualitySummary) -> Double {
  let score = 1.0 - (self.missing_field_rate + self.duplicate_id_rate) / 2.0
  if score < 0.0 {
    0.0
  } else if score > 1.0 {
    1.0
  } else {
    score
  }
}

///|
pub fn QualitySummary::is_acceptable(
  self : QualitySummary,
  max_missing_rate~ : Double,
  max_duplicate_rate~ : Double,
) -> Bool {
  self.missing_field_rate <= max_missing_rate &&
  self.duplicate_id_rate <= max_duplicate_rate
}

///|
/// Evaluate independent quality thresholds and retain actionable failure reasons.
pub fn QualitySummary::evaluate_gate(
  self : QualitySummary,
  max_missing_rate~ : Double,
  max_duplicate_rate~ : Double,
) -> QualityGateResult {
  let failures : Array[String] = []
  if self.missing_field_rate > max_missing_rate {
    failures.push("missing_field_rate exceeds threshold")
  }
  if self.duplicate_id_rate > max_duplicate_rate {
    failures.push("duplicate_id_rate exceeds threshold")
  }
  { accepted: failures.length() == 0, failures }
}
