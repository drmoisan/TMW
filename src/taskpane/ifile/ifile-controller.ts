/**
 * Presentation-agnostic iFile search-container controller (host-neutral, no direct Office.js
 * dialog calls). Satisfies AC-4, AC-5, AC-8, AC-9.
 *
 * The controller loads the mailbox leaf-folder list once (via an injected loader) when the
 * container opens, then filters it in-memory per keystroke through folder-search and composes
 * the results list through result-list-composer. It exposes a selection callback. The folder
 * list is never re-fetched per keystroke (AC-8).
 */

import type { FolderResult } from "./folder-result";
import { searchLeafFolders } from "./folder-search";
import { compose } from "./result-list-composer";

/** Loads the once-per-open leaf-folder list (typically the backend folder-list query). */
export type LeafFolderLoader = () => Promise<FolderResult[]>;

/** Invoked when the user selects a destination folder. */
export type SelectionHandler = (selected: FolderResult) => void;

/**
 * Controller dependencies. `loadLeaves` is invoked once by {@link IFileController.open}; the
 * cached result is reused for every subsequent {@link IFileController.search} call.
 */
export interface IFileControllerOptions {
    readonly loadLeaves: LeafFolderLoader;
    readonly onSelect: SelectionHandler;
}

/**
 * Stateful but host-neutral controller. Holds the once-loaded leaf list and derives the
 * results list per keystroke without re-fetching.
 */
export class IFileController {
    private readonly loadLeaves: LeafFolderLoader;
    private readonly onSelect: SelectionHandler;
    private leaves: FolderResult[] | null = null;

    constructor(options: IFileControllerOptions) {
        this.loadLeaves = options.loadLeaves;
        this.onSelect = options.onSelect;
    }

    /**
     * Loads the leaf-folder list once. Subsequent calls reuse the cached list and do not
     * re-invoke the loader.
     */
    async open(): Promise<void> {
        this.leaves ??= await this.loadLeaves();
    }

    /**
     * Computes the composed results list for the current search text. An empty textbox yields
     * an empty list (classifier and recent sources are empty this iteration). Never re-fetches
     * the folder list.
     */
    search(pattern: string): FolderResult[] {
        const leaves = this.leaves ?? [];
        const searchResults = searchLeafFolders(leaves, pattern);
        return compose([], [], searchResults);
    }

    /** Invokes the selection callback for the chosen destination folder. */
    select(folder: FolderResult): void {
        this.onSelect(folder);
    }
}
