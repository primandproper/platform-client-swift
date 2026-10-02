import Foundation
import PlatformClient
import SwiftProtobuf

/// fakeIssuedToken is a session that expires an hour after `now`, with a refresh token good
/// for a day. `configure` overrides whatever a test cares about.
public func fakeIssuedToken(
  now: Date,
  _ configure: (inout IssuedToken) -> Void = { _ in }
) -> IssuedToken {
  var token = IssuedToken()
  token.token = "access-1"
  token.tokenID = "jti-1"
  token.expiresAt = Google_Protobuf_Timestamp(date: now.addingTimeInterval(60 * 60))
  token.refreshToken = "refresh-1"
  token.refreshTokenExpiresAt = Google_Protobuf_Timestamp(
    date: now.addingTimeInterval(24 * 60 * 60))
  token.activeAccountID = "account-1"
  token.administrative = false
  token.familyID = "family-1"
  configure(&token)
  return token
}
