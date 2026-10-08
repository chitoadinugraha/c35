use crate::particle::{parse_color, Particle, KIND_LINE, KIND_ELLIPSE_FILLED};
use serde_json::Value;

struct Drop {
    x: f32,
    y: f32,
    length: f32,
    speed: f32,
    opacity: f32,
}

pub struct Thunderstorm {
    drops: Vec<Drop>,
    speed: f32,
    color: u32,
    width: f32,
    height: f32,
    flash_frequency: f32,
    flash_time: i32,
    flash_max_time: i32,
    lightning_path: Vec<(f32, f32)>,
}

impl Thunderstorm {
    pub fn new(params: &Value, width: f32, height: f32) -> Self {
        let density = params.get("density").and_then(|v| v.as_f64()).unwrap_or(120.0) as usize;
        let speed = params.get("speed").and_then(|v| v.as_f64()).unwrap_or(18.0) as f32;
        let color = parse_color(params.get("color").and_then(|v| v.as_str()).unwrap_or("#7faec6"));
        let flash_frequency = params.get("flashFrequency").and_then(|v| v.as_f64()).unwrap_or(4.0) as f32;
        let w = width.max(1.0);
        let h = height.max(1.0);
        let mut drops = Vec::with_capacity(density);
        for i in 0..density {
            let seed = i as f32 * 4.321;
            drops.push(Drop {
                x: rand01(seed) * w,
                y: rand01(seed + 1.0) * -h,
                length: rand01(seed + 2.0) * 25.0 + 20.0,
                speed: rand01(seed + 3.0) * speed + speed * 0.6,
                opacity: rand01(seed + 4.0) * 0.25 + 0.15,
            });
        }
        Self {
            drops,
            speed,
            color,
            width: w,
            height: h,
            flash_frequency,
            flash_time: 0,
            flash_max_time: 0,
            lightning_path: Vec::new(),
        }
    }

    pub fn resize(&mut self, width: f32, height: f32) {
        self.width = width.max(1.0);
        self.height = height.max(1.0);
    }

    pub fn tick(&mut self, out: &mut Vec<Particle>) {
        out.clear();

        for d in &mut self.drops {
            out.push(Particle {
                kind: KIND_LINE,
                x: d.x,
                y: d.y,
                a: d.x - 3.5,
                b: d.y + d.length,
                rot: 1.6,
                opacity: d.opacity,
                color: self.color,
            });
            d.y += d.speed;
            d.x -= d.speed * 0.12;
            if d.y > self.height + 20.0 {
                d.y = -30.0;
                d.x = rand01(d.x + d.y) * (self.width + 100.0);
                d.speed = rand01(d.opacity) * self.speed + self.speed * 0.6;
            }
        }

        if self.flash_time > 0 {
            self.flash_time -= 1;

            let intensity = (self.flash_time as f32 / self.flash_max_time as f32) * 0.45;
            out.push(Particle {
                kind: KIND_ELLIPSE_FILLED,
                x: self.width * 0.5,
                y: self.height * 0.5,
                a: self.width * 0.5,
                b: self.height * 0.5,
                rot: 0.0,
                opacity: intensity,
                color: 0xff_ff_ff_ff,
            });

            if self.flash_time > (self.flash_max_time as f32 * 0.6) as i32 && !self.lightning_path.is_empty() {
                for i in 0..self.lightning_path.len() - 1 {
                    let pt1 = self.lightning_path[i];
                    let pt2 = self.lightning_path[i + 1];
                    out.push(Particle {
                        kind: KIND_LINE,
                        x: pt1.0,
                        y: pt1.1,
                        a: pt2.0,
                        b: pt2.1,
                        rot: rand01(pt1.0) * 3.0 + 2.5,
                        opacity: 1.0,
                        color: 0xff_ff_ff_ff,
                    });
                }
            }
        } else {
            let seed = self.drops.first().map(|d| d.x).unwrap_or(0.0) + self.drops.last().map(|d| d.y).unwrap_or(0.0);
            if rand01(seed) < 0.002 * self.flash_frequency {
                let max_t = (rand01(seed + 1.0) * 18.0).floor() as i32 + 12;
                self.flash_max_time = max_t;
                self.flash_time = max_t;

                self.lightning_path.clear();
                let mut cur_x = rand01(seed + 2.0) * self.width * 0.7 + self.width * 0.15;
                let mut cur_y = 0.0;
                self.lightning_path.push((cur_x, cur_y));
                let segments = (rand01(seed + 3.0) * 6.0).floor() as usize + 8;
                for s in 0..segments {
                    let segment_seed = seed + s as f32 * 9.87;
                    cur_x += (rand01(segment_seed) - 0.5) * 60.0;
                    cur_y += self.height / segments as f32 + (rand01(segment_seed + 1.0) - 0.5) * 15.0;
                    self.lightning_path.push((cur_x, cur_y));
                }
            }
        }
    }
}

fn rand01(seed: f32) -> f32 {
    let x = (seed * 12_989.0).sin() * 43_758.5453;
    x - x.floor()
}
