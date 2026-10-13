# Windows remote — UAC / unattended elevation (future options)

Status: **options catalog** (not scheduled).  
**Near-term direction (when we implement):** [_/specs/plans/2026-10-13-windows-uac-elevation-remote.md](plans/2026-10-13-windows-uac-elevation-remote.md) — FakerInput bundle, elevation detection, `RemoteSessionPush`, Flutter banner.

**Problem:** On unattended PCs, third-party **UAC** / secure-desktop prompts can **deadlock** automation: DXGI may freeze or hide the dialog, and **`SendInput`** cannot click **Yes**. Detection + honest UI helps; fully unattended approval needs a stronger input (and often capture) plane.

Parent: [remote.md](remote.md), [remote-agent.md](remote-agent.md).

---

## Option A — Bundled third-party virtual HID (FakerInput)

| | |
|--|--|
| **What** | Ship official [FakerInput](https://github.com/Ryochan7/FakerInput/releases) at agent install; route `input_exec` through HID when present. |
| **Pros** | Fastest path; MIT source; upstream MSI/driver already Microsoft-signed; same class as DS4Windows optional driver. |
| **Cons** | **Upstream cert expiry** breaks new installs; redistribution of someone else's signed `.sys`; archived upstream; not our publisher name on Device Manager. |
| **When** | Default **v1** for proving unattended UAC click on fleet VMs. |

---

## Option B — Alien AI–signed virtual HID (fork vmulti / FakerInput / VHF sample)

| | |
|--|--|
| **What** | Fork MIT driver (e.g. [vmulti](https://github.com/djpnewton/vmulti), [vmulti-win11](https://github.com/xaviersykora/vmulti-win11), loki-hidriver, or Microsoft VHF sample); build in CI; **EV + attestation signing** under Alien AI. |
| **Pros** | We control lifecycle, updates, and trust story; no dependency on Ryochan7 cert rotation. |
| **Cons** | Engineering + Hardware Portal pipeline; WHQL optional later; driver blocklist / enterprise policy support burden. |
| **When** | Fleet scale or when Option A cert or policy blocks installs. |

---

## Option C — Licensed commercial SDK (virtual HID + optional display)

| | |
|--|--|
| **What** | Buy redistribution rights, e.g. [spacedesk SDK](https://www.spacedesk.net/products/display-driver-sdk-software-development-kit-for-windows/) (virtual keyboard UMDF + virtual mouse KMDF + indirect display), or OEM deal with [LizardByte libvirtualhid](https://docs.lizardbyte.dev/projects/libvirtualhid/latest/) (signed UMDF + per-machine license today). |
| **Pros** | Signed stack maintained by vendor; spacedesk one-time fee / no royalties (per their marketing); may improve **capture** and input together. |
| **Cons** | Cost; contract; LizardByte license model may not fit silent unattended fleet without OEM terms. |
| **When** | We want one vendor for **pixels + clicks** without owning kernel R&D. |

---

## Option D — Inbound RDP (session remote control)

| | |
|--|--|
| **What** | Enable Windows Remote Desktop (Pro/Enterprise/server SKUs); tunnel **3389** (NLA, no public exposure); Flutter or desktop client shows session framebuffer; session input often handles in-band UAC better than `SendInput`. |
| **Pros** | Well-understood UAC-in-session behavior (policy-dependent); no custom kernel HID for clicks. |
| **Cons** | Not on Windows Home; security/ops (tunnel, auth, licensing); second transport alongside WebRTC; AI computer-use must target RDP bitmap/input or hybrid. |
| **When** | Dedicated **automation VMs** (Pro image) where RDP is acceptable; optional fallback when `elevation_prompt_active` and DXGI blind. |

---

## Option E — Elevation broker (avoid arbitrary UAC)

| | |
|--|--|
| **What** | At provisioning: scheduled task or signed **service** with **highest privileges**; agent sends **allowlisted**, server-signed commands (agent update, known installers, config) over local IPC — **no** spoofing consent UI for random apps. |
| **Pros** | Best security story; reliable for **our** admin operations; no kernel mouse driver for every click. |
| **Cons** | Does **not** click arbitrary third-party UAC (e.g. random installer the model launched). |
| **When** | **Always** complement HID/RDP: reduce how often unattended hits secure desktop. |

---

## Option F — Fleet image / policy (no prompt on automation nodes)

| | |
|--|--|
| **What** | GPO or imaging: lower UAC, "no prompt for admins," dedicated automation accounts, VMs not used as daily-driver PCs. |
| **Pros** | Zero driver work for many internal flows. |
| **Cons** | Unacceptable on consumer laptops; org policy variance; security review. |
| **When** | Owned Hyper-V / datacenter workers only. |

---

## Option G — Capture-only improvements (software scrape)

| | |
|--|--|
| **What** | More DXGI tuning, GDI on elevation, mirror/indirect display drivers, "VLC/ffmpeg-style" desktop grab. |
| **Pros** | Cheap if it works. |
| **Cons** | **Does not** fix secure desktop reliably; same class as today; mirror drivers = still driver + signing. |
| **When** | **Not** primary answer for UAC; only paired with HID (A/B/C) or honest detection UI. |

---

## Option H — Physical / USB HID gadget

| | |
|--|--|
| **What** | Agent drives a USB device that enumerates as real keyboard/mouse (Arduino, Sidekick-style). |
| **Pros** | True hardware input path; works like user's mouse for many UAC cases. |
| **Cons** | Hardware per node or USB-over-IP complexity; not scalable for generic SaaS fleet. |
| **When** | Lab, kiosk, or specialty deployments. |

---

## Decision hints

| Goal | Prefer |
|------|--------|
| Ship something in months | **A** + elevation detect + broker **E** for our updates |
| Long-term owned stack | **B** + **E** |
| Minimize kernel ownership | **C** or **D** on server SKUs |
| Unattended without arbitrary installers | **E** + **F**; do not promise HID for all UAC |
| User sees UAC in app | Detection + capture retry (**plan**); **G** alone insufficient |

---

## Explicit non-options

- **Unsigned kernel driver + "user allows once"** — does not load on typical Secure Boot PCs (unlike signed VBox-style device software).
- **Tetherscript HVDK** — discontinued; no redistribution.
- **Provider-only SendInput tweaks** — will not pass secure desktop.

---

## References (conversation / external)

- FakerInput: https://github.com/Ryochan7/FakerInput  
- vmulti: https://github.com/djpnewton/vmulti  
- libvirtualhid: https://docs.lizardbyte.dev/projects/libvirtualhid/latest/  
- spacedesk SDK: https://www.spacedesk.net/products/display-driver-sdk-software-development-kit-for-windows/
