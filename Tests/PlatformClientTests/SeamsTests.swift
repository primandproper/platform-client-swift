import Foundation
import GRPCCore
import PlatformClient
import PlatformClientTesting
import Testing

@Suite struct BearerAuthorizerTests {
  @Test func carriesTheTokenAsABearerAuthorizationEntry() {
    let metadata = BearerAuthorizer().credentials("abc")

    #expect(Array(metadata[stringValues: "authorization"]) == ["Bearer abc"])
    #expect(metadata.count == 1)
  }
}

@Suite struct MemoryCredentialStoreTests {
  @Test func loadsWhatItSavedUntilItIsCleared() async {
    let store = MemoryCredentialStore()
    let token = fakeIssuedToken(now: Date())

    #expect(await store.load() == nil)
    await store.save(token)
    #expect(await store.load() == token)
    await store.clear()
    #expect(await store.load() == nil)
  }
}

@Suite struct FakeClockTests {
  @Test func movesOnlyWhenToldTo() {
    let start = Date(timeIntervalSince1970: 1_767_225_600)
    let clock = FakeClock(start)

    #expect(clock.now() == start)
    clock.advance(by: 30)

    #expect(clock.now() == start.addingTimeInterval(30))
  }
}
