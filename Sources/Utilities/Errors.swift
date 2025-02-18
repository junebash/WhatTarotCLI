public func expect<E: Error>(
  _ expression: @autoclosure () -> Bool,
  orThrow error: @autoclosure () -> E
) throws(E) {
  guard expression() else { throw error() }
}

struct Failure: Error {
  var description: String

  init(_ description: String) {
    self.description = description
  }
}

extension Optional {
  public func orThrow<E: Error>(_ error: @autoclosure () -> E) throws(E) -> Wrapped {
    if let value = self {
      return value
    } else {
      throw error()
    }
  }
}
