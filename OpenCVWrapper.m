//
//  OpenCVWrapper.m
//  MoonCaptureApp
//
//  Created by Lucas Cane on 2023-04-01.
//
#ifdef NO
#undef NO
#endif

#import <Foundation/Foundation.h>
#import "OpenCVWrapper.h"
#import <opencv2/core.hpp>
#import <opencv2/imgproc.hpp>
#import <opencv2/imgcodecs/ios.h>
#import <opencv2/imgproc/types_c.h>
#import <opencv2/imgcodecs/ios.h>

@implementation OpenCVWrapper

+ (UIImage *)detectMoonInImage:(UIImage *)inputImage {
    cv::Mat inputMat;
    UIImageToMat(inputImage, inputMat, true);

    cv::Mat grayMat;
    cv::cvtColor(inputMat, grayMat, cv::COLOR_BGR2GRAY);

    std::vector<cv::Vec3f> circles;
    cv::HoughCircles(grayMat, circles, cv::HOUGH_GRADIENT, 1, grayMat.rows / 16, 100, 30, 30, 300);

    for (const auto &circle : circles) {
        cv::circle(inputMat, cv::Point(circle[0], circle[1]), circle[2], cv::Scalar(0, 255, 0), 4);
    }

    UIImage *resultImage = MatToUIImage(inputMat);
    return resultImage;
}

@end
