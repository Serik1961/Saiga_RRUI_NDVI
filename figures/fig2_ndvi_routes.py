#!/usr/bin/env python3
"""
Figure 2. Growing-season mean NDVI (May-September) and GPS migration routes of
saiga antelopes in the core study districts, West Kazakhstan Region.

Publication layout: 2 x 2 grid at double-column width (180 mm).
  A = 2016, B = 2020, C = 2024, D = key (colourbar, route/boundary legend,
  scale bar, north arrow).  Every panel is ~88 mm wide, so 7-pt text stays
  legible at printed size.

USAGE
  python fig2_ndvi_routes.py --demo                      # synthetic test data
  python fig2_ndvi_routes.py                             # real data (edit PATHS)

OUTPUT
  NOTE: inputs (GPS routes from the Atlas of Ungulate Migration, district
  boundaries, growing-season NDVI GeoTIFFs exported by GEE/01_MOD13Q1_NDVI_MaySep.js)
  are not redistributed in this repository; set PATHS below.

  Figure2.pdf   (vector routes/text, NDVI raster embedded)  -> for typesetting
  Figure2.tiff  (600 dpi, LZW)                              -> for submission
  Figure2.png   (300 dpi preview)
"""
import argparse
import numpy as np
import matplotlib as mpl
import matplotlib.pyplot as plt
import matplotlib.patheffects as pe
from matplotlib.gridspec import GridSpec
from matplotlib.lines import Line2D
import geopandas as gpd

# ----------------------------------------------------------------------------
# 1. SETTINGS
# ----------------------------------------------------------------------------
PATHS = {
    "districts": "districts_core.gpkg",          # column NAME_COL with district names
    "routes":    "saiga_routes.gpkg",            # LineStrings; columns: year, animal_id
    "ndvi": {2016: "ndvi_2016_MaySep_mean.tif",  # MODIS MOD13Q1, growing-season mean
             2020: "ndvi_2020_MaySep_mean.tif",
             2024: "ndvi_2024_MaySep_mean.tif"},
}
NAME_COL = "name"
YEARS = [2016, 2020, 2024]
TITLES = {2016: "(A) 2016 \u2013 highest mean NDVI",
          2020: "(B) 2020 \u2013 lowest mean NDVI",
          2024: "(C) 2024 \u2013 most recent year"}
# Label offsets (deg lon, deg lat) to keep district names off the densest tracks
LABEL_SHIFT = {"Zhanybek": (0, 0), "Kaztal": (0, 0), "Akzhaik": (0, 0),
               "Bokey Orda": (0, 0), "Zhanakala": (0, 0)}

EXTENT = (46.0, 53.8, 47.5, 51.5)   # lon_min, lon_max, lat_min, lat_max
CMAP = "RdYlGn"                     # keep as in earlier figures; try "YlGn" for
                                    # colour-blind / greyscale-safe printing
VMIN, VMAX = 0.05, 0.55
ROUTE_COLOR = "#3b0f70"             # dark violet: contrasts with red AND green
ROUTE_LW, CASING_LW = 1.1, 2.4      # white casing keeps lines visible on any NDVI
FIG_W_IN, FIG_H_IN = 7.09, 6.6      # 180 mm double column

mpl.rcParams.update({
    "font.family": "sans-serif",
    "font.sans-serif": ["Arial", "Helvetica", "DejaVu Sans"],
    "font.size": 8, "axes.labelsize": 8.5, "axes.titlesize": 9.5,
    "xtick.labelsize": 7.5, "ytick.labelsize": 7.5,
    "axes.linewidth": 0.8, "xtick.major.width": 0.8, "ytick.major.width": 0.8,
    "xtick.major.size": 3, "ytick.major.size": 3,
    "pdf.fonttype": 42, "ps.fonttype": 42,     # embed TrueType, editable text
})

HALO = [pe.withStroke(linewidth=2.6, foreground="white")]

# ----------------------------------------------------------------------------
# 2. DATA
# ----------------------------------------------------------------------------
def load_real():
    import rasterio
    districts = gpd.read_file(PATHS["districts"]).to_crs(4326)
    routes = gpd.read_file(PATHS["routes"]).to_crs(4326)
    ndvi = {}
    for y, p in PATHS["ndvi"].items():
        with rasterio.open(p) as src:
            arr = src.read(1, masked=True).astype(float)
            b = src.bounds
            ndvi[y] = (arr, (b.left, b.right, b.bottom, b.top))
    return districts, routes, ndvi


def load_demo():
    """Synthetic stand-in so the layout can be tested without the real data."""
    from shapely.geometry import Polygon, LineString
    from scipy.ndimage import gaussian_filter
    rng = np.random.default_rng(1)
    polys = {
        "Zhanybek":   Polygon([(46.4, 48.4), (46.6, 49.6), (48.0, 50.4), (48.9, 49.3), (48.3, 48.3)]),
        "Kaztal":     Polygon([(48.0, 50.4), (49.5, 50.8), (50.6, 50.0), (49.2, 49.0), (48.9, 49.3)]),
        "Akzhaik":    Polygon([(49.5, 50.8), (52.4, 50.5), (53.4, 49.0), (51.0, 48.6), (50.6, 50.0)]),
        "Bokey Orda": Polygon([(46.9, 48.2), (48.3, 48.3), (49.2, 49.0), (49.4, 48.0), (47.4, 47.7)]),
        "Zhanakala":   Polygon([(49.2, 49.0), (50.6, 50.0), (51.0, 48.6), (49.4, 48.0)]),
    }
    districts = gpd.GeoDataFrame({NAME_COL: list(polys)}, geometry=list(polys.values()), crs=4326)
    ny, nx = 400, 390
    base = gaussian_filter(rng.normal(size=(ny, nx)), 25)
    base = (base - base.min()) / (base.max() - base.min())
    gx = np.linspace(0, 1, nx)[None, :]
    ndvi = {}
    for y, level in zip(YEARS, [0.36, 0.22, 0.30]):
        ndvi[y] = (level + 0.18 * (base - .5) + 0.12 * (gx - .5), EXTENT)
    n = {2016: 5, 2020: 3, 2024: 14}
    rows = []
    for y in YEARS:
        for i in range(n[y]):
            x0, y0 = rng.uniform(46.8, 49), rng.uniform(48.3, 50)
            steps = rng.normal(0, .12, size=(60, 2)).cumsum(0) * [1, .6]
            rows.append({"year": y, "animal_id": i, "geometry": LineString(np.c_[x0 + steps[:, 0], y0 + steps[:, 1]])})
    routes = gpd.GeoDataFrame(rows, crs=4326)
    return districts, routes, ndvi

# ----------------------------------------------------------------------------
# 3. HELPERS
# ----------------------------------------------------------------------------
def lon_fmt(v, _):  return f"{v:.0f}\u00b0E"
def lat_fmt(v, _):  return f"{v:.0f}\u00b0N"


def add_scale_bar(ax, length_km=100, loc=(0.06, 0.06), lat0=49.3):
    """Scale bar in km for geographic coordinates (length in lon at lat0)."""
    dlon = length_km / (111.32 * np.cos(np.deg2rad(lat0)))
    x0 = ax.get_xlim()[0] + loc[0] * np.diff(ax.get_xlim())[0]
    y0 = ax.get_ylim()[0] + loc[1] * np.diff(ax.get_ylim())[0]
    ax.plot([x0, x0 + dlon], [y0, y0], color="k", lw=2.2, solid_capstyle="butt", zorder=9)
    ax.text(x0 + dlon / 2, y0 + 0.07, f"{length_km} km", ha="center", va="bottom",
            fontsize=7.5, path_effects=HALO, zorder=9)


def add_north_arrow(ax, loc=(0.94, 0.86)):
    xl, yl = ax.get_xlim(), ax.get_ylim()
    x = xl[0] + loc[0] * (xl[1] - xl[0]); y = yl[0] + loc[1] * (yl[1] - yl[0])
    ax.annotate("N", xy=(x, y), xytext=(x, y - 0.55), ha="center", va="bottom",
                fontsize=9, fontweight="bold", path_effects=HALO,
                arrowprops=dict(arrowstyle="-|>", lw=1.3, color="k"), zorder=9)


def clip_to_districts(im, ax, districts):
    """Show NDVI only inside the study districts (white background outside)."""
    from matplotlib.path import Path
    from matplotlib.patches import PathPatch
    verts, codes = [], []
    geoms = districts.geometry.union_all() if hasattr(districts.geometry, "union_all") else districts.unary_union
    for poly in getattr(geoms, "geoms", [geoms]):
        for ring in [poly.exterior, *poly.interiors]:
            xy = np.asarray(ring.coords)
            verts += list(xy); codes += [Path.MOVETO] + [Path.LINETO] * (len(xy) - 2) + [Path.CLOSEPOLY]
    patch = PathPatch(Path(verts, codes), transform=ax.transData, fc="none", ec="none")
    ax.add_patch(patch); im.set_clip_path(patch)


def draw_panel(ax, year, districts, routes, ndvi, first_col, last_row):
    arr, ext = ndvi[year]
    im = ax.imshow(arr, extent=ext, origin="upper", cmap=CMAP, vmin=VMIN, vmax=VMAX,
                   interpolation="nearest", zorder=1, aspect="auto", rasterized=True)
    clip_to_districts(im, ax, districts)
    districts.boundary.plot(ax=ax, color="k", linewidth=1.0, zorder=4)
    r = routes[routes["year"] == year]
    r.plot(ax=ax, color="white", linewidth=CASING_LW, alpha=.85, zorder=5)   # casing
    r.plot(ax=ax, color=ROUTE_COLOR, linewidth=ROUTE_LW, zorder=6)
    for _, row in districts.iterrows():
        c = row.geometry.representative_point()
        dx, dy = LABEL_SHIFT.get(row[NAME_COL], (0, 0))
        ax.text(c.x + dx, c.y + dy, row[NAME_COL].replace(" ", "\n"), ha="center", va="center",
                fontsize=7.5, fontweight="bold", path_effects=HALO, zorder=8)
    n_ind = r["animal_id"].nunique()
    ax.text(0.98, 0.03, f"{len(r)} routes\n({n_ind} individuals)", transform=ax.transAxes,
            ha="right", va="bottom", fontsize=7.5, zorder=9,
            bbox=dict(boxstyle="round,pad=0.3", fc="white", ec="0.3", lw=0.6, alpha=.92))
    ax.set_xlim(EXTENT[0], EXTENT[1]); ax.set_ylim(EXTENT[2], EXTENT[3])
    ax.set_aspect(1 / np.cos(np.deg2rad(49.5)))
    ax.set_title(TITLES[year], loc="left", fontweight="bold", pad=4)
    ax.xaxis.set_major_formatter(mpl.ticker.FuncFormatter(lon_fmt))
    ax.yaxis.set_major_formatter(mpl.ticker.FuncFormatter(lat_fmt))
    ax.set_xticks(range(46, 54, 2)); ax.set_yticks(range(48, 52))
    ax.tick_params(labelleft=first_col, labelbottom=last_row)
    return im

# ----------------------------------------------------------------------------
# 4. FIGURE
# ----------------------------------------------------------------------------
def make_figure(districts, routes, ndvi, out="Figure2"):
    fig = plt.figure(figsize=(FIG_W_IN, FIG_H_IN))
    gs = GridSpec(2, 2, figure=fig, left=0.075, right=0.985, top=0.965, bottom=0.05,
                  wspace=0.07, hspace=0.16)
    axA, axB = fig.add_subplot(gs[0, 0]), fig.add_subplot(gs[0, 1])
    axC, axD = fig.add_subplot(gs[1, 0]), fig.add_subplot(gs[1, 1])
    im = None
    for ax, y, fc, lr in [(axA, 2016, True, False), (axB, 2020, False, False), (axC, 2024, True, True)]:
        im = draw_panel(ax, y, districts, routes, ndvi, fc, lr)
    axC.set_xlabel("Longitude"); axC.set_ylabel("Latitude")
    axA.set_ylabel("Latitude")

    # Panel D: key
    axD.axis("off")
    cax = axD.inset_axes([0.08, 0.70, 0.84, 0.07])
    cb = fig.colorbar(im, cax=cax, orientation="horizontal", extend="both")
    cb.set_label("Growing-season mean NDVI, May\u2013September\n(MODIS MOD13Q1)", fontsize=8, labelpad=4)
    cb.ax.tick_params(labelsize=7.5, width=0.8, length=3)
    cb.set_ticks(np.arange(0.1, 0.6, 0.1)); cb.outline.set_linewidth(0.8)

    handles = [Line2D([0], [0], color=ROUTE_COLOR, lw=1.6, path_effects=[pe.withStroke(linewidth=3, foreground="white")]),
               Line2D([0], [0], color="k", lw=1.2)]
    axD.legend(handles, ["GPS migration routes (saiga antelopes)", "District boundaries (core study districts)"],
               loc="center", bbox_to_anchor=(0.5, 0.30), frameon=True, fontsize=8, edgecolor="0.3",
               fancybox=False, borderpad=0.8, labelspacing=0.7)

    # scale bar + north arrow live in panel A (map data coordinates)
    add_scale_bar(axA, 100, loc=(0.04, 0.06)); add_north_arrow(axA)

    for ext in ("pdf", "png", "tiff"):
        kw = {"dpi": 600 if ext == "tiff" else 300}
        if ext == "tiff":
            kw["pil_kwargs"] = {"compression": "tiff_lzw"}
        fig.savefig(f"{out}.{ext}", **kw)
    return fig


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--demo", action="store_true")
    ap.add_argument("--out", default="Figure2")
    a = ap.parse_args()
    d, r, n = load_demo() if a.demo else load_real()
    make_figure(d, r, n, a.out)
    print("saved", a.out + ".{pdf,png,tiff}")
