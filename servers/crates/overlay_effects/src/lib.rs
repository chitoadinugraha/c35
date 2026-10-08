mod particle;
mod presets;

use particle::{Particle, PARTICLE_STRIDE};
use presets::autumn_leaves::AutumnLeaves;
use presets::drifting_clouds::DriftingClouds;
use presets::falling_hearts::FallingHearts;
use presets::fireworks::Fireworks;
use presets::floating_bubbles::FloatingBubbles;
use presets::matrix_rain::MatrixRain;
use presets::moonlight::Moonlight;
use presets::rain_shower::RainShower;
use presets::sakura_petals::SakuraPetals;
use presets::snow_fall::SnowFall;
use presets::starry_night::StarryNight;
use presets::thunderstorm::Thunderstorm;
use serde_json::Value;
use wasm_bindgen::prelude::*;

enum Engine {
    Hearts(FallingHearts),
    Rain(RainShower),
    Snow(SnowFall),
    Bubbles(FloatingBubbles),
    Thunder(Thunderstorm),
    Fire(Fireworks),
    Starry(StarryNight),
    Clouds(DriftingClouds),
    Matrix(MatrixRain),
    Sakura(SakuraPetals),
    Moon(Moonlight),
    Leaves(AutumnLeaves),
}

struct State {
    engines: Vec<Engine>,
    scratch: Vec<Particle>,
    buffer: Vec<f32>,
}

static mut STATE: Option<State> = None;

fn state_mut() -> &'static mut State {
    unsafe {
        if STATE.is_none() {
            STATE = Some(State {
                engines: Vec::new(),
                scratch: Vec::new(),
                buffer: Vec::new(),
            });
        }
        STATE.as_mut().unwrap()
    }
}

fn engine_new(preset_id: &str, params: &Value, width: f32, height: f32) -> Option<Engine> {
    Some(match preset_id {
        "falling-hearts" => Engine::Hearts(FallingHearts::new(params, width, height)),
        "rain-shower" => Engine::Rain(RainShower::new(params, width, height)),
        "snow-fall" => Engine::Snow(SnowFall::new(params, width, height)),
        "floating-bubbles" => Engine::Bubbles(FloatingBubbles::new(params, width, height)),
        "thunderstorm" => Engine::Thunder(Thunderstorm::new(params, width, height)),
        "fireworks" => Engine::Fire(Fireworks::new(params, width, height)),
        "starry-night" => Engine::Starry(StarryNight::new(params, width, height)),
        "drifting-clouds" => Engine::Clouds(DriftingClouds::new(params, width, height)),
        "matrix-rain" => Engine::Matrix(MatrixRain::new(params, width, height)),
        "sakura-petals" => Engine::Sakura(SakuraPetals::new(params, width, height)),
        "moonlight" => Engine::Moon(Moonlight::new(params, width, height)),
        "autumn-leaves" => Engine::Leaves(AutumnLeaves::new(params, width, height)),
        _ => return None,
    })
}

fn engine_resize(engine: &mut Engine, width: f32, height: f32) {
    match engine {
        Engine::Hearts(h) => h.resize(width, height),
        Engine::Rain(r) => r.resize(width, height),
        Engine::Snow(x) => x.resize(width, height),
        Engine::Bubbles(x) => x.resize(width, height),
        Engine::Thunder(x) => x.resize(width, height),
        Engine::Fire(x) => x.resize(width, height),
        Engine::Starry(x) => x.resize(width, height),
        Engine::Clouds(x) => x.resize(width, height),
        Engine::Matrix(x) => x.resize(width, height),
        Engine::Sakura(x) => x.resize(width, height),
        Engine::Moon(x) => x.resize(width, height),
        Engine::Leaves(x) => x.resize(width, height),
    }
}

fn engine_tick(engine: &mut Engine, out: &mut Vec<Particle>) {
    match engine {
        Engine::Hearts(h) => h.tick(out),
        Engine::Rain(r) => r.tick(out),
        Engine::Snow(x) => x.tick(out),
        Engine::Bubbles(x) => x.tick(out),
        Engine::Thunder(x) => x.tick(out),
        Engine::Fire(x) => x.tick(out),
        Engine::Starry(x) => x.tick(out),
        Engine::Clouds(x) => x.tick(out),
        Engine::Matrix(x) => x.tick(out),
        Engine::Sakura(x) => x.tick(out),
        Engine::Moon(x) => x.tick(out),
        Engine::Leaves(x) => x.tick(out),
    }
}

fn parse_params(params_json: &str) -> Value {
    serde_json::from_str(params_json).unwrap_or(Value::Object(Default::default()))
}

#[wasm_bindgen]
pub fn overlay_init(preset_id: &str, params_json: &str, width: f32, height: f32) -> bool {
    let s = state_mut();
    s.engines.clear();
    overlay_push(preset_id, params_json, width, height)
}

#[wasm_bindgen]
pub fn overlay_push(preset_id: &str, params_json: &str, width: f32, height: f32) -> bool {
    let params = parse_params(params_json);
    let Some(engine) = engine_new(preset_id, &params, width, height) else {
        return false;
    };
    state_mut().engines.push(engine);
    true
}

#[wasm_bindgen]
pub fn overlay_resize(width: f32, height: f32) {
    let s = state_mut();
    for engine in &mut s.engines {
        engine_resize(engine, width, height);
    }
}

#[wasm_bindgen]
pub fn overlay_tick(_dt: f32) -> usize {
    let s = state_mut();
    s.buffer.clear();
    let mut count = 0usize;
    for engine in &mut s.engines {
        s.scratch.clear();
        engine_tick(engine, &mut s.scratch);
        count += s.scratch.len();
        for p in &s.scratch {
            s.buffer.extend_from_slice(&p.to_wire());
        }
    }
    count
}

#[wasm_bindgen]
pub fn overlay_particles_ptr() -> *const f32 {
    let s = state_mut();
    s.buffer.as_ptr()
}

#[wasm_bindgen]
pub fn overlay_particle_stride() -> usize {
    PARTICLE_STRIDE
}
