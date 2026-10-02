import Foundation
import PlatformClient
import Synchronization

/// FakeClock is a WallClock that moves only when told to.
public final class FakeClock: WallClock {
  private let current: Mutex<Date>

  public init(_ start: Date = Date(timeIntervalSince1970: 1_767_225_600)) {
    current = Mutex(start)
  }

  public func now() -> Date { current.withLock { $0 } }

  public func set(_ to: Date) { current.withLock { $0 = to } }

  public func advance(by interval: TimeInterval) { current.withLock { $0 += interval } }
}
