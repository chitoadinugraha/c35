export const BRIDGE_VERSION = 1;
export const MAX_FRAME_BYTES = 16 * 1024 * 1024;

export type IpcReq = {
  bridge_version: typeof BRIDGE_VERSION;
  kind: 'req';
  id: string;
  method: string;
  params?: unknown;
};

export type IpcRes = {
  bridge_version: typeof BRIDGE_VERSION;
  kind: 'res';
  id: string;
  ok: boolean;
  result?: unknown;
  error?: { code: string; message: string };
};

export type IpcEvt = {
  bridge_version: typeof BRIDGE_VERSION;
  kind: 'evt';
  method: string;
  params: unknown;
};

export type IpcMessage = IpcReq | IpcRes | IpcEvt;

export type LaunchParams = {
  headless?: boolean;
  userDataDir?: string;
  downloadsPath?: string;
  viewport?: { width: number; height: number };
  initialUrl?: string;
};

export type ScreencastFrameParams = {
  seq: number;
  width: number;
  height: number;
  sessionId: number;
  jpeg_b64: string;
};

export type InputEvent =
  | { type: 'mouseMove'; x: number; y: number }
  | { type: 'mouseDown'; button: 'left' | 'right' | 'middle'; x: number; y: number }
  | { type: 'mouseUp'; button: 'left' | 'right' | 'middle'; x: number; y: number }
  | { type: 'wheel'; x: number; y: number; deltaX: number; deltaY: number }
  | { type: 'keyDown'; key: string }
  | { type: 'keyUp'; key: string }
  | { type: 'text'; text: string };

export const frameEncode = (obj: IpcMessage): Buffer => {
  const body = Buffer.from(JSON.stringify(obj), 'utf8');
  if (body.length > MAX_FRAME_BYTES) throw new Error(`frame body exceeds ${MAX_FRAME_BYTES} bytes`);
  const header = Buffer.allocUnsafe(4);
  header.writeUInt32LE(body.length, 0);
  return Buffer.concat([header, body]);
};

export type FrameParseResult = { message: IpcMessage; rest: Buffer };

export const frameTryParse = (buffer: Buffer): FrameParseResult | null => {
  if (buffer.length < 4) return null;
  const len = buffer.readUInt32LE(0);
  if (len === 0 || len > MAX_FRAME_BYTES) throw new Error(`invalid frame length: ${len}`);
  if (buffer.length < 4 + len) return null;
  const body = buffer.subarray(4, 4 + len);
  const message = JSON.parse(body.toString('utf8')) as IpcMessage;
  if (message.bridge_version !== BRIDGE_VERSION) {
    throw new Error(`unsupported bridge_version: ${(message as { bridge_version?: number }).bridge_version}`);
  }
  return { message, rest: buffer.subarray(4 + len) };
};

export const resOk = (id: string, result?: unknown): IpcRes => ({
  bridge_version: BRIDGE_VERSION,
  kind: 'res',
  id,
  ok: true,
  result,
});

export const resErr = (id: string, code: string, message: string): IpcRes => ({
  bridge_version: BRIDGE_VERSION,
  kind: 'res',
  id,
  ok: false,
  error: { code, message },
});

export const evt = (method: string, params: unknown): IpcEvt => ({
  bridge_version: BRIDGE_VERSION,
  kind: 'evt',
  method,
  params,
});