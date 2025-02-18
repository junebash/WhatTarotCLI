import Synchronization

final class MoreImmediateClock {
  struct Instant: InstantProtocol {
    typealias AtomicRepresentation = Duration
    typealias Duration = Swift.Duration

    let offset: Duration

    static func < (lhs: MoreImmediateClock.Instant, rhs: MoreImmediateClock.Instant) -> Bool {
      lhs.offset < rhs.offset
    }

    func advanced(by duration: Duration) -> MoreImmediateClock.Instant {
      .init(offset: offset + duration)
    }

    func duration(to other: MoreImmediateClock.Instant) -> Duration {
      other.offset - offset
    }
  }

  private let _now: Atomic<Duration>

  init(_ now: Instant? = nil) {
    self._now = .init(now?.offset ?? .zero)
  }
}

extension MoreImmediateClock: Clock {
  func sleep(until deadline: Instant, tolerance: Duration?) throws {
    try Task.checkCancellation()
    _now.store(deadline.offset, ordering: .relaxed)
  }

  var now: Instant { .init(offset: _now.load(ordering: .relaxed)) }

  var minimumResolution: Duration { .nanoseconds(1) }
}

extension MoreImmediateClock {
  static var moreImmediate: MoreImmediateClock { .init() }
}
