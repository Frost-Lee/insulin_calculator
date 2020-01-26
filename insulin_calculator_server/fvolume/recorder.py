

import numpy as np
from matplotlib import pyplot as plt
import os

container_directory = None

def record(objects, record_key):
    """ Dump the intermediate result.

    Args:
        objects: The intermediate results to dump. A list of any kind of objects.
        record_key: A string for specifying the record.
    """
    if record_key == 'image_and_mask':
        plt.imshow(objects[0])
        plt.imshow(objects[1], alpha=0.5)
        plt.savefig(os.path.join(container_directory, 'mask.jpg'), dpi=500)
        plt.clf()
    elif record_key == 'full_point_cloud_plane':
        np.save(os.path.join(container_directory, 'plane_pc.npy'), objects[0])
    elif record_key == 'full_point_cloud':
        np.save(os.path.join(container_directory, 'full_pc.npy'), objects[0])
    elif record_key == 'food_point_clouds':
        np.save(os.path.join(container_directory, 'food_pc.npy'), np.concatenate(tuple(objects[0])))
    elif record_key == 'food_grid_lookups':
        food_grid_lookups, background_depth = tuple(objects)
        for i, food_grid_lookup in enumerate(food_grid_lookups):
            grid_x_range = (min(food_grid_lookup.keys()), max(food_grid_lookup.keys()))
            grid_y_range = (min([min(values.keys()) for values in food_grid_lookup.values()]), max([max(values.keys()) for values in food_grid_lookup.values()]))
            projection_array = np.zeros((grid_x_range[1] - grid_x_range[0] + 1, grid_y_range[1] - grid_y_range[0] + 1))
            distribution_array = np.zeros((grid_x_range[1] - grid_x_range[0] + 1, grid_y_range[1] - grid_y_range[0] + 1))
            for x_value in food_grid_lookup.keys():
                for y_value in food_grid_lookup[x_value].keys():
                    points = food_grid_lookup[x_value][y_value]
                    projection_array[x_value - grid_x_range[0], y_value - grid_y_range[0]] = np.mean(background_depth - np.array(points), axis=0)[2]
                    distribution_array[x_value - grid_x_range[0], y_value - grid_y_range[0]] = len(points)
            plt.imshow(projection_array)
            plt.colorbar()
            plt.savefig(os.path.join(container_directory, 'projection_{}.jpg'.format(i)), dpi=500)
            plt.clf()
            plt.imshow(distribution_array)
            plt.colorbar()
            plt.savefig(os.path.join(container_directory, 'distribition_{}.jpg'.format(i)), dpi=500)
            plt.clf()
