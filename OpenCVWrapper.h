//
//  OpenCVWrapper.h
//  MoonCaptureApp
//
//  Created by Lucas Cane on 2023-04-01.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OpenCVWrapper : NSObject

+ (UIImage *)detectMoonInImage:(UIImage *)inputImage;

@end

NS_ASSUME_NONNULL_END
