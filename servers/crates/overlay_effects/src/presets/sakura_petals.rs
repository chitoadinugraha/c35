use crate::particle::{parse_color, Particle, KIND_SAKURA};
use serde_json::Value;
use std::f32::consts::PI;

struct Petal {
    x: f32,
    y: f32,
    size: f32,
    speed_y: f32,
    angle: f32,
    spin: f32,
    swing: f32,
    swing_speed: f32,
    opacity: f32,
}

pub struct SakuraPetals {
    petals: Vec<Petal>,
    speed: f32,
    size: f32,
    color: u32,
    width: f32,
    height: f32,
}

impl SakuraPetals {
    pub fn new(params: &Value, width: f32, height: f32) -> Self {
        let density = params.get("density").and_then(|v| v.as_f64()).unwrap_or(25.0) as usize;
        let speed = params.get("speed").and_then(|v| v.as_f64()).unwrap_or(1.8) as f32;
        let size = params.get("size").and_then(|v| v.as_f64()).unwrap_or(12.0) as f32;
        let color = parse_color(params.get("color").and_then(|v| v.as_str()).unwrap_or("#ffb7c5"));
        let w = width.max(1.0);
        let h = height.max(1.0);
        let mut petals = Vec::with_capacity(density);
        for i in 0..density {
            let seed = i as f32 * 6.28318;
            petals.push(Petal {
                x: rand01(seed) * w,
                y: rand01(seed + 1.0) * -h,
                size: rand01(seed + 2.0) * (size - 4.0) + 4.0,
                speed_y: rand01(seed + 3.0) * speed + 0.8,
                angle: rand01(seed + 4.0) * PI * 2.0,
                spin: (rand01(seed + 5.0) - 0.5) * 0.02,
                swing: rand01(seed + 6.0) * PI * 2.0,
                swing_speed: rand01(seed + 7.0) * 0.03 + 0.015,
                opacity: rand01(seed + 8.0) * 0.4 + 0.5,
            });
        }
        Self { petals, speed, size, color, width: w, height: h }
    }

    pub fn resize(&mut self, width: f32, height: f32) {
        self.width = width.max(1.0);
        self.height = height.max(1.0);
    }

    pub fn tick(&mut self, out: &mut Vec<Particle>) {
        out.clear();
        for p in &mut self.petals {
            p.y += p.speed_y;
            p.angle += p.spin;
            p.swing += p.swing_speed;
            let current_x = p.x + p.swing.sin() * (p.size * 0.75) + p.y * 0.1;

            if p.y > self.height + 20.0 {
                p.y = -20.0;
                p.x = rand01(p.x + p.y) * self.width - self.height * 0.1;
                p.speed_y = rand01(p.opacity) * self.speed + 0.8;
            }

            out.push(Particle {
                kind: KIND_SAKURA,
                x: current_x,
                y: p.y,
                a: p.size,
                b: p.swing.sin(),
                rot: p.angle,
                opacity: p.opacity,
                color: self.color,
            });
        }
    }
}

fn rand01(seed: f32) -> f32 {
    let x = (seed * 12_989.0).sin() * 43_758.5453;
    x - x.floor()
}
