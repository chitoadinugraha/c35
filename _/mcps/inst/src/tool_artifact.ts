import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { mkdir, writeFile } from "node:fs/promises";
import path from "node:path";
import { z } from "zod";
import { agentPost, ownerSchema } from "./agent_http_shared.js";
import { debugOwnerIid, jsonContent } from "./util.js";

const owner = (owner_iid?: number, uid?: number) => owner_iid ?? uid ?? debugOwnerIid();

export const registerToolArtifactTools = (server: McpServer) => {
  server.registerTool(
    "tool_artifact_list",
    {
      description:
        "List persisted device screenshot artifacts (CAS, 14d TTL) for a prompt req_id.",
      inputSchema: {
        req_id: z.string().describe("Prompt turn req_id from trace or chat_msg"),
        tool_id: z.string().optional().describe("Filter e.g. device.screenshot"),
        ...ownerSchema,
      },
    },
    async ({ req_id, tool_id, owner_iid, uid }) => {
      const result = await agentPost(
        "tool_artifact_list",
        { args_json: { req_id, tool_id } },
        owner(owner_iid, uid),
      );
      return jsonContent(result);
    },
  );

  server.registerTool(
    "tool_artifact_fetch",
    {
      description: "Fetch one tool artifact JPEG by artifact_id.",
      inputSchema: {
        artifact_id: z.string().describe("ai.tool_artifact.id"),
        include_base64: z.boolean().optional(),
        save_path: z.string().optional().describe("Write JPEG to this path"),
        ...ownerSchema,
      },
    },
    async ({ artifact_id, include_base64, save_path, owner_iid, uid }) => {
      const result = await agentPost(
        "tool_artifact_fetch",
        {
          args_json: {
            artifact_id,
            include_base64: include_base64 ?? Boolean(save_path),
          },
        },
        owner(owner_iid, uid),
      );
      const b64 = (result as { image_base64?: string }).image_base64;
      if (save_path && b64) {
        await mkdir(path.dirname(save_path), { recursive: true });
        await writeFile(save_path, Buffer.from(b64, "base64"));
        (result as Record<string, unknown>).saved_path = save_path;
      }
      return jsonContent(result);
    },
  );

  server.registerTool(
    "trace_screenshot",
    {
      description: "Latest device.screenshot/device.input artifact for req_id.",
      inputSchema: {
        req_id: z.string(),
        include_base64: z.boolean().optional(),
        save_path: z.string().optional(),
        ...ownerSchema,
      },
    },
    async ({ req_id, include_base64, save_path, owner_iid, uid }) => {
      const result = await agentPost(
        "trace_screenshot",
        {
          args_json: {
            req_id,
            include_base64: include_base64 ?? !save_path,
          },
        },
        owner(owner_iid, uid),
      );
      const b64 = (result as { image_base64?: string }).image_base64;
      if (save_path && b64) {
        await mkdir(path.dirname(save_path), { recursive: true });
        await writeFile(save_path, Buffer.from(b64, "base64"));
        (result as Record<string, unknown>).saved_path = save_path;
      }
      return jsonContent(result);
    },
  );
};