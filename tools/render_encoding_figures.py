"""Original analytic illustrations; the first four renders share geometry/camera.

Run with a Python environment containing NumPy and Matplotlib. No measured data is used.
"""
from pathlib import Path
import hashlib
import json
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.colors import LightSource, Normalize

OUT = Path(__file__).resolve().parents[1] / 'assets' / 'encoding'
OUT.mkdir(exist_ok=True)
plt.rcParams.update({'font.family': 'DejaVu Sans', 'font.size': 13,
                     'svg.fonttype': 'none', 'axes.labelcolor': '#23364a',
                     'text.color': '#23364a', 'axes.edgecolor': '#8498aa'})
x = np.linspace(-2, 2, 101)
X, Y = np.meshgrid(x, x)
S = (0.15 + 0.72*np.exp(-((X+0.65)**2+(Y+0.25)**2)/0.7)
     + 0.45*np.exp(-((X-0.8)**2+(Y-0.65)**2)/0.35)
     + 0.07*np.sin(2*X)*np.cos(2*Y))
norm = Normalize(vmin=0, vmax=1)
cmap = plt.get_cmap('viridis')
light = LightSource(azdeg=315, altdeg=45)
rgb = light.shade(S, cmap=cmap, norm=norm, vert_exag=1,
                  dx=x[1]-x[0], dy=x[1]-x[0], blend_mode='soft')
intensity = light.hillshade(S, vert_exag=1, dx=x[1]-x[0], dy=x[1]-x[0])
grey = np.repeat((.2+.75*intensity)[..., None], 3, axis=-1)

def save(fig, stem):
    fig.savefig(OUT / (stem+'.png'), dpi=170, facecolor='white')
    fig.savefig(OUT / (stem+'.svg'), facecolor='white')
    plt.close(fig)

for stem in ['color_only', 'shading_only', 'height_color', 'uniform_surface']:
    fig = plt.figure(figsize=(4.4, 3.6))
    ax = fig.add_subplot(projection='3d')
    kwargs = ({'facecolors': cmap(norm(S))} if stem=='color_only' else
              {'facecolors': grey} if stem=='shading_only' else
              {'facecolors': rgb} if stem=='height_color' else {'color': '#7299bc'})
    ax.plot_surface(X, Y, S, rstride=1, cstride=1, shade=False,
                    linewidth=0, antialiased=False, **kwargs)
    ax.view_init(elev=29, azim=-58)
    ax.set(xlim=(-2, 2), ylim=(-2, 2), zlim=(0, 1),
           xlabel='X', ylabel='Y', zlabel='h')
    ax.set_box_aspect((1, 1, .55))
    ax.set_xticks([-2, 0, 2]); ax.set_yticks([-2, 0, 2]); ax.set_zticks([0, .5, 1])
    ax.grid(False)
    for axis in (ax.xaxis, ax.yaxis, ax.zaxis):
        axis.pane.fill=False
        axis.pane.set_edgecolor('#dbe5ef')
    fig.subplots_adjust(left=0, right=.91, bottom=.04, top=1)
    save(fig, stem)

fig, ax = plt.subplots(figsize=(4.4, 3.6))
im = ax.pcolormesh(X, Y, S, cmap=cmap, norm=norm, shading='auto', rasterized=True)
ax.set(aspect='equal', xlabel='X', ylabel='Y',
       xlim=(-2, 2), ylim=(-2, 2))
ax.set_xticks([-2, 0, 2]); ax.set_yticks([-2, 0, 2])
fig.colorbar(im, ax=ax, label='h', ticks=[0, .5, 1], fraction=.046, pad=.05)
fig.subplots_adjust(left=.15, right=.85, bottom=.15, top=.96)
save(fig, 'xy_color')
(OUT/'provenance.json').write_text(json.dumps({
    'kind': 'Original analytic teaching example, not LiDAR measurements',
    'formula': 's=.15+.72 exp(-((x+.65)^2+(y+.25)^2)/.7)+.45 exp(-((x-.8)^2+(y-.65)^2)/.35)+.07 sin(2x) cos(2y)',
    'grid': [101,101], 'domain': [-2,2], 'color_limits': [0,1],
    'geometry_sha256': hashlib.sha256(S.tobytes()).hexdigest(),
    'represented_quantities': ['x','y','h(x,y)'],
    'units': 'arbitrary units',
    'same_geometry_and_camera_for_figures': [3,4,5,6],
    'camera': {'elevation':29,'azimuth':-58},
    'figure_3': 'Height geometry with Viridis scalar colour, without lighting modulation',
    'figure_4': 'Height geometry with grey shading, no scalar colour mapping; brightness follows normals and lighting',
    'figure_5': 'Height geometry with scalar colour and lighting modulation together',
    'figure_6': 'Constant opaque face colour, no lighting, no mesh edges',
    'figure_7': 'XY plan view, same scalar field and colour normalization',
    'display_aspect': [1,1,.55],
    'inspiration': 'Rheingans and Landreth 1995, DOI 10.1007/978-3-642-79057-7_6, Figure 5',
}, indent=2)+'\n', encoding='utf-8')
print('Rendered five original comparisons to', OUT)
