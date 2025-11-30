import ActivityKit
import Foundation

// MARK: - Counter Activity

@available(iOS 16.1, *)
struct CounterActivityAttributes: ActivityAttributes {
  public struct ContentState: Codable, Hashable {
    var value: Int
    var status: String?
  }
  
  var title: String
  var color: String?
}

// MARK: - Status Activity

@available(iOS 16.1, *)
struct StatusActivityAttributes: ActivityAttributes {
  public struct ContentState: Codable, Hashable {
    var status: String
    var progress: Int?
    var details: String?
    var timestamp: Double?
  }
  
  var identifier: String
  var title: String
}

// MARK: - Progress Activity

@available(iOS 16.1, *)
struct ProgressActivityAttributes: ActivityAttributes {
  public struct ContentState: Codable, Hashable {
    var current: Int
    var description: String?
    var percentage: Int?
  }
  
  var title: String
  var total: Int
  var unit: String?
}
