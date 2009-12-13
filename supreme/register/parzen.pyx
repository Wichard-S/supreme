"""Fast Parzen-Window-like estimator of the joint histogram between two
images.

"""
import numpy as np
cimport numpy as np

cdef _add_window(np.ndarray out_arr, int m, int n, np.ndarray win_arr):
    cdef np.ndarray[np.double_t, ndim=2] out = out_arr
    cdef np.ndarray[np.double_t, ndim=2] w = win_arr

    cdef int hwin = (win_arr.shape[0] - 1)/2
    cdef int i, j, ii, jj
    cdef int M, N
    M = out_arr.shape[0]
    N = out_arr.shape[1]

    for i in range(-hwin, hwin + 1):
        for j in range(-hwin, hwin + 1):
            ii = i + m
            jj = j + n

            if (ii < 0) or (ii >= M) or (jj < 0) or (jj >= N):
                continue

            out[ii, jj] += w[i + hwin, j + hwin]

    return out

def joint_hist(np.ndarray[np.uint8_t, ndim=2] A,
               np.ndarray[np.uint8_t, ndim=2] B, win_size=5, std=1.0):
    """Estimate the joint histogram of A and B.

    Parameters
    ----------
    A, B : (M, N) ndarray of uint8
        Input images.
    win_size : int
        Width of Gaussian window used in the approximation.  A larger
        window can represent the Gaussian kernel somewhat more
        accurately.
    std : float
        Standard deviation of the Gaussian used in the Parzen estimation.
        The higher the standard deviation, the smoother the resulting
        histogram.  `win_size` must be made large enough to accommodate
        an increased standard deviation.

    Returns
    -------
    H : (256, 256) ndarray of float
        Estimation of the joint probability density function between A and B.

    """
    assert A.shape[0] == B.shape[0]
    assert A.shape[1] == B.shape[1]

    # Approximation of Gaussian
    cdef np.ndarray[np.double_t, ndim=2] w

    x, y = np.mgrid[:win_size, :win_size]
    hwin = (win_size - 1) / 2
    x -= hwin
    y -= hwin
    std = float(std)
    w = np.exp(-(x**2 + y**2)/(2 ** std**2)) / (2 * np.pi * std**2)

    out = np.zeros((255, 255), dtype=np.double)

    cdef int m, n, i, j, a, b
    m = A.shape[0]
    n = A.shape[1]

    for i in range(m):
        for j in range(n):
            a = A[i, j]
            b = B[i, j]

            out = _add_window(out, a, b, w)

# Normalisation not needed if the correct window is provided

    cdef double s = 0
    for i in range(255):
        for j in range(255):
            s += out[i, j]
    out /= s

    return out

def mutual_info(H):
    """Given the joint histogram of two images, calculate
    their mutual information.

    Parameters
    ----------
    H : (256, 256) ndarray of double

    Returns
    -------
    S : float
        Mutual information.

    """
    d = (H.sum(axis=0) * H.sum(axis=1).reshape(H.shape[0], -1))
    mask = ((H != 0) & (d != 0))
    h = H.copy()
    h[mask] /= d[mask]
    S = -np.sum(H[mask] * np.log(h[mask])) / np.log(2)

    return S