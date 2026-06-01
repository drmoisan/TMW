# Phase 6 QA — TypeScript Contract Tests (Issue #43)

Timestamp: 2026-06-01T00-00
Command: npx vitest run src/taskpane/ifile/ifile-api-client.contract.test.ts src/taskpane/ifile/result-list-composer.contract.test.ts src/taskpane/ifile/dialog-host.contract.test.ts
EXIT_CODE: 0
Output Summary: 3 contract test files, 9 tests passed.
- dialog-host.contract.test.ts (P6-T1, AC-2): displayDialogAsync options shape (same-origin URL, percentage sizing, displayInIframe) and the messageParent/DialogMessageReceived JSON message contract against a faked Office.context.ui.
- ifile-api-client.contract.test.ts (P6-T2, AC-10/AC-12): the filing request body { messageRestId, destinationFolderId, archiveRootDriveItemId? } is type-equal to the generated operations["IFileFile"] request type in src/api-client/v1.ts (a drift fails compilation).
- result-list-composer.contract.test.ts (P6-T3, AC-9): the compose signature accepts three FolderResult[] sources in the documented classifier→recent→search order; a live source is added by a non-empty array with no signature change.
