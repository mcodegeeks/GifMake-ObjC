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
    NSURL *bundleURL = [[NSBundle mainBundle] URLForResource: name withExtension: @"gif"];
    NSData *imageData = [NSData dataWithContentsOfURL: bundleURL];
    return [UIImage animatedImageWithGIFData: imageData];
}


// private
+ (nullable UIImage *)animatedImageWithGIFSource:(const CGImageSourceRef)source {
    size_t count = CGImageSourceGetCount(source);
    CGImageRef images[count];
    int delays[count];
    int duration = 0;
    
    // Fill arrays
    for (size_t i = 0; i < count; ++i) {
        images[i] = CGImageSourceCreateImageAtIndex(source, i, NULL);
        delays[i] = [UIImage delayForImageAtIndex: i source: source];
        duration += delays[i];
    }
    
    // Get frames
    int gcd = [UIImage gcdForArray: delays count: count];
    size_t frameCount = duration / gcd;
    UIImage *frames[frameCount];
    for (size_t i = 0, f = 0; i < count; ++i) {
        UIImage* frame = [UIImage imageWithCGImage:images[i]];
        for (size_t j = delays[i] / gcd; j > 0; --j) {
            frames[f++] = frame;
        }
        
        // release
        CGImageRelease(images[i]);
    }
    
    NSArray *frameArray = [NSArray arrayWithObjects:frames count:frameCount];
    UIImage *animation = [UIImage animatedImageWithImages: frameArray duration: duration/100.0];
    return animation;
}

+ (int)delayForImageAtIndex:(const size_t) index
                     source:(const CGImageSourceRef) source {
    int delay = 1;
    // Get dictionaries
    CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(source, index, NULL);
    if (properties) {
        CFDictionaryRef gifProperties = CFDictionaryGetValue(properties, kCGImagePropertyGIFDictionary);
        if (gifProperties) {
            // Get delay time
            NSNumber *number = fromCF CFDictionaryGetValue(gifProperties, kCGImagePropertyGIFUnclampedDelayTime);
            if (number == NULL || [number doubleValue] == 0) {
                number = fromCF CFDictionaryGetValue(gifProperties, kCGImagePropertyGIFDelayTime);
            }
            if ([number doubleValue] > 0) {
                // Even though the GIF stores the delay as an integer number of centiseconds, ImageIO “helpfully” converts that to seconds for us.
                delay = (int)lrint([number doubleValue] * 100);
            }
        }
        CFRelease(properties);
    }
    return delay;
}

+ (int)gcdForArray:(const int []) values
             count:(const size_t) count {
    int gcd = values[0];
    for (size_t i = 1; i < count; ++i) {
        // Note that after I process the first few elements of the vector, `gcd` will probably be smaller than any remaining element.  By passing the smaller value as the second argument to `pairGCD`, I avoid making it swap the arguments.
        gcd = [UIImage gcdForPair:values[i] andNum:gcd];
    }
    return gcd;
}

+ (int)gcdForPair:(int) a
           andNum:(int) b
{
    // Swap for modulo
    if (a < b) {
        int t = a;
        a = b;
        b = t;
    }
    
    // Get greatest common divisor
    while (true) {
        int r = a % b;
        if (r == 0)
            return b;
        a = b;
        b = r;
    }
}

@end
