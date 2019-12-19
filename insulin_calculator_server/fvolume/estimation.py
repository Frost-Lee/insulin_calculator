import numpy as np
import cv2
import math
import skimage.measure
from sklearn import linear_model
from scipy.spatial.transform import Rotation

from . import config
from . import utils

import os
from matplotlib import pyplot as plt
FILE_DIR = None

def _get_remapping_intrinsics(depth_map, calibration):
    """ Returning the focal length, horizontal optical center, and vertical optical 
        center of the given depth map.
    
    Args:
        depth_map: The depth map represented as a numpy array.
        calibration: The camera calibration data when capturing the depth map.
    """
    intrinsic_matrix = np.array(calibration['intrinsic_matrix'])
    original_dimension = calibration['intrinsic_matrix_reference_dimensions']
    scale = min(depth_map.shape) / min(original_dimension)
    oc_x_offset = (original_dimension[0] - original_dimension[1]) // 2
    fl = intrinsic_matrix[0, 0] * scale
    oc_x = (intrinsic_matrix[2, 0] - oc_x_offset) * scale
    oc_y = intrinsic_matrix[2, 1] * scale
    return fl, oc_x, oc_y


def _get_plane_recognition(point_cloud):
    """ Recognize the base plane in `point_cloud`. The plane mask and the 
        rotation to make the plane parallel to xOy surface is provided.
    
    Args:
        point_cloud: A point cloud represented as an numpy array with shape `(n, 3)`.
    
    Returns:
        (inlier_mask, rotation)
        `inlier_mask` is the mask of the base plane, corresponding to the point 
            cloud. The value if `True` if the point lies in the plane, `False` 
            otherwise.
        `rotation` can help to rotate the plane parallel to xOy surface in the 
            coordinate system of `point_cloud`.
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
    """ Returning the grid lookup of a point cloud.

    A grid lookup is a dictionary for looking up the points fall in a specific 
        grid. When querying points in a grid with index `x_index, y_index`, 
        `lookup[x_index][y_index]` is the list containing points in this grid. Each 
        point is represented as a numpy array with shape `(3,)`.
    In this method, the coordinate of the grid is built by projecting all points 
        in `point_cloud` to XOY surface, the axis parallels to x-axis and y-axis of 
        the world coordinate.

    Args:
        point_cloud: The point cloud to build a grid lookup upon, represented as 
            a numpy array with shape `(n, 3)`.
    """
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
    """ Returning the 3D coordinate of a pixel, the coordinate is represented in 
        a numpy array with shape `(3,)`.
    
    Args:
        row: The row index of the pixel in the image.
        col: The column index of the pixel in the image.
        fl: The focal length when taking the image.
        oc_x: The x coordinate of the optical center.
        oc_y: The y coordinate of the optical center.
        depth: The depth value of the corresponding pixel, measured in meter.
    """
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
    preprocessed_depth_map = utils.preprocess_image(depth_map, calibration)
    regulated_depth_map = utils.regulate_image(preprocessed_depth_map)
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
    background_depth = np.mean(full_point_cloud[plane_inlier_mask][:,2])
    food_point_clouds = [rotation.apply(pc) for pc in food_point_clouds]
    food_point_clouds = [pc[background_depth - pc[:, 2] > 0] for pc in food_point_clouds]
    food_grid_lookups = [_get_xoy_grid_lookup(pc) for pc in food_point_clouds]
    np.save(os.path.join(FILE_DIR, 'food_pc.npy'), food_point_clouds[0])
    np.save(os.path.join(FILE_DIR, 'full_pc.npy'), full_point_cloud)
    grid_x_range = (min(food_grid_lookups[0].keys()), max(food_grid_lookups[0].keys()))
    grid_y_range = (min([min(values.keys()) for values in food_grid_lookups[0].values()]), max([max(values.keys()) for values in food_grid_lookups[0].values()]))
    projection_array = np.zeros((grid_x_range[1] - grid_x_range[0] + 1, grid_y_range[1] - grid_y_range[0] + 1))
    distribution_dict = {}
    for x_value in food_grid_lookups[0].keys():
        for y_value in food_grid_lookups[0][x_value].keys():
            points = food_grid_lookups[0][x_value][y_value]
            projection_array[x_value - grid_x_range[0], y_value - grid_y_range[0]] = np.mean(background_depth - np.array(points), axis=0)[2]
            if len(points) in distribution_dict:
                distribution_dict[len(points)] += 1
            else:
                distribution_dict[len(points)] = 1
    plt.imshow(projection_array)
    plt.colorbar()
    plt.savefig(os.path.join(FILE_DIR, 'projection.jpg'), dpi=500)
    plt.clf()
    plt.bar([*distribution_dict.keys()], [*distribution_dict.values()])
    plt.savefig(os.path.join(FILE_DIR, 'distribition.jpg'), dpi=500)
    plt.clf()
    area_volume_list = [(
        sum([sum([
            config.GRID_LEN ** 2 for y_value in x_value.values()
        ]) for x_value in lookup.values()]),
        sum([sum([
            (np.mean(background_depth - np.array(y_value), axis=0)[2]) * config.GRID_LEN ** 2 for y_value in x_value.values()
        ]) for x_value in lookup.values()])
    ) for lookup in food_grid_lookups]
    return area_volume_list
