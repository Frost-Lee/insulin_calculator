import seaborn as sns
from matplotlib import pyplot as plt
import os


def visualize_result_df(result_df, save_path, y_col_name):
    """ Outputting the visualization of the result data frame.

    Args:
        result_df: The result data frame containing columns factor, area, volume.
        save_path: The path to save the visualization image.
        y_col_name: The name of the desired y axis in `result_df`, 'volume' or 'area'.
    """
    plot = sns.lineplot(
        x='factor',
        y=y_col_name,
        data=result_df,
        err_style='bars'
    )
    plot.set(ylim=(0, 1.2 * result_df.max()[y_col_name]))
    if not os.path.exists(os.path.dirname(save_path)):
        os.makedirs(os.path.dirname(save_path))
    plot.get_figure().savefig(
        save_path, 
        bbox_inches='tight', 
        dpi=500
    )
    plt.clf()
