"""Export the saved world-coordinate sequence without resampling or rounding points.

Only needed to rebuild data/. The Julia notebook reads the bundled export directly.
"""
from pathlib import Path
import csv
import gzip
import hashlib
import json
import sys
import numpy as np

PROJECT = Path(__file__).resolve().parents[1]
ROOT = PROJECT.parents[1]
try:
    import h5py
except ImportError:
    sys.path.insert(0, str(ROOT / "Check from Codex/part2_refinement_2026-10-11/deps"))
    import h5py

SOURCE = ROOT / "Coding/msp_measured_l_walk/data/spatial_spectra/measured_spatial_spectra.mat"
CENTERS = SOURCE.with_name("head_centroid_sphere_comparison.csv")
OUT = PROJECT / "data"


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def nullable(values):
    return [float(v) if np.isfinite(v) else None for v in values]


def export():
    OUT.mkdir(exist_ok=True)
    source_hash = sha(SOURCE)
    references = {int(r["Frame"]): r for r in csv.DictReader(CENTERS.open(encoding="utf-8-sig"))}
    frames, total = [], 0
    with h5py.File(SOURCE, "r") as mat:
        ids = mat["p/frames"][:].ravel().astype(int)
        sensor = mat["p/sensor"][:].ravel().tolist()
        refs = mat["P"][:].ravel(order="F")
        for frame_id, ref in zip(ids, refs):
            raw = mat[ref]
            points = raw[:].T.astype(float) if raw.ndim == 2 and raw.shape[0] == 3 else np.empty((0, 3))
            assert points.shape[1] == 3 and np.isfinite(points).all()
            band = points[(points[:, 2] >= 1.4) & (points[:, 2] <= 1.6)]
            row = references[int(frame_id)]
            saved_centroid = np.array([float(row[k]) for k in ("CentroidX_m", "CentroidY_m", "CentroidZ_m")])
            centroid = band.mean(axis=0) if len(band) else np.full(3, np.nan)
            assert np.allclose(centroid, saved_centroid, atol=1e-12, rtol=0, equal_nan=True)
            sphere = np.array([float(row[k]) for k in ("SphereX_m", "SphereY_m", "SphereZ_m")])
            frames.append(dict(id=int(frame_id), count=len(points), head_count=len(band),
                x=points[:, 0].tolist(), y=points[:, 1].tolist(), z=points[:, 2].tolist(),
                head=nullable(centroid), body=nullable(points.mean(axis=0) if len(points) else np.full(3, np.nan)),
                sphere=nullable(sphere)))
            total += len(points)
        saved_path = mat["p/path"][:].T
        saved_ids = mat["p/pathFrames"][:].ravel().astype(int)
        for fid, center in zip(saved_ids, saved_path):
            assert np.allclose(frames[int(fid)-1]["sphere"], center, atol=1e-12, rtol=0)
    meta = dict(title="Measured L-shaped single-person walk", frames=len(frames),
        valid_frames=sum(f["count"] > 0 for f in frames), total_points=total, sensor=sensor,
        missing_frames=[f["id"] for f in frames if not f["count"]],
        timestamp_status="No verified acquisition timestamps; frame index only",
        coordinate_units="metres", point_source="Saved filteredWorldFrames in world coordinates",
        source=str(SOURCE.relative_to(ROOT)).replace("\\", "/"), source_sha256=source_hash,
        centroid_reference=str(CENTERS.relative_to(ROOT)).replace("\\", "/"), centroid_reference_sha256=sha(CENTERS),
        export_transformations="No additional filtering, deduplication, quantisation, rounding or resampling",
        head_centroid="Arithmetic centroid of saved returns with 1.4 <= Z <= 1.6 m",
        body_centroid="Arithmetic centroid of all saved foreground returns; not anatomical ground truth",
        sphere_center="Previously saved head_sphere_fit center; not independently validated truth",
        numpy=np.__version__, h5py=h5py.__version__)
    payload = dict(meta=meta, frames=frames)
    packed = json.dumps(payload, allow_nan=False, separators=(",", ":")).encode()
    (OUT / "measured_walk.json.gz").write_bytes(gzip.compress(packed, mtime=0))
    # Verify every original coordinate survives the full compressed export exactly.
    decoded = json.loads(gzip.decompress((OUT / "measured_walk.json.gz").read_bytes()))
    with h5py.File(SOURCE, "r") as mat:
        for frame, ref in zip(decoded["frames"], mat["P"][:].ravel(order="F")):
            raw = mat[ref]
            if frame["count"]:
                assert np.array_equal(np.column_stack([frame[k] for k in ("x", "y", "z")]), raw[:].T)
    assert sha(SOURCE) == source_hash and total == 460750
    (OUT / "measured_walk_metadata.json").write_text(json.dumps(meta, indent=2), encoding="utf-8")
    with (OUT / "representative_points.csv").open("w", newline="", encoding="utf-8") as stream:
        writer = csv.writer(stream)
        writer.writerow(["frame", "foreground_points", "head_band_points", "method", "x_m", "y_m", "z_m"])
        for frame in frames:
            for method in ("head", "body", "sphere"):
                writer.writerow([frame["id"], frame["count"], frame["head_count"], method, *frame[method]])
    print(json.dumps(dict(frames=len(frames), valid_frames=meta["valid_frames"], points=total,
        gzip_bytes=(OUT / "measured_walk.json.gz").stat().st_size, exact_coordinate_roundtrip=True,
        original_source_unchanged=True, source_sha256=source_hash), indent=2))


if __name__ == "__main__":
    export()
