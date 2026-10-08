// Generated fallback for assets/effects/presets.json — keep in sync.
const kOverlayEffectPresetsJson = r'''
[
  {
    "id": "falling-hearts",
    "name": "Falling hearts",
    "description": "Romantic hearts drifting down the page",
    "icon": "iconify://mdi:heart",
    "parameters": [
      { "key": "density", "label": "Heart count", "type": "number", "min": 5, "max": 150, "step": 5, "default": 35 },
      { "key": "speed", "label": "Fall speed", "type": "number", "min": 1, "max": 10, "step": 0.5, "default": 2.5 },
      { "key": "size", "label": "Heart size", "type": "number", "min": 10, "max": 48, "step": 2, "default": 22 },
      { "key": "color", "label": "Heart color", "type": "color", "default": "#ff6b81" },
      { "key": "interaction", "label": "Touch interaction", "type": "boolean", "group": "interaction", "default": true },
      { "key": "collect_radius", "label": "Touch reach", "type": "number", "group": "interaction", "min": 24, "max": 120, "step": 4, "default": 48 }
    ]
  },
  {
    "id": "rain-shower",
    "name": "Rain",
    "description": "Falling rain with splashes along the bottom",
    "icon": "iconify://mdi:weather-pouring",
    "parameters": [
      { "key": "density", "label": "Rain density", "type": "number", "min": 10, "max": 300, "step": 10, "default": 80 },
      { "key": "speed", "label": "Rain speed", "type": "number", "min": 5, "max": 25, "step": 1, "default": 14 },
      { "key": "size", "label": "Drop size", "type": "number", "min": 1, "max": 4, "step": 0.25, "default": 2.25 },
      { "key": "splash", "label": "Splashes", "type": "boolean", "default": true },
      { "key": "color", "label": "Rain color", "type": "color", "default": "#aedbf0" },
      { "key": "interaction", "label": "Touch interaction", "type": "boolean", "group": "interaction", "default": true },
      { "key": "touch_radius", "label": "Touch reach", "type": "number", "group": "interaction", "min": 80, "max": 220, "step": 5, "default": 165 },
      { "key": "orbit_size", "label": "Swirl ring size", "type": "number", "group": "interaction", "min": 28, "max": 80, "step": 2, "default": 47 },
      { "key": "swirl_speed", "label": "Swirl speed", "type": "number", "group": "interaction", "min": 0, "max": 100, "step": 5, "default": 40 },
      { "key": "pull_strength", "label": "Pull strength", "type": "number", "group": "interaction", "min": 0, "max": 100, "step": 5, "default": 45 },
      { "key": "clear_size", "label": "Clear center", "type": "number", "group": "interaction", "min": 20, "max": 70, "step": 2, "default": 52 },
      { "key": "touch_below", "label": "Ignore below finger", "type": "number", "group": "interaction", "min": 0, "max": 40, "step": 2, "default": 10 }
    ]
  },
  {
    "id": "snow-fall",
    "name": "Snow",
    "description": "Gentle snowflakes floating down",
    "icon": "iconify://mdi:snowflake",
    "parameters": [
      { "key": "density", "label": "Flake count", "type": "number", "min": 10, "max": 200, "step": 10, "default": 60 },
      { "key": "speed", "label": "Fall speed", "type": "number", "min": 0.5, "max": 4, "step": 0.25, "default": 1.5 },
      { "key": "size", "label": "Flake size", "type": "number", "min": 2, "max": 12, "step": 1, "default": 5 },
      { "key": "color", "label": "Snow color", "type": "color", "default": "#ffffff" },
      { "key": "interaction", "label": "Touch interaction", "type": "boolean", "group": "interaction", "default": true },
      { "key": "touch_radius", "label": "Touch reach", "type": "number", "group": "interaction", "min": 60, "max": 180, "step": 5, "default": 110 },
      { "key": "gust_strength", "label": "Gust strength", "type": "number", "group": "interaction", "min": 10, "max": 100, "step": 5, "default": 50 }
    ]
  },
  {
    "id": "floating-bubbles",
    "name": "Bubbles",
    "description": "Translucent bubbles rising from the bottom",
    "icon": "iconify://mdi:circle-multiple-outline",
    "parameters": [
      { "key": "density", "label": "Bubble count", "type": "number", "min": 5, "max": 80, "step": 5, "default": 20 },
      { "key": "speed", "label": "Rise speed", "type": "number", "min": 0.5, "max": 6, "step": 0.5, "default": 1.8 },
      { "key": "size", "label": "Max bubble size", "type": "number", "min": 8, "max": 50, "step": 2, "default": 24 },
      { "key": "color", "label": "Bubble tint", "type": "color", "default": "#8ae2ff" },
      { "key": "interaction", "label": "Touch interaction", "type": "boolean", "group": "interaction", "default": true },
      { "key": "touch_radius", "label": "Pop radius", "type": "number", "group": "interaction", "min": 40, "max": 160, "step": 5, "default": 90 },
      { "key": "pop_strength", "label": "Pop sensitivity", "type": "number", "group": "interaction", "min": 20, "max": 100, "step": 5, "default": 70 }
    ]
  },
  {
    "id": "thunderstorm",
    "name": "Thunderstorm",
    "description": "Heavy rain with sudden lightning flashes",
    "icon": "iconify://mdi:weather-lightning-rainy",
    "parameters": [
      { "key": "density", "label": "Rain density", "type": "number", "min": 20, "max": 300, "step": 10, "default": 120 },
      { "key": "speed", "label": "Rain speed", "type": "number", "min": 8, "max": 30, "step": 1, "default": 18 },
      { "key": "flashFrequency", "label": "Lightning rate", "type": "number", "min": 1, "max": 10, "step": 1, "default": 4 },
      { "key": "color", "label": "Rain color", "type": "color", "default": "#7faec6" },
      { "key": "interaction", "label": "Touch interaction", "type": "boolean", "group": "interaction", "default": true },
      { "key": "touch_radius", "label": "Charge radius", "type": "number", "group": "interaction", "min": 40, "max": 200, "step": 5, "default": 100 },
      { "key": "charge_rate", "label": "Charge rate", "type": "number", "group": "interaction", "min": 10, "max": 100, "step": 5, "default": 45 },
      { "key": "strike_intensity", "label": "Strike intensity", "type": "number", "group": "interaction", "min": 20, "max": 100, "step": 5, "default": 75 }
    ]
  },
  {
    "id": "fireworks",
    "name": "Fireworks",
    "description": "Colorful bursts that explode and fade across the page",
    "icon": "iconify://mdi:firework",
    "parameters": [
      { "key": "frequency", "label": "Burst rate", "type": "number", "min": 1, "max": 8, "step": 1, "default": 3 },
      { "key": "particles", "label": "Particles per burst", "type": "number", "min": 20, "max": 100, "step": 10, "default": 50 },
      { "key": "size", "label": "Particle size", "type": "number", "min": 1.5, "max": 6, "step": 0.5, "default": 3 },
      { "key": "gravity", "label": "Gravity", "type": "number", "min": 0.02, "max": 0.15, "step": 0.01, "default": 0.06 },
      { "key": "interaction", "label": "Touch interaction", "type": "boolean", "group": "interaction", "default": true },
      { "key": "touch_radius", "label": "Tap burst size", "type": "number", "group": "interaction", "min": 20, "max": 80, "step": 5, "default": 40 },
      { "key": "burst_particles", "label": "Tap particles", "type": "number", "group": "interaction", "min": 20, "max": 120, "step": 10, "default": 60 }
    ]
  },
  {
    "id": "starry-night",
    "name": "Starry night",
    "description": "Twinkling stars and shooting stars crossing the sky",
    "icon": "iconify://mdi:weather-night",
    "parameters": [
      { "key": "density", "label": "Star count", "type": "number", "min": 10, "max": 200, "step": 10, "default": 60 },
      { "key": "speed", "label": "Twinkle speed", "type": "number", "min": 0.1, "max": 2, "step": 0.1, "default": 0.6 },
      { "key": "color", "label": "Star color", "type": "color", "default": "#ffffff" },
      { "key": "shootingStars", "label": "Shooting stars", "type": "boolean", "default": true },
      { "key": "interaction", "label": "Touch interaction", "type": "boolean", "group": "interaction", "default": true },
      { "key": "touch_radius", "label": "Twinkle reach", "type": "number", "group": "interaction", "min": 60, "max": 220, "step": 5, "default": 140 },
      { "key": "twinkle_boost", "label": "Twinkle boost", "type": "number", "group": "interaction", "min": 20, "max": 100, "step": 5, "default": 65 }
    ]
  },
  {
    "id": "drifting-clouds",
    "name": "Drifting clouds",
    "description": "Soft, fluffy clouds floating lazily across the screen",
    "icon": "iconify://mdi:weather-cloudy",
    "parameters": [
      { "key": "density", "label": "Cloud count", "type": "number", "min": 2, "max": 12, "step": 1, "default": 4 },
      { "key": "speed", "label": "Cloud speed", "type": "number", "min": 0.1, "max": 2, "step": 0.1, "default": 0.4 },
      { "key": "color", "label": "Cloud color", "type": "color", "default": "#ffffff" },
      { "key": "opacity", "label": "Cloud opacity", "type": "number", "min": 0.05, "max": 0.6, "step": 0.05, "default": 0.15 },
      { "key": "interaction", "label": "Touch interaction", "type": "boolean", "group": "interaction", "default": true },
      { "key": "touch_radius", "label": "Wind reach", "type": "number", "group": "interaction", "min": 80, "max": 280, "step": 10, "default": 180 },
      { "key": "gust_strength", "label": "Gust strength", "type": "number", "group": "interaction", "min": 10, "max": 100, "step": 5, "default": 40 },
      { "key": "drag_strength", "label": "Drag strength", "type": "number", "group": "interaction", "min": 10, "max": 100, "step": 5, "default": 55 }
    ]
  },
  {
    "id": "matrix-rain",
    "name": "Matrix rain",
    "description": "Cascading columns of glowing digital code characters",
    "icon": "iconify://mdi:matrix",
    "parameters": [
      { "key": "density", "label": "Rain columns", "type": "number", "min": 5, "max": 60, "step": 5, "default": 25 },
      { "key": "speed", "label": "Drop speed", "type": "number", "min": 1, "max": 15, "step": 1, "default": 6 },
      { "key": "fontSize", "label": "Font size", "type": "number", "min": 8, "max": 24, "step": 1, "default": 14 },
      { "key": "color", "label": "Glow color", "type": "color", "default": "#00ff41" },
      { "key": "interaction", "label": "Touch interaction", "type": "boolean", "group": "interaction", "default": true },
      { "key": "touch_radius", "label": "Glitch reach", "type": "number", "group": "interaction", "min": 40, "max": 200, "step": 5, "default": 120 },
      { "key": "glitch_intensity", "label": "Glitch intensity", "type": "number", "group": "interaction", "min": 20, "max": 100, "step": 5, "default": 60 },
      { "key": "glitch_columns", "label": "Columns affected", "type": "number", "group": "interaction", "min": 1, "max": 8, "step": 1, "default": 3 }
    ]
  },
  {
    "id": "sakura-petals",
    "name": "Sakura petals",
    "description": "Soft pink cherry blossom petals fluttering and spinning down",
    "icon": "iconify://mdi:flower",
    "parameters": [
      { "key": "density", "label": "Petal count", "type": "number", "min": 5, "max": 100, "step": 5, "default": 25 },
      { "key": "speed", "label": "Fall speed", "type": "number", "min": 0.5, "max": 5, "step": 0.5, "default": 1.8 },
      { "key": "size", "label": "Petal size", "type": "number", "min": 6, "max": 20, "step": 1, "default": 12 },
      { "key": "color", "label": "Petal color", "type": "color", "default": "#ffb7c5" },
      { "key": "interaction", "label": "Touch interaction", "type": "boolean", "group": "interaction", "default": true },
      { "key": "touch_radius", "label": "Touch reach", "type": "number", "group": "interaction", "min": 60, "max": 200, "step": 5, "default": 130 },
      { "key": "gust_strength", "label": "Gust strength", "type": "number", "group": "interaction", "min": 10, "max": 100, "step": 5, "default": 45 },
      { "key": "swirl_strength", "label": "Swirl strength", "type": "number", "group": "interaction", "min": 10, "max": 100, "step": 5, "default": 50 }
    ]
  },
  {
    "id": "moonlight",
    "name": "Moonlight",
    "description": "A glowing moon with gentle moonbeams and floating dust",
    "icon": "iconify://mdi:moon-waning-crescent",
    "parameters": [
      { "key": "density", "label": "Dust count", "type": "number", "min": 5, "max": 60, "step": 5, "default": 20 },
      { "key": "moonColor", "label": "Moon color", "type": "color", "default": "#fffbe3" },
      { "key": "showMoon", "label": "Show moon", "type": "boolean", "default": true },
      { "key": "glowIntensity", "label": "Glow intensity", "type": "number", "min": 1, "max": 10, "step": 1, "default": 5 },
      { "key": "interaction", "label": "Touch interaction", "type": "boolean", "group": "interaction", "default": true },
      { "key": "touch_radius", "label": "Glow reach", "type": "number", "group": "interaction", "min": 60, "max": 240, "step": 5, "default": 150 },
      { "key": "glow_boost", "label": "Touch glow boost", "type": "number", "group": "interaction", "min": 20, "max": 100, "step": 5, "default": 60 }
    ]
  },
  {
    "id": "autumn-leaves",
    "name": "Autumn leaves",
    "description": "Colorful leaves drifting down with a gentle sway",
    "icon": "iconify://mdi:leaf",
    "parameters": [
      { "key": "density", "label": "Leaf count", "type": "number", "min": 5, "max": 100, "step": 5, "default": 30 },
      { "key": "speed", "label": "Fall speed", "type": "number", "min": 0.5, "max": 6, "step": 0.5, "default": 2 },
      { "key": "size", "label": "Leaf size", "type": "number", "min": 12, "max": 40, "step": 2, "default": 24 },
      { "key": "color", "label": "Leaf tint", "type": "color", "default": "#e67e22" },
      { "key": "interaction", "label": "Touch interaction", "type": "boolean", "group": "interaction", "default": true },
      { "key": "touch_radius", "label": "Touch reach", "type": "number", "group": "interaction", "min": 60, "max": 200, "step": 5, "default": 130 },
      { "key": "gust_strength", "label": "Gust strength", "type": "number", "group": "interaction", "min": 10, "max": 100, "step": 5, "default": 45 },
      { "key": "swirl_strength", "label": "Swirl strength", "type": "number", "group": "interaction", "min": 10, "max": 100, "step": 5, "default": 50 }
    ]
  }
]
''';
