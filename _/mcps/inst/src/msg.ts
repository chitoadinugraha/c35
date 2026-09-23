import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import { pool } from "./db.js";
import { clampLimit, debugOwnerIid, ilike, jsonContent } from "./util.js";

type ChatMsgRow = {
  id: string;
  chat_id: string;
  owner_iid: string;
  req_id: string;
  sender_iid: string;
  role: string;
  source: string;
  content: string;
  thought: string;
  attachments: unknown;
  blocks_json: unknown;
  tokens_in: number;
  tokens_out: number;
  duration_ms: number;
  cost_usd: string;
  status: string;
  created_ts: string;
  updated_ts: string;
};

type LogRow = {
  id: string;
  kind: string;
  topic: string;
  req_id: string;
  text: string;
  model: string;
  tokens_in: number;
  tokens_out: number;
  duration_ms: number;
  cost_usd: string;
  meta: Record<string, unknown>;
  created_ts: string;
};

const MSG_COLS =
  "id, chat_id, owner_iid, req_id, sender_iid, role, source, content, thought, attachments, blocks_json, tokens_in, tokens_out, duration_ms, cost_usd, status, created_ts, updated_ts";

const msgRowJson = (r: ChatMsgRow) => ({
  id: r.id,
  chat_id: r.chat_id,
  owner_iid: r.owner_iid,
  req_id: r.req_id,
  sender_iid: r.sender_iid,
  role: r.role,
  source: r.source,
  content: r.content,
  thought: r.thought,
  attachments: r.attachments,
  blocks_json: r.blocks_json,
  tokens_in: r.tokens_in,
  tokens_out: r.tokens_out,
  duration_ms: r.duration_ms,
  cost_usd: r.cost_usd,
  status: r.status,
  created_ts: r.created_ts,
  updated_ts: r.updated_ts,
});

const traceForReq = async (reqId: string, ownerIid?: number) => {
  const clauses = ["deleted_ts IS NULL", "req_id = $1"];
  const params: unknown[] = [reqId];
  if (ownerIid !== undefined) {
    params.push(ownerIid);
    clauses.push(`owner_iid = $${params.length}`);
  }
  const sql = `SELECT id, kind, topic, req_id, text, model, tokens_in, tokens_out, duration_ms, cost_usd, meta, created_ts
    FROM ai.log WHERE ${clauses.join(" AND ")} ORDER BY created_ts ASC, id ASC`;
  const { rows } = await pool.query<LogRow>(sql, params);
  return rows.map((r) => ({
    id: r.id,
    kind: r.kind,
    topic: r.topic,
    req_id: r.req_id,
    text: r.text,
    model: r.model,
    tokens_in: r.tokens_in,
    tokens_out: r.tokens_out,
    duration_ms: r.duration_ms,
    cost_usd: r.cost_usd,
    meta: r.meta,
    created_ts: r.created_ts,
  }));
};

export const registerMsgTools = (server: McpServer) => {
  server.registerTool(
    "msg_get",
    {
      description: "Get chat message(s) by msg_id or req_id, plus linked ai.log trace rows.",
      inputSchema: {
        msg_id: z.number().optional().describe("Message id"),
        req_id: z.string().optional().describe("Request id (returns all messages for turn)"),
        owner_iid: z.number().optional().describe("Owner filter (default C35_DEBUG_OWNER_IID or 99000)"),
      },
    },
    async ({ msg_id, req_id, owner_iid }) => {
      const ownerIid = owner_iid ?? debugOwnerIid();
      if (msg_id === undefined && !req_id?.trim()) throw new Error("msg_id or req_id required");

      if (msg_id !== undefined) {
        const { rows } = await pool.query<ChatMsgRow>(
          `SELECT ${MSG_COLS} FROM ai.chat_msg WHERE id = $1 AND owner_iid = $2 AND deleted_ts IS NULL`,
          [msg_id, ownerIid],
        );
        if (!rows[0]) throw new Error("message not found");
        const msg = rows[0];
        const trace = msg.req_id ? await traceForReq(msg.req_id, ownerIid) : [];
        return jsonContent({ message: msgRowJson(msg), trace });
      }

      const rid = req_id!.trim();
      const { rows } = await pool.query<ChatMsgRow>(
        `SELECT ${MSG_COLS} FROM ai.chat_msg WHERE req_id = $1 AND owner_iid = $2 AND deleted_ts IS NULL ORDER BY created_ts ASC, id ASC`,
        [rid, ownerIid],
      );
      const trace = await traceForReq(rid, ownerIid);
      return jsonContent({
        req_id: rid,
        messages: rows.map(msgRowJson),
        trace,
      });
    },
  );

  server.registerTool(
    "msg_find",
    {
      description: "Search ai.chat_msg by content ILIKE (default owner 99000).",
      inputSchema: {
        q: z.string().describe("ILIKE search on content"),
        owner_iid: z.number().optional().describe("Owner iid (default C35_DEBUG_OWNER_IID or 99000)"),
        chat_id: z.number().optional().describe("Optional chat filter"),
        limit: z.number().optional().describe("Max rows (default 20)"),
      },
    },
    async ({ q, owner_iid, chat_id, limit }) => {
      const query = q.trim();
      if (!query) throw new Error("q required");
      const ownerIid = owner_iid ?? debugOwnerIid();
      const lim = clampLimit(limit, 20, 100);
      const clauses = ["deleted_ts IS NULL", "owner_iid = $1", "content ILIKE $2"];
      const params: unknown[] = [ownerIid, ilike(query)];
      if (chat_id !== undefined) {
        params.push(chat_id);
        clauses.push(`chat_id = $${params.length}`);
      }
      params.push(lim);
      const sql = `SELECT id, chat_id, req_id, role, left(content, 200) AS preview, created_ts
        FROM ai.chat_msg WHERE ${clauses.join(" AND ")} ORDER BY created_ts DESC, id DESC LIMIT $${params.length}`;
      const { rows } = await pool.query(sql, params);
      return jsonContent({ owner_iid: ownerIid, q: query, count: rows.length, messages: rows });
    },
  );
};
