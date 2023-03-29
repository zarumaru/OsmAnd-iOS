//
//  OACameraDistanceWidget.m
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 03.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OACameraDistanceWidget.h"
#import "OARootViewController.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OAOsmAndFormatter.h"
#import "OAAppSettings.h"
#import "Localization.h"

@implementation OACameraDistanceWidget
{
    OAMapRendererView *_rendererView;
    OAAppSettings *_settings;
    int _cachedCameraDistance;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _cachedCameraDistance = -1;
        _settings = [OAAppSettings sharedManager];
        _rendererView = [OARootViewController instance].mapPanel.mapViewController.mapView;
        [self setText:@"-" subtext:@""];
        [self setIcons:@"widget_developer_camera_distance_day" widgetNightIcon:@"widget_developer_camera_distance_night"];
        
        __weak OACameraDistanceWidget *selfWeak = self;
        self.updateInfoFunction = ^BOOL{
            [selfWeak updateInfo];
            return NO;
        };
    }
    return self;
}

- (BOOL) updateInfo
{
    float cameraDistance = [self getCameraHeightInMeters];
    if (self.isUpdateNeeded || cameraDistance != _cachedCameraDistance)
    {
        _cachedCameraDistance = cameraDistance;
        NSString *text = _cachedCameraDistance > 0 ? [self formatDistance:_cachedCameraDistance] : @"-";
        [self setText:text subtext:@""];
        [self setIcons:@"widget_developer_camera_distance_day" widgetNightIcon:@"widget_developer_camera_distance_night"];
        [self addAccessibilityLabelsWithValue:text];
    }
    return YES;
}

- (float) getCameraHeightInMeters
{
    return [_rendererView getCameraHeightInMeters];
}

- (NSString *) formatDistance: (float) distanceInMeters
{
    return [OAOsmAndFormatter getFormattedDistance:distanceInMeters];
}

- (void) addAccessibilityLabelsWithValue:(NSString *)value
{
    self.accessibilityLabel = OALocalizedString(@"map_widget_camera_distance");
    self.accessibilityValue = value;
}

- (void) setImage:(UIImage *)image
{
    [self.imageView setImage:image.imageFlippedForRightToLeftLayoutDirection];
}

@end