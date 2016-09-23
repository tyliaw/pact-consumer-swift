import Foundation
import Nimble

@objc public class PactRunner : NSObject {
  private let pact: Pact
  private let mockServer: MockServer
  private var interactions: [Interaction] = []

  public var baseUrl: String {
    get {
      return "http://localhost:\(mockServer.port)"
    }
  }

  public init(provider: String, consumer: String, mockServer: MockServer) {
    self.pact = Pact(provider: provider, consumer: consumer)
    self.mockServer = mockServer
  }

  @objc(initWithProvider: consumer: )
  public convenience init(provider: String, consumer: String) {
    self.init(provider: provider, consumer: consumer, mockServer: MockServer())
  }

  public func given(_ providerState: String) -> Interaction {
    let interaction = Interaction().given(providerState)
    interactions.append(interaction)
    return interaction
  }

  @objc(uponReceiving:)
  public func uponReceiving(_ description: String) -> Interaction {
    let interaction = Interaction().uponReceiving(description)
    interactions.append(interaction)
    return interaction
  }

  @objc(run:)
  open func objcRun(_ testFunction: @escaping (_ testComplete: () -> Void) -> Void) -> Void {
    self.run(nil, line: nil, testFunction: testFunction)
  }

  open func run(_ file: String? = #file, line: UInt? = #line, testFunction: @escaping (_ testComplete: @escaping () -> Void) -> Void) -> Void {
    var complete = false
    pact.withInteractions(interactions)
    mockServer.withPact(pact)
    testFunction { () in
      complete = true
      if(!self.mockServer.matched()) {
        print("Actual request did not match expectations. Mismatches: ")
        print(self.mockServer.mismatches())
        fail("Actual request did not match expectations. Mismatches: \(self.mockServer.mismatches())")
      }
      self.mockServer.writeFile()
      self.mockServer.cleanup()
    }
    if let fileName = file, let lineNumber = line {
      expect(fileName, line: lineNumber, expression: { complete} ).toEventually(beTrue(), timeout: 10, description: "Expected requests were never received. Make sure the testComplete() fuction is called at the end of your test.")
    } else {
      expect(complete).toEventually(beTrue(), timeout: 10, description: "Expected requests were never received. Make sure the testComplete() fuction is called at the end of your test.")
    }
  }
}
