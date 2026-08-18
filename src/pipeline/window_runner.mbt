///|
pub struct PagedLinkResult {
  result : BatchLinkageResult
  page_count : Int
  processed_left_records : Int
} derive(Debug)

///|
fn append_page_result(
  target : BatchLinkageResult,
  page : BatchLinkageResult,
) -> Unit {
  target.candidate_pair_count = target.candidate_pair_count +
    page.candidate_pair_count
  for pair in page.match_pairs {
    target.match_pairs.push(pair)
  }
  for pair in page.possible_pairs {
    target.possible_pairs.push(pair)
  }
  for cluster in page.clusters {
    target.clusters.push(cluster)
  }
}

///|
/// Link left records page by page while retaining a single auditable result.
pub fn run_paged_link(
  config : @core.LinkageConfig,
  records_a : Array[@core.Record],
  records_b : Array[@core.Record],
  page_size~ : Int,
) -> PagedLinkResult {
  let result = BatchLinkageResult::new()
  if page_size <= 0 || records_a.is_empty() {
    return { result, page_count: 0, processed_left_records: 0 }
  }
  let mut offset = 0
  let mut page_count = 0
  let mut processed = 0
  while offset < records_a.length() {
    let page = slice_page(records_a, PageRequest::new(offset~, limit=page_size))
    let page_result = BatchPipeline::new(config).run_link(page.items, records_b)
    append_page_result(result, page_result)
    processed = processed + page.items.length()
    page_count = page_count + 1
    offset = page.next_offset
  }
  { result, page_count, processed_left_records: processed }
}
