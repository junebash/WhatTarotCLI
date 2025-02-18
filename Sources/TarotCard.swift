@preconcurrency import Algorithms
import Foundation

private enum Keys {
  static let meaningUp = "meaning_up"
  static let valueInt = "value_int"
  static let type = "type"
  static let cards = "cards"
  static let suit = "suit"

  static let major: JSON = "major"
  static let minor: JSON = "minor"
}

public enum TarotCard: Hashable, Sendable {
  case majorArcana(MajorArcana)
  case minorArcana(MinorArcana)

  public func meaning() throws -> String {
    func failedToFindMeaning() -> Failure {
      Failure("Failed to find meaning for card \(self)")
    }

    let json = try Deck.json
    guard
      let cardsJSON = json[Keys.cards],
      case .array(let cards) = cardsJSON
    else { throw Failure("tarot.json has unexpected format") }
    
    switch self {
    case .majorArcana(let major):
      let valueInt = JSON.number(Double(major.rawValue))
      return try cards.lazy
        .filter { $0[Keys.type] == Keys.major }
        .first { $0[Keys.valueInt] == valueInt }
        .flatMap { $0[Keys.meaningUp]?.string }
        .orThrow(failedToFindMeaning())
    case .minorArcana(let minor):
      let valueInt = JSON.number(Double(minor.value.rawValue))
      let suit = JSON.string(minor.suit.description.lowercased())
      return try cards.lazy
        .filter { $0[Keys.type] == Keys.minor }
        .first { $0[Keys.valueInt] == valueInt && $0[Keys.suit] == suit }
        .flatMap { $0[Keys.meaningUp]?.string }
        .orThrow(failedToFindMeaning())
    }
  }

  public init(_ majorArcana: MajorArcana) {
    self = .majorArcana(majorArcana)
  }

  public init(_ minorArcana: MinorArcana) {
    self = .minorArcana(minorArcana)
  }

  public enum MajorArcana: UInt8, CaseIterable, Hashable, Sendable {
    case theFool = 0
    case theMagician
    case theHighPriestess
    case theEmpress
    case theEmperor
    case theHierophant
    case theLovers
    case theChariot
    case strength
    case theHermit
    case wheelOfFortune
    case justice
    case theHangedMan
    case death
    case temperance
    case theDevil
    case theTower
    case theStar
    case theMoon
    case theSun
    case judgement
    case theWorld
  }

  public struct MinorArcana: Hashable, Sendable {
    public var value: Value
    public var suit: Suit

    public enum Suit: UInt8, Hashable, Sendable, CaseIterable {
      case wands, cups, swords, pentacles
    }

    public enum Value: UInt8, Hashable, CaseIterable, Sendable {
      case ace = 1, two, three, four, five, six, seven, eight, nine, ten, page, knight, queen, king
    }
  }
}

extension TarotCard.MinorArcana.Suit: CustomStringConvertible {
  public var description: String {
    switch self {
    case .wands: "Wands"
    case .cups: "Cups"
    case .swords: "Swords"
    case .pentacles: "Pentacles"
    }
  }
}

extension TarotCard.MinorArcana.Value: CustomStringConvertible {
  public var description: String {
    switch self {
    case .ace: "Ace"
    case .two: "Two"
    case .three: "Three"
    case .four: "Four"
    case .five: "Five"
    case .six: "Six"
    case .seven: "Seven"
    case .eight: "Eight"
    case .nine: "Nine"
    case .ten: "Ten"
    case .page: "Page"
    case .knight: "Knight"
    case .queen: "Queen"
    case .king: "King"
    }
  }
}

extension TarotCard.MinorArcana: CustomStringConvertible {
  public var description: String {
    "\(value.description) of \(suit.description)"
  }
}

extension TarotCard.MinorArcana: CaseIterable {
  public static let allCases = Array(lazyAllCases)

  static nonisolated(unsafe) let lazyAllCases = Suit.allCases.lazy
    .flatMap { suit in Value.allCases.lazy.map { value in Self(value: value, suit: suit) } }
}

extension TarotCard.MajorArcana: CustomStringConvertible {
  public var description: String {
    switch self {
    case .theFool: "The Fool"
    case .theMagician: "The Magician"
    case .theHighPriestess: "The High Priestess"
    case .theEmpress: "The Empress"
    case .theEmperor: "The Emperor"
    case .theHierophant: "The Hierophant"
    case .theLovers: "The Lovers"
    case .theChariot: "The Chariot"
    case .strength: "Strength"
    case .theHermit: "The Hermit"
    case .wheelOfFortune: "Wheel of Fortune"
    case .justice: "Justice"
    case .theHangedMan: "The Hanged Man"
    case .death: "Death"
    case .temperance: "Temperance"
    case .theDevil: "The Devil"
    case .theTower: "The Tower"
    case .theStar: "The Star"
    case .theMoon: "The Moon"
    case .theSun: "The Sun"
    case .judgement: "Judgement"
    case .theWorld: "The World"
    }
  }
}

extension TarotCard: CustomStringConvertible {
  public var description: String {
    switch self {
    case .majorArcana(let card): card.description
    case .minorArcana(let card): card.description
    }
  }
}
extension TarotCard: CaseIterable {
  static let lazyAllCases = chain(
    MajorArcana.allCases.lazy.map(TarotCard.majorArcana(_:)),
    MinorArcana.lazyAllCases.lazy.map(TarotCard.minorArcana(_:))
  )
  public static let allCases = Array(lazyAllCases)
}

extension TarotCard {
  public struct Deck: ~Copyable {
    private(set) var cards: [TarotCard]

    public var indices: Range<Int> { cards.indices }

    fileprivate init(cards: [TarotCard]) {
      self.cards = cards
    }

    public init() {
      self.init(cards: TarotCard.allCases)
    }

    public mutating func shuffle(using rng: inout some RandomNumberGenerator) {
      cards.shuffle(using: &rng)
    }

    public consuming func shuffled(using rng: inout some RandomNumberGenerator) -> Self {
      shuffle(using: &rng)
      return self
    }

    public mutating func cut(at index: Int) {
      cards.rotate(toStartAt: index)
    }

    public mutating func cut(with rng: inout some RandomNumberGenerator) {
      let index = indices.randomElement(using: &rng)!
      self.cut(at: index)
    }

    public consuming func withCut(at index: Int) -> Self {
      self.cut(at: index)
      return self
    }

    public mutating func drawCard() -> TarotCard? {
      cards.popLast()
    }

    private static let _json: Result<JSON, Error> = Result {
      guard let url = Bundle.module.url(forResource: "tarot", withExtension: "json") else {
        throw Failure("Failed to locate tarot.json")
      }
      let data = try Data(contentsOf: url)
      return try JSONDecoder().decode(JSON.self, from: data)
    }

    public static var json: JSON {
      get throws {
        try _json.get()
      }
    }
  }
}
