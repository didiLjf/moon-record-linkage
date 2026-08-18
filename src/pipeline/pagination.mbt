///|
/// Slice records into a bounded page without mutating the source array.
pub fn slice_page(
  records : Array[@core.Record],
  request : PageRequest,
) -> PageResult {
  let start = if request.offset > records.length() {
    records.length()
  } else {
    request.offset
  }
  let requested_end = start + request.limit
  let end = if requested_end > records.length() {
    records.length()
  } else {
    requested_end
  }
  let items : Array[@core.Record] = []
  for i = start; i < end; i = i + 1 {
    items.push(records[i])
  }
  { items, offset: start, next_offset: end, has_more: end < records.length() }
}
