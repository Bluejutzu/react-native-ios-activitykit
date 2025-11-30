import { requireNativeModule } from 'expo-modules-core';
import { Platform } from 'react-native';
import { ActivityInfo } from './types';

// Export types
export * from './types';
export type {
    ActivityAttributes,
    ActivityInfo,
    CounterActivityAttributes,
    CounterActivityContent,
    StatusActivityAttributes,
    StatusActivityContent,
    ProgressActivityAttributes,
    ProgressActivityContent,
    CustomActivityType
} from './types';
export { DismissalPolicy } from './types';

// Get native module (only available on iOS)
const ExpoLiveActivitiesModule = Platform.OS === 'ios'
    ? requireNativeModule('ExpoLiveActivities')
    : null;

/**
 * Check if Live Activities are supported on this device
 * @returns true if Live Activities are available (iOS 16.1+)
 */
export function isSupported(): boolean {
    if (Platform.OS !== 'ios') {
        return false;
    }

    if (!ExpoLiveActivitiesModule) {
        return false;
    }

    try {
        return ExpoLiveActivitiesModule.isSupported();
    } catch (error) {
        console.warn('Failed to check Live Activities support:', error);
        return false;
    }
}

/**
 * Start a new Live Activity
 * 
 * @param activityType - Name of your custom activity type (must match Swift ActivityAttributes struct name)
 * @param attributes - Static attributes for the activity
 * @param contentState - Initial dynamic content state
 * @returns Promise with activity information including activityId
 * 
 * @example
 * ```ts
 * const activity = await startActivity(
 *   'CounterActivity',
 *   { title: 'My Timer', color: '#007AFF' },
 *   { value: 60, status: 'Running' }
 * );
 * console.log('Started activity:', activity.activityId);
 * ```
 */
export async function startActivity<TAttributes = any, TContent = any>(
    activityType: string,
    attributes: TAttributes,
    contentState: TContent
): Promise<ActivityInfo> {
    if (!isSupported()) {
        throw new Error('Live Activities are not supported on this device (requires iOS 16.1+)');
    }

    if (!activityType || typeof activityType !== 'string') {
        throw new Error('activityType must be a non-empty string');
    }

    try {
        const result = await ExpoLiveActivitiesModule.startActivity(
            activityType,
            attributes || {},
            contentState || {}
        );
        return result;
    } catch (error) {
        throw new Error(`Failed to start activity: ${error}`);
    }
}

/**
 * Update an existing Live Activity's content state
 * 
 * @param activityId - ID returned from startActivity
 * @param contentState - New content state to display
 * 
 * @example
 * ```ts
 * await updateActivity(activityId, {
 *   value: 45,
 *   status: 'Almost done'
 * });
 * ```
 */
export async function updateActivity<TContent = any>(
    activityId: string,
    contentState: TContent
): Promise<void> {
    if (!isSupported()) {
        throw new Error('Live Activities are not supported on this device (requires iOS 16.1+)');
    }

    if (!activityId || typeof activityId !== 'string') {
        throw new Error('activityId must be a non-empty string');
    }

    try {
        await ExpoLiveActivitiesModule.updateActivity(activityId, contentState || {});
    } catch (error) {
        throw new Error(`Failed to update activity: ${error}`);
    }
}

/**
 * End a Live Activity
 * 
 * @param activityId - ID returned from startActivity
 * @param dismissalPolicy - How to dismiss the activity (optional, defaults to 'default')
 * 
 * @example
 * ```ts
 * import { DismissalPolicy } from 'react-native-ios-activitykit';
 * 
 * await endActivity(activityId, DismissalPolicy.IMMEDIATE);
 * ```
 */
export async function endActivity(
    activityId: string,
    dismissalPolicy: 'immediate' | 'after' | 'default' = 'default'
): Promise<void> {
    if (!isSupported()) {
        throw new Error('Live Activities are not supported on this device (requires iOS 16.1+)');
    }

    if (!activityId || typeof activityId !== 'string') {
        throw new Error('activityId must be a non-empty string');
    }

    try {
        await ExpoLiveActivitiesModule.endActivity(activityId, dismissalPolicy);
    } catch (error) {
        throw new Error(`Failed to end activity: ${error}`);
    }
}

/**
 * Get all active Live Activity IDs
 * 
 * @returns Promise with array of active activity IDs
 * 
 * @example
 * ```ts
 * const activeIds = await getAllActivities();
 * console.log('Active activities:', activeIds);
 * ```
 */
export async function getAllActivities(): Promise<string[]> {
    if (!isSupported()) {
        return [];
    }

    try {
        return await ExpoLiveActivitiesModule.getAllActivities();
    } catch (error) {
        console.warn('Failed to get all activities:', error);
        return [];
    }
}

/**
 * End all active Live Activities
 * 
 * @param dismissalPolicy - How to dismiss the activities (optional, defaults to 'default')
 * 
 * @example
 * ```ts
 * await endAllActivities('immediate');
 * ```
 */
export async function endAllActivities(
    dismissalPolicy: 'immediate' | 'after' | 'default' = 'default'
): Promise<void> {
    if (!isSupported()) {
        return;
    }

    try {
        const activityIds = await getAllActivities();
        await Promise.all(
            activityIds.map(id => endActivity(id, dismissalPolicy))
        );
    } catch (error) {
        throw new Error(`Failed to end all activities: ${error}`);
    }
}
