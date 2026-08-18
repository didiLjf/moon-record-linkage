// Moon-Record-Linkage Engine Demonstration CLI

///|
pub fn run_demo() -> Unit {
  println("=================================================================")
  println("   MoonBit Entity Matching & Record Linkage Engine (v0.1.0)     ")
  println("=================================================================")

  // 1. Normalization & Cleaning Demo
  println("\n--- [1] Text Normalization & Cleaning ---")
  let raw_company = "  北京天工创新科技有限公司(海淀分公司)  "
  let clean_company = @normalization.normalize_company_name(raw_company)
  println("Raw Company Name: '" + raw_company + "'")
  println("Cleaned Company:  '" + clean_company + "'")

  let raw_phone = "+86 138-1234-5678"
  let clean_phone = @normalization.normalize_phone(raw_phone)
  println("Raw Phone: '" + raw_phone + "' -> Cleaned: '" + clean_phone + "'")

  // 2. Phonetic Encodings Demo
  println("\n--- [2] Phonetic Algorithms ---")
  let name1 = "Robert"
  let name2 = "Rupert"
  println("Soundex('" + name1 + "') = " + @phonetic.soundex(name1))
  println("Soundex('" + name2 + "') = " + @phonetic.soundex(name2))
  println("Soundex Match: " + @phonetic.soundex_match(name1, name2).to_string())

  println("Metaphone('Smith') = " + @phonetic.metaphone("Smith"))
  println("Metaphone('Smyth') = " + @phonetic.metaphone("Smyth"))

  // 3. Similarity Metrics Demo
  println("\n--- [3] Multi-Field Similarity Distance Metrics ---")
  let s1 = "JOHNNY DEPP"
  let s2 = "JOHN DEPP"
  println(
    "Levenshtein Distance: " +
    @similarity.levenshtein_distance(s1, s2).to_string(),
  )
  println(
    "Levenshtein Similarity: " +
    @similarity.levenshtein_similarity(s1, s2).to_string(),
  )
  println(
    "Jaro-Winkler Score:    " + @similarity.jaro_winkler(s1, s2).to_string(),
  )
  println(
    "N-Gram Jaccard Score:  " +
    @similarity.ngram_jaccard(s1, s2, n=2).to_string(),
  )

  // 4. Batch Record Linkage Pipeline Demo
  println("\n--- [4] Batch Record Linkage & Deduplication Pipeline ---")
  let cfg = @core.LinkageConfig::new("demo-pipeline")
  cfg.add_blocking(@core.StandardBlocking(["name"]))
  cfg.add_field_comparison("name", @core.JaroWinkler, weight=2.0)
  cfg.add_field_comparison("city", @core.ExactMatch, weight=1.0)
  cfg.set_thresholds(0.75, 0.45)

  let pipeline = @pipeline.BatchPipeline::new(cfg)

  // Construct Dataset A (Customer DB 1)
  let records_a : Array[@core.Record] = []
  let r_a1 = @core.Record::new("A001", source="CRM_1")
  r_a1.set_field("name", @core.StringVal("Zhang San"))
  r_a1.set_field("city", @core.StringVal("Beijing"))
  records_a.push(r_a1)

  let r_a2 = @core.Record::new("A002", source="CRM_1")
  r_a2.set_field("name", @core.StringVal("Li Si"))
  r_a2.set_field("city", @core.StringVal("Shanghai"))
  records_a.push(r_a2)

  // Construct Dataset B (Customer DB 2 with slight typos)
  let records_b : Array[@core.Record] = []
  let r_b1 = @core.Record::new("B001", source="CRM_2")
  r_b1.set_field("name", @core.StringVal("Zhang San"))
  r_b1.set_field("city", @core.StringVal("Beijing"))
  records_b.push(r_b1)

  let r_b2 = @core.Record::new("B002", source="CRM_2")
  r_b2.set_field("name", @core.StringVal("Li Sii"))
  r_b2.set_field("city", @core.StringVal("Shanghai"))
  records_b.push(r_b2)

  println("Dataset A: " + records_a.length().to_string() + " records")
  println("Dataset B: " + records_b.length().to_string() + " records")

  let result = pipeline.run_link(records_a, records_b)
  println("Candidates Evaluated: " + result.candidate_pair_count.to_string())
  println("Matched Pairs Found:  " + result.match_pairs.length().to_string())
  println("Entity Clusters Formed: " + result.clusters.length().to_string())

  // 5. Exporter & Report Generation Demo
  println("\n--- [5] JSON / CSV Export & Performance Report ---")
  let json_output = @export.linkage_result_to_json(result)
  println("JSON Summary (first 120 chars):")
  println(truncate_string(json_output, 120))

  let csv_output = @export.match_pairs_to_csv(result.match_pairs)
  println("\nCSV Output:")
  println(csv_output)

  let metrics = @core.EvaluationMetrics::new()
  metrics.add_observation(true, true)
  metrics.add_observation(true, true)
  metrics.add_observation(false, false)
  metrics.add_observation(false, false)
  println(@export.format_metrics_report(metrics))
}

///|
fn truncate_string(s : String, max_len : Int) -> String {
  let chars = s.to_array()
  if chars.length() <= max_len {
    s
  } else {
    let sb = StringBuilder(size_hint=max_len + 3)
    for i = 0; i < max_len; i = i + 1 {
      sb.write_char(chars[i])
    }
    sb.write_string("...")
    sb.to_string()
  }
}

///|
pub struct CliOptions {
  mode : String
  records : Int
  seed : Int
} derive(Debug, Eq)

///|
fn parse_positive_int(value : String, fallback : Int) -> Int {
  let chars = value.to_array()
  if chars.is_empty() {
    return fallback
  }
  let mut result = 0
  for ch in chars {
    if ch < '0' || ch > '9' {
      return fallback
    }
    result = result * 10 + (ch.to_int() - '0'.to_int())
  }
  result
}

///|
pub fn parse_cli_options(args : Array[String]) -> CliOptions {
  let mode = if args.length() > 1 { args[1] } else { "demo" }
  let mut records = 100
  let mut seed = 1
  let mut index = 2
  while index < args.length() {
    if args[index] == "--records" && index + 1 < args.length() {
      records = parse_positive_int(args[index + 1], records)
      index = index + 2
    } else if args[index] == "--seed" && index + 1 < args.length() {
      seed = parse_positive_int(args[index + 1], seed)
      index = index + 2
    } else {
      index = index + 1
    }
  }
  { mode, records, seed }
}

///|
pub fn run_benchmark_demo(records : Int, seed : Int) -> String {
  let report = @evaluation.run_benchmark(
    @evaluation.BenchmarkConfig::new(entity_count=records, seed~, repeats=1),
  )
  let text = report.render_text()
  println(text)
  text
}

///|
pub fn run_quality_demo() -> String {
  let first = @core.Record::new("quality-1", source="crm")
  first.set_field("name", @core.StringVal("Alice"))
  first.set_field("phone", @core.StringVal("1380001"))
  let second = @core.Record::new("quality-2", source="erp")
  second.set_field("name", @core.StringVal("Alice"))
  second.set_field("phone", @core.StringVal("1380002"))
  let profile = @core.profile_dataset([first, second])
  let text = "records=" +
    profile.record_count.to_string() +
    " fields=" +
    profile.field_profiles.length().to_string() +
    " duplicate_rate=" +
    profile.duplicate_rate().to_string()
  println(text)
  text
}

///|
pub fn run_cli(args : Array[String]) -> Unit {
  let options = parse_cli_options(args)
  match options.mode {
    "benchmark" => ignore(run_benchmark_demo(options.records, options.seed))
    "quality" => ignore(run_quality_demo())
    _ => run_demo()
  }
}
