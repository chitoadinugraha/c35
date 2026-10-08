use crate::particle::{parse_color, Particle, KIND_ELLIPSE_FILLED, KIND_MOON};
use serde_json::Value;

struct DustParticle {
    x: f32,
    y: f32,
    size: f32,
    speed: f32,
    sway_speed: f32,
    sway_range: f32,
    sway_offset: f32,
    opacity: f32,
}

pub struct Moonlight {
    dust: Vec<DustParticle>,
    moon_color: u32,
    show_moon: bool,
    glow_intensity: f32,
    width: f32,
    height: f32,
}

impl Moonlight {
    pub fn new(params: &Value, width: f32, height: f32) -> Self {
        let density = params.get("density").and_then(|v| v.as_f64()).unwrap_or(20.0) as usize;
        let moon_color = parse_color(params.get("moonColor").and_then(|v| v.as_str()).unwrap_or("#fffbe3"));
        let show_moon = params.get("showMoon").and_then(|v| v.as_bool()).unwrap_or(true);
        let glow_intensity = params.get("glowIntensity").and_then(|v| v.as_f64()).unwrap_or(5.0) as f32;
        let w = width.max(1.0);
        let h = height.max(1.0);

        let mut dust = Vec::with_capacity(density);
        for i in 0..density {
            let seed = i as f32 * 8.91;
            dust.push(DustParticle {
                x: rand01(seed) * w,
                y: rand01(seed + 1.0) * h,
                size: rand01(seed + 2.0) * 2.0 + 1.0,
                speed: rand01(seed + 3.0) * 0.4 + 0.15,
                sway_speed: rand01(seed + 4.0) * 0.015 + 0.005,
                sway_range: rand01(seed + 5.0) * 12.0 + 4.0,
                sway_offset: rand01(seed + 6.0) * std::f32::consts::PI * 2.0,
                opacity: rand01(seed + 7.0) * 0.4 + 0.2,
            });
        }

        Self {
            dust,
            moon_color,
            show_moon,
            glow_intensity,
            width: w,
            height: h,
        }
    }

    pub fn resize(&mut self, width: f32, height: f32) {
        let w = width.max(1.0);
        let h = height.max(1.0);
        let changed = (self.width - w).abs() > 1.0 || (self.height - h).abs() > 1.0;
        self.width = w;
        self.height = h;
        if !changed {
            return;
        }
        let n = self.dust.len();
        self.dust.clear();
        for i in 0..n {
            let seed = i as f32 * 8.91;
            self.dust.push(DustParticle {
                x: rand01(seed) * w,
                y: rand01(seed + 1.0) * h,
                size: rand01(seed + 2.0) * 2.0 + 1.0,
                speed: rand01(seed + 3.0) * 0.4 + 0.15,
                sway_speed: rand01(seed + 4.0) * 0.015 + 0.005,
                sway_range: rand01(seed + 5.0) * 12.0 + 4.0,
                sway_offset: rand01(seed + 6.0) * std::f32::consts::PI * 2.0,
                opacity: rand01(seed + 7.0) * 0.4 + 0.2,
            });
        }
    }

    pub fn tick(&mut self, out: &mut Vec<Particle>) {
        out.clear();
        let moon_x = self.width * 0.8;
        let moon_y = self.height * 0.25;
        let moon_r = self.width.min(self.height) * 0.12;
        let glow_a = 0.16 * (self.glow_intensity / 5.0).clamp(0.2, 2.5);

        for (scale, alpha) in [(4.0, glow_a), (2.2, glow_a * 0.55), (1.1, glow_a * 0.35)] {
            out.push(Particle {
                kind: KIND_ELLIPSE_FILLED,
                x: moon_x,
                y: moon_y,
                a: moon_r * scale,
                b: moon_r * scale,
                rot: 0.0,
                opacity: alpha,
                color: self.moon_color,
            });
        }

        if self.show_moon {
            out.push(Particle {
                kind: KIND_MOON,
                x: moon_x,
                y: moon_y,
                a: moon_r * 0.4,
                b: 0.0,
                rot: -0.15 * std::f32::consts::PI,
                opacity: 0.65,
                color: self.moon_color,
            });
        }

        for d in &mut self.dust {
            d.y -= d.speed;
            d.sway_offset += d.sway_speed;
            let current_x = d.x + d.sway_offset.sin() * d.sway_range;

            if d.y < -10.0 {
                d.y = self.height + 10.0;
                d.x = rand01(d.x + d.y) * self.width;
                d.speed = rand01(d.opacity) * 0.4 + 0.15;
            }

            out.push(Particle {
                kind: KIND_ELLIPSE_FILLED,
                x: current_x,
                y: d.y,
                a: d.size,
                b: d.size,
                rot: 0.0,
                opacity: d.opacity,
                color: self.moon_color,
            });

            out.push(Particle {
                kind: KIND_ELLIPSE_FILLED,
                x: current_x,
                y: d.y,
                a: d.size * 2.8,
                b: d.size * 2.8,
                rot: 0.0,
                opacity: d.opacity * 0.35,
                color: self.moon_color,
            });
        }
    }
}

fn rand01(seed: f32) -> f32 {
    let x = (seed * 12_989.0).sin() * 43_758.5453;
    x - x.floor()
}
