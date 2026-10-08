use crate::particle::{parse_color, Particle, KIND_ELLIPSE, KIND_LINE};
use serde_json::Value;

struct Drop {
    x: f32,
    y: f32,
    length: f32,
    speed: f32,
    opacity: f32,
}

struct Splash {
    x: f32,
    y: f32,
    radius: f32,
    max_radius: f32,
    opacity: f32,
}

pub struct RainShower {
    drops: Vec<Drop>,
    splashes: Vec<Splash>,
    speed: f32,
    drop_scale: f32,
    has_splash: bool,
    color: u32,
    line_width: f32,
    width: f32,
    height: f32,
}

impl RainShower {
    pub fn new(params: &Value, width: f32, height: f32) -> Self {
        let density = params.get("density").and_then(|v| v.as_f64()).unwrap_or(80.0) as usize;
        let speed = params.get("speed").and_then(|v| v.as_f64()).unwrap_or(14.0) as f32;
        let drop_scale = params.get("size").and_then(|v| v.as_f64()).unwrap_or(2.25) as f32;
        let has_splash = params.get("splash").and_then(|v| v.as_bool()).unwrap_or(true);
        let color = parse_color(params.get("color").and_then(|v| v.as_str()).unwrap_or("#aedbf0"));
        let line_width = 1.2 + drop_scale * 0.8;
        let length_base = 18.0 + drop_scale * 12.0;
        let w = width.max(1.0);
        let h = height.max(1.0);
        let mut drops = Vec::with_capacity(density);
        for i in 0..density {
            let seed = i as f32 * 2.718;
            drops.push(Drop {
                x: rand01(seed) * w,
                y: rand01(seed + 1.0) * -h,
                length: rand01(seed + 2.0) * length_base + length_base * 0.6,
                speed: rand01(seed + 3.0) * speed + speed * 0.7,
                opacity: rand01(seed + 4.0) * 0.35 + 0.2,
            });
        }
        Self {
            drops,
            splashes: Vec::new(),
            speed,
            drop_scale,
            has_splash,
            color,
            line_width,
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
        for drop in &mut self.drops {
            let x1 = drop.x;
            let y1 = drop.y;
            let x2 = drop.x - self.drop_scale * 1.5;
            let y2 = drop.y + drop.length;
            out.push(Particle {
                kind: KIND_LINE,
                x: x1,
                y: y1,
                a: x2,
                b: y2,
                rot: self.line_width,
                opacity: drop.opacity,
                color: self.color,
            });
            drop.y += drop.speed;
            drop.x -= 0.1;
            if drop.y > self.height - 10.0 {
                if self.has_splash && self.splashes.len() < 50 {
                    self.splashes.push(Splash {
                        x: drop.x,
                        y: self.height - 5.0,
                        radius: 1.0,
                        max_radius: rand01(drop.y) * (6.0 + self.drop_scale * 3.0) + 4.0 + self.drop_scale * 2.0,
                        opacity: 0.5,
                    });
                }
                drop.y = rand01(drop.x) * -40.0;
                drop.x = rand01(drop.y) * self.width;
                drop.speed = rand01(drop.length) * self.speed + self.speed * 0.7;
            }
        }
        let mut i = 0;
        while i < self.splashes.len() {
            let splash = &mut self.splashes[i];
            out.push(Particle {
                kind: KIND_ELLIPSE,
                x: splash.x,
                y: splash.y,
                a: splash.radius,
                b: splash.radius * 0.3,
                rot: 0.8 + self.drop_scale * 0.4,
                opacity: splash.opacity,
                color: self.color,
            });
            splash.radius += 0.5;
            splash.opacity -= 0.03;
            if splash.opacity <= 0.0 || splash.radius >= splash.max_radius {
                self.splashes.remove(i);
            } else {
                i += 1;
            }
        }
    }
}

fn rand01(seed: f32) -> f32 {
    let x = (seed * 12_989.0).sin() * 43_758.5453;
    x - x.floor()
}
