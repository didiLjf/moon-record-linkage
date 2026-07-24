// Numeric and Date Similarity Metrics with Range-Based Decay Functions

///|
/// Compute absolute difference similarity for numeric values.
/// Returns 1.0 if |a-b| == 0, decays linearly to 0 at max_diff.
pub fn numeric_absolute_similarity(
  a : Double,
  b : Double,
  max_diff? : Double = 1.0,
) -> Double {
  if max_diff <= 0.0 {
    return if a == b { 1.0 } else { 0.0 }
  }
  let diff = if a > b { a - b } else { b - a }
  if diff >= max_diff {
    0.0
  } else {
    1.0 - diff / max_diff
  }
}

///|
/// Compute relative (percentage) difference similarity.
/// Returns 1.0 if values are equal, decays as |a-b|/max(|a|,|b|) increases.
pub fn numeric_relative_similarity(
  a : Double,
  b : Double,
  max_pct? : Double = 0.1,
) -> Double {
  if a == 0.0 && b == 0.0 {
    return 1.0
  }
  let abs_max = if (if a > 0.0 { a } else { -a }) >
    (if b > 0.0 { b } else { -b }) {
    if a > 0.0 {
      a
    } else {
      -a
    }
  } else if b > 0.0 {
    b
  } else {
    -b
  }
  if abs_max == 0.0 {
    return 1.0
  }
  let pct_diff = (if a > b { a - b } else { b - a }) / abs_max
  if pct_diff >= max_pct {
    0.0
  } else {
    1.0 - pct_diff / max_pct
  }
}

///|
/// Age-group binned similarity.
/// Groups ages into buckets of bin_size and returns 1 if same bucket, else 0.
pub fn age_bin_similarity(
  age_a : Int,
  age_b : Int,
  bin_size? : Int = 5,
) -> Double {
  let bin_a = age_a / bin_size
  let bin_b = age_b / bin_size
  if bin_a == bin_b {
    1.0
  } else {
    0.0
  }
}

///|
/// Parse a simple date string "YYYY-MM-DD" into integer day count since year 0.
/// Returns -1 if format is invalid.
pub fn parse_date_to_days(date : String) -> Int {
  let chars = date.to_array()
  if chars.length() != 10 {
    return -1
  }
  if chars[4] != '-' || chars[7] != '-' {
    return -1
  }
  let year = parse_int4(chars, 0)
  let month = parse_int2(chars, 5)
  let day = parse_int2(chars, 8)
  if year < 0 || month < 1 || month > 12 || day < 1 || day > 31 {
    return -1
  }
  // Approximate: days = year*365 + month*30 + day
  year * 365 + month * 30 + day
}

///|
fn parse_int4(chars : Array[Char], offset : Int) -> Int {
  let mut result = 0
  for i = offset; i < offset + 4 && i < chars.length(); i = i + 1 {
    let ch = chars[i]
    if ch >= '0' && ch <= '9' {
      result = result * 10 + (ch.to_int() - 48)
    } else {
      return -1
    }
  }
  result
}

///|
fn parse_int2(chars : Array[Char], offset : Int) -> Int {
  let mut result = 0
  for i = offset; i < offset + 2 && i < chars.length(); i = i + 1 {
    let ch = chars[i]
    if ch >= '0' && ch <= '9' {
      result = result * 10 + (ch.to_int() - 48)
    } else {
      return -1
    }
  }
  result
}

///|
/// Date similarity: 1.0 if same date, decays with day difference.
/// max_days controls the window beyond which similarity = 0.
pub fn date_similarity(
  date_a : String,
  date_b : String,
  max_days? : Int = 365,
) -> Double {
  let da = parse_date_to_days(date_a)
  let db = parse_date_to_days(date_b)
  if da < 0 || db < 0 {
    return 0.0
  }
  let diff = if da > db { da - db } else { db - da }
  if diff >= max_days {
    0.0
  } else {
    1.0 - diff.to_double() / max_days.to_double()
  }
}

///|
/// Exact year match similarity (returns 1.0 only if same year).
pub fn year_exact_similarity(year_a : Int, year_b : Int) -> Double {
  if year_a == year_b {
    1.0
  } else {
    0.0
  }
}
