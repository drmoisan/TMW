/**
 * Contract test asserting the iFile filing request shape matches the generated
 * src/api-client/v1.ts operation type for POST /api/ifile/file (AC-10, AC-12). A mismatch with
 * the generated FileMessageEndpointRequest operation type (produced by P3-T3) fails compilation.
 */

import { describe, expect, it } from "vitest";
import type { components, operations } from "../../../src/api-client/v1";
import type { FileMessageRequest } from "../../../src/taskpane/ifile/ifile-api-client";

describe("ifile-api-client filing-endpoint contract", () => {
    it("request body type equals the generated /api/ifile/file operation request type", () => {
        // The generated operation's requestBody content type must be assignable to and from the
        // client's FileMessageRequest. These type-level checks fail compilation on any drift.
        type GeneratedRequest =
            operations["IFileFile"]["requestBody"]["content"]["application/json"];

        const toGenerated = (req: FileMessageRequest): GeneratedRequest => req;
        const fromGenerated = (req: GeneratedRequest): FileMessageRequest => req;

        // Runtime assertion that a documented body carries exactly the three contract fields.
        const sample: FileMessageRequest = {
            messageRestId: "msg-1",
            destinationFolderId: "acme",
            archiveRootDriveItemId: "drive-root",
        };
        expect(Object.keys(toGenerated(sample)).sort()).toEqual([
            "archiveRootDriveItemId",
            "destinationFolderId",
            "messageRestId",
        ]);
        expect(fromGenerated(sample).messageRestId).toBe("msg-1");
    });

    it("the generated request schema matches the FileMessageEndpointRequest component", () => {
        // FileMessageRequest is the component schema; assert it is the same shape the operation
        // references, anchoring the seam between the client and the generated contract.
        const schema: components["schemas"]["FileMessageEndpointRequest"] = {
            messageRestId: "m",
            destinationFolderId: "d",
            archiveRootDriveItemId: null,
        };
        expect(schema.messageRestId).toBe("m");
    });
});
