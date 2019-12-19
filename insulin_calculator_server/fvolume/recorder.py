

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
    elif record_key == 'full_point_cloud':
        np.save(os.path.join(container_directory, 'full_pc.npy'), objects[0])
    elif record_key == 'food_point_clouds':
        np.save(os.path.join(container_directory, 'food_pc.npy'), objects[0])
    elif record_key == 'food_grid_lookups':
        food_grid_lookups, background_depth = tuple(objects)
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
        plt.savefig(os.path.join(container_directory, 'projection.jpg'), dpi=500)
        plt.clf()
        plt.bar([*distribution_dict.keys()], [*distribution_dict.values()])
        plt.savefig(os.path.join(container_directory, 'distribition.jpg'), dpi=500)
        plt.clf()
