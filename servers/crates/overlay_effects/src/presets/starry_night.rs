use crate::particle::{parse_color, Particle, KIND_ELLIPSE_FILLED, KIND_LINE};
use serde_json::Value;

struct Star {
    x: f32,
    y: f32,
    size: f32,
    phase: f32,
    phase_speed: f32,
}

struct ShootingStar {
    x: f32,
    y: f32,
    len: f32,
    dx: f32,
    dy: f32,
    speed: f32,
    opacity: f32,
}

pub struct StarryNight {
    stars: Vec<Star>,
    shooting_stars: Vec<ShootingStar>,
    speed: f32,
    color: u32,
    shooting_stars_enabled: bool,
    width: f32,
    height: f32,
    seed_counter: f32,
}

impl StarryNight {
    pub fn new(params: &Value, width: f32, height: f32) -> Self {
        let density = params.get("density").and_then(|v| v.as_f64()).unwrap_or(60.0) as usize;
        let speed = params.get("speed").and_then(|v| v.as_f64()).unwrap_or(0.6) as f32;
        let color = parse_color(params.get("color").and_then(|v| v.as_str()).unwrap_or("#ffffff"));
        let shooting_stars_enabled = params.get("shootingStars").and_then(|v| v.as_bool()).unwrap_or(true);
        let w = width.max(1.0);
        let h = height.max(1.0);
        let mut stars = Vec::with_capacity(density);
        for i in 0..density {
            let seed = i as f32 * 7.111;
            stars.push(Star {
                x: rand01(seed) * w,
                y: rand01(seed + 1.0) * h,
                size: rand01(seed + 2.0) * 1.5 + 0.5,
                phase: rand01(seed + 3.0) * std::f32::consts::PI * 2.0,
                phase_speed: (rand01(seed + 4.0) * 0.03 + 0.01) * speed,
            });
        }
        Self {
            stars,
            shooting_stars: Vec::new(),
            speed,
            color,
            shooting_stars_enabled,
            width: w,
            height: h,
            seed_counter: 0.0,
        }
    }

    pub fn resize(&mut self, width: f32, height: f32) {
        let w = width.max(1.0);
        let h = height.max(1.0);
        let changed = (self.width - w).abs() > 1.0 || (self.height - h).abs() > 1.0;
        self.width = w;
        self.height = h;
        if changed {
            self.respawn_stars();
        }
    }

    fn respawn_stars(&mut self) {
        let w = self.width;
        let h = self.height;
        let n = self.stars.len().max(1);
        self.stars.clear();
        self.stars.reserve(n);
        for i in 0..n {
            let seed = i as f32 * 7.111;
            self.stars.push(Star {
                x: rand01(seed) * w,
                y: rand01(seed + 1.0) * h,
                size: rand01(seed + 2.0) * 1.5 + 0.5,
                phase: rand01(seed + 3.0) * std::f32::consts::PI * 2.0,
                phase_speed: (rand01(seed + 4.0) * 0.03 + 0.01) * self.speed,
            });
        }
        self.shooting_stars.clear();
    }

    pub fn tick(&mut self, out: &mut Vec<Particle>) {
        out.clear();

        for star in &mut self.stars {
            star.phase += star.phase_speed;
            let twinkle = ((star.phase.sin() + 1.0) / 2.0) * 0.6 + 0.4;
            out.push(Particle {
                kind: KIND_ELLIPSE_FILLED,
                x: star.x,
                y: star.y,
                a: star.size,
                b: star.size,
                rot: 0.0,
                opacity: twinkle,
                color: self.color,
            });
        }

        if self.shooting_stars_enabled {
            self.seed_counter += 0.456;
            let seed = self.seed_counter;
            if rand01(seed) < 0.008 && self.shooting_stars.len() < 3 {
                self.shooting_stars.push(ShootingStar {
                    x: rand01(seed + 1.0) * self.width,
                    y: rand01(seed + 2.0) * (self.height * 0.4),
                    len: rand01(seed + 3.0) * 80.0 + 40.0,
                    dx: rand01(seed + 4.0) * 4.0 + 4.0,
                    dy: rand01(seed + 5.0) * 2.0 + 2.0,
                    speed: rand01(seed + 6.0) * 6.0 + 6.0,
                    opacity: 1.0,
                });
            }

            let mut i = 0;
            while i < self.shooting_stars.len() {
                let ss = &mut self.shooting_stars[i];
                ss.x += ss.dx * (ss.speed / 5.0);
                ss.y += ss.dy * (ss.speed / 5.0);
                ss.opacity -= 0.025;

                if ss.opacity <= 0.0 || ss.x > self.width || ss.y > self.height {
                    self.shooting_stars.remove(i);
                } else {
                    let vx = ss.dx * (ss.speed / 5.0);
                    let vy = ss.dy * (ss.speed / 5.0);
                    out.push(Particle {
                        kind: KIND_LINE,
                        x: ss.x,
                        y: ss.y,
                        a: ss.x - vx * 1.5,
                        b: ss.y - vy * 1.5,
                        rot: 1.5,
                        opacity: ss.opacity,
                        color: self.color,
                    });
                    i += 1;
                }
            }
        }
    }
}

fn rand01(seed: f32) -> f32 {
    let x = (seed * 12_989.0).sin() * 43_758.5453;
    x - x.floor()
}
