import PlatformClient
import Synchronization
import Testing

private typealias QueryFilter = Primandproper_Platform_Filtering_V1_QueryFilter
private typealias Pagination = Primandproper_Platform_Filtering_V1_Pagination

/// Request is a list request with a field of its own beside the filter, as a product's is.
private struct Request: ListRequest, Equatable {
  var filter = QueryFilter()
  var parentID = "p"
}

private struct Response: ListResponse {
  var pagination = Pagination()
  var results: [String] = []
}

private func pagination(_ cursor: String, configure: (inout Pagination) -> Void = { _ in })
  -> Pagination
{
  var pagination = Pagination()
  pagination.cursor = cursor
  pagination.maxResponseSize = 2
  configure(&pagination)
  return pagination
}

private func filter(sortBy: String? = nil, cursor: String? = nil) -> QueryFilter {
  var filter = QueryFilter()
  if let sortBy { filter.sortBy = sortBy }
  if let cursor { filter.cursor = cursor }
  return filter
}

/// Server answers from `rows` `pageSize` at a time, keyed on the last row's value, as a keyset
/// store does, and keeps every request it was sent.
private final class Server: Sendable {
  let requests = Mutex<[Request]>([])
  private let rows: [String]
  private let pageSize: Int

  init(_ rows: [String], pageSize: Int = 2) {
    self.rows = rows
    self.pageSize = pageSize
  }

  var sent: [Request] { requests.withLock { $0 } }

  @Sendable func fetch(_ request: Request) async throws -> Response {
    requests.withLock { $0.append(request) }
    let after =
      request.filter.hasCursor ? (rows.firstIndex(of: request.filter.cursor) ?? -1) + 1 : 0
    let results = Array(rows[after..<min(after + pageSize, rows.count)])
    return Response(pagination: pagination(results.last ?? ""), results: results)
  }
}

private func collect<S: AsyncSequence>(_ sequence: S) async throws -> [S.Element] {
  var out: [S.Element] = []
  for try await element in sequence {
    out.append(element)
  }
  return out
}

@Suite struct PagesTests {
  @Test func walksToTheFirstPageWithNoRowsPassingEachCursorBackUnchanged() async throws {
    let server = Server(["a", "b", "c", "d", "e"])

    let walked = try await collect(
      Pages(Request(filter: filter(sortBy: "desc")), fetch: server.fetch))

    #expect(walked.map(\.results) == [["a", "b"], ["c", "d"], ["e"]])
    #expect(
      server.sent.map { $0.filter.hasCursor ? $0.filter.cursor : nil } == [nil, "b", "d", "e"])
    #expect(server.sent.allSatisfy { $0.parentID == "p" && $0.filter.sortBy == "desc" })
  }

  @Test func doesNotStopOnAShortPage() async throws {
    // A server whose pages come back short before the end: one row where two were allowed.
    let server = Server(["a", "b", "c"], pageSize: 1)

    let walked = try await collect(Items(Request(), fetch: server.fetch))

    #expect(walked == ["a", "b", "c"])
    #expect(server.sent.count == 4)
  }

  @Test func startsFromTheCursorTheRequestAlreadyCarries() async throws {
    let server = Server(["a", "b", "c", "d"])

    let walked = try await collect(Items(Request(filter: filter(cursor: "b")), fetch: server.fetch))

    #expect(walked == ["c", "d"])
  }

  @Test func yieldsNothingForAnEmptyListAfterOneRoundTrip() async throws {
    let server = Server([])

    #expect(try await collect(Pages(Request(), fetch: server.fetch)).isEmpty)
    #expect(server.sent.count == 1)
  }

  @Test func refusesAPageWithRowsAndNoCursorRatherThanRestartingTheList() async throws {
    let pages = Pages(Request()) { _ in Response(pagination: pagination(""), results: ["a"]) }

    await #expect(throws: PageWalkError.rowsWithoutCursor) { try await collect(pages) }
  }

  @Test func refusesAPageThatHandsBackTheCursorThatReachedIt() async throws {
    let pages = Pages(Request(filter: filter(cursor: "a"))) { _ in
      Response(pagination: pagination("a"), results: ["a"])
    }

    await #expect(throws: PageWalkError.cursorRepeated) { try await collect(pages) }
  }

  @Test func endsOnceItHasThrown() async throws {
    var pages = Pages(Request()) { _ in Response(pagination: pagination(""), results: ["a"]) }
      .makeAsyncIterator()

    await #expect(throws: PageWalkError.rowsWithoutCursor) { try await pages.next() }
    #expect(try await pages.next() == nil)
  }

  @Test func doesNotChangeTheRequestItWasGiven() async throws {
    let server = Server(["a", "b", "c"])
    let request = Request()
    let pages = Pages(request, fetch: server.fetch)

    _ = try await collect(pages)

    #expect(request == Request())
    // And walking it again starts from the beginning again.
    #expect(try await collect(pages).flatMap(\.results) == ["a", "b", "c"])
  }

  @Test func stopsBetweenPagesWhenItsTaskIsCancelled() async throws {
    let server = Server(["a", "b", "c", "d", "e"])
    let (arrived, firstPage) = AsyncStream.makeStream(of: Void.self)
    let (resumed, resume) = AsyncStream.makeStream(of: Void.self)

    let walk = Task {
      var pages = Pages(Request(), fetch: server.fetch).makeAsyncIterator()
      _ = try await pages.next()
      firstPage.yield()
      for await _ in resumed { break }
      return try await pages.next()
    }
    for await _ in arrived { break }
    walk.cancel()
    resume.yield()

    await #expect(throws: CancellationError.self) { try await walk.value }
    #expect(server.sent.count == 1)
  }

  @Test func walksAGeneratedListRPC() async throws {
    typealias ListUsersRequest = Primandproper_Platform_Identity_V1_ListUsersRequest
    typealias ListUsersResponse = Primandproper_Platform_Identity_V1_ListUsersResponse
    typealias User = Primandproper_Platform_Identity_V1_User

    let users = ["u1", "u2", "u3"].map { id in
      var user = User()
      user.id = id
      return user
    }
    let walked = try await collect(
      Items(ListUsersRequest()) { request in
        let after = users.firstIndex { $0.id == request.filter.cursor }.map { $0 + 1 } ?? 0
        var response = ListUsersResponse()
        response.results = Array(users[after..<min(after + 2, users.count)])
        response.pagination.cursor = response.results.last?.id ?? ""
        return response
      })

    #expect(walked.map(\.id) == ["u1", "u2", "u3"])
  }
}

@Suite struct CountsTests {
  @Test func answersTheCountsWhenThePageVouchesForThem() {
    let page = pagination("a") {
      $0.countsKnown = true
      $0.filteredCount = 3
      $0.totalCount = 10
    }

    #expect(page.counts == Counts(filtered: 3, total: 10))
  }

  @Test func answersNilRatherThanZeroWhenCountsAreNotKnown() {
    #expect(pagination("") { $0.countsKnown = false }.counts == nil)
  }

  @Test func answersNilForAResponseWithNoPagination() {
    #expect(Response().counts == nil)
  }

  @Test func answersNilForCountsThatAreSetButNotVouchedFor() {
    let page = pagination("a") {
      $0.filteredCount = 3
      $0.totalCount = 10
    }

    #expect(page.counts == nil)
  }

  @Test func reportsAKnownZeroAsZero() {
    #expect(pagination("") { $0.countsKnown = true }.counts == Counts(filtered: 0, total: 0))
  }
}
