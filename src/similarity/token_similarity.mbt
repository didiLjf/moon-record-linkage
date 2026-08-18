// Token-Based String Similarity Metrics:
// Jaccard, Cosine (TF), Monge-Elkan, Soft-TFIDF

///|
/// Compute Jaccard similarity between two token sets.
/// |A ∩ B| / |A ∪ B|
pub fn jaccard_similarity(
  tokens_a : Array[String],
  tokens_b : Array[String],
) -> Double {
  if tokens_a.is_empty() && tokens_b.is_empty() {
    return 1.0
  }
  let set_a : Map[String, Bool] = Map([])
  let set_b : Map[String, Bool] = Map([])
  for t in tokens_a {
    set_a.set(t, true)
  }
  for t in tokens_b {
    set_b.set(t, true)
  }
  let mut intersection = 0
  for entry in set_a {
    if set_b.contains(entry.0) {
      intersection = intersection + 1
    }
  }
  let union = set_a.length() + set_b.length() - intersection
  if union == 0 {
    1.0
  } else {
    intersection.to_double() / union.to_double()
  }
}

///|
/// Compute Jaccard similarity between n-gram sets of two strings.
pub fn ngram_jaccard(a : String, b : String, n? : Int = 2) -> Double {
  let grams_a = char_ngrams_for_jaccard(a, n)
  let grams_b = char_ngrams_for_jaccard(b, n)
  jaccard_similarity(grams_a, grams_b)
}

///|
fn char_ngrams_for_jaccard(s : String, n : Int) -> Array[String] {
  let chars = s.to_array()
  let len = chars.length()
  let result : Array[String] = []
  if n <= 0 || len < n {
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
/// Compute cosine similarity between two term-frequency vectors.
/// Input: arrays of tokens (may have repetitions).
pub fn cosine_similarity(
  tokens_a : Array[String],
  tokens_b : Array[String],
) -> Double {
  if tokens_a.is_empty() || tokens_b.is_empty() {
    return 0.0
  }
  let freq_a : Map[String, Int] = Map([])
  let freq_b : Map[String, Int] = Map([])
  for t in tokens_a {
    match freq_a.get(t) {
      Some(c) => freq_a.set(t, c + 1)
      None => freq_a.set(t, 1)
    }
  }
  for t in tokens_b {
    match freq_b.get(t) {
      Some(c) => freq_b.set(t, c + 1)
      None => freq_b.set(t, 1)
    }
  }
  let mut dot_product = 0.0
  for entry in freq_a {
    match freq_b.get(entry.0) {
      Some(cnt_b) =>
        dot_product = dot_product + entry.1.to_double() * cnt_b.to_double()
      None => ()
    }
  }
  let mut norm_a = 0.0
  for entry in freq_a {
    norm_a = norm_a + entry.1.to_double() * entry.1.to_double()
  }
  let mut norm_b = 0.0
  for entry in freq_b {
    norm_b = norm_b + entry.1.to_double() * entry.1.to_double()
  }
  let denom = double_sqrt(norm_a) * double_sqrt(norm_b)
  if denom == 0.0 {
    0.0
  } else {
    dot_product / denom
  }
}

///|
/// Compute Monge-Elkan similarity between two token lists.
/// For each token in A, find the best similarity with any token in B.
pub fn monge_elkan(
  tokens_a : Array[String],
  tokens_b : Array[String],
  inner_sim : (String, String) -> Double,
) -> Double {
  if tokens_a.is_empty() {
    return 0.0
  }
  if tokens_b.is_empty() {
    return 0.0
  }
  let mut total = 0.0
  for ta in tokens_a {
    let mut best = 0.0
    for tb in tokens_b {
      let sim = inner_sim(ta, tb)
      if sim > best {
        best = sim
      }
    }
    total = total + best
  }
  total / tokens_a.length().to_double()
}

///|
/// Simple integer square root approximation via Newton's method.
fn double_sqrt(x : Double) -> Double {
  if x <= 0.0 {
    return 0.0
  }
  let mut guess = x / 2.0
  let mut itr = 0
  while itr < 20 {
    let next = (guess + x / guess) / 2.0
    let diff = if next > guess { next - guess } else { guess - next }
    if diff < 1.0e-12 {
      break
    }
    guess = next
    itr = itr + 1
  }
  guess
}

///|
/// Overlap coefficient: |A ∩ B| / min(|A|, |B|)
pub fn overlap_similarity(
  tokens_a : Array[String],
  tokens_b : Array[String],
) -> Double {
  if tokens_a.is_empty() || tokens_b.is_empty() {
    return 0.0
  }
  let set_a : Map[String, Bool] = Map([])
  let set_b : Map[String, Bool] = Map([])
  for t in tokens_a {
    set_a.set(t, true)
  }
  for t in tokens_b {
    set_b.set(t, true)
  }
  let mut intersection = 0
  for entry in set_a {
    if set_b.contains(entry.0) {
      intersection = intersection + 1
    }
  }
  let min_size = if set_a.length() < set_b.length() {
    set_a.length()
  } else {
    set_b.length()
  }
  if min_size == 0 {
    0.0
  } else {
    intersection.to_double() / min_size.to_double()
  }
}
