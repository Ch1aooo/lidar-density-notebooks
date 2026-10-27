# Measured replay data

`measured_walk.json.gz` retains every saved XYZ coordinate from the project's processed single-person L-walk cache. It contains the original 203 frame IDs, frame counts, physical sensor position and three representative-point sequences. No new point filtering or rounding is applied by this export.

- `head`: arithmetic centroid of returns in the inclusive 1.4–1.6 m world-height band.
- `body`: arithmetic centroid of all saved foreground returns.
- `sphere`: the existing saved head-sphere fit, matching the stored path.

Frame 1 contains no saved points and all representatives are null. No acquisition time is fabricated. The current selected frame is always shown in full. Optional accumulation may show a declared subset of frames.

`representative_points.csv` is the accessible numeric counterpart to the displayed trajectories. `measured_walk_metadata.json` records the original source, hashes and transformation definitions. `tools/export_measured_sequence.py` rebuilds these files and checks an exact XYZ round trip; only that rebuilding step requires Python, NumPy and h5py.

These are saved, already processed foreground returns; they may contain residual background. They are not full-room raw LiDAR scans or independently labelled anatomical truth. The single recorded subject does not validate multi-person identity association.
