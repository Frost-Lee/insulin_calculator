# Insulin Calculator

A system that calculates the insulin required to compensate the blood glucose rise caused by a meal.



## System Modules

The system is a client - server system with multiple functional modules.

### Food Segmentation Model

A segmentation model that generate a mask indicating food / not food for a given image. See [here](./food_segmentation_model/README.md) the details.

### Food Volume Estimation

A module that estimate the food volume and top surface area with depth map and color image. See [here](./inculin_calculator_server/fvolume/README.md) for the details.

### Food Density Library

A food density library that maps the food volume to food weight. See [here](./inculin_calculator_server/fdensitylib/README.md) for the details.

### Insulin Dose Estimation

A module that calculates the insulin dose considering the intake food nutrition and personalized data. This module is not finished yet.

### Front End

An iOS application that runs on iPhones with True Depth camera. This module is capable for capturing the depth map and color image of food, submitting the result to the server, and handle the response. See [here](./insulin_calculator/README.md) for the details.

### Back End

A Flask HTTP server that handles the front end data and provides model response. The submitted data will be stored in the server if the user permits. See [here](./inculin_calculator_server/README.md) for the details.



## Possible Improvements

Here are some possible ways for improving the performance of this system. They are worth trying for the future work.

### Speed Improvements

- Try different semantic segmentation network for food segmentation, such as [DeepLab V3](https://github.com/tensorflow/models/tree/master/research/deeplab).
- Find better ways to extract depth map as JSON.
- Filtering entities that is too small to be a real food entity.
- Switch the segmentation mask generation to CoreML and run it on device.

### Accuracy Improvements

- Using algorithm that considers color image instead of simple connect domain detection.
- Correct depth map and color image distortion, see [here](https://developer.apple.com/documentation/avfoundation/avcameracalibrationdata) for the details.
- Compensating the device orientation bias by applying transformation to the point cloud.



## Copyright

This project is my bachelor thesis project at Massachusetts Institute of Technology (MIT), the copyright terms and conditions should follow [Inventions and Proprietary Information Agreement (IPIA)](https://tlo.mit.edu/learn-about-intellectual-property/ownership/inventions-and-proprietary-information-agreement-ipia) of MIT.