import GRPCCore
import Testing

@testable import PlatformClient

@Suite struct GeneratedTests {
  @Test func servicesNameTheirWireIdentity() {
    #expect(
      Primandproper_Platform_Signin_V1_SignInService.descriptor.fullyQualifiedService
        == "primandproper.platform.signin.v1.SignInService")
    #expect(
      Primandproper_Platform_Passkeys_V1_PasskeysService.descriptor.fullyQualifiedService
        == "primandproper.platform.passkeys.v1.PasskeysService")
    #expect(
      Primandproper_Platform_Passwordreset_V1_PasswordResetService.descriptor.fullyQualifiedService
        == "primandproper.platform.passwordreset.v1.PasswordResetService")
  }
}
