import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import { pool } from "./db.js";
import { debugOwnerIid, jsonContent } from "./util.js";
import { agentPost, ownerSchema } from "./agent_http_shared.js";

type ClientRow = {
  dv: string;
  client_id: string;
  platform: number;
  app_build: string;
  app_version_name: string;
  last_ws_ts_ms: string;
};

const clientJson = (row: ClientRow) => ({
  dv: row.dv,
  client_id: row.client_id,
  platform: Number(row.platform),
  app_build: Number(row.app_build),
  app_version_name: row.app_version_name,
  last_ws_ts_ms: Number(row.last_ws_ts_ms),
});

export const registerClientTools = (server: McpServer) => {
  server.registerTool(
    "client_list",
    {
      description:
        "List app installs (ai.identity_client) for an owner with last reported build. Default owner 99000.",
      inputSchema: {
        ...ownerSchema,
        uid: z.number().optional().describe("Alias for owner_iid"),
      },
    },
    async ({ owner_iid, uid }) => {
      const owner = owner_iid ?? uid ?? debugOwnerIid();
      const res = await pool.query<ClientRow>(
        `SELECT dv, client_id, platform, app_build::text, app_version_name, last_ws_ts_ms::text
         FROM ai.identity_client
         WHERE identity_iid = $1 AND deleted_ts IS NULL
         ORDER BY last_ws_ts_ms DESC`,
        [owner],
      );
      const clients = res.rows.map(clientJson);
      return jsonContent({ ok: true, owner_iid: owner, count: clients.length, clients });
    },
  );

  server.registerTool(
    "client_list_http",
    {
      description: "Same as client_list via server_ai /v1/mcp/agent (includes release compare).",
      inputSchema: ownerSchema,
    },
    async ({ owner_iid, uid }) => {
      const owner = owner_iid ?? uid ?? debugOwnerIid();
      const result = await agentPost("client_list", {}, owner);
      return jsonContent(result);
    },
  );
};