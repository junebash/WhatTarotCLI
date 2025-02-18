import ArgumentParser
import Clocks

@main
struct WhatTarotCLI: AsyncParsableCommand {
  struct Context: Sendable {
    let clock: any Clock<Duration>
    let printer: any AsyncPrinter

    init(clock: some Clock<Duration>, printer: some AsyncPrinter) {
      self.clock = clock
      self.printer = printer
    }

    @TaskLocal static var current: Context = Context(
      clock: ContinuousClock(),
      printer: .byCharacter
    )

    @TaskLocal static var immediateClock: any Clock<Duration> = MoreImmediateClock()
    @TaskLocal static var standardOut: any AsyncPrinter = .standardOut

    static var immediate: Self {
      Self(clock: Self.immediateClock, printer: Self.standardOut)
    }
  }

  @Option(name: [.short, .long], help: "The number of cards to draw (1-78)")
  var cardCount: Int = 3

  @Option(
    name: [.customShort("l"), .customLong("labels")],
    help: "The labels for each card (comma-separated)"
  )
  var rawLabels: String?

  @Option(help: "Cut the deck at this index (0-77)")
  var cut: Int? = nil

  @Option(
    name: [.short, .long],
    help: "The seed to use for (pseudo-)randomness; usually only used for testing"
  )
  var seed: UInt64? = nil

  @Flag(name: [.short, .long], help: "Shows results immediately instead of bit by bit")
  var immediate: Bool = false

  @Flag(name: [.customShort("m"), .customLong("meanings")], help: "Show card meanings")
  var showMeanings: Bool = false

  var labels: [String]? {
    rawLabels?.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
  }

  func run() async throws {
    if immediate {
      try await Context.$current.withValue(.immediate) {
        try await draw()
      }
    } else {
      try await draw()
    }
  }

  func draw() async throws {
    let clock = Context.current.clock
    let print = Context.current.printer
    let labels = labels
    var deck = TarotCard.Deck()

    try expect(
      (1..<deck.cards.count).contains(cardCount),
      orThrow: Failure("`cardCount` must be between 1 and \(deck.cards.count)")
    )

    var rng: any RandomNumberGenerator = if let seed {
      Xoshiro(seed: seed)
    } else {
      SystemRandomNumberGenerator()
    }

    if immediate {
      deck.shuffle(using: &rng)
    } else {
      await print("Shuffling the deck...")
      try await clock.sleep(for: .milliseconds(600))
      for _ in 1...6 {
        await print(".")
        deck.shuffle(using: &rng)
        try await clock.sleep(for: .milliseconds(400))
      }
      try await clock.sleep(for: .milliseconds(300))

      await print("Cutting the deck...")
      try await clock.sleep(for: .milliseconds(800))
      await print(".")
      try await clock.sleep(for: .milliseconds(300))
      await print(".")
      try await clock.sleep(for: .milliseconds(600))

      if let cut {
        try expect((0...51).contains(cut), orThrow: Failure("`cut` must be between 0 and 51"))
        deck.cut(at: cut)
      } else {
        deck.cut(with: &rng)
      }

      await print("Drawing your cards", terminator: "")
      try await clock.sleep(for: .milliseconds(300))
      await print(".", terminator: "")
      try await clock.sleep(for: .milliseconds(600))
      await print(".", terminator: "")
      try await clock.sleep(for: .milliseconds(900))
      await print(".")
      try await clock.sleep(for: .milliseconds(700))
      await print()
      try await clock.sleep(for: .milliseconds(100))
    }

    let labelWidth = labels?.max(by: { $0.count < $1.count })?.count ?? String(cardCount).count

    for i in 0..<cardCount {
      let card = deck.drawCard()!
      let label = labels?[safe: i] ?? "\(i + 1)"
      let padding = labelWidth - label.count

      await print(
        label + String(repeating: " ", count: padding + 1) + ":",
        card.description
      )
      if showMeanings {
        try await print(
          indent: labelWidth + 3,
          maxWidth: Size.terminalCharacters().width,
          card.meaning()
        )
      }
      try await clock.sleep(for: .milliseconds(800))
    }
  }
}
