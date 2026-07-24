// Disjoint Set Union (DSU / Union-Find) data structure
// Supports path compression and union by rank for near O(1) amortized ops.
// Used for entity clustering: merge record IDs into connected components.

///|
pub struct DSU {
  parent : Map[String, String]
  rank : Map[String, Int]
  mut component_count : Int
} derive(Debug)

///|
pub fn DSU::new() -> DSU {
  { parent: Map([]), rank: Map([]), component_count: 0 }
}

///|
/// Register a new element. No-op if already registered.
pub fn DSU::add(self : DSU, id : String) -> Unit {
  if !self.parent.contains(id) {
    self.parent.set(id, id)
    self.rank.set(id, 0)
    self.component_count = self.component_count + 1
  }
}

///|
/// Find the root of the component containing id (with path compression).
pub fn DSU::find(self : DSU, id : String) -> String {
  if !self.parent.contains(id) {
    self.add(id)
    return id
  }
  let mut current = id
  // Path compression: find root
  let mut root = current
  while true {
    let p = match self.parent.get(root) {
      Some(r) => r
      None => root
    }
    if p == root {
      break
    }
    root = p
  }
  // Path compress all nodes on the path
  let mut node = current
  while node != root {
    let next = match self.parent.get(node) {
      Some(p) => p
      None => root
    }
    self.parent.set(node, root)
    node = next
    current = current // suppress unused warning
  }
  root
}

///|
/// Union two elements into the same component.
pub fn DSU::union(self : DSU, a : String, b : String) -> Unit {
  self.add(a)
  self.add(b)
  let ra = self.find(a)
  let rb = self.find(b)
  if ra == rb {
    return
  }
  let rank_a = match self.rank.get(ra) {
    Some(r) => r
    None => 0
  }
  let rank_b = match self.rank.get(rb) {
    Some(r) => r
    None => 0
  }
  if rank_a < rank_b {
    self.parent.set(ra, rb)
  } else if rank_a > rank_b {
    self.parent.set(rb, ra)
  } else {
    self.parent.set(rb, ra)
    self.rank.set(ra, rank_a + 1)
  }
  self.component_count = self.component_count - 1
}

///|
/// Return true if two elements are in the same component.
pub fn DSU::same_component(self : DSU, a : String, b : String) -> Bool {
  self.find(a) == self.find(b)
}

///|
/// Extract all connected components as a map from root ID to list of members.
pub fn DSU::components(self : DSU) -> Map[String, Array[String]] {
  let result : Map[String, Array[String]] = Map([])
  for entry in self.parent {
    let id = entry.0
    let root = self.find(id)
    match result.get(root) {
      Some(members) => members.push(id)
      None => result.set(root, [id])
    }
  }
  result
}

///|
pub fn DSU::component_count(self : DSU) -> Int {
  self.component_count
}

///|
/// Build a DSU from a list of match pairs (edges in the entity graph).
pub fn DSU::from_pairs(pairs : Array[(String, String)]) -> DSU {
  let dsu = DSU::new()
  for pair in pairs {
    dsu.add(pair.0)
    dsu.add(pair.1)
    dsu.union(pair.0, pair.1)
  }
  dsu
}
