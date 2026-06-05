/**
 * Host-neutral backend-URL reachability guard (issue #43, root cause 1).
 *
 * A mobile build must inject a reachable Dev-Tunnel / deployed host as the API base URL. A
 * localhost URL resolves to the device itself on a physical phone, so `GET /api/ifile/folders`
 * can never reach the backend. This guard fails fast and visibly when a mobile build is pointed
 * at a loopback host, and otherwise returns the URL unchanged.
 *
 * Pure: no Office.js, no fetch, no I/O. Satisfies the `ifile-pure-modules-no-host-deps`
 * architecture rule.
 */

/** Options controlling the reachability check. */
export interface ApiBaseUrlGuardOptions {
    /** True when the bundle is built for a mobile (on-device) host. */
    readonly isMobileBuild: boolean;
}

/** Loopback hosts that are unreachable from a physical mobile device. */
const LOOPBACK_HOSTS: ReadonlySet<string> = new Set(["localhost", "127.0.0.1", "[::1]", "::1"]);

/**
 * Returns the loopback host token from a URL, or null when the URL is not a loopback host.
 *
 * Parses with the URL constructor when possible; falls back to a host-token extraction for
 * inputs the URL constructor rejects so a malformed mobile URL still fails closed.
 */
function loopbackHostOf(url: string): string | null {
    let hostname: string;
    try {
        hostname = new URL(url).hostname;
    } catch {
        // Fall back to a coarse host-token extraction (strip scheme, path, and port).
        const withoutScheme = url.replace(/^[a-zA-Z][a-zA-Z0-9+.-]*:\/\//, "");
        hostname = withoutScheme.split("/")[0]?.split(":")[0] ?? withoutScheme;
    }
    const normalized = hostname.toLowerCase();
    return LOOPBACK_HOSTS.has(normalized) ? normalized : null;
}

/**
 * Asserts that `url` is reachable from the target host class and returns it unchanged.
 *
 * Throws a clear Error when `isMobileBuild` is true and the URL host is a loopback address
 * (`localhost`, `127.0.0.1`, `[::1]`). Desktop (non-mobile) builds are allowed to use loopback
 * hosts for the local dev server.
 */
export function assertReachableApiBaseUrl(url: string, options: ApiBaseUrlGuardOptions): string {
    if (!options.isMobileBuild) {
        return url;
    }
    const loopback = loopbackHostOf(url);
    if (loopback !== null) {
        throw new Error(
            `iFile mobile build is configured with an unreachable API base URL "${url}" ` +
                `(loopback host "${loopback}"). A mobile build must set API_BASE_URL to a ` +
                `reachable Dev-Tunnel or deployed host before 'npm run build'.`
        );
    }
    return url;
}
