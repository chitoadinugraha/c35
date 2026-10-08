/// Particle draw kinds exported to hosts.
pub const KIND_LINE: f32 = 0.0;
pub const KIND_GLYPH: f32 = 1.0;
pub const KIND_ELLIPSE: f32 = 2.0;
pub const KIND_ELLIPSE_FILLED: f32 = 3.0;
pub const KIND_SAKURA: f32 = 4.0;
pub const KIND_LEAF: f32 = 5.0;
pub const KIND_MOON: f32 = 6.0;


/// Stride floats per particle: kind, x, y, a, b, rot, opacity, color_u32
pub const PARTICLE_STRIDE: usize = 8;

#[derive(Clone, Copy)]
pub struct Particle {
    pub kind: f32,
    pub x: f32,
    pub y: f32,
    pub a: f32,
    pub b: f32,
    pub rot: f32,
    pub opacity: f32,
    pub color: u32,
}

impl Particle {
    /// Wire format — RGB packed in f32 (exact for 24-bit) for web canvas hosts.
    pub fn to_wire(&self) -> [f32; PARTICLE_STRIDE] {
        [
            self.kind,
            self.x,
            self.y,
            self.a,
            self.b,
            self.rot,
            self.opacity,
            color_to_wire(self.color),
        ]
    }

    pub fn to_slice(&self) -> [f32; PARTICLE_STRIDE] {
        self.to_wire()
    }
}

/// Pack RGB from ARGB u32 into an f32 (lossless for 24-bit color).
pub fn color_to_wire(color: u32) -> f32 {
    let r = (color >> 16) & 0xff;
    let g = (color >> 8) & 0xff;
    let b = color & 0xff;
    (r as f32) * 65536.0 + (g as f32) * 256.0 + b as f32
}

pub fn parse_color(hex: &str) -> u32 {
    let first = hex
        .split([',', '|'])
        .map(|s| s.trim().trim_start_matches('#'))
        .find(|s| !s.is_empty())
        .unwrap_or("");
    if first.len() != 6 {
        return 0xff_ff_ff_ff; // white fallback — visible on dark themes
    }
    let r = u32::from_str_radix(&first[0..2], 16).unwrap_or(255);
    let g = u32::from_str_radix(&first[2..4], 16).unwrap_or(255);
    let b = u32::from_str_radix(&first[4..6], 16).unwrap_or(255);
    (255 << 24) | (r << 16) | (g << 8) | b
}

pub fn color_to_css(color: u32) -> String {
    let r = (color >> 16) & 0xff;
    let g = (color >> 8) & 0xff;
    let b = color & 0xff;
    format!("#{:02x}{:02x}{:02x}", r, g, b)
}
