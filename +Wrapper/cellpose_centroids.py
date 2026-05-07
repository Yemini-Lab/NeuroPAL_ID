#!/usr/bin/env python3
"""Cellpose centroid runner for NeuroPAL_ID integration."""

from __future__ import annotations

import argparse
import json
from itertools import permutations
from pathlib import Path
from typing import Iterable

import numpy as np
from scipy.io import loadmat, savemat


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Run Cellpose or a deterministic stub and return centroid detections."
    )
    parser.add_argument("--input", required=True, help="JSON request manifest path")
    parser.add_argument("--output", required=True, help="JSON response path")
    parser.add_argument(
        "--mode",
        default="cellpose",
        choices=("cellpose", "stub"),
        help="Detection mode.",
    )
    return parser.parse_args()


def load_request(path: Path) -> dict:
    payload = json.loads(path.read_text(encoding="utf-8"))
    scale_um_xyz = payload.get("scale_um_xyz", [])
    volume_source = payload.get("volume_source", {})
    shape_xyzc = volume_source.get("shape_xyzc", [])

    if len(scale_um_xyz) != 3:
        raise ValueError(
            f"Expected scale_um_xyz to have length 3, got {len(scale_um_xyz)}"
        )
    if len(shape_xyzc) < 3:
        raise ValueError(
            f"Expected volume_source.shape_xyzc to have at least 3 values, got {shape_xyzc}"
        )

    return payload


def load_volume_from_request(request: dict) -> np.ndarray:
    volume_path = Path(request["volume_source"]["path"])
    payload = loadmat(volume_path, squeeze_me=False)
    if "volume" not in payload:
        raise KeyError(f"Volume payload missing 'volume': {volume_path}")
    return np.asarray(payload["volume"])


def to_uint8_volume(volume: np.ndarray) -> np.ndarray:
    arr = np.asarray(volume)
    if arr.ndim == 3:
        arr = arr[..., None]
    if arr.ndim != 4:
        raise ValueError(f"Expected a 3D or 4D volume, got shape {arr.shape}")

    if arr.shape[-1] == 1:
        arr = np.repeat(arr, 3, axis=-1)
    elif arr.shape[-1] == 2:
        arr = np.concatenate([arr, arr[..., -1:]], axis=-1)
    elif arr.shape[-1] > 3:
        arr = arr[..., :3]

    if np.issubdtype(arr.dtype, np.floating):
        lo = float(np.nanmin(arr))
        hi = float(np.nanmax(arr))
        if not np.isfinite(lo) or not np.isfinite(hi) or hi <= lo:
            return np.zeros(arr.shape, dtype=np.uint8)
        scaled = (arr - lo) / (hi - lo)
        return np.round(np.clip(scaled, 0.0, 1.0) * 255.0).astype(np.uint8)

    if np.issubdtype(arr.dtype, np.integer):
        info = np.iinfo(arr.dtype)
        if info.min >= 0 and info.max > 255:
            scaled = arr.astype(np.float32) * (255.0 / float(info.max))
            return np.round(np.clip(scaled, 0.0, 255.0)).astype(np.uint8)
        return np.clip(arr, 0, 255).astype(np.uint8)

    arr = arr.astype(np.float32)
    lo = float(arr.min())
    hi = float(arr.max())
    if hi <= lo:
        return np.zeros(arr.shape, dtype=np.uint8)
    scaled = (arr - lo) / (hi - lo)
    return np.round(np.clip(scaled, 0.0, 1.0) * 255.0).astype(np.uint8)


def build_stub_centroids(shape_xyz: Iterable[int]) -> list[list[int]]:
    fractions = [
        (0.25, 0.25, 0.35),
        (0.50, 0.50, 0.50),
        (0.75, 0.70, 0.65),
    ]
    shape_xyz = [int(v) for v in shape_xyz]
    centroids = []
    for frac_x, frac_y, frac_z in fractions:
        point = []
        for fraction, extent in zip((frac_x, frac_y, frac_z), shape_xyz):
            value = round(1.0 + fraction * max(extent - 1, 0))
            point.append(max(1, min(extent, value)))
        centroids.append(point)

    unique = []
    seen = set()
    for point in centroids:
        key = tuple(point)
        if key in seen:
            continue
        seen.add(key)
        unique.append(point)
    return unique


def run_cellpose(
    volume_xyzc: np.ndarray, model_path: str, requested_mask_source: str
) -> tuple[np.ndarray, np.ndarray]:
    try:
        from cellpose import core, models
    except Exception as exc:  # noqa: BLE001
        raise RuntimeError(
            "Cellpose dependencies are unavailable. Install torch and cellpose into the selected Python environment."
        ) from exc

    use_gpu = False
    try:
        use_gpu = bool(core.use_gpu())
    except Exception:
        use_gpu = False

    model = models.CellposeModel(pretrained_model=model_path, gpu=use_gpu)
    eval_kwargs = dict(
        z_axis=2,
        channel_axis=3,
        batch_size=4,
    )
    masks_3d = np.array([], dtype=np.int32)
    masks_stitched = np.array([], dtype=np.int32)

    if requested_mask_source == "3d":
        masks_3d, _, _ = model.eval(
            volume_xyzc,
            do_3D=True,
            flow3D_smooth=1,
            **eval_kwargs,
        )
    elif requested_mask_source in {"stitched", "2d_stitched"}:
        masks_stitched, _, _ = model.eval(
            volume_xyzc,
            do_3D=False,
            stitch_threshold=0.5,
            **eval_kwargs,
        )
    else:
        masks_stitched, _, _ = model.eval(
            volume_xyzc,
            do_3D=False,
            stitch_threshold=0.5,
            **eval_kwargs,
        )
        has_stitched = np.asarray(masks_stitched).size > 0 and np.any(np.asarray(masks_stitched) > 0)
        if not has_stitched:
            masks_3d, _, _ = model.eval(
                volume_xyzc,
                do_3D=True,
                flow3D_smooth=1,
                **eval_kwargs,
            )
    return np.asarray(masks_3d), np.asarray(masks_stitched)


def choose_mask_source(
    request: dict, masks_3d: np.ndarray, masks_stitched: np.ndarray
) -> tuple[str, np.ndarray]:
    requested = str(request.get("mask_source", "auto")).strip().lower()
    has_stitched = masks_stitched.size > 0 and np.any(masks_stitched > 0)

    if requested == "3d":
        return "masks_3d", masks_3d
    if requested in {"stitched", "2d_stitched"}:
        return "masks_stitched", masks_stitched
    if has_stitched:
        return "masks_stitched", masks_stitched
    return "masks_3d", masks_3d


def infer_mask_permutation(mask_shape: tuple[int, int, int], volume_shape_xyz: tuple[int, int, int]) -> tuple[int, int, int]:
    if mask_shape == volume_shape_xyz:
        return (0, 1, 2)

    candidates = [
        perm
        for perm in permutations(range(3))
        if tuple(volume_shape_xyz[image_axis] for image_axis in perm) == mask_shape
    ]
    if not candidates:
        raise ValueError(
            f"Cannot align mask shape {mask_shape} to image shape {volume_shape_xyz}"
        )

    preferred = [(2, 0, 1), (0, 1, 2)]
    for candidate in preferred:
        if candidate in candidates:
            return candidate
    return candidates[0]


def extract_mask_centroids(mask_data: np.ndarray, volume_shape_xyz: tuple[int, int, int]) -> list[dict]:
    mask_data = np.asarray(mask_data)
    if mask_data.size == 0:
        return []
    if mask_data.ndim != 3:
        raise ValueError(f"Expected a 3D mask volume, got {mask_data.shape}")

    permutation = infer_mask_permutation(tuple(mask_data.shape), volume_shape_xyz)
    mask_axis_for_image = {image_axis: mask_axis for mask_axis, image_axis in enumerate(permutation)}

    segments: list[dict] = []
    for cellpose_id in np.unique(mask_data):
        if cellpose_id <= 0:
            continue
        voxels = np.argwhere(mask_data == cellpose_id)
        if voxels.size == 0:
            continue
        center = voxels.mean(axis=0)
        centroid_xyz = [
            float(center[mask_axis_for_image[0]] + 1.0),
            float(center[mask_axis_for_image[1]] + 1.0),
            float(center[mask_axis_for_image[2]] + 1.0),
        ]
        segments.append(
            {
                "mask_id": int(cellpose_id),
                "centroid_xyz": centroid_xyz,
                "voxel_count": int(voxels.shape[0]),
            }
        )
    return segments


def maybe_write_masks_mat(
    request: dict,
    volume_xyzc: np.ndarray,
    masks_3d: np.ndarray,
    masks_stitched: np.ndarray,
) -> str | None:
    if not request.get("save_masks_mat", False):
        return None

    output_dir = Path(request["output_dir"])
    output_dir.mkdir(parents=True, exist_ok=True)
    mat_path = output_dir / f"{request['prefix']}_masks.mat"
    savemat(
        str(mat_path),
        {
            "image_XYZC": volume_xyzc,
            "masks_3D": np.asarray(masks_3d, dtype=np.int32),
            "masks_stitched": np.asarray(masks_stitched, dtype=np.int32),
        },
    )
    return str(mat_path.resolve())


def build_stub_response(request: dict) -> dict:
    shape_xyzc = [int(v) for v in request["volume_source"]["shape_xyzc"]]
    centroids_xyz = build_stub_centroids(shape_xyzc[:3])
    return {
        "version": 2,
        "backend": "cellpose_stub",
        "mode": "stub",
        "model_path": request.get("model_path", ""),
        "mask_source_used": "stub",
        "coordinate_convention": {
            "order": "xyz",
            "index_base": 1,
            "units": "voxels",
        },
        "scale_um_xyz": request["scale_um_xyz"],
        "source_shape_xyzc": shape_xyzc,
        "centroids_xyz": centroids_xyz,
        "mask_ids": list(range(1, len(centroids_xyz) + 1)),
    }


def build_cellpose_response(request: dict) -> dict:
    volume = load_volume_from_request(request)
    volume_xyzc = to_uint8_volume(volume)
    volume_shape_xyz = tuple(int(v) for v in volume_xyzc.shape[:3])
    requested_mask_source = str(request.get("mask_source", "stitched")).strip().lower()

    masks_3d, masks_stitched = run_cellpose(
        volume_xyzc, request["model_path"], requested_mask_source
    )
    mask_source_used, selected_masks = choose_mask_source(request, masks_3d, masks_stitched)
    segments = extract_mask_centroids(selected_masks, volume_shape_xyz)
    masks_mat_path = maybe_write_masks_mat(request, volume_xyzc, masks_3d, masks_stitched)

    return {
        "version": 2,
        "backend": "cellpose",
        "mode": "cellpose",
        "model_path": request["model_path"],
        "mask_source_used": mask_source_used,
        "coordinate_convention": {
            "order": "xyz",
            "index_base": 1,
            "units": "voxels",
        },
        "scale_um_xyz": request["scale_um_xyz"],
        "source_shape_xyzc": [int(v) for v in volume_xyzc.shape],
        "selected_mask_shape": [int(v) for v in selected_masks.shape],
        "centroids_xyz": [segment["centroid_xyz"] for segment in segments],
        "mask_ids": [segment["mask_id"] for segment in segments],
        "voxel_counts": [segment["voxel_count"] for segment in segments],
        "masks_mat_path": masks_mat_path,
    }


def main() -> None:
    args = parse_args()
    request = load_request(Path(args.input))

    if args.mode == "stub":
        response = build_stub_response(request)
    else:
        response = build_cellpose_response(request)

    output_path = Path(args.output)
    output_path.write_text(json.dumps(response, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()
