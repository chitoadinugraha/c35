import pg from "pg";

const { Pool } = pg;

export const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.DATABASE_SSL === "true" ? { rejectUnauthorized: false } : undefined,
});

type PromptRunChildRow = {
  req_id: string;
  parent_req_id: string;
  kind: string;
  status: string;
  topic_id: string;
  turn_count: number;
  cost_usd: string;
  fail_class: string | null;
  fail_reason: string | null;
  created_ts: string;
};

export const promptRunChildren = async (parentReqId: string) => {
  const { rows } = await pool.query<PromptRunChildRow>(
    `SELECT req_id, parent_req_id, kind, status, topic_id, turn_count, cost_usd::text, fail_class, fail_reason, created_ts
     FROM ai.prompt_run
     WHERE parent_req_id = $1
     ORDER BY created_ts ASC`,
    [parentReqId],
  );
  return rows.map((r) => ({
    req_id: r.req_id,
    parent_req_id: r.parent_req_id,
    kind: r.kind,
    status: r.status,
    topic_id: r.topic_id,
    turn_count: r.turn_count,
    cost_usd: r.cost_usd,
    fail_class: r.fail_class ?? "",
    fail_reason: r.fail_reason ?? "",
    created_ts: r.created_ts,
  }));
};
