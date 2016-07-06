//
//  UIImage+animatedGIF.m
//  GifMake-ObjC
//
//  Modified by Younghwan Mun on 2016-07-06.
//  Author: Rob Mayoff 2012-01-27
//  The contents of the source repository for these files are dedicated to the public domain, in accordance with the CC0 1.0 Universal Public Domain Dedication, which is reproduced in the file COPYRIGHT.

#import "UIImage+animatedGIF.h"
@import ImageIO;

#if __has_feature(objc_arc)
#define toCF (__bridge CFTypeRef)
#define fromCF (__bridge id)
#else
#define toCF (CFTypeRef)
#define fromCF (id)
#endif

@implementation UIImage (animatedGIF)


+ (nullable UIImage *)animatedImageWithGIFData:(nullable NSData *)data {
    return [UIImage animatedImageWithGIFSource: CGImageSourceCreateWithData(toCF data, NULL)];
}

+ (nullable UIImage *)animatedImageWithGIFUrl:(nullable NSURL *)url {
    return [UIImage animatedImageWithGIFSource: CGImageSourceCreateWithURL(toCF url, NULL)];
}

+ (nullable UIImage *)animatedImageWithGIFName:(nullable NSString *)name {
    NSURL *bundleURL = [[NSBundle mainBundle] URLForResource: name withExtension:@"gif"];
    NSData *imageData = [NSData dataWithContentsOfURL: bundleURL];
    return [UIImage animatedImageWithGIFSource: CGImageSourceCreateWithData(toCF imageData, NULL)];
}


// private
+ (nullable UIImage *)animatedImageWithGIFSource:(const CGImageSourceRef)source {
    size_t const count = CGImageSourceGetCount(source);
    CGImageRef images[count];
    int delayCentiseconds[count]; // in centiseconds
    [UIImage createImagesAndDelays:source count:count imagesOut:images delayCentisecondsOut:delayCentiseconds];
    const int totalDurationCentiseconds = [UIImage sum: count values:delayCentiseconds];
    
    NSMutableArray *frames = [NSMutableArray arrayWithArray: [UIImage frameArray:count images:images delayCentiseconds:delayCentiseconds totalDurationCentiseconds:totalDurationCentiseconds]];
    UIImage *animation = [UIImage animatedImageWithImages:frames duration:(NSTimeInterval)totalDurationCentiseconds / 100.0];
    [UIImage releaseImages:count images:images];
    return animation;
}

+ (void)createImagesAndDelays:(const CGImageSourceRef) source
                        count:(const size_t) count
                    imagesOut:(CGImageRef []) images
                    delayCentisecondsOut:(int []) delayCentiseconds {
    for (size_t i = 0; i < count; ++i) {
        images[i] = CGImageSourceCreateImageAtIndex(source, i, NULL);
        delayCentiseconds[i] = [UIImage delayCentisecondsForImageAtIndex:source index:i];
    }
}

+ (int)delayCentisecondsForImageAtIndex:(const CGImageSourceRef) source
                                  index:(const size_t) index {
    int delayCentiseconds = 1;
    const CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(source, index, NULL);
    if (properties) {
        const CFDictionaryRef gifProperties = CFDictionaryGetValue(properties, kCGImagePropertyGIFDictionary);
        if (gifProperties) {
            NSNumber *number = fromCF CFDictionaryGetValue(gifProperties, kCGImagePropertyGIFUnclampedDelayTime);
            if (number == NULL || [number doubleValue] == 0) {
                number = fromCF CFDictionaryGetValue(gifProperties, kCGImagePropertyGIFDelayTime);
            }
            if ([number doubleValue] > 0) {
                // Even though the GIF stores the delay as an integer number of centiseconds, ImageIO “helpfully” converts that to seconds for us.
                delayCentiseconds = (int)lrint([number doubleValue] * 100);
            }
        }
        CFRelease(properties);
    }
    return delayCentiseconds;
}

+ (int)sum:(const size_t) count
    values:(const int []) values {
    int sum = 0;
    for (size_t i = 0; i < count; ++i) {
        sum += values[i];
    }
    return sum;
}

+ (int)pairGCD:(int) a
        andNum:(int) b
{
    if (a < b)
        return [UIImage pairGCD:a andNum:b];
    while (true) {
        const int r = a % b;
        if (r == 0)
            return b;
        a = b;
        b = r;
    }
}

+ (int)vectorGCD:(const size_t) count
          values:(const int []) values {
    int gcd = values[0];
    for (size_t i = 1; i < count; ++i) {
        // Note that after I process the first few elements of the vector, `gcd` will probably be smaller than any remaining element.  By passing the smaller value as the second argument to `pairGCD`, I avoid making it swap the arguments.
        gcd = [UIImage pairGCD:values[i] andNum:gcd];
    }
    return gcd;
}

+ (NSArray *)frameArray:(const size_t) count
                 images:(const CGImageRef []) images
      delayCentiseconds:(const int []) delayCentiseconds
totalDurationCentiseconds:(const int) totalDurationCentiseconds {
    int const gcd = [UIImage vectorGCD:count values:delayCentiseconds];
    size_t const frameCount = totalDurationCentiseconds / gcd;
    UIImage *frames[frameCount];
    for (size_t i = 0, f = 0; i < count; ++i) {
        UIImage* frame = [UIImage imageWithCGImage:images[i]];
        for (size_t j = delayCentiseconds[i] / gcd; j > 0; --j) {
            frames[f++] = frame;
        }
    }
    return [NSArray arrayWithObjects:frames count:frameCount];
}

+ (void) releaseImages:(const size_t) count
                images:(const CGImageRef []) images {
    for (size_t i = 0; i < count; ++i) {
        CGImageRelease(images[i]);
    }
}

@end
