# VeinGuard - Biological Tower Defense

Game *tower-defense* bergaya *card-battle* (mirip Clash Royale) dengan tema biologi, berfokus pada pertahanan sistem imun tubuh manusia (sel darah) melawan infeksi patogen (bakteri dan virus).

---

## Stack

| Layer | Tech |
|---|---|
| Game Engine | Godot Engine 4.x |
| Scripting Language | GDScript |
| Architecture | State Machine (FSM), Object-Oriented, Modular |
| UI/HUD | Godot Control Nodes, CanvasLayer |
| Game State | Autoloads (Singletons) |

---

## Struktur Repo

```
veinguard/
├-- core/         # Sistem utama (Autoloads, UI, Base Classes, Shaders, Resources)
├-- units/        # Direktori modular untuk semua entitas karakter
│   ├-- player/   # Pasukan imun (Eritrosit, NKiller, Trombosit, dll)
│   └-- enemies/  # Patogen penyerang (Bacteria, Virus, dll)
├-- audio/        # (Future) Aset SFX & Music
└-- Main.tscn     # Entry point scene / Arena pertempuran
```

---

## Dokumentasi

| Doc | Path |
|---|---|
| Roadmap Pengembangan & Panduan Fase (MVP) | [`CLAUDE.md`](CLAUDE.md) |
| Base Unit FSM Architecture | [`core/unit_base.gd`](core/unit_base.gd) |
| Unit Stats Resources | [`core/resources/UnitStats.gd`](core/resources/UnitStats.gd) |

---

## Menjalankan Secara Lokal

Karena VeinGuard dibangun menggunakan Godot Engine, tidak perlu instalasi `npm` atau *build tools* eksternal.

1. Unduh dan install **Godot Engine 4.x**.
2. Buka Godot Editor, klik tombol **Import**.
3. Arahkan ke file `project.godot` di dalam folder repo ini.
4. Klik **Import & Edit**.
5. Tekan tombol `F5` pada keyboard atau klik tombol **Play (▶️)** di pojok kanan atas editor untuk menjalankan game.

---

## Konvensi Kode

**Arsitektur & Scene**
- `core/autoloads/` - Tempat menyimpan Singleton/Global scripts (`GameManager.gd`, dll).
- `core/unit_base.gd` - Class utama pengatur *State Machine* (IDLE, MOVE, ATTACK). **Semua unit karakter wajib meng-extend class ini**.
- `units/` - Dibuat **sangat modular**. Satu karakter = satu folder (berisi file `.gd`, `.tscn`, dan stat resource `.tres`).

**Naming Rules (Berdasarkan standar GDScript)**
- **Class / Nodes / Scene**: PascalCase (Contoh: `KillerT.tscn`, `EnemyBase`)
- **Fungsi / Variabel**: snake_case (Contoh: `current_target`, `take_damage()`)
- **Private Variables / Functions**: Diawali underscore (Contoh: `_process_attack()`, `_charge_timer`)
- **Konstanta**: UPPER_SNAKE_CASE (Contoh: `MAX_OXYGEN`)
- **Resource Data**: snake_case (Contoh: `killert_stats.tres`)

---

## Branching

```
main          # production-ready code only (versi stabil / playable)
dev           # active development, PR target
feature/xxx   # fitur baru (misal: feature/virus-enemy, feature/deck-system)
fix/xxx       # bug fix (misal: fix/dash-collision)
```

Jangan langsung push ke `main`. Buat PR ke `dev`, lakukan *playtest* dan minta *review* sebelum di-merge.

---

## Tim

Dikembangkan oleh Kelompok GKV **12 Mipa 1**.
Mendukung kolaborasi tim secara modular (desainer/programmer lain cukup fokus di folder karakter masing-masing).
