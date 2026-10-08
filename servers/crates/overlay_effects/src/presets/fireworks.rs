use crate::particle::{Particle, KIND_ELLIPSE_FILLED};
use serde_json::Value;
use std::f32::consts::PI;

struct Spark {
    x: f32,
    y: f32,
    vx: f32,
    vy: f32,
    life: f32,
    decay: f32,
    color: u32,
    size: f32,
}

pub struct Fireworks {
    sparks: Vec<Spark>,
    frequency: f32,
    particle_count: usize,
    particle_size: f32,
    gravity: f32,
    width: f32,
    height: f32,
    frame: usize,
    seed_counter: f32,
}

impl Fireworks {
    pub fn new(params: &Value, width: f32, height: f32) -> Self {
        let frequency = params.get("frequency").and_then(|v| v.as_f64()).unwrap_or(3.0) as f32;
        let particle_count = params.get("particles").and_then(|v| v.as_f64()).unwrap_or(50.0) as usize;
        let particle_size = params.get("size").and_then(|v| v.as_f64()).unwrap_or(3.0) as f32;
        let gravity = params.get("gravity").and_then(|v| v.as_f64()).unwrap_or(0.06) as f32;
        let w = width.max(1.0);
        let h = height.max(1.0);
        Self {
            sparks: Vec::new(),
            frequency,
            particle_count,
            particle_size,
            gravity,
            width: w,
            height: h,
            frame: 0,
            seed_counter: 0.0,
        }
    }

    pub fn resize(&mut self, width: f32, height: f32) {
        self.width = width.max(1.0);
        self.height = height.max(1.0);
    }

    fn spawn_burst(&mut self) {
        self.seed_counter += 1.357;
        let seed = self.seed_counter;
        let cx = rand01(seed) * self.width * 0.75 + self.width * 0.125;
        let cy = rand01(seed + 1.0) * self.height * 0.45 + self.height * 0.08;

        let colors = [
            0xff_ff_6b_6b,
            0xff_ff_d9_3d,
            0xff_6b_cb_77,
            0xff_4d_96_ff,
            0xff_c7_7d_ff,
            0xff_ff_9f_43,
            0xff_ff_ff_ff,
        ];
        let base_color = colors[(rand01(seed + 2.0) * colors.len() as f32) as usize];

        for i in 0..self.particle_count {
            let angle_seed = seed + i as f32 * 1.618;
            let angle = (PI * 2.0 * i as f32) / self.particle_count as f32 + (rand01(angle_seed) - 0.5) * 0.35;
            let velocity = rand01(angle_seed + 1.0) * 3.5 + 1.8;
            let color = if rand01(angle_seed + 2.0) > 0.25 {
                base_color
            } else {
                colors[(rand01(angle_seed + 3.0) * colors.len() as f32) as usize]
            };
            self.sparks.push(Spark {
                x: cx,
                y: cy,
                vx: angle.cos() * velocity,
                vy: angle.sin() * velocity,
                life: 1.0,
                decay: rand01(angle_seed + 4.0) * 0.012 + 0.008,
                color,
                size: rand01(angle_seed + 5.0) * self.particle_size + self.particle_size * 0.5,
            });
        }
    }

    pub fn tick(&mut self, out: &mut Vec<Particle>) {
        out.clear();
        self.frame += 1;

        let mut interval = (72.0 / self.frequency).floor() as usize;
        if interval < 8 { interval = 8; }

        if self.frame % interval == 0 {
            self.spawn_burst();
        }
        if self.frame % (interval * 2 + 12) == 0 {
            self.spawn_burst();
        }

        let mut i = 0;
        while i < self.sparks.len() {
            let s = &mut self.sparks[i];
            s.x += s.vx;
            s.y += s.vy;
            s.vy += self.gravity;
            s.vx *= 0.985;
            s.life -= s.decay;

            if s.life <= 0.0 {
                self.sparks.remove(i);
            } else {
                out.push(Particle {
                    kind: KIND_ELLIPSE_FILLED,
                    x: s.x,
                    y: s.y,
                    a: s.size * s.life,
                    b: s.size * s.life,
                    rot: 0.0,
                    opacity: s.life,
                    color: s.color,
                });

                out.push(Particle {
                    kind: KIND_ELLIPSE_FILLED,
                    x: s.x - s.vx * 1.5,
                    y: s.y - s.vy * 1.5,
                    a: s.size * 1.6 * s.life,
                    b: s.size * 1.6 * s.life,
                    rot: 0.0,
                    opacity: s.life * 0.35,
                    color: s.color,
                });
                i += 1;
            }
        }
    }
}

fn rand01(seed: f32) -> f32 {
    let x = (seed * 12_989.0).sin() * 43_758.5453;
    x - x.floor()
}
