import PlatformClient

/// MemoryDeviceRegistrationStore holds a device registration in memory. It is for tests: a
/// store that forgets on restart registers again on every launch.
public actor MemoryDeviceRegistrationStore: DeviceRegistrationStore {
  private var registration: DeviceRegistration?

  public init(_ registration: DeviceRegistration? = nil) {
    self.registration = registration
  }

  public func load() -> DeviceRegistration? { registration }

  public func save(_ registration: DeviceRegistration) { self.registration = registration }

  public func clear() { registration = nil }
}
