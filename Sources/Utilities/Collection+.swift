extension Collection {
  public subscript(safe index: Index) -> Element? {
    if indices.contains(index) { self[index] } else { nil }
  }
}
