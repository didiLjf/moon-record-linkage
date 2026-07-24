// Fellegi-Sunter Probabilistic Record Linkage Model
// Computes m-probability (P(agree|match)) and u-probability (P(agree|non-match))
// for each field. Uses EM algorithm to estimate these parameters.
// Final weight = log(m/u) per field; records are linked if sum >= threshold.

///|
pub struct FSFieldParams {
  field_name : String
  mut m_prob : Double
  mut u_prob : Double
  weight : Double
} derive(Debug)

///|
pub fn FSFieldParams::new(
  field_name : String,
  m_prob? : Double = 0.9,
  u_prob? : Double = 0.1,
  weight? : Double = 1.0,
) -> FSFieldParams {
  { field_name, m_prob, u_prob, weight }
}

///|
/// Compute the log-likelihood weight for a field given its m/u probabilities.
pub fn FSFieldParams::log_weight(self : FSFieldParams) -> Double {
  if self.m_prob <= 0.0 || self.u_prob <= 0.0 {
    return 0.0
  }
  // log2(m/u) = log2(m) - log2(u) approximated as ln ratio / ln(2)
  let ratio = self.m_prob / self.u_prob
  natural_log(ratio) / natural_log(2.0)
}

///|
/// Natural logarithm approximation via series for ratio near 1,
/// or decomposition for larger values.
fn natural_log(x : Double) -> Double {
  if x <= 0.0 {
    return -1.0e10
  }
  if x == 1.0 {
    return 0.0
  }
  // Reduce x into range [0.5, 1.5] by factoring powers of 2 (ln(2) ≈ 0.6931471805599453)
  let mut val = x
  let mut k = 0
  let ln2 = 0.6931471805599453
  while val > 1.5 {
    val = val / 2.0
    k = k + 1
  }
  while val < 0.5 {
    val = val * 2.0
    k = k - 1
  }
  let y = (val - 1.0) / (val + 1.0)
  let y2 = y * y
  let mut sum = y
  let mut term = y
  let mut n = 3
  while n < 40 {
    term = term * y2
    sum = sum + term / n.to_double()
    n = n + 2
  }
  k.to_double() * ln2 + 2.0 * sum
}

///|
pub struct FellegiSunterModel {
  field_params : Array[FSFieldParams]
  match_threshold : Double
  non_match_threshold : Double
  mut prior_match_prob : Double
} derive(Debug)

///|
pub fn FellegiSunterModel::new(
  prior_match_prob? : Double = 0.1,
) -> FellegiSunterModel {
  {
    field_params: [],
    match_threshold: 3.0,
    non_match_threshold: -3.0,
    prior_match_prob,
  }
}

///|
pub fn FellegiSunterModel::add_field(
  self : FellegiSunterModel,
  params : FSFieldParams,
) -> Unit {
  self.field_params.push(params)
}

///|
/// Compute the total linkage weight for a pair given per-field agreements.
/// agreements[i] = true if field i agrees (similarity >= threshold).
pub fn FellegiSunterModel::compute_weight(
  self : FellegiSunterModel,
  agreements : Array[Bool],
) -> Double {
  let mut total = 0.0
  let n = if agreements.length() < self.field_params.length() {
    agreements.length()
  } else {
    self.field_params.length()
  }
  for i = 0; i < n; i = i + 1 {
    let params = self.field_params[i]
    let lw = params.log_weight()
    if agreements[i] {
      total = total + lw * params.weight
    } else {
      // Disagreement weight: log((1-m)/(1-u))
      let m2 = 1.0 - params.m_prob
      let u2 = 1.0 - params.u_prob
      if m2 > 0.0 && u2 > 0.0 {
        let disag_weight = natural_log(m2 / u2) / natural_log(2.0)
        total = total + disag_weight * params.weight
      }
    }
  }
  total
}

///|
pub fn FellegiSunterModel::classify(
  self : FellegiSunterModel,
  weight : Double,
) -> @core.MatchStatus {
  if weight >= self.match_threshold {
    @core.Match
  } else if weight <= self.non_match_threshold {
    @core.NonMatch
  } else {
    @core.PossibleMatch
  }
}

///|
/// Run EM algorithm to estimate m and u probabilities from observed data.
/// pairs_agreements: array of per-pair field agreement vectors.
/// Returns updated field parameters.
pub fn FellegiSunterModel::em_train(
  self : FellegiSunterModel,
  pairs_agreements : Array[Array[Bool]],
  max_iterations? : Int = 50,
  convergence_delta? : Double = 0.0001,
) -> Unit {
  let n_pairs = pairs_agreements.length()
  if n_pairs == 0 {
    return
  }
  let n_fields = self.field_params.length()
  let mut lambda = self.prior_match_prob
  for _iter = 0; _iter < max_iterations; _iter = _iter + 1 {
    // E-step: compute expected match probability for each pair
    let expected_match : Array[Double] = []
    for pair_agreements in pairs_agreements {
      let mut w = 0.0
      for i = 0; i < n_fields && i < pair_agreements.length(); i = i + 1 {
        let params = self.field_params[i]
        if pair_agreements[i] {
          if params.u_prob > 0.0 {
            w = w + natural_log(params.m_prob / params.u_prob)
          }
        } else {
          let m2 = 1.0 - params.m_prob
          let u2 = 1.0 - params.u_prob
          if u2 > 0.0 {
            w = w + natural_log(m2 / u2)
          }
        }
      }
      // P(M | agreement) via Bayes
      let odds = lambda * double_exp(w)
      let p_match = odds / (odds + 1.0 - lambda)
      expected_match.push(p_match)
    }
    // M-step: update m, u, and lambda
    let mut sum_m = 0.0
    for e in expected_match {
      sum_m = sum_m + e
    }
    let new_lambda = sum_m / n_pairs.to_double()
    let mut changed = if new_lambda - lambda > convergence_delta ||
      lambda - new_lambda > convergence_delta {
      true
    } else {
      false
    }
    lambda = new_lambda
    // Update field m/u probs
    for fi = 0; fi < n_fields; fi = fi + 1 {
      let mut sum_agree_m = 0.0
      let mut sum_agree_u = 0.0
      for pi = 0; pi < n_pairs; pi = pi + 1 {
        let agree = if fi < pairs_agreements[pi].length() {
          pairs_agreements[pi][fi]
        } else {
          false
        }
        if agree {
          sum_agree_m = sum_agree_m + expected_match[pi]
          sum_agree_u = sum_agree_u + (1.0 - expected_match[pi])
        }
      }
      let new_m = sum_agree_m / (sum_m + 1.0e-10)
      let new_u = sum_agree_u / (n_pairs.to_double() - sum_m + 1.0e-10)
      let old_m = self.field_params[fi].m_prob
      let old_u = self.field_params[fi].u_prob
      let dm = if new_m - old_m > convergence_delta ||
        old_m - new_m > convergence_delta {
        true
      } else {
        false
      }
      let du = if new_u - old_u > convergence_delta ||
        old_u - new_u > convergence_delta {
        true
      } else {
        false
      }
      if dm || du {
        changed = true
      }
      self.field_params[fi].m_prob = new_m
      self.field_params[fi].u_prob = new_u
    }
    if !changed {
      break
    }
  }
  self.prior_match_prob = lambda
}

///|
/// Approximate exponential function.
fn double_exp(x : Double) -> Double {
  // Limit to avoid overflow
  if x > 20.0 {
    return 485165195.0
  }
  if x < -20.0 {
    return 0.0000000021
  }
  // Taylor: e^x ≈ 1 + x + x²/2 + x³/6 + x⁴/24 + x⁵/120 + x⁶/720
  let x2 = x * x
  let x3 = x2 * x
  let x4 = x3 * x
  let x5 = x4 * x
  let x6 = x5 * x
  1.0 + x + x2 / 2.0 + x3 / 6.0 + x4 / 24.0 + x5 / 120.0 + x6 / 720.0
}
