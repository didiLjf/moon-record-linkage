// Entity Clustering: Convert match pairs into entity clusters using DSU.
// Supports threshold-based filtering and multi-record cluster merging.

///|
pub struct EntityGraph {
  dsu : DSU
  edges : Array[(String, String, Double)] // (a, b, score)
} derive(Debug)

///|
pub fn EntityGraph::new() -> EntityGraph {
  { dsu: DSU::new(), edges: [] }
}

///|
pub fn EntityGraph::add_match(
  self : EntityGraph,
  id_a : String,
  id_b : String,
  score : Double,
  threshold? : Double = 0.5,
) -> Unit {
  self.edges.push((id_a, id_b, score))
  if score >= threshold {
    self.dsu.add(id_a)
    self.dsu.add(id_b)
    self.dsu.union(id_a, id_b)
  }
}

///|
pub fn EntityGraph::add_record(self : EntityGraph, id : String) -> Unit {
  self.dsu.add(id)
}

///|
/// Get all entity clusters.
pub fn EntityGraph::clusters(self : EntityGraph) -> Map[String, Array[String]] {
  self.dsu.components()
}

///|
pub fn EntityGraph::cluster_count(self : EntityGraph) -> Int {
  self.dsu.component_count()
}

///|
/// Check if two records are in the same cluster.
pub fn EntityGraph::are_linked(
  self : EntityGraph,
  id_a : String,
  id_b : String,
) -> Bool {
  self.dsu.same_component(id_a, id_b)
}

///|
/// Convert entity clusters to EntityCluster objects using a record lookup.
pub fn entity_graph_to_clusters(
  graph : EntityGraph,
  record_lookup : Map[String, @core.Record],
) -> Array[@core.EntityCluster] {
  let components = graph.clusters()
  let result : Array[@core.EntityCluster] = []
  let mut cluster_idx = 0
  for entry in components {
    let root = entry.0
    let members = entry.1
    // Use the root record as canonical (if available)
    let canonical = match record_lookup.get(root) {
      Some(r) => r
      None => @core.Record::new(root)
    }
    let cluster_id = "cluster-" + cluster_idx.to_string()
    let cluster = @core.EntityCluster::new(cluster_id, canonical)
    for member_id in members {
      match record_lookup.get(member_id) {
        Some(r) => cluster.add_record(r)
        None => ()
      }
    }
    result.push(cluster)
    cluster_idx = cluster_idx + 1
  }
  result
}
