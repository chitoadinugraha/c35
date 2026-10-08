use crate::particle::{parse_color, Particle, KIND_ELLIPSE_FILLED};
use serde_json::Value;

struct Flake {
    x: f32,
    y: f32,
    size: f32,
    speed: f32,
    drift: f32,
    opacity: f32,
}

pub struct SnowFall {
    flakes: Vec<Flake>,
    speed: f32,
    color: u32,
    width: f32,
    height: f32,
}

impl SnowFall {
    pub fn new(params: &Value, width: f32, height: f32) -> Self {
        let density = params.get("density").and_then(|v| v.as_f64()).unwrap_or(60.0) as usize;
        let speed = params.get("speed").and_then(|v| v.as_f64()).unwrap_or(1.5) as f32;
        let max_size = params.get("size").and_then(|v| v.as_f64()).unwrap_or(5.0) as f32;
        let color = parse_color(params.get("color").and_then(|v| v.as_str()).unwrap_or("#ffffff"));
        let w = width.max(1.0);
        let h = height.max(1.0);
        let mut flakes = Vec::with_capacity(density);
        for i in 0..density {
            let seed = i as f32 * 3.141592;
            flakes.push(Flake {
                x: rand01(seed) * w,
                y: rand01(seed + 1.0) * h,
                size: rand01(seed + 2.0) * max_size + 1.0,
                speed: rand01(seed + 3.0) * speed + 0.3,
                drift: (rand01(seed + 4.0) - 0.5) * 0.6,
                opacity: rand01(seed + 5.0) * 0.5 + 0.4,
            });
        }
        Self { flakes, speed, color, width: w, height: h }
    }

    pub fn resize(&mut self, width: f32, height: f32) {
        self.width = width.max(1.0);
        self.height = height.max(1.0);
    }

    pub fn tick(&mut self, out: &mut Vec<Particle>) {
        out.clear();
        for flake in &mut self.flakes {
            flake.y += flake.speed;
            flake.x += flake.drift;
            if flake.y > self.height + 10.0 {
                flake.y = -10.0;
                flake.x = rand01(flake.x + flake.y) * self.width;
            }
            if flake.x < -10.0 { flake.x = self.width + 10.0; }
            if flake.x > self.width + 10.0 { flake.x = -10.0; }
            out.push(Particle {
                kind: KIND_ELLIPSE_FILLED,
                x: flake.x,
                y: flake.y,
                a: flake.size,
                b: flake.size,
                rot: 0.0,
                opacity: flake.opacity,
                color: self.color,
            });
        }
    }
}

fn rand01(seed: f32) -> f32 {
    let x = (seed * 12_989.0).sin() * 43_758.5453;
    x - x.floor()
}
