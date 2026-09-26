import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import { pool } from "./db.js";
import { clampLimit, debugOwnerIid, ilike, jsonContent } from "./util.js";

type DeviceRow = {
  id: string;
  name: string;
  type: string;
  meta: Record<string, unknown>;
};

const cloudOnlineFromMeta = (meta: Record<string, unknown>) => {
  if (meta.online === false) return false;
  const last = meta.last_seen_ts_ms ?? meta.last_seen_ms ?? meta.last_seen;
  const ms = typeof last === "number" ? last : Number(last ?? 0);
  if (!ms) return meta.online === true;
  return Date.now() - ms < 120_000;
};

const deviceJson = (row: DeviceRow) => ({
  device_iid: row.id,
  name: row.name,
  type: row.type,
  cloud_online: cloudOnlineFromMeta(row.meta),
  online: metaField(row.meta, "online"),
  last_seen_ts_ms: metaField(row.meta, "last_seen_ts_ms"),
  agent_version: metaField(row.meta, "agent_version"),
});

const metaField = (meta: Record<string, unknown>, key: string) => meta[key] ?? null;

export const registerDeviceTools = (server: McpServer) => {
  server.registerTool(
    "device_list",
    {
      description:
        "List paired remote devices for an owner (default C35_DEBUG_OWNER_IID or 99000). Uses ai.identity kind=remote.",
      inputSchema: {
        owner_iid: z.number().optional().describe("Owner iid (default debug owner 99000)"),
        uid: z.number().optional().describe("Alias for owner_iid"),
      },
    },
    async ({ owner_iid, uid }) => {
      const owner = owner_iid ?? uid ?? debugOwnerIid();
      const res = await pool.query<DeviceRow>(
        `SELECT id::text, name, type, COALESCE(meta, '{}'::jsonb) AS meta
         FROM ai.identity
         WHERE owner_iid = $1 AND kind = 'remote' AND deleted_ts IS NULL
         ORDER BY id DESC`,
        [owner],
      );
      const devices = res.rows.map(deviceJson);
      return jsonContent({ ok: true, owner_iid: owner, count: devices.length, devices });
    },
  );

  server.registerTool(
    "device_get",
    {
      description: "Get one remote device row + cloud_online for owner (default 99000).",
      inputSchema: {
        device_iid: z.number().describe("Remote device identity id"),
        owner_iid: z.number().optional(),
        uid: z.number().optional(),
      },
    },
    async ({ device_iid, owner_iid, uid }) => {
      const owner = owner_iid ?? uid ?? debugOwnerIid();
      const res = await pool.query<{ id: string; owner_iid: string; name: string; type: string; meta: Record<string, unknown> }>(
        `SELECT id::text, owner_iid::text, name, type, COALESCE(meta, '{}'::jsonb) AS meta
         FROM ai.identity
         WHERE id = $1 AND kind = 'remote' AND deleted_ts IS NULL`,
        [device_iid],
      );
      const row = res.rows[0];
      if (!row) return jsonContent({ ok: false, error: "device not found" });
      if (row.owner_iid !== String(owner)) {
        return jsonContent({ ok: false, error: "device not owned by this owner_iid" });
      }
      return jsonContent({
        ok: true,
        device_iid: row.id,
        owner_iid: owner,
        name: row.name,
        type: row.type,
        cloud_online: cloudOnlineFromMeta(row.meta),
        meta: row.meta,
      });
    },
  );

  server.registerTool(
    "device_log_tail",
    {
      description:
        "Tail agent connection logs (kind conn, topic agent.*) for an owner. Optional ILIKE q (e.g. webrtc).",
      inputSchema: {
        owner_iid: z.number().optional(),
        uid: z.number().optional(),
        q: z.string().optional(),
        limit: z.number().optional(),
        since_minutes: z.number().optional(),
      },
    },
    async ({ owner_iid, uid, q, limit, since_minutes }) => {
      const owner = owner_iid ?? uid ?? debugOwnerIid();
      const lim = clampLimit(limit, 30, 200);
      const clauses = ["deleted_ts IS NULL", "owner_iid = $1", "kind = 'conn'", "topic LIKE 'agent.%'"];
      const params: unknown[] = [owner];
      if (q?.trim()) {
        params.push(ilike(q));
        clauses.push(`text ILIKE $${params.length}`);
      }
      if (since_minutes && since_minutes > 0) {
        params.push(since_minutes);
        clauses.push(`created_ts >= NOW() - ($${params.length}::int * INTERVAL '1 minute')`);
      }
      params.push(lim);
      const sql = `SELECT created_ts, topic, text FROM ai.log
        WHERE ${clauses.join(" AND ")}
        ORDER BY created_ts DESC
        LIMIT $${params.length}`;
      const res = await pool.query<{ created_ts: string; topic: string; text: string }>(sql, params);
      const lines = res.rows.map((r) => `${r.created_ts} [${r.topic}] ${r.text}`);
      return jsonContent({ ok: true, owner_iid: owner, count: lines.length, lines });
    },
  );
};
