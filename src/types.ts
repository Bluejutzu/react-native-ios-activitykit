/**
 * Generic activity attributes interface
 */
export interface ActivityAttributes<T = any> {
  /** Static attributes that don't change during the activity's lifetime */
  attributes: T;
  /** Dynamic content state that can be updated */
  contentState: any;
}

/**
 * Dismissal policy for ending a Live Activity
 */
export enum DismissalPolicy {
  /** Remove immediately */
  IMMEDIATE = 'immediate',
  /** Keep in history after ending */
  AFTER = 'after',
  /** Let system decide */
  DEFAULT = 'default'
}

/**
 * Activity information returned when starting an activity
 */
export interface ActivityInfo {
  /** Unique identifier for this activity */
  activityId: string;
  /** The activity type name */
  activityType: string;
  /** Timestamp when activity was started */
  startTime: number;
}

/**
 * Example: Counter/Timer Activity
 * Can be used for countdowns, timers, or simple counters
 */
export interface CounterActivityAttributes {
  /** Title of the timer/counter */
  title: string;
  /** Optional color for theming */
  color?: string;
}

export interface CounterActivityContent {
  /** Current value */
  value: number;
  /** Optional status text */
  status?: string;
}

/**
 * Example: Status Tracking Activity
 * Can be used for delivery, order status, etc.
 */
export interface StatusActivityAttributes {
  /** Identifier (e.g., order number, tracking ID) */
  identifier: string;
  /** Title of what's being tracked */
  title: string;
}

export interface StatusActivityContent {
  /** Current status */
  status: string;
  /** Optional progress percentage (0-100) */
  progress?: number;
  /** Optional additional details */
  details?: string;
  /** Optional timestamp */
  timestamp?: number;
}

/**
 * Example: Progress Activity
 * Can be used for file uploads, downloads, processing, etc.
 */
export interface ProgressActivityAttributes {
  /** Task title */
  title: string;
  /** Total units (e.g., bytes, items, steps) */
  total: number;
  /** Optional unit label */
  unit?: string;
}

export interface ProgressActivityContent {
  /** Current progress value */
  current: number;
  /** Current step description */
  description?: string;
  /** Optional percentage (calculated if not provided) */
  percentage?: number;
}

/**
 * Type for custom activity types
 * Developers can extend this to create their own activity types
 */
export type CustomActivityType = string;
