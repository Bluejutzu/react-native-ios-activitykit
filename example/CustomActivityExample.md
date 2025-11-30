# Creating a Custom Activity Type

This guide walks you through creating a custom Live Activity for a ride-sharing app.

## What We're Building

A **RideActivity** that shows:

- Driver name and photo
- Estimated arrival time
- Current status (finding driver, en route, arriving)
- Live location updates

---

## Step 1: Define TypeScript Types

Create or add to your types file:

```typescript
// In your app or in a custom types file
export interface RideActivityAttributes {
  /** Trip ID */
  tripId: string;
  /** Pickup location name */
  pickupLocation: string;
  /** Destination name */
  destination: string;
}

export interface RideActivityContent {
  /** Current status */
  status: "finding" | "accepted" | "enroute" | "arriving" | "arrived";
  /** Driver name (available after accepted) */
  driverName?: string;
  /** Driver photo URL */
  driverPhoto?: string;
  /** Estimated minutes until arrival */
  etaMinutes?: number;
  /** Driver's current distance in miles */
  distanceMiles?: number;
}
```

---

## Step 2: Create Swift ActivityAttributes

Create `ios/RideActivityAttributes.swift`:

```swift
import ActivityKit
import Foundation

@available(iOS 16.1, *)
struct RideActivityAttributes: ActivityAttributes {
  public struct ContentState: Codable, Hashable {
    // Status
    var status: String // 'finding', 'accepted', 'enroute', 'arriving', 'arrived'

    // Driver info
    var driverName: String?
    var driverPhoto: String?

    // Timing
    var etaMinutes: Int?
    var distanceMiles: Double?
  }

  // Static attributes
  var tripId: String
  var pickupLocation: String
  var destination: String
}
```

---

## Step 3: Register in Module

Edit `ios/ExpoLiveActivitiesModule.swift`:

### 3.1: Add to `createActivity` switch

```swift
private func createActivity(
  activityId: String,
  activityType: String,
  attributes: [String: Any],
  contentState: [String: Any]
) throws {
  switch activityType {
  case "CounterActivity":
    try createCounterActivity(activityId: activityId, attributes: attributes, contentState: contentState)
  case "StatusActivity":
    try createStatusActivity(activityId: activityId, attributes: attributes, contentState: contentState)
  case "ProgressActivity":
    try createProgressActivity(activityId: activityId, attributes: attributes, contentState: contentState)
  case "RideActivity":  // ← ADD THIS
    try createRideActivity(activityId: activityId, attributes: attributes, contentState: contentState)
  default:
    throw LiveActivityError.unknownType(activityType)
  }
}
```

### 3.2: Add type-safe update handling

In `updateExistingActivity`, add:

```swift
private func updateExistingActivity(activityId: String, contentState: [String: Any]) throws {
  guard let activity = activeActivities[activityId] else {
    throw LiveActivityError.notFound(activityId)
  }

  // ... existing code ...

  else if let rideActivity = activity as? Activity<RideActivityAttributes> {  // ← ADD THIS
    let content = try parseRideContent(contentState)
    Task {
      await rideActivity.update(using: content)
    }
  }

  // ... rest of code ...
}
```

### 3.3: Add end handling

In `endExistingActivity`, add:

```swift
else if let rideActivity = activity as? Activity<RideActivityAttributes> {  // ← ADD THIS
  await rideActivity.end(dismissalPolicy: dismissalPolicy)
}
```

### 3.4: Implement helper methods

Add at the end of the file:

```swift
// MARK: - RideActivity Helpers

@available(iOS 16.1, *)
private func createRideActivity(
  activityId: String,
  attributes: [String: Any],
  contentState: [String: Any]
) throws {
  let attrs = try parseRideAttributes(attributes)
  let content = try parseRideContent(contentState)

  let activity = try Activity<RideActivityAttributes>.request(
    attributes: attrs,
    contentState: content,
    pushType: nil
  )

  activeActivities[activityId] = activity
}

@available(iOS 16.1, *)
private func parseRideAttributes(_ dict: [String: Any]) throws -> RideActivityAttributes {
  guard let tripId = dict["tripId"] as? String,
        let pickupLocation = dict["pickupLocation"] as? String,
        let destination = dict["destination"] as? String else {
    throw LiveActivityError.invalidAttributes("Missing required fields for RideActivity")
  }

  return RideActivityAttributes(
    tripId: tripId,
    pickupLocation: pickupLocation,
    destination: destination
  )
}

@available(iOS 16.1, *)
private func parseRideContent(_ dict: [String: Any]) throws -> RideActivityAttributes.ContentState {
  guard let status = dict["status"] as? String else {
    throw LiveActivityError.invalidContent("Missing 'status' for RideActivity")
  }

  let driverName = dict["driverName"] as? String
  let driverPhoto = dict["driverPhoto"] as? String
  let etaMinutes = dict["etaMinutes"] as? Int
  let distanceMiles = dict["distanceMiles"] as? Double

  return RideActivityAttributes.ContentState(
    status: status,
    driverName: driverName,
    driverPhoto: driverPhoto,
    etaMinutes: etaMinutes,
    distanceMiles: distanceMiles
  )
}
```

---

## Step 4: Use in Your App

```typescript
import {
  startActivity,
  updateActivity,
  endActivity,
} from "react-native-ios-activitykit";
import type { RideActivityAttributes, RideActivityContent } from "./types";

// Start the activity when ride is requested
const startRide = async () => {
  const activity = await startActivity<
    RideActivityAttributes,
    RideActivityContent
  >(
    "RideActivity",
    {
      tripId: "TRIP-12345",
      pickupLocation: "123 Main St",
      destination: "Airport Terminal 1",
    },
    {
      status: "finding",
      etaMinutes: undefined,
    }
  );

  // Save activity ID for updates
  return activity.activityId;
};

// Update when driver accepts
const onDriverAccepted = async (activityId: string, driver: Driver) => {
  await updateActivity<RideActivityContent>(activityId, {
    status: "accepted",
    driverName: driver.name,
    driverPhoto: driver.photoUrl,
    etaMinutes: 5,
    distanceMiles: 2.3,
  });
};

// Update location periodically
const onLocationUpdate = async (
  activityId: string,
  eta: number,
  distance: number
) => {
  await updateActivity<RideActivityContent>(activityId, {
    status: "enroute",
    etaMinutes: eta,
    distanceMiles: distance,
  });
};

// End when ride is complete
const onRideComplete = async (activityId: string) => {
  await updateActivity<RideActivityContent>(activityId, {
    status: "arrived",
  });

  // End after 3 seconds
  setTimeout(async () => {
    await endActivity(activityId, "after");
  }, 3000);
};
```

---

## Step 5: Create UI (Widget Extension)

To display the Live Activity, you'll need to create a Widget Extension in Xcode.

### 5.1: Add Widget Extension

1. Open your iOS project in Xcode
2. File → New → Target → Widget Extension
3. Name it "RideActivityWidget"
4. Uncheck "Include Configuration Intent"

### 5.2: Create Widget UI

In the generated `RideActivityWidget.swift`:

```swift
import ActivityKit
import WidgetKit
import SwiftUI

struct RideActivityWidget: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: RideActivityAttributes.self) { context in
      // Lock screen / banner UI
      LockScreenView(context: context)
    } dynamicIsland: { context in
      DynamicIsland {
        // Expanded view
        DynamicIslandExpandedRegion(.leading) {
          HStack {
            // Driver photo
            if let photoUrl = context.state.driverPhoto {
              AsyncImage(url: URL(string: photoUrl)) { image in
                image.resizable()
              } placeholder: {
                Circle().fill(.gray)
              }
              .frame(width: 40, height: 40)
              .clipShape(Circle())
            }

            VStack(alignment: .leading) {
              Text(context.state.driverName ?? "Finding driver...")
                .font(.headline)
              Text(context.attributes.destination)
                .font(.caption)
                .foregroundColor(.secondary)
            }
          }
        }

        DynamicIslandExpandedRegion(.trailing) {
          if let eta = context.state.etaMinutes {
            VStack {
              Text("\(eta)")
                .font(.title)
              Text("min")
                .font(.caption)
            }
          }
        }

        DynamicIslandExpandedRegion(.bottom) {
          // Progress bar or map
          ProgressView(value: getProgress(context.state.status))
            .progressViewStyle(.linear)
        }
      } compactLeading: {
        Image(systemName: "car.fill")
      } compactTrailing: {
        if let eta = context.state.etaMinutes {
          Text("\(eta) min")
            .font(.caption2)
        }
      } minimal: {
        Image(systemName: "car.fill")
      }
    }
  }

  func getProgress(_ status: String) -> Double {
    switch status {
    case "finding": return 0.0
    case "accepted": return 0.25
    case "enroute": return 0.5
    case "arriving": return 0.75
    case "arrived": return 1.0
    default: return 0.0
    }
  }
}

struct LockScreenView: View {
  let context: ActivityViewContext<RideActivityAttributes>

  var body: some View {
    HStack {
      VStack(alignment: .leading) {
        Text(context.state.driverName ?? "Finding driver...")
          .font(.headline)
        Text("to \(context.attributes.destination)")
          .font(.caption)
      }

      Spacer()

      if let eta = context.state.etaMinutes {
        VStack {
          Text("\(eta)")
            .font(.title2)
          Text("min")
            .font(.caption)
        }
      }
    }
    .padding()
  }
}
```

---

## Complete! 🎉

You now have a fully functional custom Live Activity. The flow is:

1. **TypeScript types** define the interface
2. **Swift structs** match those types
3. **Module integration** handles creation/updates
4. **Widget Extension** displays the UI
5. **Your app** controls the lifecycle

Every custom activity follows this same pattern!
