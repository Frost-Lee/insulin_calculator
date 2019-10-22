import numpy as np
import cv2
import skimage.measure
from sklearn import linear_model

from . import config


def _get_remapping_intrinsics(depth_map, calibration):
    """ Returning the focal length, horizontal optical center, and vertical optical 
        center of the given depth map.
    
    Args:
        depth_map: The depth map represented as a numpy array.
        calibration: The camera calibration data when capturing the depth map.
    """
    # FIXME(canchen.lee@gmail.com): The way calculating the optical center might 
    # be errorneous because of the cropping of the image.
    intrinsic_matrix = np.array(calibration['intrinsic_matrix'])
    scale = min(depth_map.shape) / min(calibration['intrinsic_matrix_reference_dimensions'])
    fl = intrinsic_matrix[0, 0] * scale     # focal length
    oc_x = intrinsic_matrix[0, 2] * scale   # horizontal optical center
    oc_y = intrinsic_matrix[1, 2] * scale   # vertical optical center
    return fl, oc_x, oc_y


def _get_plane_mask(point_cloud):
    """ Returning the inlier mask of the base plane in a point cloud.

    Args:
        point_cloud: A point cloud represented as an numpy array with shape `(n, 3)`.
    
    Returns:
        An inlier mask of the base plane, corresponding to the point cloud. The 
        value if `True` if the point lies in the plane, `False` otherwise.
    """
    ransac = linear_model.RANSACRegressor(
        linear_model.LinearRegression(),
        residual_threshold=config.RANSAC_THRESHOLD
    )
    ransac.fit(point_cloud[:,:2], point_cloud[:,2])
    return ransac.inlier_mask_


def _get_point_cloud(depth_map, focal_length, oc_x, oc_y, attitude):
    """ Getting the point cloud with a depth map as well as related calibration data.

    Args:
        depth_map: The depth map represented as a numpy array.
        focal_length: The focal length of the camera taking the depth map. Measured 
            in pixel.
        oc_x: The optical center coordinates of the depth map. Measured in pixel.
        oc_y: The optical center coordinates of the depth map. Measured in pixel.
        attitude: The device attitude data when capturing the image.
    
    Returns:
        The point cloud represented as numpy array. The shape is supposed to be 
        `(n, 3)`, where `n` stands for the number of elements in the depth map.
    """
    point_cloud = np.array(
        [np.array([(i[0] - oc_x) * v / focal_length, (i[1] - oc_y) * v / focal_length, v]
    ) for i, v in np.ndenumerate(depth_map)])
    return point_cloud


def _get_area_volume_map(depth_map, calibration, attitude):
    """ Returning the reduced area map and volume map of the given depth map. Both 
        maps will be reduced according to `config.BLOCK_REDUCT_WINDOW`.

    Args:
        depth_map: The depth map represented as a numpy array.
        calibration: The camera calibration data when capturing the depth map.
        attitude: The device attitude data when capturing the image.
    """
    fl, oc_x, oc_y = _get_remapping_intrinsics(depth_map, calibration)
    point_cloud = _get_point_cloud(depth_map, fl, oc_x, oc_y, attitude)
    inlier_mask = _get_plane_mask(point_cloud)
    background_depth = np.mean(point_cloud[inlier_mask][:,2])
    depth_map_reduced = skimage.measure.block_reduce(depth_map, config.BLOCK_REDUCT_WINDOW, np.mean)
    area_map = np.vectorize(
        lambda x: np.product(config.BLOCK_REDUCT_WINDOW) * (x / fl) ** 2
    )(depth_map_reduced)
    volume_map = area_map * (- depth_map_reduced + background_depth)
    return area_map, volume_map


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
    depth_map_regulated = cv2.resize(depth_map, config.UNIFIED_IMAGE_SIZE)
    area_map, volume_map = _get_area_volume_map(depth_map_regulated, calibration, attitude)
    area_volume_list = [(
        np.sum(area_map[np.where(label_mask == food_id)]),
        np.sum(volume_map[np.where(label_mask == food_id)])
    )for food_id in np.unique(label_mask)][1:]
    return area_volume_list
