#!/usr/bin/env python3
"""
One-figure ΔΔG visualisation for chain B (viral target).
• Row 1 : full profile (zoom windows shaded) – no residue labels
• Rows 2..N : One zoom row **per region** (from --regions or --auto-zoom), with residue labels
All zoom panels share the same y-axis limits.

Compared to the chain-A CDR plotter, this version:
  - Defaults to chain B (viral).
  - Uses generic "regions" instead of antibody CDRs.
  - Lets you provide named regions, OR auto-picks hotspots by |ΔΔG| with rolling windows.
  - Global positional restriction with --start / --end (e.g., only plot 50–200).
  - **Dynamic layout**: number of zoom panels scales with number of regions.

Examples:
  # Use explicit regions (name:start-end) and restrict to 50–200
  python YOUR_SCRIPT.py interactions-summary.tsv \
      --chain B \
      --start 50 --end 200 \
      --regions "Region1:120-140,Region2:160-175,Region3:185-195" \
      --out fig_B.png

  # Auto-pick top 3 hotspots (default), 11-residue windows, but only within 50–200
  python YOUR_SCRIPT.py interactions-summary.tsv --chain B --start 50 --end 200 --out fig_B.png

  # Auto-pick 5 hotspots with 15-residue windows on full range (will create 5 zoom rows)
  python YOUR_SCRIPT.py interactions-summary.tsv --auto-zoom 5 --window 15
"""

import argparse
from pathlib import Path
import re
from typing import List, Tuple, Dict

import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

# ────────── sensible defaults ──────────
FONTSIZE  = 14
LABEL_OFF = 0.25
FIGSIZE   = (12, 10)  # minimum size; height will grow with number of regions
PAD_Y     = 0.3
TOP_H     = 3.5  # extra height for the full profile panel
ZOOM_H    = 2.3  # height added per zoom panel

# ────────── helpers ──────────
def parse_regions(spec: str) -> Dict[str, Tuple[int, int]]:
    """Parse a region spec string: "Name1:10-20,Name2:30-40"."""
    regions = {}
    if not spec:
        return regions
    parts = [p.strip() for p in spec.split(",") if p.strip()]
    for p in parts:
        m = re.match(r"([^:]+)\s*:\s*(\d+)\s*-\s*(\d+)$", p)
        if not m:
            raise ValueError(f"Bad region format: '{p}'. Use Name:start-end")
        name, s, e = m.group(1).strip(), int(m.group(2)), int(m.group(3))
        if e < s:
            s, e = e, s
        regions[name] = (s, e)
    return regions


def auto_hotspot_windows(df: pd.DataFrame, k: int, width: int, pos_min: int, pos_max: int) -> Dict[str, Tuple[int, int]]:
    """Pick up to k non-overlapping windows of given width around positions with largest |ΔΔG|.
    Greedy selection; returns dict like {"Region1": (s, e), ...} sorted by start.
    Windows are clamped to [pos_min, pos_max].
    """
    if k <= 0 or df.empty:
        return {}

    half = max(1, width // 2)
    ranked = df.assign(absE=df["dif_energy"].abs()).sort_values("absE", ascending=False)[["pos", "absE"]]

    windows: List[Tuple[int, int]] = []
    for _, row in ranked.iterrows():
        p = int(row["pos"])  # position
        s = p - half
        e = p + half
        # Check overlap with existing windows (allow small gaps to merge)
        overlaps = False
        for i, (s0, e0) in enumerate(windows):
            if not (e < s0 - 1 or s > e0 + 1):  # overlaps or touches
                # Merge into existing window
                windows[i] = (min(s0, s), max(e0, e))
                overlaps = True
                break
        if not overlaps:
            windows.append((s, e))
        # Stop when we have enough *distinct* windows
        if len(windows) >= k:
            break

    # Clamp to provided positional bounds and normalise
    windows = [(max(pos_min, s), min(pos_max, e)) for (s, e) in windows]
    windows = [(s, e) for (s, e) in windows if s <= e]
    windows.sort(key=lambda t: t[0])
    return {f"Region{i}": w for i, w in enumerate(windows, start=1)}


# ────────── CLI ──────────
ap = argparse.ArgumentParser()
ap.add_argument("tsv", help="FoldX-style TSV (chain, pos, res, dif_energy)")
ap.add_argument("--chain", default="B", help="Chain ID (default: B)")
ap.add_argument("--regions", default=None, help="Comma-separated region spec: 'Name1:s-e,Name2:s-e' (overrides auto)")
ap.add_argument("--auto-zoom", type=int, default=3, help="Number of auto hotspot windows if --regions not given (default: 3)")
ap.add_argument("--window", type=int, default=11, help="Window width for auto hotspot selection (default: 11)")
ap.add_argument("--max-pos", type=int, default=None, help="[Deprecated] Optional positional cutoff (e.g., 129). Prefer --end.")
ap.add_argument("--start", type=int, default=None, help="Global minimum position to include (inclusive), e.g., 50")
ap.add_argument("--end", type=int, default=None, help="Global maximum position to include (inclusive), e.g., 200")
ap.add_argument("--title", default="Target", help="Title prefix shown in panel tags (default: Target)")
ap.add_argument("--out", default=None, help="Optional output file")
args = ap.parse_args()

# ────────── load data ──────────
df = pd.read_csv(args.tsv, sep="\t", dtype=str)
df = df[df["chain"] == args.chain].copy()
if df.empty:
    raise SystemExit(f"No rows for chain '{args.chain}' in {args.tsv}")

df["pos"]        = pd.to_numeric(df["pos"], errors="coerce")
df["dif_energy"] = pd.to_numeric(df["dif_energy"], errors="coerce")
df                = df.dropna(subset=["pos", "dif_energy", "res"]).copy()

# Legacy cap
if args.max_pos is not None:
    df = df[df["pos"] <= args.max_pos]

# Apply global positional restrictions
if args.start is not None:
    df = df[df["pos"] >= args.start]
if args.end is not None:
    df = df[df["pos"] <= args.end]

# Sort & deduplicate by position
df = df.sort_values("pos").drop_duplicates("pos")

if df.empty:
    raise SystemExit("No data remain after applying --start/--end filters.")

# Bounds of the filtered data
pos_min = int(df["pos"].min())
pos_max = int(df["pos"].max())

# ────────── determine regions ──────────
if args.regions:
    REGIONS: Dict[str, Tuple[int, int]] = parse_regions(args.regions)
else:
    REGIONS = auto_hotspot_windows(df, k=args.auto_zoom, width=args.window, pos_min=pos_min, pos_max=pos_max)

if not REGIONS:
    # Fallback: single window spanning all data
    REGIONS = {"Region1": (pos_min, pos_max)}

# ────────── layout (dynamic rows) ──────────
num_regions = len(REGIONS)
fig_height = max(FIGSIZE[1], TOP_H + ZOOM_H * num_regions)
fig, axes = plt.subplots(
    nrows=1 + num_regions,
    ncols=1,
    figsize=(FIGSIZE[0], fig_height),
    gridspec_kw=dict(height_ratios=[2.5] + [1]*num_regions, hspace=0.45)
)

# Ensure axes is always an array for consistent indexing (robust across pandas versions)
axes = np.atleast_1d(axes).ravel()
# ────────── 1) full profile ──────────
ax = axes[0]
ax.plot(df["pos"], df["dif_energy"], marker="o", linestyle="-", color="tab:blue")
for _, (s, e) in REGIONS.items():
    s2, e2 = max(pos_min, s), min(pos_max, e)
    if s2 <= e2:
        ax.axvspan(s2, e2, color="grey", alpha=0.3)

ax.set_ylabel("ΔΔG (kcal/mol)", fontsize=FONTSIZE)
ax.set_xlabel("Position",         fontsize=FONTSIZE)
ax.tick_params(labelsize=FONTSIZE)
ax.grid(True)
ax.text(1.02, 0.5, f"PDB: {args.title}", rotation=90, ha="left", va="center",
        fontsize=FONTSIZE, transform=ax.transAxes,
        bbox=dict(facecolor="white", edgecolor="black"))
ax.set_xlim(pos_min, pos_max)

# ────────── compute common y-scale for all zooms ──────────
zoom_slices = []
for (s, e) in REGIONS.values():
    z = df[df["pos"].between(max(pos_min, s), min(pos_max, e))]
    if not z.empty:
        zoom_slices.append(z)

if zoom_slices:
    all_zoom = pd.concat(zoom_slices)
else:
    all_zoom = df.copy()

ylim_lo  = all_zoom["dif_energy"].min() - PAD_Y
ylim_hi  = all_zoom["dif_energy"].max() + PAD_Y

# ────────── 2..N) zoom panels with uniform y-limits ──────────
for idx, (name, (s, e)) in enumerate(REGIONS.items(), start=1):
    ax  = axes[idx]
    zdf = df[df["pos"].between(max(pos_min, s), min(pos_max, e))]
    ax.plot(zdf["pos"], zdf["dif_energy"], marker="o", linestyle="-", color="tab:blue")

    # annotate residues
    for _, r in zdf.iterrows():
        ax.text(r["pos"], r["dif_energy"] + LABEL_OFF,
                f"{int(r['pos'])} {r['res']}",
                fontsize=FONTSIZE, ha="center", rotation=45)

    ax.set_ylabel("ΔΔG\n(kcal/mol)", fontsize=FONTSIZE)
    ax.set_xlabel("Position",         fontsize=FONTSIZE)
    ax.tick_params(labelsize=FONTSIZE)
    ax.grid(True)
    ax.text(1.02, 0.5, f"PDB: {args.title} {name}", rotation=90,
            ha="left", va="center", fontsize=FONTSIZE,
            transform=ax.transAxes,
            bbox=dict(facecolor="white", edgecolor="black"))
    ax.set_ylim(ylim_lo, ylim_hi)

# ────────── finish ──────────
plt.tight_layout()
if args.out:
    out = Path(args.out).with_suffix(Path(args.out).suffix or ".png")
    fig.savefig(out, dpi=300, bbox_inches="tight")
    print(f"Saved figure → {out.resolve()}")
else:
    plt.show()

