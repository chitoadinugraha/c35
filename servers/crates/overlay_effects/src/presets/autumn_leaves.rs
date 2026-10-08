use crate::particle::{parse_color, Particle, KIND_LEAF};
use serde_json::Value;
use std::f32::consts::PI;

struct Leaf {
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
    color: u32,
}

pub struct AutumnLeaves {
    leaves: Vec<Leaf>,
    speed: f32,
    color: u32,
    width: f32,
    height: f32,
}

impl AutumnLeaves {
    pub fn new(params: &Value, width: f32, height: f32) -> Self {
        let density = params.get("density").and_then(|v| v.as_f64()).unwrap_or(30.0) as usize;
        let speed = params.get("speed").and_then(|v| v.as_f64()).unwrap_or(2.0) as f32;
        let max_size = params.get("size").and_then(|v| v.as_f64()).unwrap_or(24.0) as f32;
        let tint = parse_color(params.get("color").and_then(|v| v.as_str()).unwrap_or("#e67e22"));
        let w = width.max(1.0);
        let h = height.max(1.0);

        let leaf_colors = [
            tint,
            parse_color("#d35400"),
            parse_color("#c0392b"),
            parse_color("#f39c12"),
            parse_color("#e74c3c"),
            parse_color("#d4a017"),
        ];

        let mut leaves = Vec::with_capacity(density);
        for i in 0..density {
            let seed = i as f32 * 9.81;
            let color = leaf_colors[(rand01(seed) * leaf_colors.len() as f32) as usize];
            leaves.push(Leaf {
                x: rand01(seed + 1.0) * w,
                y: rand01(seed + 2.0) * -h,
                size: rand01(seed + 3.0) * (max_size - 10.0) + 12.0,
                speed: rand01(seed + 4.0) * speed + 0.5,
                sway_speed: rand01(seed + 5.0) * 0.025 + 0.01,
                sway_range: rand01(seed + 6.0) * 30.0 + 15.0,
                sway_offset: rand01(seed + 7.0) * PI * 2.0,
                opacity: rand01(seed + 8.0) * 0.4 + 0.5,
                rotation: rand01(seed + 9.0) * PI * 2.0,
                spin: (rand01(seed + 10.0) - 0.5) * 0.03,
                color,
            });
        }

        Self { leaves, speed, color: tint, width: w, height: h }
    }

    pub fn resize(&mut self, width: f32, height: f32) {
        self.width = width.max(1.0);
        self.height = height.max(1.0);
    }

    pub fn tick(&mut self, out: &mut Vec<Particle>) {
        out.clear();
        for leaf in &mut self.leaves {
            leaf.y += leaf.speed;
            leaf.sway_offset += leaf.sway_speed;
            leaf.rotation += leaf.spin;
            let current_x = leaf.x + leaf.sway_offset.sin() * leaf.sway_range;

            if leaf.y > self.height + 20.0 {
                leaf.y = -20.0;
                leaf.x = rand01(leaf.x + leaf.y) * self.width;
                leaf.speed = rand01(leaf.opacity) * self.speed + 0.5;
            }

            out.push(Particle {
                kind: KIND_LEAF,
                x: current_x,
                y: leaf.y,
                a: leaf.size,
                b: 0.0,
                rot: leaf.rotation,
                opacity: leaf.opacity,
                color: leaf.color,
            });
        }
    }
}

fn rand01(seed: f32) -> f32 {
    let x = (seed * 12_989.0).sin() * 43_758.5453;
    x - x.floor()
}
