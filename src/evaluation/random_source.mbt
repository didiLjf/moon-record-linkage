///|
/// Small deterministic pseudo-random source for reproducible fixtures and benchmarks.
pub struct DeterministicRandom {
  mut state : Int64
} derive(Debug, Eq)

///|
pub fn DeterministicRandom::new(seed : Int) -> DeterministicRandom {
  let seed64 = seed.to_int64()
  let normalized = if seed64 <= 0L { 1L } else { seed64 % 2147483647L }
  { state: normalized }
}

///|
pub fn DeterministicRandom::next(self : DeterministicRandom) -> Int {
  // Keep the Park-Miller multiplication in Int64 so Int32 overflow cannot
  // collapse a valid seed into the constant state 1.
  self.state = self.state * 48271L % 2147483647L
  if self.state <= 0L {
    self.state = 1L
  }
  self.state.to_int()
}

///|
pub fn DeterministicRandom::next_bounded(
  self : DeterministicRandom,
  bound~ : Int,
) -> Int {
  if bound <= 1 {
    0
  } else {
    self.next() % bound
  }
}

///|
pub fn DeterministicRandom::next_unit(self : DeterministicRandom) -> Double {
  self.next().to_double() / 2147483647.0
}
