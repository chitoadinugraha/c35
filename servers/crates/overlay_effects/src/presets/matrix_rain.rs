use crate::particle::{parse_color, Particle, KIND_GLYPH};
use serde_json::Value;

struct TrailChar {
    y: f32,
    char_code: u32,
    opacity: f32,
}

struct MatrixColumn {
    x: f32,
    y: f32,
    speed: f32,
    ticks_since_last_char: f32,
    trails: Vec<TrailChar>,
}

pub struct MatrixRain {
    cols: Vec<MatrixColumn>,
    density: usize,
    speed: f32,
    font_size: f32,
    color: u32,
    width: f32,
    height: f32,
    alphabet: Vec<u32>,
    seed_counter: f32,
}

impl MatrixRain {
    pub fn new(params: &Value, width: f32, height: f32) -> Self {
        let density = params.get("density").and_then(|v| v.as_f64()).unwrap_or(25.0) as usize;
        let speed = params.get("speed").and_then(|v| v.as_f64()).unwrap_or(6.0) as f32;
        let font_size = params.get("fontSize").and_then(|v| v.as_f64()).unwrap_or(14.0) as f32;
        let color = parse_color(params.get("color").and_then(|v| v.as_str()).unwrap_or("#00ff41"));
        let w = width.max(1.0);
        let h = height.max(1.0);

        let alphabet_str = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
        let alphabet = alphabet_str.chars().map(|c| c as u32).collect::<Vec<_>>();

        let mut instance = Self {
            cols: Vec::new(),
            density,
            speed,
            font_size,
            color,
            width: w,
            height: h,
            alphabet,
            seed_counter: 0.0,
        };

        instance.setup_columns();
        instance
    }

    fn setup_columns(&mut self) {
        self.cols.clear();
        let step = (self.width / self.density as f32).max(12.0);
        for i in 0..self.density {
            let seed = i as f32 * 4.98 + 1.23;
            self.cols.push(MatrixColumn {
                x: i as f32 * step + (rand01(seed) - 0.5) * 5.0,
                y: rand01(seed + 1.0) * -self.height,
                speed: rand01(seed + 2.0) * self.speed + self.speed * 0.5 + 2.0,
                ticks_since_last_char: 0.0,
                trails: Vec::new(),
            });
        }
    }

    fn random_char(seed_counter: &mut f32, alphabet: &[u32]) -> u32 {
        *seed_counter += 0.777;
        let idx = (rand01(*seed_counter) * alphabet.len() as f32) as usize;
        alphabet[idx]
    }

    pub fn resize(&mut self, width: f32, height: f32) {
        self.width = width.max(1.0);
        self.height = height.max(1.0);
        self.setup_columns();
    }

    pub fn tick(&mut self, out: &mut Vec<Particle>) {
        out.clear();
        if self.cols.is_empty() && self.width > 0.0 {
            self.setup_columns();
        }

        let mut seed = self.seed_counter;
        let alphabet = &self.alphabet;

        for col in &mut self.cols {
            col.y += col.speed;
            col.ticks_since_last_char += 1.0;

            if col.ticks_since_last_char > 1.8 {
                let char_code = Self::random_char(&mut seed, alphabet);
                col.trails.push(TrailChar {
                    y: col.y,
                    char_code,
                    opacity: 1.0,
                });
                col.ticks_since_last_char = 0.0;
            }

            let mut j = 0;
            while j < col.trails.len() {
                let trail = &mut col.trails[j];
                trail.opacity -= 0.02;

                if trail.opacity <= 0.0 {
                    col.trails.remove(j);
                } else {
                    out.push(Particle {
                        kind: KIND_GLYPH,
                        x: col.x,
                        y: trail.y,
                        a: self.font_size,
                        b: trail.char_code as f32,
                        rot: 0.0,
                        opacity: trail.opacity,
                        color: self.color,
                    });
                    j += 1;
                }
            }

            let head_char = Self::random_char(&mut seed, alphabet);
            out.push(Particle {
                kind: KIND_GLYPH,
                x: col.x,
                y: col.y,
                a: self.font_size,
                b: head_char as f32,
                rot: 0.0,
                opacity: 1.0,
                color: 0xff_ff_ff_ff,
            });

            if col.y > self.height + 100.0 {
                col.y = rand01(col.x + col.speed) * -100.0;
                col.speed = rand01(col.y) * self.speed + self.speed * 0.5 + 2.0;
                col.trails.clear();
            }
        }

        self.seed_counter = seed;
    }
}

fn rand01(seed: f32) -> f32 {
    let x = (seed * 12_989.0).sin() * 43_758.5453;
    x - x.floor()
}
