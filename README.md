# react-native-ios-activitykit

A generic, customizable Expo module for implementing iOS Live Activities and Dynamic Island features in React Native apps.

## Features

✨ **Generic Design**: Not limited to specific use cases - create any activity type you need  
🎨 **Type-Safe**: Full TypeScript support with generics  
📱 **iOS 16.1+**: Supports Live Activities and Dynamic Island  
🔧 **Customizable**: Easy to extend with your own activity types  
📦 **Expo Compatible**: Works seamlessly with Expo's managed workflow

## Installation

```bash
npm install react-native-ios-activitykit
```

Or with yarn:

```bash
yarn add react-native-ios-activitykit
```

## Configuration

### 1. Add to your Expo app's `package.json`:

```json
{
  "dependencies": {
    "react-native-ios-activitykit": "file:../path/to/react-native-ios-activitykit"
  }
}
```

### 2. Configure Info.plist

Add Live Activities support to your `app.json` or `app.config.js`:

```json
{
  "expo": {
    "ios": {
      "infoPlist": {
        "NSSupportsLiveActivities": true
      }
    }
  }
}
```

### 3. Run prebuild

```bash
npx expo prebuild -p ios
```

## Quick Start

```typescript
import {
  startActivity,
  updateActivity,
  endActivity,
  isSupported,
  DismissalPolicy,
} from "react-native-ios-activitykit";

// Check if supported
if (isSupported()) {
  // Start a counter activity
  const activity = await startActivity(
    "CounterActivity",
    { title: "Pizza Timer", color: "#FF6B6B" },
    { value: 900, status: "Baking..." }
  );

  // Update it
  await updateActivity(activity.activityId, {
    value: 600,
    status: "Almost done!",
  });

  // End it
  await endActivity(activity.activityId, DismissalPolicy.IMMEDIATE);
}
```

## Built-in Activity Types

### 1. CounterActivity

Perfect for timers, countdowns, or simple counters.

```typescript
import type {
  CounterActivityAttributes,
  CounterActivityContent,
} from "react-native-ios-activitykit";

const activity = await startActivity<
  CounterActivityAttributes,
  CounterActivityContent
>(
  "CounterActivity",
  {
    title: "Workout Timer",
    color: "#007AFF",
  },
  {
    value: 3600,
    status: "In progress",
  }
);
```

### 2. StatusActivity

For tracking order status, delivery, or any status-based workflow.

```typescript
import type {
  StatusActivityAttributes,
  StatusActivityContent,
} from "react-native-ios-activitykit";

const activity = await startActivity<
  StatusActivityAttributes,
  StatusActivityContent
>(
  "StatusActivity",
  {
    identifier: "ORDER-12345",
    title: "Pizza Delivery",
  },
  {
    status: "Preparing",
    progress: 25,
    details: "Your pizza is being made",
    timestamp: Date.now(),
  }
);
```

### 3. ProgressActivity

For file uploads, downloads, or any progress-based tasks.

```typescript
import type {
  ProgressActivityAttributes,
  ProgressActivityContent,
} from "react-native-ios-activitykit";

const activity = await startActivity<
  ProgressActivityAttributes,
  ProgressActivityContent
>(
  "ProgressActivity",
  {
    title: "Uploading Photos",
    total: 100,
    unit: "files",
  },
  {
    current: 45,
    description: "Uploading IMG_2345.jpg",
    percentage: 45,
  }
);
```

## Creating Custom Activity Types

You can create your own custom activity types by:

1. **Creating the Swift ActivityAttributes struct**
2. **Adding TypeScript types**
3. **Registering in the module**

### Example: Custom Music Activity

#### Step 1: Create Swift Struct (`ios/MusicActivityAttributes.swift`)

```swift
import ActivityKit

@available(iOS 16.1, *)
struct MusicActivityAttributes: ActivityAttributes {
  public struct ContentState: Codable, Hashable {
    var songTitle: String
    var artist: String
    var isPlaying: Bool
    var currentTime: Int
    var duration: Int
  }

  var albumArt: String? // URL or asset name
  var albumName: String
}
```

#### Step 2: Add TypeScript Types

```typescript
export interface MusicActivityAttributes {
  albumArt?: string;
  albumName: string;
}

export interface MusicActivityContent {
  songTitle: string;
  artist: string;
  isPlaying: boolean;
  currentTime: number;
  duration: number;
}
```

#### Step 3: Extend Module (in `ExpoLiveActivitiesModule.swift`)

Add to the `createActivity` switch statement:

```swift
case "MusicActivity":
  try createMusicActivity(activityId: activityId, attributes: attributes, contentState: contentState)
```

Then implement the helper methods following the pattern of existing activities.

#### Step 4: Use It!

```typescript
const activity = await startActivity<
  MusicActivityAttributes,
  MusicActivityContent
>(
  "MusicActivity",
  {
    albumName: "Greatest Hits",
    albumArt: "https://example.com/album.jpg",
  },
  {
    songTitle: "Bohemian Rhapsody",
    artist: "Queen",
    isPlaying: true,
    currentTime: 45,
    duration: 354,
  }
);
```

## API Reference

### `isSupported(): boolean`

Check if Live Activities are supported on the current device.

**Returns:** `true` if iOS 16.1+ and Live Activities are available

---

### `startActivity<TAttributes, TContent>(activityType, attributes, contentState): Promise<ActivityInfo>`

Start a new Live Activity.

**Parameters:**

- `activityType: string` - Name of the activity type (must match Swift struct)
- `attributes: TAttributes` - Static attributes (don't change during activity lifetime)
- `contentState: TContent` - Dynamic content (can be updated)

**Returns:** Promise resolving to `ActivityInfo` with `activityId`

**Throws:** Error if not supported or if activity creation fails

---

### `updateActivity<TContent>(activityId, contentState): Promise<void>`

Update an existing Live Activity's dynamic content.

**Parameters:**

- `activityId: string` - ID from `startActivity`
- `contentState: TContent` - New dynamic content

**Throws:** Error if activity not found or update fails

---

### `endActivity(activityId, dismissalPolicy?): Promise<void>`

End a Live Activity.

**Parameters:**

- `activityId: string` - ID from `startActivity`
- `dismissalPolicy?: 'immediate' | 'after' | 'default'` - How to dismiss (default: 'default')

---

### `getAllActivities(): Promise<string[]>`

Get all active Live Activity IDs.

**Returns:** Array of activity ID strings

---

### `endAllActivities(dismissalPolicy?): Promise<void>`

End all active Live Activities.

**Parameters:**

- `dismissalPolicy?: 'immediate' | 'after' | 'default'` - How to dismiss (default: 'default')

## Dismissal Policies

```typescript
enum DismissalPolicy {
  IMMEDIATE = "immediate", // Remove immediately
  AFTER = "after", // Keep in history briefly (iOS 16.2+)
  DEFAULT = "default", // Let system decide
}
```

## Platform Support

- ✅ **iOS 16.1+**: Full support
- ❌ **iOS < 16.1**: `isSupported()` returns false, functions throw errors
- ❌ **Android**: Not supported (platform limitation)
- ⚠️ **iOS Simulator**: Live Activities don't display (test on real device)

## Troubleshooting

### Live Activities don't appear

1. **Check iOS version**: Must be 16.1 or later
2. **Test on real device**: Simulator doesn't show Live Activities
3. **Verify Info.plist**: Ensure `NSSupportsLiveActivities` is `true`
4. **Check Focus mode**: Some Focus modes hide Live Activities

### Module not found error

1. Run `npx expo prebuild -p ios --clean`
2. Install CocoaPods: `cd ios && pod install`
3. Rebuild the app

### TypeScript errors

Ensure you're importing types:

```typescript
import type {
  CounterActivityAttributes,
  CounterActivityContent,
} from "react-native-ios-activitykit";
```

## Examples

See the `example/` directory for complete examples of:

- Timer/Counter app
- Delivery tracking
- File upload progress
- Custom music player

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT

## Credits

Built with [Expo Modules API](https://docs.expo.dev/modules/overview/)
