// Spatial / Geographic Similarity using Haversine Distance Formula

///|
/// Earth's mean radius in kilometers.
let earth_radius_km : Double = 6371.0

///|
/// Approximate π.
let pi : Double = 3.14159265358979323846

///|
/// Convert degrees to radians.
fn deg_to_rad(deg : Double) -> Double {
  deg * pi / 180.0
}

///|
/// Compute the Haversine distance in kilometers between two lat/lon points.
pub fn haversine_distance_km(
  lat1 : Double,
  lon1 : Double,
  lat2 : Double,
  lon2 : Double,
) -> Double {
  let d_lat = deg_to_rad(lat2 - lat1)
  let d_lon = deg_to_rad(lon2 - lon1)
  let r_lat1 = deg_to_rad(lat1)
  let r_lat2 = deg_to_rad(lat2)
  let sin_dlat2 = double_sin(d_lat / 2.0)
  let sin_dlon2 = double_sin(d_lon / 2.0)
  let a = sin_dlat2 * sin_dlat2 +
    double_cos(r_lat1) * double_cos(r_lat2) * sin_dlon2 * sin_dlon2
  let c = 2.0 * double_atan2(double_sqrt_geo(a), double_sqrt_geo(1.0 - a))
  earth_radius_km * c
}

///|
/// Compute geographic similarity based on Haversine distance.
/// Returns 1.0 for same location, decays to 0 at max_km.
pub fn geo_haversine_similarity(
  lat1 : Double,
  lon1 : Double,
  lat2 : Double,
  lon2 : Double,
  max_km? : Double = 100.0,
) -> Double {
  if max_km <= 0.0 {
    return if lat1 == lat2 && lon1 == lon2 { 1.0 } else { 0.0 }
  }
  let dist = haversine_distance_km(lat1, lon1, lat2, lon2)
  if dist >= max_km {
    0.0
  } else {
    1.0 - dist / max_km
  }
}

///|
/// Same-city check based on a coarse grid bucket (1° = ~111 km).
pub fn same_city_bucket(
  lat1 : Double,
  lon1 : Double,
  lat2 : Double,
  lon2 : Double,
  bucket_deg? : Double = 0.5,
) -> Bool {
  let d_lat = if lat1 > lat2 { lat1 - lat2 } else { lat2 - lat1 }
  let d_lon = if lon1 > lon2 { lon1 - lon2 } else { lon2 - lon1 }
  d_lat <= bucket_deg && d_lon <= bucket_deg
}

// ---- Trigonometric approximations ----

///|
fn double_sqrt_geo(x : Double) -> Double {
  if x <= 0.0 {
    return 0.0
  }
  let mut g = x / 2.0
  let mut itr = 0
  while itr < 30 {
    let next = (g + x / g) / 2.0
    let diff = if next > g { next - g } else { g - next }
    if diff < 1.0e-12 {
      break
    }
    g = next
    itr = itr + 1
  }
  g
}

///|
/// Sine approximation using Taylor series (good for small angles).
fn double_sin(x : Double) -> Double {
  // Reduce to [-π, π]
  let mut r = x
  while r > pi {
    r = r - 2.0 * pi
  }
  while r < -pi {
    r = r + 2.0 * pi
  }
  // Taylor: sin(x) ≈ x - x³/6 + x⁵/120 - x⁷/5040 + x⁹/362880
  let x2 = r * r
  r *
  (1.0 - x2 / 6.0 * (1.0 - x2 / 20.0 * (1.0 - x2 / 42.0 * (1.0 - x2 / 72.0))))
}

///|
/// Cosine approximation.
fn double_cos(x : Double) -> Double {
  double_sin(x + pi / 2.0)
}

///|
/// atan2 approximation using the identity and series.
fn double_atan2(y : Double, x : Double) -> Double {
  if x == 0.0 {
    if y > 0.0 {
      return pi / 2.0
    } else if y < 0.0 {
      return -pi / 2.0
    } else {
      return 0.0
    }
  }
  let r = y / x
  let atan_r = double_atan(r)
  if x > 0.0 {
    atan_r
  } else if y >= 0.0 {
    atan_r + pi
  } else {
    atan_r - pi
  }
}

///|
fn double_atan(x : Double) -> Double {
  // atan approximation: atan(x) ≈ x/(1 + 0.28125*x²) for |x|<=1
  // For |x|>1: atan(x) = π/2 - atan(1/x)
  if x < 0.0 {
    return -double_atan(-x)
  }
  if x > 1.0 {
    return pi / 2.0 - double_atan(1.0 / x)
  }
  let x2 = x * x
  x / (1.0 + 0.28125 * x2)
}
