export const jsonContent = (data: unknown) => ({
  content: [{ type: "text" as const, text: JSON.stringify(data, null, 2) }],
});

export const debugOwnerIid = () => Number(process.env.C35_DEBUG_OWNER_IID ?? "99000");

export const testOwnerIid = () => Number(process.env.C35_TEST_OWNER_IID ?? "33000");

export const clampLimit = (limit: number | undefined, def: number, max: number) =>
  Math.min(Math.max(limit ?? def, 1), max);

export const ilike = (q: string) => `%${q.trim()}%`;
