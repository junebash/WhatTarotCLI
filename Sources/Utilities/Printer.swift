import Algorithms
import Darwin
import System

public protocol AsyncPrinter: Sendable {
  func callAsFunction(
    _ items: [Any],
    separator: String,
    terminator: String
  ) async
}

extension AsyncPrinter {
  public func callAsFunction(
    _ items: Any...,
    separator: String = " ",
    terminator: String = "\n"
  ) async {
    await self(items, separator: separator, terminator: terminator)
  }

  public func callAsFunction(
    indent indentSize: Int,
    maxWidth: Int,
    _ input: String
  ) async {
    await self(input.wordWrap(maxWidth: maxWidth, indent: indentSize))
  }
}

public struct AnyAsyncPrinter: AsyncPrinter {
  public typealias Handler = @Sendable (
    _ items: [Any],
    _ separator: String,
    _ terminator: String
  ) async -> Void

  private let _print: Handler

  public init(_ print: @escaping Handler) {
    self._print = print
  }

  public func callAsFunction(
    _ items: [Any],
    separator: String,
    terminator: String
  ) async {
    await _print(items, separator, terminator)
  }
}

@TaskLocal private var currentAsyncPrinter: any AsyncPrinter = .byCharacter

public func withAsyncPrinter<Out>(
  _ printer: some AsyncPrinter,
  operation: () throws -> Out
) rethrows -> Out {
  try $currentAsyncPrinter.withValue(printer) {
    try operation()
  }
}

public func withAsyncPrinter<Out>(
  _ printer: some AsyncPrinter,
  operation: () async throws -> Out
) async rethrows -> Out {
  try await $currentAsyncPrinter.withValue(printer) {
    try await operation()
  }
}

// MARK: - Instances

public enum AsyncPrinters {
  public static var current: any AsyncPrinter { currentAsyncPrinter }
}

extension AsyncPrinter where Self == AsyncPrinters.StandardOut {
  public static var standardOut: Self { .shared }
}

extension AsyncPrinter where Self == AsyncPrinters.Into {
  public static func into(_ print: @escaping @Sendable (String) async -> Void) -> Self {
    Self(print)
  }
}

extension AsyncPrinter {
  public static func byCharacter<C: Clock<Duration>, Base: AsyncPrinter>(
    waitTime: Duration = .milliseconds(50),
    clock: C,
    into printer: Base
  ) -> Self where Self == AsyncPrinters.ByCharacter<Base, C> {
    Self(waitTime: waitTime, clock: clock, printer: printer)
  }

  public static func byCharacter<Base: AsyncPrinter>(
    waitTime: Duration = .milliseconds(50),
    into printer: Base
  ) -> Self where Self == AsyncPrinters.ByCharacter<Base, ContinuousClock> {
    Self(waitTime: waitTime, clock: ContinuousClock(), printer: printer)
  }

  public static func byCharacter<C: Clock<Duration>>(
    waitTime: Duration = .milliseconds(50),
    clock: C
  ) -> Self where Self == AsyncPrinters.ByCharacter<AsyncPrinters.StandardOut, C> {
    Self(waitTime: waitTime, clock: clock, printer: .shared)
  }
}

extension AsyncPrinter
where Self == AsyncPrinters.ByCharacter<AsyncPrinters.StandardOut, ContinuousClock> {
  public static var byCharacter: Self { .byCharacter(waitTime: .milliseconds(50)) }

  public static func byCharacter(
    waitTime: Duration
  ) -> Self where Self == AsyncPrinters.ByCharacter<AsyncPrinters.StandardOut, ContinuousClock> {
    Self(waitTime: waitTime, clock: ContinuousClock(), printer: .shared)
  }
}

// MARK: - Impl

extension AsyncPrinters {
  public struct StandardOut: AsyncPrinter {
    private init(_: ()) {}

    static let shared: Self = .init(())

    public func callAsFunction(
      _ items: [Any],
      separator: String,
      terminator: String
    ) async {
      let content = chain(
        items.lazy.map(String.init(describing:)).joined(separator: separator) as JoinedSequence,
        terminator
      ).lazy.flatMap(\.utf8)
      try! FileDescriptor.standardOutput.writeAll(content)
    }
  }

  public struct Into: AsyncPrinter {
    let print: @Sendable (String) async -> Void

    init(_ print: @escaping @Sendable (String) async -> Void) {
      self.print = print
    }

    public func callAsFunction(_ items: [Any], separator: String, terminator: String) async {
      guard let item = items.first else {
        await print(terminator)
        return
      }
      await print(String(describing: item))
      for item in items.dropFirst() {
        await print(separator)
        await print(String(describing: item))
      }
      await print(terminator)
    }
  }

  public struct ByCharacter<Base: AsyncPrinter, C: Clock<Duration>>: AsyncPrinter {
    let waitTime: Duration
    let clock: C
    let printer: Base

    init(waitTime: Duration, clock: C, printer: Base) {
      self.waitTime = waitTime
      self.clock = clock
      self.printer = printer
    }

    public func callAsFunction(_ items: [Any], separator: String, terminator: String) async {
      if let first = items.first {
        await printItem(first)
      }

      for item in items.dropFirst() {
        await printer(separator, terminator: "")
        await printItem(item)
      }

      await printer(terminator, terminator: "")
    }

    func printItem(_ item: Any) async {
      let str = String(describing: item)
      for char in str {
        await printer(char, terminator: "")
        if !char.isWhitespace {
          let now = clock.now
          try? await clock.sleep(until: now.advanced(by: waitTime), tolerance: .microseconds(1))
        }
      }
    }
  }
}
