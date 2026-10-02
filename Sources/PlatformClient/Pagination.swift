/// ListRequest is the shape every list RPC's request shares: a filter, which carries the cursor.
///
/// Swift has no structural typing, so a generated request conforms by extension. Platform's own
/// conform below; a product's list request conforms with one empty extension of its own.
public protocol ListRequest: Sendable {
  var filter: Primandproper_Platform_Filtering_V1_QueryFilter { get set }
}

/// ListResponse is the shape every list RPC's response shares: a page of rows, and the
/// pagination that reaches the next one.
public protocol ListResponse: Sendable {
  associatedtype Row: Sendable

  var pagination: Primandproper_Platform_Filtering_V1_Pagination { get }
  var results: [Row] { get }
}

extension ListResponse {
  /// counts is this page's `Pagination.counts`.
  public var counts: Counts? { pagination.counts }
}

/// PageWalkError is a page that would send a walk somewhere other than onwards.
public enum PageWalkError: Error, Sendable, Hashable, CustomStringConvertible {
  /// rowsWithoutCursor is a page that held rows and no cursor to the next one. Walking on would
  /// send an empty cursor, which starts the list again.
  case rowsWithoutCursor
  /// cursorRepeated is a page that answered with the cursor that reached it. Walking on would
  /// fetch the same page forever.
  case cursorRepeated

  public var description: String {
    switch self {
    case .rowsWithoutCursor:
      "a page held rows and no cursor to the next one; walking on would restart the list"
    case .cursorRepeated:
      "a page answered with the cursor that reached it; walking on would repeat it forever"
    }
  }
}

/// Pages walks a list from `request`'s cursor (or the start) to its end, yielding each page that
/// held rows. `fetch` is one call of the list RPC:
///
/// ```swift
/// for try await page in Pages(request, fetch: { request in
///   try await session.call { try await users.listUsers(request, metadata: $0) }
/// }) { … }
/// ```
///
/// It ends on a page with no rows and nowhere else (R14). A page shorter than
/// `max_response_size` is not the end, since nothing promises that, and stopping on one silently
/// truncates the list. Reaching the end therefore costs one extra round trip, which is the shape
/// of a keyset walk.
///
/// Cursors are passed back exactly as they came (R8): never parsed or built, and compared only
/// to tell an empty one from the one that reached the page. The request is otherwise sent as
/// given, page after page, and the first page is sent with the cursor it already carried.
///
/// A cancelled task stops the walk before its next page, by throwing CancellationError rather
/// than ending, since an end would read as the end of the list.
public struct Pages<Request: ListRequest, Response: ListResponse>: AsyncSequence, Sendable {
  public typealias Element = Response
  public typealias Fetch = @Sendable (Request) async throws -> Response

  private let request: Request
  private let fetch: Fetch

  public init(_ request: Request, fetch: @escaping Fetch) {
    self.request = request
    self.fetch = fetch
  }

  public func makeAsyncIterator() -> AsyncIterator {
    AsyncIterator(request: request, fetch: fetch)
  }

  public struct AsyncIterator: AsyncIteratorProtocol {
    /// request is the next page's request, and nil once the walk is over.
    private var request: Request?
    private let fetch: Fetch

    init(request: Request, fetch: @escaping Fetch) {
      self.request = request
      self.fetch = fetch
    }

    public mutating func next() async throws -> Response? {
      guard var request else { return nil }
      self.request = nil

      try Task.checkCancellation()
      let page = try await fetch(request)
      if page.results.isEmpty {
        return nil
      }
      let next = page.pagination.cursor
      if next.isEmpty {
        throw PageWalkError.rowsWithoutCursor
      }
      if next == request.filter.cursor {
        throw PageWalkError.cursorRepeated
      }
      request.filter.cursor = next
      self.request = request
      return page
    }
  }
}

/// Items walks a list as `Pages` does, yielding its rows one at a time.
public struct Items<Request: ListRequest, Response: ListResponse>: AsyncSequence, Sendable {
  public typealias Element = Response.Row

  private let pages: Pages<Request, Response>

  public init(_ request: Request, fetch: @escaping Pages<Request, Response>.Fetch) {
    pages = Pages(request, fetch: fetch)
  }

  public func makeAsyncIterator() -> AsyncIterator {
    AsyncIterator(pages: pages.makeAsyncIterator())
  }

  public struct AsyncIterator: AsyncIteratorProtocol {
    private var pages: Pages<Request, Response>.AsyncIterator
    private var rows: IndexingIterator<[Response.Row]> = [].makeIterator()

    init(pages: Pages<Request, Response>.AsyncIterator) {
      self.pages = pages
    }

    public mutating func next() async throws -> Response.Row? {
      while true {
        if let row = rows.next() {
          return row
        }
        guard let page = try await pages.next() else { return nil }
        rows = page.results.makeIterator()
      }
    }
  }
}

/// Counts is how many rows the collection a page was cut from holds. Neither describes the page.
public struct Counts: Hashable, Sendable {
  /// filtered is how many rows in the collection match the filter.
  public let filtered: UInt64
  /// total is how many rows the collection holds.
  public let total: UInt64

  public init(filtered: UInt64, total: UInt64) {
    self.filtered = filtered
    self.total = total
  }
}

extension Primandproper_Platform_Filtering_V1_Pagination {
  /// counts is this page's counts, or nil when the page does not vouch for them (R9). A store
  /// that reads counts off its rows has none to read on an empty page, so a zero there is not a
  /// result, and `countsKnown` is what tells the two apart.
  public var counts: Counts? {
    countsKnown ? Counts(filtered: filteredCount, total: totalCount) : nil
  }
}
