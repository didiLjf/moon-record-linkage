// Locality Sensitive Hashing (LSH) with MinHash for approximate set similarity blocking.
// Each record's token set is hashed with num_hashes permutations.
// Records sharing a minhash bucket in any band are candidate pairs.

///|
pub struct LSHBlocker {
  key_field : String
  num_hashes : Int
  num_bands : Int
  rows_per_band : Int
  ngram_size : Int
} derive(Debug, Eq)

///|
pub fn LSHBlocker::new(
  key_field : String,
  num_hashes? : Int = 100,
  num_bands? : Int = 20,
  ngram_size? : Int = 2,
) -> LSHBlocker {
  let rows_per_band = if num_bands > 0 { num_hashes / num_bands } else { 1 }
  { key_field, num_hashes, num_bands, rows_per_band, ngram_size }
}

///|
/// Simple polynomial hash for a string with a given seed.
fn poly_hash(s : String, seed : Int) -> Int {
  let chars = s.to_array()
  let mut h = seed
  for ch in chars {
    h = h * 31 + ch.to_int()
    // Keep in positive int range
    h = h % 2147483647
    if h < 0 {
      h = -h
    }
  }
  h
}

///|
/// Generate n-grams for a string (character level).
fn lsh_ngrams(s : String, n : Int) -> Array[String] {
  let chars = s.to_array()
  let len = chars.length()
  let result : Array[String] = []
  if n <= 0 || len < n {
    if len > 0 {
      result.push(s)
    }
    return result
  }
  for i = 0; i <= len - n; i = i + 1 {
    let sb = StringBuilder(size_hint=n)
    for j = i; j < i + n; j = j + 1 {
      sb.write_char(chars[j])
    }
    result.push(sb.to_string())
  }
  result
}

///|
/// Compute a MinHash signature for a string using num_hashes permutations.
fn compute_minhash(
  s : String,
  num_hashes : Int,
  ngram_size : Int,
) -> Array[Int] {
  let grams = lsh_ngrams(s, ngram_size)
  let sig = FixedArray::make(num_hashes, 2147483647)
  for k = 0; k < num_hashes; k = k + 1 {
    let seed = (k * 1000003 + 17) % 2147483647
    for gram in grams {
      let h = poly_hash(gram, seed)
      if h < sig[k] {
        sig[k] = h
      }
    }
  }
  let result : Array[Int] = []
  for k = 0; k < num_hashes; k = k + 1 {
    result.push(sig[k])
  }
  result
}

///|
pub struct LSHIndex {
  band_buckets : Array[Map[String, Array[String]]]
  num_bands : Int
  rows_per_band : Int
} derive(Debug)

///|
pub fn LSHIndex::new(num_bands : Int, rows_per_band : Int) -> LSHIndex {
  let buckets : Array[Map[String, Array[String]]] = []
  for _ in 0..<num_bands {
    buckets.push(Map([]))
  }
  { band_buckets: buckets, num_bands, rows_per_band }
}

///|
fn signature_band_key(
  sig : Array[Int],
  band : Int,
  rows_per_band : Int,
) -> String {
  let start = band * rows_per_band
  let sb = StringBuilder(size_hint=16)
  for i = start; i < start + rows_per_band && i < sig.length(); i = i + 1 {
    if i > start {
      sb.write_char(',')
    }
    sb.write_string(sig[i].to_string())
  }
  sb.to_string()
}

///|
pub fn LSHIndex::add_signature(
  self : LSHIndex,
  record_id : String,
  sig : Array[Int],
) -> Unit {
  for b = 0; b < self.num_bands; b = b + 1 {
    let band_key = signature_band_key(sig, b, self.rows_per_band)
    let bucket = self.band_buckets[b]
    match bucket.get(band_key) {
      Some(ids) => ids.push(record_id)
      None => bucket.set(band_key, [record_id])
    }
  }
}

///|
pub fn LSHIndex::candidate_pairs(self : LSHIndex) -> Array[(String, String)] {
  let seen : Map[String, Bool] = Map([])
  let result : Array[(String, String)] = []
  for bucket_map in self.band_buckets {
    for entry in bucket_map {
      let ids = entry.1
      let n = ids.length()
      for i = 0; i < n; i = i + 1 {
        for j = i + 1; j < n; j = j + 1 {
          let key = ids[i] + "##" + ids[j]
          if !seen.contains(key) {
            seen.set(key, true)
            result.push((ids[i], ids[j]))
          }
        }
      }
    }
  }
  result
}

///|
/// Build an LSH index from records using the blocker config.
pub fn LSHBlocker::build_index(
  self : LSHBlocker,
  records : Array[@core.Record],
) -> LSHIndex {
  let idx = LSHIndex::new(self.num_bands, self.rows_per_band)
  for r in records {
    let val = @normalization.to_lowercase(r.get_string(self.key_field))
    let sig = compute_minhash(val, self.num_hashes, self.ngram_size)
    idx.add_signature(r.id, sig)
  }
  idx
}

///|
/// Generate candidate pairs for a set of records.
pub fn LSHBlocker::candidate_pairs(
  self : LSHBlocker,
  records : Array[@core.Record],
) -> Array[(String, String)] {
  let idx = self.build_index(records)
  idx.candidate_pairs()
}
