import numpy as np
import cv2
import math
import skimage.measure
from sklearn import linear_model
from scipy.spatial.transform import Rotation

from . import config
from . import utils

intrinsics = None

def _get_remapping_intrinsics(depth_map, calibration):
    """ Returning the focal length, horizontal optical center, and vertical optical 
        center of the given depth map.
    
    Args:
        depth_map: The depth map represented as a numpy array.
        calibration: The camera calibration data when capturing the depth map.
    """
    # FIXME(canchen.lee@gmail.com): The way calculating the optical center might 
    # be errorneous because of the cropping of the image.
    global intrinsics
    if intrinsics is None:
        intrinsic_matrix = np.array(calibration['intrinsic_matrix'])
        scale = min(depth_map.shape) / min(calibration['intrinsic_matrix_reference_dimensions'])
        fl = intrinsic_matrix[0, 0] * scale     # focal length
        oc_x = intrinsic_matrix[0, 2] * scale   # horizontal optical center
        oc_y = intrinsic_matrix[1, 2] * scale   # vertical optical center
        intrinsics = fl, oc_x, oc_y
    return intrinsics


def _get_plane_recognition(point_cloud):
    """ Recognize the base plane in `point_cloud`. The plane mask and the 
        rotation to make the plane parallel to xOy surface is provided.
    Args:
        point_cloud: A point cloud represented as an numpy array with shape `(n, 3)`.
    
    Returns:
        inlier_mask, rotation
        `inlier_mask` is the mask of the base plane, corresponding to the point 
        cloud. The value if `True` if the point lies in the plane, `False` otherwise.
        `rotation` can help to rotate the plane parallel to xOy surface in the 
        coordinate system of `point_cloud`
    """
    ransac = linear_model.RANSACRegressor(
        linear_model.LinearRegression(),
        residual_threshold=config.RANSAC_THRESHOLD
    )
    ransac.fit(point_cloud[:,:2], point_cloud[:,2])
    coef_a, coef_b = ransac.estimator_.coef_
    normal_len_square = coef_a ** 2 + coef_b ** 2 + 1
    normal_len = np.sqrt(normal_len_square)
    regularizer = np.arccos(1.0 / normal_len) / np.sqrt((coef_b ** 2 + coef_a ** 2) * normal_len_square)
    rotvec = np.array([
        - coef_b * normal_len * regularizer,
        coef_a * normal_len * regularizer,
        0
    ])
    rotation = Rotation.from_rotvec(rotvec)
    return ransac.inlier_mask_, rotation


def _get_xoy_grid_lookup(point_cloud):
    xoy_grid_lookup = {}
    x_min, y_min = np.min(point_cloud[:,0]), np.min(point_cloud[:,1])
    for point in point_cloud:
        x_index = math.floor((point[0] - x_min) / config.GRID_LEN)
        y_index = math.floor((point[1] - y_min) / config.GRID_LEN)
        if x_index not in xoy_grid_lookup:
            xoy_grid_lookup[x_index] = {}
        if y_index not in xoy_grid_lookup[x_index]:
            xoy_grid_lookup[x_index][y_index] = []
        xoy_grid_lookup[x_index][y_index].append(point)
    return xoy_grid_lookup


def _get_3d_coordinate(row, col, fl, oc_x, oc_y, depth):
    return np.array([(row - oc_x) * depth / fl, (col - oc_y) * depth / fl, depth])


def get_area_volume(depth_map, calibration, attitude, label_mask):
    """ Get the estimated top surface area and volume of each object specified by 
        `label_mask`.
    
    Args:
        depth_map: The depth map captured by device, represented as a numpy array.
        calibration: The camera calibration data when capturing the depth map.
        attitude: The device attitude data when capturing the image.
        label_mask: The entity label mask of the depth map, it should be of shape 
            `config.UNIFIED_IMAGE_SIZE`. Within these labels, 0 stands for the 
            background, and other positive integers stands for different objects.
    
    Returns:
        A area volume list. The values stands for `(area, volume)`, measured in 
        square meter and cube meter.
    """
    regulated_depth_map = utils.regulate_image(depth_map, calibration)
    intrinsics = _get_remapping_intrinsics(regulated_depth_map, calibration)
    full_point_cloud = np.array([
        _get_3d_coordinate(
            i[0], i[1], *intrinsics, v
        ) for i, v in np.ndenumerate(regulated_depth_map)
    ])
    food_point_clouds = [np.array([
        _get_3d_coordinate(
            row, col, *intrinsics, regulated_depth_map[row, col]
        ) for row, col in zip(*np.where(label_mask == food_id))
    ]) for food_id in np.unique(label_mask)[1:]]
    plane_inlier_mask, rotation = _get_plane_recognition(full_point_cloud)
    full_point_cloud = rotation.apply(full_point_cloud)
    food_point_clouds = [rotation.apply(pc) for pc in food_point_clouds]
    background_depth = np.mean(full_point_cloud[plane_inlier_mask][:,2])
    food_grid_lookups = [_get_xoy_grid_lookup(pc) for pc in food_point_clouds]
    area_volume_list = [(
        sum([sum([
            config.GRID_LEN ** 2 for y_value in x_value.values()
        ]) for x_value in lookup.values()]),
        sum([sum([
            (np.mean(background_depth - np.array(y_value), axis=0)[2]) * config.GRID_LEN ** 2 for y_value in x_value.values()
        ]) for x_value in lookup.values()])
    ) for lookup in food_grid_lookups]
    return area_volume_list
