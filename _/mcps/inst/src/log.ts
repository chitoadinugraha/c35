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
  event_kind?: string;
  class?: string;
  subject?: string;
  meta?: Record<string, unknown>;
  created_ts: string;
};

const LOG_COLS =
  "id, owner_iid, kind, topic, dv, req_id, chat_id, text, model, tokens_in, tokens_out, duration_ms, cost_usd, event_kind, class, subject, created_ts";

const LOG_COLS_META = `${LOG_COLS}, meta`;

const logCompactLine = (r: LogRow) => {
  const tag = r.event_kind
    ? `${r.class ?? "event"}/${r.event_kind}`
    : r.topic
      ? `${r.kind}/${r.topic}`
      : r.kind;
  const req = r.req_id || "-";
  const preview = r.text.replace(/\s+/g, " ").trim().slice(0, 160);
  const tok =
    r.tokens_in || r.tokens_out ? ` in=${r.tokens_in} out=${r.tokens_out}` : "";
  const dur = r.duration_ms ? ` ${r.duration_ms}ms` : "";
  return `${r.created_ts} [${tag}] owner=${r.owner_iid} req=${req}${tok}${dur} ${preview}`;
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
  event_kind: r.event_kind ?? "",
  class: r.class ?? "",
  subject: r.subject ?? "",
  created_ts: r.created_ts,
  ...(includeMeta ? { meta: r.meta ?? {} } : {}),
});

const resolveOwner = (owner_iid?: number, uid?: number, global?: boolean) => {
  if (global) return undefined;
  if (uid !== undefined) return uid;
  if (owner_iid !== undefined) return owner_iid;
  return debugOwnerIid();
};

const buildLogWhere = (
  ownerIid: number | undefined,
  filters: {
    q?: string;
    kind?: string;
    topic?: string;
    req_id?: string;
    event_kind?: string;
    class?: string;
    subject_prefix?: string;
    since_minutes?: number;
    since_ms?: number;
    until_ms?: number;
    exclude_trace?: boolean;
  },
) => {
  const clauses = ["deleted_ts IS NULL"];
  const params: unknown[] = [];
  if (ownerIid !== undefined) {
    params.push(ownerIid);
    clauses.push(`owner_iid = $${params.length}`);
  }
  if (filters.exclude_trace) {
    clauses.push("class IN ('event', 'error')");
  }
  if (filters.q?.trim()) {
    params.push(ilike(filters.q));
    const n = params.length;
    clauses.push(
      `(text ILIKE $${n} OR topic ILIKE $${n} OR event_kind ILIKE $${n} OR subject ILIKE $${n} OR req_id ILIKE $${n} OR meta::text ILIKE $${n})`,
    );
  }
  if (filters.kind?.trim()) {
    params.push(filters.kind.trim());
    clauses.push(`kind = $${params.length}`);
  }
  if (filters.topic?.trim()) {
    params.push(filters.topic.trim());
    clauses.push(`topic = $${params.length}`);
  }
  if (filters.event_kind?.trim()) {
    params.push(filters.event_kind.trim());
    clauses.push(`event_kind = $${params.length}`);
  }
  if (filters.class?.trim()) {
    params.push(filters.class.trim());
    clauses.push(`class = $${params.length}`);
  }
  if (filters.subject_prefix?.trim()) {
    params.push(`${filters.subject_prefix.trim()}%`);
    clauses.push(`subject LIKE $${params.length}`);
  }
  if (filters.req_id?.trim()) {
    params.push(filters.req_id.trim());
    clauses.push(`req_id = $${params.length}`);
  }
  if (filters.since_ms !== undefined && filters.since_ms > 0) {
    params.push(filters.since_ms);
    clauses.push(`created_ts >= to_timestamp($${params.length}::double precision / 1000.0)`);
  } else if (filters.since_minutes !== undefined && filters.since_minutes > 0) {
    params.push(filters.since_minutes);
    clauses.push(`created_ts >= NOW() - ($${params.length}::int * INTERVAL '1 minute')`);
  }
  if (filters.until_ms !== undefined && filters.until_ms > 0) {
    params.push(filters.until_ms);
    clauses.push(`created_ts <= to_timestamp($${params.length}::double precision / 1000.0)`);
  }
  return { clauses, params };
};

const runLogQuery = async (
  ownerIid: number | undefined,
  filters: ReturnType<typeof buildLogWhere> extends infer _ ? Parameters<typeof buildLogWhere>[1] : never,
  lim: number,
  include_meta: boolean,
) => {
  const { clauses, params } = buildLogWhere(ownerIid, filters);
  params.push(lim);
  const cols = include_meta ? LOG_COLS_META : LOG_COLS;
  const sql = `SELECT ${cols} FROM ai.log WHERE ${clauses.join(" AND ")} ORDER BY created_ts DESC, id DESC LIMIT $${params.length}`;
  const { rows } = await pool.query<LogRow>(sql, params);
  return rows;
};

export const registerLogTools = (server: McpServer) => {
  server.registerTool(
    "log_tail",
    {
      description:
        "Tail ai.log ordered by created_ts DESC. Filter by owner (owner_iid or uid alias). Domain events: event_kind, class, exclude_trace. English text on event rows.",
      inputSchema: {
        owner_iid: z.number().optional().describe("Owner iid (default C35_DEBUG_OWNER_IID or 99000)"),
        uid: z.number().optional().describe("Alias for owner_iid"),
        global: z.boolean().optional().describe("If true, all owners (no owner filter)"),
        q: z.string().optional().describe("ILIKE grep: text, topic, event_kind, subject, req_id, meta"),
        kind: z.string().optional().describe("Legacy log kind (llm, conn, …)"),
        topic: z.string().optional().describe("Topic / slug"),
        event_kind: z.string().optional().describe("Catalog kind e.g. user.sign_in"),
        class: z.string().optional().describe("event | error | trace"),
        subject_prefix: z.string().optional().describe("NATS subject prefix"),
        req_id: z.string().optional().describe("Prompt turn req_id"),
        since_minutes: z.number().optional().describe("Rows newer than N minutes"),
        since_ms: z.number().optional().describe("created_ts >= since_ms (epoch ms)"),
        until_ms: z.number().optional().describe("created_ts <= until_ms (epoch ms)"),
        exclude_trace: z.boolean().optional().describe("Only class event|error (domain timeline)"),
        limit: z.number().optional().describe("Max rows (default 50, max 500)"),
        include_meta: z.boolean().optional().describe("Include raw rows with meta JSON"),
      },
    },
    async (args) => {
      const ownerIid = resolveOwner(args.owner_iid, args.uid, args.global);
      const lim = clampLimit(args.limit, 50, 500);
      const rows = await runLogQuery(
        ownerIid,
        {
          q: args.q,
          kind: args.kind,
          topic: args.topic,
          req_id: args.req_id,
          event_kind: args.event_kind,
          class: args.class,
          subject_prefix: args.subject_prefix,
          since_minutes: args.since_minutes,
          since_ms: args.since_ms,
          until_ms: args.until_ms,
          exclude_trace: args.exclude_trace,
        },
        lim,
        args.include_meta ?? false,
      );
      return jsonContent({
        owner_iid: ownerIid ?? null,
        global: args.global ?? false,
        count: rows.length,
        lines: rows.map(logCompactLine),
        ...(args.include_meta ? { rows: rows.map((r) => logRowJson(r, true)) } : {}),
      });
    },
  );

  server.registerTool(
    "log_find",
    {
      description:
        "Grep domain events (exclude_trace default true) for one owner. Same filters as log_tail; default limit 100.",
      inputSchema: {
        uid: z.number().optional(),
        owner_iid: z.number().optional(),
        q: z.string().optional(),
        event_kind: z.string().optional(),
        since_minutes: z.number().optional(),
        since_ms: z.number().optional(),
        until_ms: z.number().optional(),
        limit: z.number().optional(),
        include_meta: z.boolean().optional(),
      },
    },
    async (args) => {
      const ownerIid = resolveOwner(args.owner_iid, args.uid, false);
      const lim = clampLimit(args.limit, 100, 500);
      const rows = await runLogQuery(
        ownerIid,
        {
          q: args.q,
          event_kind: args.event_kind,
          since_minutes: args.since_minutes,
          since_ms: args.since_ms,
          until_ms: args.until_ms,
          exclude_trace: true,
        },
        lim,
        args.include_meta ?? false,
      );
      return jsonContent({
        owner_iid: ownerIid,
        count: rows.length,
        lines: rows.map(logCompactLine),
        ...(args.include_meta ? { rows: rows.map((r) => logRowJson(r, true)) } : {}),
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
        uid: z.number().optional().describe("Alias for owner_iid"),
      },
    },
    async ({ req_id, owner_iid, uid }) => {
      const rid = req_id.trim();
      if (!rid) throw new Error("req_id required");
      const clauses = ["deleted_ts IS NULL", "req_id = $1"];
      const params: unknown[] = [rid];
      const owner = uid ?? owner_iid;
      if (owner !== undefined) {
        params.push(owner);
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
