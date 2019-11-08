import numpy as np
import math
import cv2
import ctypes
import functools

from . import config


def center_crop(array):
    """ Crop the largest center square of an numpy array. Only the first two axis 
        are considered.
    
    Args:
        array: The numpy array to crop. The array should have at least 2 dimensions.
    
    Returns:
        The center cropped numpy array. The first two axis are of equal length.
    """
    assert len(array.shape) >= 2
    if array.shape[0] == array.shape[1]:
        return array
    shape_difference = abs(array.shape[0] - array.shape[1])
    offset = shape_difference // 2
    if array.shape[0] > array.shape[1]:
        return array[offset:array.shape[1] + offset, :]
    else:
        return array[:, offset:array.shape[0] + offset]


def regulate_image(image, calibration):
    """ Rectify, center crop and resize the image to a square of shape `config.UNIFIED_IMAGE_SIZE`.

    Args:
        image: The image to be regulated. Represented as a numpy array with shape 
            `(width, height, channel)`.
        calibration: The camera calibration data when capturing the image.
    
    Returns:
        The regulated image with shape specified by `config.UNIFIED_IMAGE_SIZE`.
    """
    scale = min(config.UNIFIED_IMAGE_SIZE) / min(image.shape[:2])
    resized_image = cv2.resize(image, (int(image.shape[0] * scale), int(image.shape[1] * scale)))
    rectified_image = rectify_image_c(
        resized_image,
        np.array(calibration['lens_distortion_lookup_table']),
        np.array(calibration['lens_distortion_center']) * scale
    )
    center_cropped_image = center_crop(rectified_image)
    return cv2.resize(center_cropped_image, config.UNIFIED_IMAGE_SIZE)


undistort_dll = ctypes.CDLL(config.UNDISTORT_DLL_PATH)


def rectify_image_c(image, lookup_table, distortion_center):
    """ Get the rectified image, implemented in C.

    Args:
        image: The image to be rectified. Represented as a numpy array with shape 
            `(width, height, channel)`. The dtype is `uint_8`.
        lookup_table: The lookuptable to rectify the image, represented as a one 
            dimensional array. The dtype is `c_double` equivalent.
        distortion_center: The distortion center of the image, numpy array with shape 
            `(2,)`. The dtype is `c_double` equivalent.
    
    Returns:
        The rectified image as numpy array with shape `(width, height, channel)`.
    """
    c_rectify_image = undistort_dll.rectify_image
    c_rectify_image.restype = ctypes.POINTER(ctypes.c_uint8 * functools.reduce(lambda x, y: x * y, image.shape))
    c_free_double_pointer = undistort_dll.free_double_pointer
    c_free_double_pointer.restype = None
    raw_result = c_rectify_image(
        image.ctypes.data_as(ctypes.POINTER(ctypes.c_uint8)),
        image.shape[0],
        image.shape[1],
        image.shape[2],
        (ctypes.c_double * len(lookup_table))(*lookup_table),
        len(lookup_table),
        (ctypes.c_double * 2)(*distortion_center)
    ).contents
    reshaped_result = np.reshape(raw_result, image.shape)
    c_free_double_pointer(raw_result)
    return reshaped_result


def get_lens_distortion_point_c(point, lookup_table, distortion_center, image_size):
    """ Get the position of a point after distortion specified by `lookup_table`, 
        implemented in C.

    Args:
        point: The point position before distortion. numpy array with shape `(2,)`, 
            the dtype is `int`.
        lookup_table: The lookuptable to rectify the image, represented as a one 
            dimensional array. The dtype is `c_double` equivalent.
        distortion_center: The distortion center of the image, numpy array with shape 
            `(2,)`. The dtype is `c_double` equivalent.
        image_size: The size of the image, `(width, height)`. The dtype is `int`.
    """
    global undistort_dll
    c_get_lens_distortion_point = undistort_dll.get_lens_distortion_point
    c_get_lens_distortion_point.restype = ctypes.POINTER(ctypes.c_double * 2)
    c_free_double_pointer = undistort_dll.free_double_pointer
    c_free_double_pointer.restype = None
    raw_result = c_get_lens_distortion_point(
        (ctypes.c_int * 2)(*point),
        (ctypes.c_double * len(lookup_table))(*lookup_table),
        len(lookup_table),
        (ctypes.c_double * 2)(*distortion_center),
        (ctypes.c_int * 2)(*image_size)
    ).contents
    converted_result = (int(raw_result[0]), int(raw_result[1]))
    c_free_double_pointer(raw_result)
    return converted_result


def rectify_image(image, lookup_table, distortion_center):
    """ Get the rectified image.

    Args:
        image: The image to be rectified. Represented as a numpy array with shape 
            `(width, height, channel)`.
        lookup_table: The lookuptable to rectify the image, represented as a one 
            dimensional array.
        distortion_center: The distortion center of the image, numpy array with shape 
            `(2,)`.
    
    Returns:
        The rectified image as numpy array with shape `(width, height, channel)`.
    """
    rectified_image = np.zeros(image.shape, dtype=np.int)
    for index in np.ndindex(image.shape[:2]):
        original_index = get_lens_distortion_point(
            np.array(index), 
            lookup_table, 
            distortion_center, 
            image.shape[:2]
        )
        try:
            rectified_image[index] = image[original_index]
        except IndexError:
            pass
    return rectified_image


def get_lens_distortion_point(point, lookup_table, distortion_center, image_size):
    """ Get the position of a point after distortion specified by `lookup_table`.

    Args:
        point: The point position before distortion. numpy array with shape `(2,)`.
        lookup_table: The lookuptable to rectify the image, represented as a one 
            dimensional array.
        distortion_center: The distortion center of the image, numpy array with shape 
            `(2,)`.
        image_size: The size of the image, `(width, height)`.
    """
    radius_max = np.sqrt(np.sum(np.maximum(distortion_center, image_size - distortion_center) ** 2))
    radius_point = np.sqrt(np.sum((point - distortion_center) ** 2))
    magnification = lookup_table[-1]
    if radius_point < radius_max:
        relative_position = radius_point / radius_max * (len(lookup_table) - 1)
        frac = relative_position - math.floor(relative_position)
        magnification = lookup_table[math.floor(relative_position)] * (1.0 - frac) + lookup_table[math.ceil(relative_position)] * frac
    return tuple(map(int, distortion_center + (point - distortion_center) * (1.0 + magnification)))
