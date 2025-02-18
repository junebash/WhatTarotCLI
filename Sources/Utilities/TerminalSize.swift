import Darwin

struct Size: Hashable, Sendable, BitwiseCopyable {
  var width: Int
  var height: Int
}

extension Size {
  static func terminalCharacters() throws -> Size {
    var w = winsize()
    guard ioctl(STDOUT_FILENO, TIOCGWINSZ, &w) == 0 else {
      throw Failure("Failed to get terminal size")
    }
    return Size(width: Int(w.ws_col), height: Int(w.ws_row))
  }
}
