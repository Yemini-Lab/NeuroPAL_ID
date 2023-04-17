import numpy as np
import torch


def corr_loss(prediction, target):
    # normalized correlation loss for registering prediction to target descriptors
    vx = prediction - torch.mean(prediction, dim=[1, 2, 3, 4], keepdim=True)
    vy = target - torch.mean(target, dim=[1, 2, 3, 4], keepdim=True)
    if torch.any(torch.std(prediction, dim=[1, 2, 3, 4]) == 0):
        sxy = torch.mul(torch.std(target, dim=[1, 2, 3, 4]),
                        torch.std(target, dim=[1, 2, 3, 4]))
    else:
        sxy = torch.mul(torch.std(prediction, dim=[1, 2, 3, 4]),
                        torch.std(target, dim=[1, 2, 3, 4]))
    cc = torch.div(torch.mean(torch.mul(vx, vy), dim=[1, 2, 3, 4]), sxy + 1e-10)
    return torch.mean(1 - cc)


def to_tensor(data, n_dim=None, grad=False, dtype=None, dev=torch.device('cpu')):
    if isinstance(data, np.ndarray) or isinstance(data, list):
        if n_dim is not None:
            while len(data.shape) < n_dim:
                data = np.array(data)[np.newaxis, ...]
        if dtype is not None:
            return torch.tensor(data, requires_grad=grad, device=dev, dtype=dtype)
        return torch.tensor(data, requires_grad=grad, device=dev).float()
    else:
        return data


def to_numpy(tensor):
    if isinstance(tensor, torch.Tensor):
        return tensor.cpu().detach().numpy()
    else:
        return tensor


def get_pixel(coords, img_shape):
    if isinstance(coords, torch.Tensor):
        return idx_from_coords(
            tuple((to_numpy(coords) + 1) / 2),
            tuple(np.array(img_shape)[::-1])
        )
    else:
        return idx_from_coords(
            tuple((coords + 1) / 2),
            tuple(np.array(img_shape)[::-1])
        )


# ported over from vlab.images.transform
def _idx_from_coords(coords: float, shape: int) -> int:
    return max(round(coords*shape - 1E-6), 0)


def idx_from_coords(coords: tuple, shape: tuple) -> tuple:
    return tuple((_idx_from_coords(c, s) for (c, s) in zip(coords, shape)))


def _coords_from_idx(idx: int, shape: int) -> float:
    return (idx + 0.5) / shape


def coords_from_idx(idx: tuple, shape: tuple) -> tuple:
    return tuple((_coords_from_idx(i, s) for (i, s) in zip(idx, shape)))


def gaussian(sigma: np.ndarray, shape=None, dtype=np.float32, norm="max"
             ) -> np.ndarray:
    """Make a 3D gaussian array density with the specified shape. norm can be
    either 'max' (largest value is set to 1.0) or 'area' (sum of values is
    1.0)."""

    sigma = np.array(sigma)
    if shape is None:
        shape = 2*sigma + 1
    shape = np.array(shape).astype(int)
    bounds = ((shape - 1)/2).astype(int)

    z = np.linspace(-bounds[0], bounds[0], shape[0])
    y = np.linspace(-bounds[1], bounds[1], shape[1])
    x = np.linspace(-bounds[2], bounds[2], shape[2])
    Z, Y, X = np.meshgrid(z, y, x, indexing='ij')
    g = np.exp(-(X**2)/(2.0*sigma[2]) - (Y**2)/(2.0*sigma[1]) - (Z**2)/(2.0*sigma[0]))

    if norm == "max":
        return (g / np.max(g)).astype(dtype)
    elif norm == "area":
        return (g / np.sum(g)).astype(dtype)
    else:
        raise ValueError("norm must be one of 'max' or 'area'")

