import ExpoModulesCore
import ActivityKit

public class ExpoLiveActivitiesModule: Module {
  // Dictionary to store active activities by ID
  private var activeActivities: [String: Any] = [:]
  
  public func definition() -> ModuleDefinition {
    Name("ExpoLiveActivities")
    
    // Check if Live Activities are supported
    Function("isSupported") {
      if #available(iOS 16.1, *) {
        return true
      }
      return false
    }
    
    // Start a new Live Activity
    AsyncFunction("startActivity") { (activityType: String, attributes: [String: Any], contentState: [String: Any]) -> [String: Any] in
      guard #available(iOS 16.1, *) else {
        throw LiveActivityError.unsupported
      }
      
      do {
        let activityId = UUID().uuidString
        let startTime = Date().timeIntervalSince1970
        
        // Create the activity based on type
        try self.createActivity(
          activityId: activityId,
          activityType: activityType,
          attributes: attributes,
          contentState: contentState
        )
        
        return [
          "activityId": activityId,
          "activityType": activityType,
          "startTime": startTime
        ]
      } catch {
        throw LiveActivityError.startFailed(error.localizedDescription)
      }
    }
    
    // Update an existing Live Activity
    AsyncFunction("updateActivity") { (activityId: String, contentState: [String: Any]) in
      guard #available(iOS 16.1, *) else {
        throw LiveActivityError.unsupported
      }
      
      do {
        try self.updateExistingActivity(activityId: activityId, contentState: contentState)
      } catch {
        throw LiveActivityError.updateFailed(error.localizedDescription)
      }
    }
    
    // End a Live Activity
    AsyncFunction("endActivity") { (activityId: String, dismissalPolicy: String) in
      guard #available(iOS 16.1, *) else {
        throw LiveActivityError.unsupported
      }
      
      do {
        let policy = self.parseDismissalPolicy(dismissalPolicy)
        try self.endExistingActivity(activityId: activityId, dismissalPolicy: policy)
      } catch {
        throw LiveActivityError.endFailed(error.localizedDescription)
      }
    }
    
    // Get all active activity IDs
    AsyncFunction("getAllActivities") { () -> [String] in
      guard #available(iOS 16.1, *) else {
        return []
      }
      
      return Array(self.activeActivities.keys)
    }
  }
  
  // MARK: - Helper Methods
  
  @available(iOS 16.1, *)
  private func createActivity(
    activityId: String,
    activityType: String,
    attributes: [String: Any],
    contentState: [String: Any]
  ) throws {
    // This is where you'll implement activity creation based on type
    // For now, we'll support the example activity types
    
    switch activityType {
    case "CounterActivity":
      try createCounterActivity(activityId: activityId, attributes: attributes, contentState: contentState)
    case "StatusActivity":
      try createStatusActivity(activityId: activityId, attributes: attributes, contentState: contentState)
    case "ProgressActivity":
      try createProgressActivity(activityId: activityId, attributes: attributes, contentState: contentState)
    default:
      throw LiveActivityError.unknownType(activityType)
    }
  }
  
  @available(iOS 16.1, *)
  private func updateExistingActivity(activityId: String, contentState: [String: Any]) throws {
    guard let activity = activeActivities[activityId] else {
      throw LiveActivityError.notFound(activityId)
    }
    
    // Type-safe updates for each activity type
    if let counterActivity = activity as? Activity<CounterActivityAttributes> {
      let content = try parseCounterContent(contentState)
      Task {
        await counterActivity.update(using: content)
      }
    } else if let statusActivity = activity as? Activity<StatusActivityAttributes> {
      let content = try parseStatusContent(contentState)
      Task {
        await statusActivity.update(using: content)
      }
    } else if let progressActivity = activity as? Activity<ProgressActivityAttributes> {
      let content = try parseProgressContent(contentState)
      Task {
        await progressActivity.update(using: content)
      }
    } else {
      throw LiveActivityError.unknownType("Unknown activity type for ID: \(activityId)")
    }
  }
  
  @available(iOS 16.1, *)
  private func endExistingActivity(activityId: String, dismissalPolicy: ActivityUIDismissalPolicy) throws {
    guard let activity = activeActivities[activityId] else {
      throw LiveActivityError.notFound(activityId)
    }
    
    Task {
      if let counterActivity = activity as? Activity<CounterActivityAttributes> {
        await counterActivity.end(dismissalPolicy: dismissalPolicy)
      } else if let statusActivity = activity as? Activity<StatusActivityAttributes> {
        await statusActivity.end(dismissalPolicy: dismissalPolicy)
      } else if let progressActivity = activity as? Activity<ProgressActivityAttributes> {
        await progressActivity.end(dismissalPolicy: dismissalPolicy)
      }
    }
    
    activeActivities.removeValue(forKey: activityId)
  }
  
  @available(iOS 16.1, *)
  private func parseDismissalPolicy(_ policy: String) -> ActivityUIDismissalPolicy {
    switch policy.lowercased() {
    case "immediate":
      return .immediate
    case "after":
      if #available(iOS 16.2, *) {
        return .after(.now + 3)
      }
      return .default
    default:
      return .default
    }
  }
  
  // MARK: - CounterActivity Helpers
  
  @available(iOS 16.1, *)
  private func createCounterActivity(
    activityId: String,
    attributes: [String: Any],
    contentState: [String: Any]
  ) throws {
    let attrs = try parseCounterAttributes(attributes)
    let content = try parseCounterContent(contentState)
    
    let activity = try Activity<CounterActivityAttributes>.request(
      attributes: attrs,
      contentState: content,
      pushType: nil
    )
    
    activeActivities[activityId] = activity
  }
  
  @available(iOS 16.1, *)
  private func parseCounterAttributes(_ dict: [String: Any]) throws -> CounterActivityAttributes {
    guard let title = dict["title"] as? String else {
      throw LiveActivityError.invalidAttributes("Missing 'title' for CounterActivity")
    }
    let color = dict["color"] as? String
    return CounterActivityAttributes(title: title, color: color)
  }
  
  @available(iOS 16.1, *)
  private func parseCounterContent(_ dict: [String: Any]) throws -> CounterActivityAttributes.ContentState {
    guard let value = dict["value"] as? Int else {
      throw LiveActivityError.invalidContent("Missing 'value' for CounterActivity")
    }
    let status = dict["status"] as? String
    return CounterActivityAttributes.ContentState(value: value, status: status)
  }
  
  // MARK: - StatusActivity Helpers
  
  @available(iOS 16.1, *)
  private func createStatusActivity(
    activityId: String,
    attributes: [String: Any],
    contentState: [String: Any]
  ) throws {
    let attrs = try parseStatusAttributes(attributes)
    let content = try parseStatusContent(contentState)
    
    let activity = try Activity<StatusActivityAttributes>.request(
      attributes: attrs,
      contentState: content,
      pushType: nil
    )
    
    activeActivities[activityId] = activity
  }
  
  @available(iOS 16.1, *)
  private func parseStatusAttributes(_ dict: [String: Any]) throws -> StatusActivityAttributes {
    guard let identifier = dict["identifier"] as? String,
          let title = dict["title"] as? String else {
      throw LiveActivityError.invalidAttributes("Missing 'identifier' or 'title' for StatusActivity")
    }
    return StatusActivityAttributes(identifier: identifier, title: title)
  }
  
  @available(iOS 16.1, *)
  private func parseStatusContent(_ dict: [String: Any]) throws -> StatusActivityAttributes.ContentState {
    guard let status = dict["status"] as? String else {
      throw LiveActivityError.invalidContent("Missing 'status' for StatusActivity")
    }
    let progress = dict["progress"] as? Int
    let details = dict["details"] as? String
    let timestamp = dict["timestamp"] as? Double
    
    return StatusActivityAttributes.ContentState(
      status: status,
      progress: progress,
      details: details,
      timestamp: timestamp
    )
  }
  
  // MARK: - ProgressActivity Helpers
  
  @available(iOS 16.1, *)
  private func createProgressActivity(
    activityId: String,
    attributes: [String: Any],
    contentState: [String: Any]
  ) throws {
    let attrs = try parseProgressAttributes(attributes)
    let content = try parseProgressContent(contentState)
    
    let activity = try Activity<ProgressActivityAttributes>.request(
      attributes: attrs,
      contentState: content,
      pushType: nil
    )
    
    activeActivities[activityId] = activity
  }
  
  @available(iOS 16.1, *)
  private func parseProgressAttributes(_ dict: [String: Any]) throws -> ProgressActivityAttributes {
    guard let title = dict["title"] as? String,
          let total = dict["total"] as? Int else {
      throw LiveActivityError.invalidAttributes("Missing 'title' or 'total' for ProgressActivity")
    }
    let unit = dict["unit"] as? String
    return ProgressActivityAttributes(title: title, total: total, unit: unit)
  }
  
  @available(iOS 16.1, *)
  private func parseProgressContent(_ dict: [String: Any]) throws -> ProgressActivityAttributes.ContentState {
    guard let current = dict["current"] as? Int else {
      throw LiveActivityError.invalidContent("Missing 'current' for ProgressActivity")
    }
    let description = dict["description"] as? String
    let percentage = dict["percentage"] as? Int
    
    return ProgressActivityAttributes.ContentState(
      current: current,
      description: description,
      percentage: percentage
    )
  }
}

// MARK: - Error Types

enum LiveActivityError: Error {
  case unsupported
  case unknownType(String)
  case invalidAttributes(String)
  case invalidContent(String)
  case notFound(String)
  case startFailed(String)
  case updateFailed(String)
  case endFailed(String)
}

extension LiveActivityError: LocalizedError {
  var errorDescription: String? {
    switch self {
    case .unsupported:
      return "Live Activities require iOS 16.1 or later"
    case .unknownType(let type):
      return "Unknown activity type: \(type)"
    case .invalidAttributes(let message):
      return "Invalid attributes: \(message)"
    case .invalidContent(let message):
      return "Invalid content: \(message)"
    case .notFound(let id):
      return "Activity not found: \(id)"
    case .startFailed(let message):
      return "Failed to start activity: \(message)"
    case .updateFailed(let message):
      return "Failed to update activity: \(message)"
    case .endFailed(let message):
      return "Failed to end activity: \(message)"
    }
  }
}
