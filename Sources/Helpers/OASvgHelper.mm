//
//  OASvgHelper.m
//  OsmAnd Maps
//
//  Created by Alexey K on 12.01.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import "OASvgHelper.h"
#import "OANativeUtilities.h"

#include <OsmAndCore/SkiaUtilities.h>

const static float kDefaultIconSize = 24.0f;

@implementation OASvgHelper

+ (nullable UIImage *) mapImageNamed:(NSString *)name
{
    CGFloat scaleFactor = [[UIScreen mainScreen] scale];
    float scaledSize = kDefaultIconSize * scaleFactor;
    return [self.class mapImageFromSvgResource:name width:scaledSize height:scaledSize];
}

+ (nullable UIImage *) mapImageNamed:(NSString *)name scale:(float)scale
{
    CGFloat scaleFactor = [[UIScreen mainScreen] scale];
    float scaledSize = kDefaultIconSize * scaleFactor * scale;
    return [self.class mapImageFromSvgResource:name width:scaledSize height:scaledSize];
}

+ (nullable UIImage *) imageNamed:(NSString *)name
{
    NSString *resourceName = [name lastPathComponent];
    NSString *subpath = [name stringByDeletingLastPathComponent];
    const auto resourcePath = [[NSBundle mainBundle] pathForResource:resourceName
                                                              ofType:@"svg"
                                                         inDirectory:subpath];
    if (resourcePath == nil)
        return nil;

    CGFloat scaleFactor = [[UIScreen mainScreen] scale];
    float scaledSize = kDefaultIconSize * scaleFactor;
    return [OANativeUtilities skImageToUIImage:[OANativeUtilities skImageFromSvgResourcePath:resourcePath width:scaledSize height:scaledSize]];
}

+ (UIImage *) mapImageFromSvgResource:(NSString *)resourceName width:(float)width height:(float)height
{
    const auto resourcePath = [[NSBundle mainBundle] pathForResource:resourceName
                                                              ofType:@"svg"
                                                         inDirectory:@"map-icons-svg"];
    if (resourcePath == nil)
        return nil;

    return [OANativeUtilities skImageToUIImage:[OANativeUtilities skImageFromSvgResourcePath:resourcePath width:width height:height]];
}

+ (UIImage *) mapImageFromSvgResource:(NSString *)resourceName scale:(float)scale
{
    const auto resourcePath = [[NSBundle mainBundle] pathForResource:resourceName
                                                              ofType:@"svg"
                                                         inDirectory:@"map-icons-svg"];
    if (resourcePath == nil)
        return nil;

    return [OANativeUtilities skImageToUIImage:[OANativeUtilities skImageFromSvgResourcePath:resourcePath scale:scale]];
}

+ (UIImage *) imageFromSvgResourcePath:(NSString *)resourcePath width:(float)width height:(float)height
{
    if (resourcePath == nil)
        return nil;

    NSData* resourceData = [NSData dataWithContentsOfFile:resourcePath];
    if (!resourceData)
        return nil;

    return [OANativeUtilities skImageToUIImage:[OANativeUtilities skImageFromSvgData:resourceData width:width height:height]];
}

+ (UIImage *) imageFromSvgResourcePath:(NSString *)resourcePath scale:(float)scale
{
    if (resourcePath == nil)
        return nil;

    NSData* resourceData = [NSData dataWithContentsOfFile:resourcePath];
    if (!resourceData)
        return nil;

    return [OANativeUtilities skImageToUIImage:[OANativeUtilities skImageFromSvgData:resourceData scale:scale]];
}

+ (UIImage *) imageFromSvgData:(const NSData *)data width:(float)width height:(float)height
{
    return data ? [OANativeUtilities skImageToUIImage:OsmAnd::SkiaUtilities::createImageFromVectorData(QByteArray::fromRawNSData(data), width, height)] : nil;
}

+ (UIImage *) imageFromSvgData:(const NSData *)data scale:(float)scale
{
    return data ? [OANativeUtilities skImageToUIImage:OsmAnd::SkiaUtilities::createImageFromVectorData(QByteArray::fromRawNSData(data), scale)] : nil;
}

@end
