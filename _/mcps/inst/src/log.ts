import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import { pool } from "./db.js";
import { clampLimit, debugOwnerIid, ilike, jsonContent } from "./util.js";

type LogRow = {
  id: string;
  owner_iid: string;
  kind: string;
  topic: string;
  dv: string;
  req_id: string;
  chat_id: string | null;
  text: string;
  model: string;
  tokens_in: number;
  tokens_out: number;
  duration_ms: number;
  cost_usd: string;
  meta?: Record<string, unknown>;
  created_ts: string;
};

const LOG_COLS =
  "id, owner_iid, kind, topic, dv, req_id, chat_id, text, model, tokens_in, tokens_out, duration_ms, cost_usd, created_ts";

const LOG_COLS_META = `${LOG_COLS}, meta`;

const logCompactLine = (r: LogRow) => {
  const tag = r.topic ? `${r.kind}/${r.topic}` : r.kind;
  const req = r.req_id || "-";
  const preview = r.text.replace(/\s+/g, " ").trim().slice(0, 160);
  const tok =
    r.tokens_in || r.tokens_out ? ` in=${r.tokens_in} out=${r.tokens_out}` : "";
  const dur = r.duration_ms ? ` ${r.duration_ms}ms` : "";
  return `${r.created_ts} [${tag}] req=${req}${tok}${dur} ${preview}`;
};

const logRowJson = (r: LogRow, includeMeta: boolean) => ({
  id: r.id,
  owner_iid: r.owner_iid,
  kind: r.kind,
  topic: r.topic,
  dv: r.dv,
  req_id: r.req_id,
  chat_id: r.chat_id,
  text: r.text,
  model: r.model,
  tokens_in: r.tokens_in,
  tokens_out: r.tokens_out,
  duration_ms: r.duration_ms,
  cost_usd: r.cost_usd,
  created_ts: r.created_ts,
  ...(includeMeta ? { meta: r.meta ?? {} } : {}),
});

const buildLogWhere = (
  ownerIid: number | undefined,
  filters: {
    q?: string;
    kind?: string;
    topic?: string;
    req_id?: string;
    since_minutes?: number;
  },
) => {
  const clauses = ["deleted_ts IS NULL"];
  const params: unknown[] = [];
  if (ownerIid !== undefined) {
    params.push(ownerIid);
    clauses.push(`owner_iid = $${params.length}`);
  }
  if (filters.q?.trim()) {
    params.push(ilike(filters.q));
    clauses.push(`(text ILIKE $${params.length} OR topic ILIKE $${params.length})`);
  }
  if (filters.kind?.trim()) {
    params.push(filters.kind.trim());
    clauses.push(`kind = $${params.length}`);
  }
  if (filters.topic?.trim()) {
    params.push(filters.topic.trim());
    clauses.push(`topic = $${params.length}`);
  }
  if (filters.req_id?.trim()) {
    params.push(filters.req_id.trim());
    clauses.push(`req_id = $${params.length}`);
  }
  if (filters.since_minutes !== undefined && filters.since_minutes > 0) {
    params.push(filters.since_minutes);
    clauses.push(`created_ts >= NOW() - ($${params.length}::int * INTERVAL '1 minute')`);
  }
  return { clauses, params };
};

export const registerLogTools = (server: McpServer) => {
  server.registerTool(
    "log_tail",
    {
      description:
        "Tail ai.log rows ordered by created_ts DESC. Default owner 99000; set global=true for all owners (uses idx_log_created_desc).",
      inputSchema: {
        owner_iid: z.number().optional().describe("Owner iid (default C35_DEBUG_OWNER_IID or 99000); omit with global=true"),
        global: z.boolean().optional().describe("If true, tail all owners (no owner_iid filter)"),
        q: z.string().optional().describe("ILIKE filter on text and topic"),
        kind: z.string().optional().describe("Filter by log kind"),
        topic: z.string().optional().describe("Filter by topic"),
        req_id: z.string().optional().describe("Filter by req_id"),
        since_minutes: z.number().optional().describe("Only rows newer than N minutes"),
        limit: z.number().optional().describe("Max rows (default 50, max 500)"),
        include_meta: z.boolean().optional().describe("Include raw rows with meta JSON"),
      },
    },
    async ({ owner_iid, global, q, kind, topic, req_id, since_minutes, limit, include_meta }) => {
      const ownerIid = global ? undefined : (owner_iid ?? debugOwnerIid());
      const lim = clampLimit(limit, 50, 500);
      const { clauses, params } = buildLogWhere(ownerIid, { q, kind, topic, req_id, since_minutes });
      params.push(lim);
      const cols = include_meta ? LOG_COLS_META : LOG_COLS;
      const sql = `SELECT ${cols} FROM ai.log WHERE ${clauses.join(" AND ")} ORDER BY created_ts DESC, id DESC LIMIT $${params.length}`;
      const { rows } = await pool.query<LogRow>(sql, params);
      const lines = rows.map(logCompactLine);
      return jsonContent({
        owner_iid: ownerIid ?? null,
        global: global ?? false,
        count: rows.length,
        lines,
        ...(include_meta ? { rows: rows.map((r) => logRowJson(r, true)) } : {}),
      });
    },
  );

  server.registerTool(
    "trace_get",
    {
      description: "Full turn trace from ai.log for one req_id, ordered chronologically.",
      inputSchema: {
        req_id: z.string().describe("Request id (required)"),
        owner_iid: z.number().optional().describe("Optional owner filter"),
      },
    },
    async ({ req_id, owner_iid }) => {
      const rid = req_id.trim();
      if (!rid) throw new Error("req_id required");
      const clauses = ["deleted_ts IS NULL", "req_id = $1"];
      const params: unknown[] = [rid];
      if (owner_iid !== undefined) {
        params.push(owner_iid);
        clauses.push(`owner_iid = $${params.length}`);
      }
      const sql = `SELECT ${LOG_COLS_META} FROM ai.log WHERE ${clauses.join(" AND ")} ORDER BY created_ts ASC, id ASC`;
      const { rows } = await pool.query<LogRow>(sql, params);
      return jsonContent({
        req_id: rid,
        count: rows.length,
        lines: rows.map(logCompactLine),
        trace: rows.map((r) => logRowJson(r, true)),
      });
    },
  );
};
