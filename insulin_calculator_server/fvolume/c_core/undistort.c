#include <stdio.h>
#include <stdlib.h>
#include <math.h>

double* get_lens_distortion_point(
    int* point, 
    double* lookup_table, 
    int lookup_table_len, 
    double* distortion_center, 
    int* image_size
) {
    double radius_max_x = distortion_center[0];
    double radius_max_y = distortion_center[1];
    if (image_size[0] - radius_max_x > radius_max_x) {
        radius_max_x = image_size[0] - radius_max_x;
    }
    if (image_size[1] - radius_max_y > radius_max_y) {
        radius_max_y = image_size[1] - radius_max_y;
    }
    double radius_max = sqrt(pow(radius_max_x, 2) + pow(radius_max_y, 2));

    double radius_point_x = point[0] - distortion_center[0];
    double radius_point_y = point[1] - distortion_center[1];
    double radius_point = sqrt(pow(radius_point_x, 2) + pow(radius_point_y, 2));

    double magnification = lookup_table[lookup_table_len - 1];
    if (radius_point < radius_max) {
        double relative_position = radius_point / radius_max * (lookup_table_len - 1);
        double frac = relative_position - (int)floor(relative_position);
        double lower_lookup = lookup_table[(int)floor(relative_position)];
        double upper_lookup = lookup_table[(int)ceil(relative_position)];
        magnification = lower_lookup * (1.0 - frac) + upper_lookup * frac;
    }
    double* mapped_point = (double*)malloc(sizeof(double) * 2);
    mapped_point[0] = distortion_center[0] + radius_point_x * (1.0 + magnification);
    mapped_point[1] = distortion_center[1] + radius_point_y * (1.0 + magnification);
    return mapped_point;
}

double* rectify_image(
    double* image, 
    int width, 
    int height, 
    int channel, 
    double* lookup_table, 
    int lookup_table_len, 
    double* distortion_center
) {
    int image_size[2] = {width, height};
    double* rectified_image = (double*)malloc(sizeof(double) * width * height * channel);
    for (int i = 0; i < width; i ++) {
        for (int j = 0; j < height; j ++) {
            int rectified_index[2] = {i, j};
            double* original_index = get_lens_distortion_point(
                rectified_index,
                lookup_table,
                lookup_table_len,
                distortion_center,
                image_size
            );
            if ((int)original_index[0] < 0 || (int)original_index[0] >= width ||
                (int)original_index[1] < 0 || (int)original_index[1] >= height) {
                continue;
            }
            for (int c = 0; c < channel; c ++) {
                double original_value = image[((int)original_index[0] * height + (int)original_index[1]) * channel + c];
                rectified_image[(i * height + j) * channel + c] = original_value;
            } 
        }
    }
    return rectified_image;
}

void free_double_pointer(double* ptr) {
    free(ptr);
}
