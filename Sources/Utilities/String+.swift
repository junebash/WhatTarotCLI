extension String {
  public func lines() -> Lines {
    Lines(input: self)
  }

  public func words() -> Words {
    Words(input: self)
  }
}

public struct Lines {
  let input: String
}

extension Lines: Sequence {
  public struct Iterator: IteratorProtocol {
    var remainder: Substring?

    public mutating func next() -> Substring? {
      if remainder == nil { return nil }
      let nextLine = remainder!.prefix(while: { !$0.isNewline })
      remainder!.removeFirst(nextLine.count)
      if remainder!.isEmpty {
        remainder = nil
      } else {
        remainder!.removeFirst()
      }
      return nextLine
    }
  }

  public func makeIterator() -> Iterator {
    Iterator(remainder: input[...])
  }
}

public struct Words {
  let input: String
}

extension Words: Sequence {
  public struct Iterator: IteratorProtocol {
    var remainder: Substring?

    public mutating func next() -> Substring? {
      if remainder == nil { return nil }
      try? remainder!.trimPrefix { $0.isWhitespace }
      let nextLine = remainder!.prefix(while: { !$0.isWhitespace })
      remainder!.removeFirst(nextLine.count)
      if remainder!.isEmpty {
        remainder = nil
      } else {
        try? remainder!.trimPrefix(while: { $0.isWhitespace })
      }
      return nextLine
    }
  }

  public func makeIterator() -> Iterator {
    Iterator(remainder: input[...])
  }
}

extension String {
  public func wordWrap(maxWidth: Int, indent indentSize: Int) -> String {
    let indent = String(repeating: " ", count: indentSize)
    var lines = [String]()
    var currentLine = ""
    for word in self.words() {
      if currentLine.count + word.count + 1 > maxWidth {
        lines.append(currentLine)
        currentLine = ""
      }
      if !currentLine.isEmpty {
        currentLine.append(" ")
      } else {
        currentLine.append(indent)
      }
      currentLine.append(contentsOf: word)
    }
    lines.append(currentLine)
    return lines.joined(separator: "\n")
  }
}
