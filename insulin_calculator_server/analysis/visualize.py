import seaborn as sns
import numpy as np
from matplotlib import pyplot as plt
import os


def visualize_result_df(result_df, save_path):
    """ Outputting the visualization of the result data frame. Area and volume 
        are plotted in blue and orange.

    Args:
        result_df: The result data frame containing columns factor, area, volume.
        save_path: The path to save the visualization image.
    """
    figure, volume_axis = plt.subplots()
    area_axis = volume_axis.twinx()
    sns.lineplot(
        x='factor',
        y='volume',
        data=result_df,
        err_style='bars',
        color='#DF8300',    # orange
        ax=volume_axis
    )
    sns.lineplot(
        x='factor',
        y='area',
        data=result_df,
        err_style='bars',
        color='#0083DF',    # blue
        ax=area_axis
    )
    volume_axis.set_ylim(0, _get_axis_lim(result_df.max()['volume']))
    area_axis.set_ylim(0, _get_axis_lim(result_df.max()['area']))
    if not os.path.exists(os.path.dirname(save_path)):
        os.makedirs(os.path.dirname(save_path))
    plt.savefig(
        save_path, 
        bbox_inches='tight',
        dpi=500
    )
    plt.clf()

def _get_axis_lim(range_max):
    return (1.2 + (np.random.rand() - 0.5) * 0.1) * range_max
