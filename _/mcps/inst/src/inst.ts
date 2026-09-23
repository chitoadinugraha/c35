import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { connect as natsConnect } from "nats";
import { z } from "zod";
import { pool } from "./db.js";
import { jsonContent } from "./util.js";

type InstRow = {
  id: string;
  scope: string;
  kind: string;
  topic_id: string;
  topics: string[];
  inst: string;
  phrases: string[];
  triggers: string[];
  priority: number;
  enabled: boolean;
  def_hash: string;
  created_ts: string;
  updated_ts: string;
  deleted_ts: string | null;
};

let nats: Awaited<ReturnType<typeof natsConnect>> | null = null;

const natsConnectLazy = async () => {
  if (nats) return nats;
  const url = process.env.NATS_URL?.trim();
  if (!url) return null;
  nats = await natsConnect({
    servers: url,
    user: process.env.NATS_USER,
    pass: process.env.NATS_PASS,
  });
  return nats;
};

const instPublish = async (instId: string) => {
  const client = await natsConnectLazy();
  if (!client || !instId.trim()) return;
  client.publish(`c35.inst.${instId}`, instId);
};

const rowToJson = (r: InstRow) => ({
  id: r.id,
  scope: r.scope,
  kind: r.kind,
  topic_id: r.topic_id,
  topics: r.topics,
  inst: r.inst,
  phrases: r.phrases,
  triggers: r.triggers,
  priority: r.priority,
  enabled: r.enabled,
  def_hash: r.def_hash,
  created_ts: r.created_ts,
  updated_ts: r.updated_ts,
  deleted_ts: r.deleted_ts,
});

const SELECT_COLS =
  "id, scope, kind, topic_id, topics, inst, phrases, triggers, priority, enabled, def_hash, created_ts, updated_ts, deleted_ts";

export const registerInstTools = (server: McpServer) => {
  server.registerTool(
    "inst_list",
    {
      description:
        "List ai.inst rows with optional filters (scope, kind, enabled). Excludes soft-deleted unless include_deleted=true.",
      inputSchema: {
        scope: z.string().optional().describe("Filter by scope (e.g. global, role:personal_assistant)"),
        kind: z.string().optional().describe("Filter by kind (task, mention, topic, trigger)"),
        enabled: z.boolean().optional().describe("Filter by enabled flag"),
        include_deleted: z.boolean().optional().describe("Include soft-deleted rows"),
      },
    },
    async ({ scope, kind, enabled, include_deleted }) => {
      const clauses: string[] = ["1=1"];
      const params: unknown[] = [];
      if (!include_deleted) clauses.push("deleted_ts IS NULL");
      if (scope) {
        params.push(scope);
        clauses.push(`scope = $${params.length}`);
      }
      if (kind) {
        params.push(kind);
        clauses.push(`kind = $${params.length}`);
      }
      if (enabled !== undefined) {
        params.push(enabled);
        clauses.push(`enabled = $${params.length}`);
      }
      const sql = `SELECT ${SELECT_COLS} FROM ai.inst WHERE ${clauses.join(" AND ")} ORDER BY priority DESC, id ASC`;
      const { rows } = await pool.query<InstRow>(sql, params);
      return jsonContent(rows.map(rowToJson));
    },
  );

  server.registerTool(
    "inst_get",
    {
      description: "Get one ai.inst row by id.",
      inputSchema: {
        id: z.string().describe("Inst id (e.g. inst.consumption_coach)"),
      },
    },
    async ({ id }) => {
      const instId = id.trim();
      if (!instId) throw new Error("id required");
      const { rows } = await pool.query<InstRow>(`SELECT ${SELECT_COLS} FROM ai.inst WHERE id = $1`, [instId]);
      if (!rows[0]) throw new Error("inst not found");
      return jsonContent(rowToJson(rows[0]));
    },
  );

  server.registerTool(
    "inst_put",
    {
      description:
        "Upsert ai.inst row. Sets updated_ts=NOW(), enabled defaults true. Publishes NATS c35.inst.{id} invalidation.",
      inputSchema: {
        id: z.string().describe("Inst id (required)"),
        inst: z.string().describe("Instruction body (required, non-empty)"),
        scope: z.string().optional().describe("Scope (default global)"),
        kind: z.string().optional().describe("Kind (default task)"),
        topic_id: z.string().optional().describe("Topic id for mention/topic kinds"),
        topics: z.array(z.string()).optional().describe("Topic filter list"),
        phrases: z.array(z.string()).optional().describe("Phrase triggers"),
        triggers: z.array(z.string()).optional().describe("Tool/signal triggers"),
        priority: z.number().optional().describe("Priority (higher wins)"),
        enabled: z.boolean().optional().describe("Enabled flag (default true)"),
        def_hash: z.string().optional().describe("Seed provenance hash"),
      },
    },
    async (args) => {
      const id = args.id.trim();
      const body = args.inst.trim();
      if (!id) throw new Error("id required");
      if (!body) throw new Error("inst body required");
      const scope = (args.scope ?? "global").trim() || "global";
      const kind = (args.kind ?? "task").trim() || "task";
      const topicId = (args.topic_id ?? "").trim();
      const topics = args.topics ?? [];
      const phrases = args.phrases ?? [];
      const triggers = args.triggers ?? [];
      const priority = args.priority ?? 0;
      const enabled = args.enabled ?? true;
      const defHash = (args.def_hash ?? "").trim();

      await pool.query(
        `INSERT INTO ai.inst (id, scope, kind, topic_id, topics, inst, phrases, triggers, priority, enabled, def_hash, updated_ts, deleted_ts)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,NOW(),NULL)
         ON CONFLICT (id) DO UPDATE SET
           scope = EXCLUDED.scope, kind = EXCLUDED.kind, topic_id = EXCLUDED.topic_id,
           topics = EXCLUDED.topics, inst = EXCLUDED.inst, phrases = EXCLUDED.phrases,
           triggers = EXCLUDED.triggers, priority = EXCLUDED.priority, enabled = EXCLUDED.enabled,
           def_hash = EXCLUDED.def_hash, updated_ts = NOW(), deleted_ts = NULL`,
        [id, scope, kind, topicId, topics, body, phrases, triggers, priority, enabled, defHash],
      );
      await instPublish(id);
      const { rows } = await pool.query<InstRow>(`SELECT ${SELECT_COLS} FROM ai.inst WHERE id = $1`, [id]);
      return jsonContent(rowToJson(rows[0]));
    },
  );

  server.registerTool(
    "inst_delete",
    {
      description: "Soft-delete ai.inst row (deleted_ts=NOW()). Publishes NATS c35.inst.{id} invalidation.",
      inputSchema: {
        id: z.string().describe("Inst id to delete"),
      },
    },
    async ({ id }) => {
      const instId = id.trim();
      if (!instId) throw new Error("id required");
      const res = await pool.query(
        "UPDATE ai.inst SET deleted_ts = NOW(), updated_ts = NOW() WHERE id = $1 AND deleted_ts IS NULL",
        [instId],
      );
      if (res.rowCount === 0) throw new Error("inst not found");
      await instPublish(instId);
      return jsonContent({ ok: true, id: instId });
    },
  );
};
