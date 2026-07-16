# XternalZ

External overlay ESP for Standoff 2 on iOS. It's a standalone TrollStore HUD app
that reads the game's memory from the outside (no injection, no dylib in the game)
and draws the ESP in its own window on top.

> For educational / research use only. Don't be a dick with it.

## What it does

- **ESP** — 2D box, snaplines, vertical health bar, name and weapon labels.
- **Team check** — hide teammates (toggle).
- **Material chams** — recolors enemy models solid purple via the "missing material"
  trick. No through-walls (that needs an in-process build — see notes below).
- **Stealth overlay** — hide the menu + ESP from screenshots and screen recording.
  Chams stays visible (it's the game's own render), so your clips look clean.
- **ImGui menu** — Metal-rendered, touch-friendly, lives in the left half of the screen.

Everything is controlled from the in-game overlay menu. ESP is drawn with
`CAShapeLayer` + `UILabel` pools, the menu is Dear ImGui on Metal.

## How it works

The HUD runs as its own app and grabs the game's task port via `task_for_pid`
(falls back to `processor_set_tasks`). From there it reads player structs straight
out of memory — health/team come from the Photon custom props, positions from the
move controller, and WorldToScreen uses the camera view matrix. The HUD window is
locked to portrait while the game renders landscape, so the ESP container just gets
rotated to match the device orientation.

Offsets are for **Standoff 2 on Unity 2022.3.69f1 (arm64, il2cpp)**, dump `0382`.
Game updates will break them.

**Stealth overlay** uses the classic iOS secure-layer trick: a hidden
`UITextField` with `secureTextEntry` owns a canvas layer the render server keeps
out of the captured framebuffer. When you toggle stealth on, the menu and ESP
container get reparented into that layer, so they're on-screen but invisible to
screenshots and recordings. Chams isn't ours to hide — it's the game rendering the
recolored model — so it shows up normally, which is the point.

## Build

Needs [theos](https://theos.dev/) and an arm64 toolchain.

```bash
make package
```

Output lands in `packages/XternalZ.tipa`. Sideload it with TrollStore. The app is
signed with `ent.plist` for the entitlements it needs (`task_for_pid-allow`, etc.).

## Status / TODO

- Chams **through walls** doesn't work from the external app — `ZTest` is baked into
  the shader and can't be flipped reliably with external memory writes. Real
  through-wall chams needs an **in-process** build that can call Unity's Material API
  or swap the shader.
- Stealth overlay needs on-device verification with the Metal menu — UIKit ESP layers
  hide for sure, but Metal content under the secure layer should be double-checked on
  a real recording.
- Offsets need re-dumping on every game update.

## Layout

- `objc_base/HUDMainApplication.mm` — HUD app, the ESP draw loop, stealth, all the `SO2_Read*` readers.
- `objc_base/HUDApp.mm` / `MainApplication.mm` — app entry + launcher UI.
- `imgui/ImGuiDrawView.mm` — the ImGui menu.
- `imgui/ESPImGuiView.mm` — menu state + the overlay container.
- `esp/helpers/` — task port / pid helpers. `esp/unity_api/` — memory read/write + WorldToScreen.

Offsets came from an il2cpp dump of build `0382` (not bundled — it's huge).

## Disclaimer

This is a learning project about iOS memory access and Unity internals. Using it on
live servers will likely get your account banned. Your call, your risk.
