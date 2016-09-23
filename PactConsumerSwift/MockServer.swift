import Foundation
import PactMockServer

import Nimble

public class MockServer {
  public var port: Int32 = -1
  public var pactDir: String

  public init(_ dir: String = "./pacts") {
    pactDir = dir
    port = randomPort()
  }

  func randomPort() -> Int32 {
    return Int(arc4random_uniform(200)) + 4000
  }

  public func withPact(_ pact: Pact) {
    do {
      let jsonData = try JSONSerialization.data(withJSONObject: pact.payload())
      let jsonString = String(bytes: jsonData, encoding: String.Encoding.utf8)

      // Stupid iOS json generation adds extra backslashes to "application/json" --> "application\\/json"
      // SwiftlyJSON doesnt fuck with the values, but is not working with swift 3.
      let sanitizedString = jsonString!.replacingOccurrences(of: "\\/", with: "/")
      let result = PactMockServer.create_mock_server(sanitizedString, port)
      if(result < 0) {
        switch result {
        case -1:
          fail("Mock server creation failed, pact supplied was nil")
        case -2:
          fail("Mock server creation failed, pact JSON file could not be parsed")
        default:
          fail("Mock server creation failed, result: \(result)")
        }
      }
      print("Server started on port \(port)")
    } catch let error as NSError {
      print(error)
    }
  }

  public func mismatches() -> String? {
    let mismatches = PactMockServer.mock_server_mismatches(port)
    if let mismatches = mismatches {
      return String(cString: mismatches)
    } else {
      return nil
    }
  }

  public func matched() -> Bool {
    return PactMockServer.mock_server_matched(port)
  }

  public func writeFile() {
    PactMockServer.write_pact_file(port, pactDir)
    print("notify: You can find the generated pact files here: \(self.pactDir)")
  }

  public func cleanup() {
    PactMockServer.cleanup_mock_server(port)
  }

}
