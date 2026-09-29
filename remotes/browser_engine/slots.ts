import path from 'node:path';

export const sanitizeSlotId = (slotId: string): string => {
  const s = slotId.replace(/[^a-zA-Z0-9_-]/g, '_');
  return s || 'default';
};

export const slotPaths = (
  configDir: string,
  slotId: string,
): { userDataDir: string; downloadsPath: string } => {
  const id = sanitizeSlotId(slotId);
  const userDataDir = path.join(configDir, 'slots', id);
  const downloadsPath = path.join(userDataDir, 'downloads');
  return { userDataDir, downloadsPath };
};
