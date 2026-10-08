use crate::particle::{parse_color, Particle, KIND_ELLIPSE_FILLED};
use serde_json::Value;

struct CloudCircle {
    dx: f32,
    dy: f32,
    r: f32,
}

struct Cloud {
    x: f32,
    y: f32,
    w: f32,
    speed: f32,
    circles: Vec<CloudCircle>,
}

pub struct DriftingClouds {
    clouds: Vec<Cloud>,
    speed: f32,
    color: u32,
    opacity: f32,
    width: f32,
    height: f32,
    seed_counter: f32,
}

impl DriftingClouds {
    pub fn new(params: &Value, width: f32, height: f32) -> Self {
        let density = params.get("density").and_then(|v| v.as_f64()).unwrap_or(4.0) as usize;
        let speed = params.get("speed").and_then(|v| v.as_f64()).unwrap_or(0.4) as f32;
        let color = parse_color(params.get("color").and_then(|v| v.as_str()).unwrap_or("#ffffff"));
        let opacity = params.get("opacity").and_then(|v| v.as_f64()).unwrap_or(0.15) as f32;
        let w = width.max(1.0);
        let h = height.max(1.0);

        let mut seed_counter = 0.0;
        let mut clouds = Vec::with_capacity(density);
        for i in 0..density {
            let start_x = rand01(i as f32 * 3.42) * (w + 300.0) - 150.0;
            let cloud = Self::create_cloud(&mut seed_counter, speed, h, start_x);
            clouds.push(cloud);
        }

        Self {
            clouds,
            speed,
            color,
            opacity,
            width: w,
            height: h,
            seed_counter,
        }
    }

    fn create_cloud(seed_counter: &mut f32, speed: f32, height: f32, start_x: f32) -> Cloud {
        *seed_counter += 1.489;
        let seed = *seed_counter;
        let cloud_y = rand01(seed) * (height * 0.4) + 40.0;
        let num_circles = (rand01(seed + 1.0) * 3.0).floor() as usize + 4;
        let mut circles = Vec::with_capacity(num_circles);

        let mut current_dx = 0.0;
        for j in 0..num_circles {
            let circle_seed = seed + j as f32 * 2.33;
            let r = rand01(circle_seed) * 25.0 + 20.0;
            circles.push(CloudCircle {
                dx: current_dx,
                dy: (rand01(circle_seed + 1.0) - 0.5) * 12.0,
                r,
            });
            current_dx += r * 0.6;
        }

        Cloud {
            x: start_x,
            y: cloud_y,
            w: current_dx + 40.0,
            speed: (rand01(seed + 2.0) * 0.4 + 0.8) * speed,
            circles,
        }
    }

    pub fn resize(&mut self, width: f32, height: f32) {
        self.width = width.max(1.0);
        self.height = height.max(1.0);
    }

    pub fn tick(&mut self, out: &mut Vec<Particle>) {
        out.clear();
        let mut seed = self.seed_counter;
        let speed = self.speed;
        let height = self.height;

        for i in 0..self.clouds.len() {
            self.clouds[i].x += self.clouds[i].speed;

            if self.clouds[i].x > self.width + 50.0 {
                let w = self.clouds[i].w;
                self.clouds[i] = Self::create_cloud(&mut seed, speed, height, -w - 50.0);
            }

            let cloud = &self.clouds[i];
            for c in &cloud.circles {
                out.push(Particle {
                    kind: KIND_ELLIPSE_FILLED,
                    x: cloud.x + c.dx,
                    y: cloud.y + c.dy,
                    a: c.r,
                    b: c.r,
                    rot: 0.0,
                    opacity: self.opacity,
                    color: self.color,
                });
            }
        }

        self.seed_counter = seed;
    }
}

fn rand01(seed: f32) -> f32 {
    let x = (seed * 12_989.0).sin() * 43_758.5453;
    x - x.floor()
}
