/** Parse snowflake ids from MCP JSON without Number precision loss. */
export const snowflakeFromJson = (v: unknown): string | undefined => {
  if (v === undefined || v === null) return undefined;
  if (typeof v === "string") {
    const s = v.trim();
    return s.length > 0 ? s : undefined;
  }
  if (typeof v === "number" && Number.isFinite(v)) {
    return Number.isSafeInteger(v) ? String(v) : undefined;
  }
  return undefined;
};

export const deviceIidArg = (v: unknown): number | string => {
  const s = snowflakeFromJson(v);
  if (s) {
    const n = BigInt(s);
    if (n > BigInt(Number.MAX_SAFE_INTEGER)) return s;
    return Number(s);
  }
  if (typeof v === "number" && Number.isFinite(v)) return v;
  throw new Error("device_iid required (string snowflake recommended)");
};