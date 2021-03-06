//
// UIImage+Extra.m
// CodeLibary
//
//  Created by zichaochu on 16/9/2.
//  Copyright © 2016年 linxun. All rights reserved.
//

#import "UIImage+Extra.h"

#pragma mark UIImage Extra

UIImage *UIImageFromColor(UIColor *color, CGSize size) {
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

NSData *UIImageCompress(UIImage *image, NSUInteger length) {
    if (length < 1024) {
        length = 1024;
    }
    NSData *data = UIImageJPEGRepresentation(image, 1.f);
    NSLog(@"[ORIGINAL] size:%@ bytes:%d",
          NSStringFromCGSize(image.size), (int)data.length);
    int retry = 0;
    while (data.length > length) {
        CGFloat quality = (CGFloat)length / data.length;
        if (quality < 0.5f) {
            quality = 0.5f;
        }
        data = UIImageJPEGRepresentation(image, quality);
        if (data.length > length) {
            image = UIImageScaling(image, quality);
        }
        retry++;
    }
    NSLog(@"[COMPRESSED] size:%@ bytes:%d retry:%d",
          NSStringFromCGSize(image.size), (int)data.length, retry);
    return data;
}

UIImage *UIImageCropping(UIImage *image, CGRect rect) {
    rect.origin.x = roundf(rect.origin.x * image.scale);
    rect.origin.y = roundf(rect.origin.y * image.scale);
    rect.size.width = roundf(rect.size.width * image.scale);
    rect.size.height = roundf(rect.size.height * image.scale);
    //
    //    CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], rect);
    //    CGRect cropRect = CGRectMake(0, 0, CGImageGetWidth(imageRef), CGImageGetHeight(imageRef));
    //    UIGraphicsBeginImageContextWithOptions(cropRect.size, NO, 0);
    //    CGContextDrawImage(UIGraphicsGetCurrentContext(), cropRect, imageRef);
    //    UIImage *croppedImage = [UIImage imageWithCGImage:imageRef scale:image.scale orientation:image.imageOrientation];
    //    UIGraphicsEndImageContext();
    //    return croppedImage;
    //
    CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], rect);
    UIImage *croppedImage = [UIImage imageWithCGImage:imageRef scale:image.scale orientation:image.imageOrientation];
    CGImageRelease(imageRef);
    return croppedImage;
}

UIImage *UIImageScaling(UIImage *image, CGFloat scale) {
    CGSize size = CGSizeZero;
    size.width = roundf(image.size.width * scale);
    size.height = roundf(image.size.height * scale);
    return UIImageResizing(image, size);
}

UIImage *UIImageResizing(UIImage *image, CGSize size) {
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resizedImage;
}

UIImage *UIImageThumbnail(UIImage *image, CGSize size, BOOL cropIfNeeded) {
    CGSize imageSize = image.size;
    CGSize thumbSize = size;
    CGSize cropSize = CGSizeZero;
    BOOL needsToCrop = NO;
    // check size
    if (thumbSize.width <= 0 || thumbSize.height <= 0) {
        return image;
    }
    // scale aspect
    if (imageSize.width > imageSize.height) {
        if (thumbSize.width < thumbSize.height) {
            thumbSize = size = CGSizeMake(size.height, size.width);
        }
    } else if (imageSize.width < imageSize.height) {
        if (thumbSize.width > thumbSize.height) {
            thumbSize = size = CGSizeMake(size.height, size.width);
        }
    } else { // square
        if (thumbSize.width > thumbSize.height) {
            thumbSize.width = thumbSize.height;
        } else {
            thumbSize.height = thumbSize.width;
        }
    }
    // only crop
    if (thumbSize.width >= imageSize.width || thumbSize.height >= imageSize.height) {
        UIImage *thumbImage = image;
        if (cropIfNeeded) {
            if (imageSize.width > thumbSize.width) {
                needsToCrop = YES;
                cropSize = CGSizeMake(thumbSize.width, imageSize.height);
            } else if (imageSize.height > thumbSize.height) {
                needsToCrop = YES;
                cropSize = CGSizeMake(imageSize.width, thumbSize.height);
            }
            // crop
            if (needsToCrop) {
                CGRect cropRect = CGRectZero;
                cropRect.origin.x = (imageSize.width - cropSize.width) / 2;
                cropRect.origin.y = (imageSize.height - cropSize.height) / 2;
                cropRect.size = cropSize;
                thumbImage = UIImageCropping(image, cropRect);
            }
        }
        // return
        return thumbImage;
    }
    // scale aspect fill
    if (cropIfNeeded) {
        if (imageSize.width > imageSize.height) {
            thumbSize.width = imageSize.width / (imageSize.height / thumbSize.height);
            needsToCrop = thumbSize.width > size.width;
            cropSize = CGSizeMake(size.width, thumbSize.height);
        } else if (imageSize.width < imageSize.height) {
            thumbSize.height = imageSize.height / (imageSize.width / thumbSize.width);
            needsToCrop = thumbSize.height > size.height;
            cropSize = CGSizeMake(thumbSize.width, size.height);
        }
    } else { // scale aspect fit
        if (imageSize.width > imageSize.height) {
            thumbSize.height = imageSize.height / (imageSize.width / thumbSize.width);
        } else if (imageSize.width < imageSize.height) {
            thumbSize.width = imageSize.width / (imageSize.height / thumbSize.height);
        }
    }
    // resize
    UIImage *thumbImage = UIImageResizing(image, thumbSize);
    // crop
    if (cropIfNeeded && needsToCrop) {
        thumbSize = thumbImage.size;
        CGRect cropRect = CGRectZero;
        cropRect.origin.x = (thumbSize.width - cropSize.width) / 2;
        cropRect.origin.y = (thumbSize.height - cropSize.height) / 2;
        cropRect.size = cropSize;
        thumbImage = UIImageCropping(thumbImage, cropRect);
    }
    // result
    return thumbImage;
}

UIImage *UIImageThumbnailLimit(UIImage *image, CGSize size, CGSize maxsize, CGSize minsize) {
    CGSize imageSize = image.size;
    CGSize thumbSize = size;
    CGSize maxSize = CGSizeMake(MAX(maxsize.width, minsize.width), MAX(maxsize.height, minsize.height));
    CGSize minSize = CGSizeMake(MIN(maxsize.width, minsize.width), MIN(maxsize.height, minsize.height));
    // check size
    if (thumbSize.width <= 0 || thumbSize.height <= 0) {
        return image;
    }
    // scale aspect
    if (imageSize.width > imageSize.height) {
        if (thumbSize.width < thumbSize.height) {
            thumbSize = size = CGSizeMake(size.height, size.width);
        }
    } else if (imageSize.width < imageSize.height) {
        if (thumbSize.width > thumbSize.height) {
            thumbSize = size = CGSizeMake(size.height, size.width);
        }
    }
    // limit size
    if (thumbSize.width > maxSize.width || thumbSize.height > maxSize.height) {
        thumbSize = CGSizeMake(MIN(thumbSize.width, maxSize.width), MIN(thumbSize.height, maxSize.height));
    }
    if (thumbSize.width >= imageSize.width || thumbSize.height >= imageSize.height) {
        thumbSize = CGSizeMake(MIN(thumbSize.width, minSize.width), MIN(thumbSize.height, minSize.height));
    }
    // thumb size
    if (imageSize.width > imageSize.height) {
        thumbSize.width = imageSize.width / (imageSize.height / thumbSize.height);
    } else if (imageSize.width < imageSize.height) {
        thumbSize.height = imageSize.height / (imageSize.width / thumbSize.width);
    } else { // square
        if (thumbSize.width > thumbSize.height) {
            thumbSize.width = thumbSize.height;
        } else {
            thumbSize.height = thumbSize.width;
        }
    }
    // over size
    if (thumbSize.width > size.width) {
        thumbSize.width = size.width;
        thumbSize.height = imageSize.height / (imageSize.width / thumbSize.width);
    } else if (thumbSize.height > size.height) {
        thumbSize.height = size.height;
        thumbSize.width = imageSize.width / (imageSize.height / thumbSize.height);
    }
    // under size
    if (thumbSize.width < minSize.width) {
        thumbSize.width = minSize.width;
        thumbSize.height = imageSize.height / (imageSize.width / thumbSize.width);
    } else if (thumbSize.height < minSize.height) {
        thumbSize.height = minSize.height;
        thumbSize.width = imageSize.width / (imageSize.height / thumbSize.height);
    }
    // resize
    UIImage *thumbImage = UIImageResizing(image, thumbSize);
    // crop size
    thumbSize = thumbImage.size;
    if (thumbSize.width > maxSize.width || thumbSize.height > maxSize.height) {
        CGRect cropRect = CGRectZero;
        CGSize cropSize = CGSizeMake(MIN(thumbSize.width, maxSize.width), MIN(thumbSize.height, maxSize.height));
        cropRect.origin.x = (thumbSize.width - cropSize.width) / 2;
        cropRect.origin.y = (thumbSize.height - cropSize.height) / 2;
        cropRect.size = cropSize;
        thumbImage = UIImageCropping(thumbImage, cropRect);
    }
    // return
    return thumbImage;
}

UIImage *UIImageCorrectOrientation(UIImage *image) {
    
    // No-op if the orientation is already correct
    if (image.imageOrientation == UIImageOrientationUp)
        return image;
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (image.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, image.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, image.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        default:
            break;
    }
    
    switch (image.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        default:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, image.size.width, image.size.height,
                                             CGImageGetBitsPerComponent(image.CGImage), 0,
                                             CGImageGetColorSpace(image.CGImage),
                                             CGImageGetBitmapInfo(image.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (image.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,image.size.height,image.size.width), image.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,image.size.width,image.size.height), image.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *imgup = [UIImage imageWithCGImage:cgimg scale:image.scale orientation:UIImageOrientationUp];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    //
    return imgup;
}

UIImage *UIImageGrayscale(UIImage *image) {
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    CGContextRef context = CGBitmapContextCreate(nil, image.size.width, image.size.height, 8, 0, colorSpace, kCGImageAlphaNone);
    CGColorSpaceRelease(colorSpace);
    //
    if (context) {
        CGContextDrawImage(context, CGRectMake(0, 0, image.size.width, image.size.height), image.CGImage);
        UIImage *grayImage = [UIImage imageWithCGImage:CGBitmapContextCreateImage(context)];
        CGContextRelease(context);
        return grayImage;
    }
    //
    return image;
}

//https://developer.apple.com/library/ios/documentation/GraphicsImaging/Reference/CoreImageFilterReference/index.html#//apple_ref/doc/filter/ci/CIGaussianBlur
UIImage *UIImageGaussianBlur(UIImage *image, CGFloat radius) {
    if (image) {
        //
        CIImage *inputImage = [CIImage imageWithCGImage:image.CGImage];
        CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];
        [filter setValue:inputImage forKey:@"inputImage"];
        [filter setValue:@(radius) forKey:@"inputRadius"];
        //
        CIContext *context = [CIContext contextWithOptions:nil];
        CIImage *outputImage = [filter valueForKey:@"outputImage"];
        CGRect outputRect = CGRectZero;
        outputRect.size = UIImageSizeForScale(image, 1.f);
        CGImageRef imageRef = [context createCGImage:outputImage
                                            fromRect:outputRect];
        image = [[UIImage alloc] initWithCGImage:imageRef scale:image.scale orientation:image.imageOrientation];
        CGImageRelease(imageRef);
    }
    //
    return image;
}

CGSize UIImageSizeForScale(UIImage *image, CGFloat scale) {
    CGSize size = image.size;
    if (image && image.scale != scale && scale > 0) {
        size.width *= image.scale / scale;
        size.height *= image.scale / scale;
    }
    return size;
}

CGSize UIImageSizeForWidth(UIImage *image, CGFloat width) {
    CGSize size = UIImageSizeForScreenScale(image);
    if (size.width > 0) {
        size.height *= width / size.width;
    }
    size.width = width;
    return size;
}

CGSize UIImageSizeForHeight(UIImage *image, CGFloat height) {
    CGSize size = UIImageSizeForScreenScale(image);
    if (size.height > 0) {
        size.width *= height / size.height;
    }
    size.height = height;
    return size;
}

CGSize UIImageSizeForScreenScale(UIImage *image) {
    return UIImageSizeForScale(image, [UIScreen mainScreen].scale);
}

CGSize UIImageSizeForScreenWidth(UIImage *image) {
    return UIImageSizeForWidth(image, [UIScreen mainScreen].bounds.size.width);
}

CGSize UIImageSizeForScreenHeight(UIImage *image) {
    return UIImageSizeForHeight(image, [UIScreen mainScreen].bounds.size.height);
}

#pragma mark UIImage (Extra)

@implementation UIImage (Extra)

+ (UIImage *)imageNamed:(NSString *)name bundleNamed:(NSString *)bundle {
    if (bundle.length > 0) {
        if (![[bundle lowercaseString] hasSuffix:@".bundle"]) {
            bundle = [bundle stringByAppendingString:@".bundle"];
        }
        name = [bundle stringByAppendingPathComponent:name];
    }
    return [UIImage imageNamed:name];
}

+ (UIImage *)imageWithColor:(UIColor *)color {
    return UIImageFromColor(color, CGSizeMake(1, 1));
}

+ (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size {
    return UIImageFromColor(color, size);
}

- (NSData *)compressedData:(NSUInteger)length {
    return UIImageCompress(self, length);
}

- (UIImage *)imageWithRect:(CGRect)rect {
    return UIImageCropping(self, rect);
}

- (UIImage *)imageWithScale:(CGFloat)scale {
    return UIImageScaling(self, scale);
}

- (UIImage *)imageWithSize:(CGSize)size {
    return UIImageResizing(self, size);
}

- (UIImage *)thumbnailWithSize:(CGSize)size cropIfNeeded:(BOOL)crop {
    return UIImageThumbnail(self, size, crop);
}

- (UIImage *)thumbnailWithSize:(CGSize)size maxsize:(CGSize)maxsize minsize:(CGSize)minsize {
    return UIImageThumbnailLimit(self, size, maxsize, minsize);
}

- (UIImage *)correctOrientationImage {
    return UIImageCorrectOrientation(self);
}

- (UIImage *)grayscaleImage {
    return UIImageGrayscale(self);
}

- (UIImage *)imageWithBlurRadius:(CGFloat)radius {
    return UIImageGaussianBlur(self, radius);
}

- (CGSize)sizeForScale:(CGFloat)scale {
    return UIImageSizeForScale(self, scale);
}

- (CGSize)sizeForWidth:(CGFloat)width {
    return UIImageSizeForWidth(self, width);
}

- (CGSize)sizeForHeight:(CGFloat)height {
    return UIImageSizeForHeight(self, height);
}

- (CGSize)sizeForScreenScale {
    return UIImageSizeForScreenScale(self);
}

- (CGSize)sizeForScreenWidth {
    return UIImageSizeForScreenWidth(self);
}

- (CGSize)sizeForScreenHeight {
    return UIImageSizeForScreenHeight(self);
}

@end

