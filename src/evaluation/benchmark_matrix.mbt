///|
/// Results from a repeatable size/noise benchmark matrix.
pub struct BenchmarkMatrix {
  reports : Array[BenchmarkReport]
  total_entities : Int
  average_precision : Double
  average_recall : Double
  average_f1 : Double
  average_reduction_ratio : Double
} derive(Debug)

///|
pub fn run_benchmark_matrix(
  configs : Array[BenchmarkConfig],
) -> BenchmarkMatrix {
  let reports : Array[BenchmarkReport] = []
  let mut total_entities = 0
  let mut precision = 0.0
  let mut recall = 0.0
  let mut f1 = 0.0
  let mut reduction = 0.0
  for config in configs {
    let report = run_benchmark(config)
    reports.push(report)
    total_entities = total_entities + report.entity_count
    precision = precision + report.precision
    recall = recall + report.recall
    f1 = f1 + report.f1
    reduction = reduction + report.reduction_ratio
  }
  let count = reports.length()
  {
    reports,
    total_entities,
    average_precision: if count == 0 {
      0.0
    } else {
      precision / count.to_double()
    },
    average_recall: if count == 0 {
      0.0
    } else {
      recall / count.to_double()
    },
    average_f1: if count == 0 {
      0.0
    } else {
      f1 / count.to_double()
    },
    average_reduction_ratio: if count == 0 {
      0.0
    } else {
      reduction / count.to_double()
    },
  }
}

///|
pub fn BenchmarkMatrix::render_csv(self : BenchmarkMatrix) -> String {
  let sb = StringBuilder(size_hint=512)
  sb.write_string(
    "entity_count,candidates,precision,recall,f1,reduction_ratio,elapsed_ticks\n",
  )
  for report in self.reports {
    sb.write_string(
      report.entity_count.to_string() +
      "," +
      report.candidate_pair_count.to_string() +
      "," +
      report.precision.to_string() +
      "," +
      report.recall.to_string() +
      "," +
      report.f1.to_string() +
      "," +
      report.reduction_ratio.to_string() +
      "," +
      report.elapsed_ticks.to_string() +
      "\n",
    )
  }
  sb.write_string(
    "average,0," +
    self.average_precision.to_string() +
    "," +
    self.average_recall.to_string() +
    "," +
    self.average_f1.to_string() +
    "," +
    self.average_reduction_ratio.to_string() +
    ",0\n",
  )
  sb.to_string()
}

///|
pub fn BenchmarkMatrix::render_json(self : BenchmarkMatrix) -> String {
  let sb = StringBuilder(size_hint=512)
  sb.write_string(
    "{\"total_entities\":" +
    self.total_entities.to_string() +
    ",\"average_f1\":" +
    self.average_f1.to_string() +
    ",\"reports\":[",
  )
  for i, report in self.reports {
    if i > 0 {
      sb.write_char(',')
    }
    sb.write_string(
      "{\"entity_count\":" +
      report.entity_count.to_string() +
      ",\"candidate_pairs\":" +
      report.candidate_pair_count.to_string() +
      ",\"precision\":" +
      report.precision.to_string() +
      ",\"recall\":" +
      report.recall.to_string() +
      ",\"f1\":" +
      report.f1.to_string() +
      "}",
    )
  }
  sb.write_string("]}")
  sb.to_string()
}
