use crate::particle::{parse_color, Particle, KIND_GLYPH};
use serde_json::Value;
use std::f32::consts::PI;

struct Heart {
    x: f32,
    y: f32,
    size: f32,
    speed: f32,
    sway_speed: f32,
    sway_range: f32,
    sway_offset: f32,
    opacity: f32,
    rotation: f32,
    spin: f32,
}

pub struct FallingHearts {
    hearts: Vec<Heart>,
    speed: f32,
    color: u32,
    width: f32,
    height: f32,
}

impl FallingHearts {
    pub fn new(params: &Value, width: f32, height: f32) -> Self {
        let density = params.get("density").and_then(|v| v.as_f64()).unwrap_or(35.0) as usize;
        let speed = params.get("speed").and_then(|v| v.as_f64()).unwrap_or(2.5) as f32;
        let max_size = params.get("size").and_then(|v| v.as_f64()).unwrap_or(22.0) as f32;
        let color = parse_color(params.get("color").and_then(|v| v.as_str()).unwrap_or("#ff6b81"));
        let w = width.max(1.0);
        let h = height.max(1.0);
        let mut hearts = Vec::with_capacity(density);
        for i in 0..density {
            let seed = i as f32 * 1.618;
            hearts.push(Heart {
                x: rand01(seed) * w,
                y: rand01(seed + 1.0) * -h,
                size: rand01(seed + 2.0) * (max_size - 8.0) + 10.0,
                speed: rand01(seed + 3.0) * speed + 0.8,
                sway_speed: rand01(seed + 4.0) * 0.02 + 0.01,
                sway_range: rand01(seed + 5.0) * 25.0 + 10.0,
                sway_offset: rand01(seed + 6.0) * PI * 2.0,
                opacity: rand01(seed + 7.0) * 0.5 + 0.45,
                rotation: rand01(seed + 8.0) * PI * 2.0,
                spin: (rand01(seed + 9.0) - 0.5) * 0.02,
            });
        }
        Self {
            hearts,
            speed,
            color,
            width: w,
            height: h,
        }
    }

    pub fn resize(&mut self, width: f32, height: f32) {
        self.width = width.max(1.0);
        self.height = height.max(1.0);
    }

    pub fn tick(&mut self, out: &mut Vec<Particle>) {
        out.clear();
        for heart in &mut self.hearts {
            heart.y += heart.speed;
            heart.sway_offset += heart.sway_speed;
            heart.rotation += heart.spin;
            let x = heart.x + heart.sway_offset.sin() * heart.sway_range;
            out.push(Particle {
                kind: KIND_GLYPH,
                x,
                y: heart.y,
                a: heart.size,
                b: 0.0,
                rot: heart.rotation,
                opacity: heart.opacity,
                color: self.color,
            });
            if heart.y > self.height + 20.0 {
                heart.x = rand01(heart.x + heart.rotation) * self.width;
                heart.y = -20.0;
                heart.speed = rand01(heart.rotation) * self.speed + 0.8;
            }
        }
    }
}

fn rand01(seed: f32) -> f32 {
    let x = (seed * 12_989.0).sin() * 43_758.5453;
    x - x.floor()
}
