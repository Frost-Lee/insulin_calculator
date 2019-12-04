import seaborn as sns


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
    plot.get_figure().savefig(
        save_path, 
        bbox_inches='tight', 
        dpi=500
    )
