import Synchronization
import Testing
@testable import WhatTarotCLI

@Suite
struct ArgumentTests {
  @Test("basic parsing")
  func basics() async throws {
    let cli = try WhatTarotCLI.parse([
      "-c", "12",
      "-s", "899"
    ])
    #expect(cli.cardCount == 12)
    #expect(cli.labels == nil)
    #expect(cli.seed == 899)
  }

  @Test("labels parse correctly")
  func labelParsing() async throws {
    let cli = try WhatTarotCLI.parse([
      "-l", "Past, Present, Future"
    ])
    #expect(cli.labels == ["Past", "Present", "Future"])
  }

  @Test("end-to-end happy path")
  func happyPath() async throws {
    actor State {
      var value = ""

      func append(_ string: String) {
        value += string
      }
    }

    let state = State()
    let printer: some AsyncPrinter = .into { @Sendable s in await state.append(s) }
    try await WhatTarotCLI.Context.$current.withValue(
      WhatTarotCLI.Context(clock: .immediate, printer: printer)
    ) {
      var cli = try WhatTarotCLI.parse(["-s", "12345"])
      try await cli.run()
    }
    #expect(
      await state.value == """
        Shuffling the deck...
        .
        .
        .
        .
        .
        .
        Cutting the deck...
        .
        .
        Drawing your cards...

        1 : The Chariot
        2 : Ace of Pentacles
        3 : Three of Cups

        """
    )
  }
}

@Suite
struct UtilityTests {
  @Test("word wrap works at all")
  func wordWrap() {
    let text = "This is a very long line that needs to be wrapped to fit within the terminal window."
    let expected = "This is a very long line that\nneeds to be wrapped to fit\nwithin the terminal window."
    #expect(text.wordWrap(maxWidth: 30, indent: 0) == expected)
  }
}
