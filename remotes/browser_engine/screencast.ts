import type { CDPSession, Page } from 'playwright';

export type ScreencastFrame = { jpeg: Buffer; sessionId: number };

export type ScreencastOptions = {
  width: number;
  height: number;
  quality?: number;
  onFrame: (frame: ScreencastFrame, seq: number) => void;
};

export class Screencast {
  private cdp: CDPSession | null = null;
  private seq = 0;
  private lastJpeg: Buffer | null = null;
  private pending: ScreencastFrame | null = null;
  private draining = false;

  constructor(private readonly page: Page, private readonly opts: ScreencastOptions) {}

  public async start(): Promise<void> {
    if (this.cdp) return;
    this.cdp = await this.page.context().newCDPSession(this.page);
    this.seq = 0;
    this.cdp.on('Page.screencastFrame', (evt: { data: string; sessionId: number }) => {
      void this.cdp
        ?.send('Page.screencastFrameAck', { sessionId: evt.sessionId })
        .catch(() => {});
      this.pending = {
        jpeg: Buffer.from(evt.data, 'base64'),
        sessionId: evt.sessionId,
      };
      void this.drain();
    });
    await this.cdp.send('Page.startScreencast', {
      format: 'jpeg',
      quality: this.opts.quality ?? 65,
      maxWidth: this.opts.width,
      maxHeight: this.opts.height,
      everyNthFrame: 1,
    });
  }

  public async stop(): Promise<void> {
    if (!this.cdp) return;
    await this.cdp.send('Page.stopScreencast').catch(() => {});
    await this.cdp.detach().catch(() => {});
    this.cdp = null;
    this.pending = null;
    this.lastJpeg = null;
  }

  private async drain(): Promise<void> {
    if (this.draining) return;
    this.draining = true;
    try {
      while (this.pending) {
        const frame = this.pending;
        this.pending = null;
        if (this.lastJpeg?.equals(frame.jpeg)) continue;
        this.seq += 1;
        this.opts.onFrame(frame, this.seq);
        this.lastJpeg = frame.jpeg;
      }
    } finally {
      this.draining = false;
      if (this.pending) void this.drain();
    }
  }
}
