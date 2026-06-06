/**
 * Host-neutral formatter for the on-screen build stamp (issue #43). The iFile pane renders a small,
 * unobtrusive build identifier on every load so the developer can confirm on the device which build
 * is loaded — the iOS Outlook web-view can serve a cached bundle, and a physical device has no
 * attachable console to read the build id from.
 *
 * Pure: no Office.js, no DOM, no I/O. Satisfies the `ifile-pure-modules-no-host-deps` architecture
 * rule and is unit-testable without the Outlook host.
 */

/** Prefix placed before the build id in the visible stamp label. */
const BUILD_STAMP_PREFIX = "build ";

/**
 * Formats a build id into the visible stamp label, for example `build 2026-06-05T12:00:00.000Z`.
 * The id is injected at build time via the webpack `__BUILD_ID__` define (an ISO timestamp by
 * default, or the reproducible `BUILD_ID` override when set). An empty id yields the bare prefix
 * `build ` rather than throwing, so the stamp element is always populated.
 */
export function formatBuildStamp(buildId: string): string {
    return `${BUILD_STAMP_PREFIX}${buildId}`;
}
