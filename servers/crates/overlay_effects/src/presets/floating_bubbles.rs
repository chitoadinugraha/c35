use crate::particle::{parse_color, Particle, KIND_ELLIPSE, KIND_ELLIPSE_FILLED};
use serde_json::Value;
use std::f32::consts::PI;

struct Bubble {
    x: f32,
    y: f32,
    size: f32,
    speed: f32,
    sway_speed: f32,
    sway_range: f32,
    sway_offset: f32,
    opacity: f32,
}

pub struct FloatingBubbles {
    bubbles: Vec<Bubble>,
    speed: f32,
    color: u32,
    width: f32,
    height: f32,
}

impl FloatingBubbles {
    pub fn new(params: &Value, width: f32, height: f32) -> Self {
        let density = params.get("density").and_then(|v| v.as_f64()).unwrap_or(20.0) as usize;
        let speed = params.get("speed").and_then(|v| v.as_f64()).unwrap_or(1.8) as f32;
        let max_size = params.get("size").and_then(|v| v.as_f64()).unwrap_or(24.0) as f32;
        let color = parse_color(params.get("color").and_then(|v| v.as_str()).unwrap_or("#8ae2ff"));
        let w = width.max(1.0);
        let h = height.max(1.0);
        let mut bubbles = Vec::with_capacity(density);
        for i in 0..density {
            let seed = i as f32 * 5.4321;
            bubbles.push(Bubble {
                x: rand01(seed) * w,
                y: h + rand01(seed + 1.0) * h,
                size: rand01(seed + 2.0) * (max_size - 6.0) + 6.0,
                speed: rand01(seed + 3.0) * speed + 0.4,
                sway_speed: rand01(seed + 4.0) * 0.03 + 0.015,
                sway_range: rand01(seed + 5.0) * 20.0 + 8.0,
                sway_offset: rand01(seed + 6.0) * PI * 2.0,
                opacity: rand01(seed + 7.0) * 0.35 + 0.25,
            });
        }
        Self { bubbles, speed, color, width: w, height: h }
    }

    pub fn resize(&mut self, width: f32, height: f32) {
        self.width = width.max(1.0);
        self.height = height.max(1.0);
    }

    pub fn tick(&mut self, out: &mut Vec<Particle>) {
        out.clear();
        for b in &mut self.bubbles {
            b.y -= b.speed;
            b.sway_offset += b.sway_speed;
            let cx = b.x + b.sway_offset.sin() * b.sway_range;

            if b.y < -b.size - 5.0 {
                b.y = self.height + b.size + 10.0;
                b.x = rand01(b.x + b.y) * self.width;
                b.speed = rand01(b.opacity) * self.speed + 0.4;
            }

            // Stroked main bubble
            out.push(Particle {
                kind: KIND_ELLIPSE,
                x: cx,
                y: b.y,
                a: b.size,
                b: b.size,
                rot: 1.2,
                opacity: b.opacity,
                color: self.color,
            });

            // Small highlight filled circle
            out.push(Particle {
                kind: KIND_ELLIPSE_FILLED,
                x: cx - b.size * 0.32,
                y: b.y - b.size * 0.32,
                a: b.size * 0.15,
                b: b.size * 0.15,
                rot: 0.0,
                opacity: b.opacity * 0.8,
                color: 0xff_ff_ff_ff,
            });
        }
    }
}

fn rand01(seed: f32) -> f32 {
    let x = (seed * 12_989.0).sin() * 43_758.5453;
    x - x.floor()
}
