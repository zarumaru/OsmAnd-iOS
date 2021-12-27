//
//  OAWeatherRasterLayer.m
//  OsmAnd Maps
//
//  Created by Alexey on 24.12.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAWeatherRasterLayer.h"

#import "OAMapCreatorHelper.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OAAutoObserverProxy.h"
#import "OARootViewController.h"

#include <OsmAndCore/Map/WeatherRasterLayerProvider.h>

@implementation OAWeatherRasterLayer
{
    std::shared_ptr<OsmAnd::IMapLayerProvider> _provider;
    OAAutoObserverProxy* _weatherRasterMapSourceChangeObserver;
    OAAutoObserverProxy* _weatherMapAlphaChangeObserver;
}

- (NSString *) layerId
{
    return [NSString stringWithFormat:@"%@_%d", kWeatherRasterMapLayerId, self.layerIndex];
}

- (void) initLayer
{
    /* TODO
    _weatherRasterMapSourceChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                      withHandler:@selector(onWeatherLayerChanged)
                                                                       andObserve:self.app.data.weatherRasterMapSourceChangeObservable];
    _weatherMapAlphaChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                  withHandler:@selector(onWeaherLayerAlphaChanged)
                                                                   andObserve:self.app.data.weatherMapAlphaChangeObservable];
    */
}

- (void) deinitLayer
{
    if (_weatherRasterMapSourceChangeObserver)
    {
        [_weatherRasterMapSourceChangeObserver detach];
        _weatherRasterMapSourceChangeObserver = nil;
    }
    if (_weatherMapAlphaChangeObserver)
    {
        [_weatherMapAlphaChangeObserver detach];
        _weatherMapAlphaChangeObserver = nil;
    }
}

- (void) resetLayer
{
    _provider.reset();
    [self.mapView resetProviderFor:self.layerIndex];
}

- (BOOL) updateLayer
{
    [super updateLayer];

    [self updateOpacitySliderVisibility];
    
    NSString *geotiffPath = [self.app.documentsPath stringByAppendingString:@"/20211217_0000_M.tiff"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:geotiffPath])
    {
        [self showProgressHUD];
                
        _provider = std::make_shared<OsmAnd::WeatherRasterLayerProvider>(QString::fromNSString(geotiffPath));//, 256, self.displayDensityFactor);
        [self.mapView setProvider:_provider forLayer:self.layerIndex];
        
        OsmAnd::MapLayerConfiguration config;
        config.setOpacityFactor(1.f);
        //TODO config.setOpacityFactor(self.app.data.weatherAlpha);
        [self.mapView setMapLayerConfiguration:self.layerIndex configuration:config forcedUpdate:NO];

        [self hideProgressHUD];
        
        return YES;
    }
    return NO;
}

- (void) onWeatherLayerChanged
{
    [self updateWeatherLayer];
}

- (void) onWeaherLayerAlphaChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.mapViewController runWithRenderSync:^{
            OsmAnd::MapLayerConfiguration config;
            //TODO config.setOpacityFactor(self.app.data.weatherAlpha);
            [self.mapView setMapLayerConfiguration:self.layerIndex configuration:config forcedUpdate:NO];
        }];
    });
}

- (void) updateWeatherLayer
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.mapViewController runWithRenderSync:^{
            if (![self updateLayer])
            {
                [self.mapView resetProviderFor:self.layerIndex];
                _provider.reset();
            }
        }];
    });
}

- (void) updateOpacitySliderVisibility
{
    dispatch_async(dispatch_get_main_queue(), ^{
        //TODO [[OARootViewController instance].mapPanel updateWeatherView];
    });
}

@end
