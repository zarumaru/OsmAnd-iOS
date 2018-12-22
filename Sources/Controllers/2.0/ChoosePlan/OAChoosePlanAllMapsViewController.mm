//
//  OAChoosePlanFreeBannerViewController.m
//  OsmAnd
//
//  Created by Alexey on 20/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAChoosePlanAllMapsViewController.h"
#import "OsmAndApp.h"
#import "OAIAPHelper.h"
#import "Localization.h"

@interface OAChoosePlanAllMapsViewController ()

@property (nonatomic) NSArray<OAFeature *> *osmLiveFeatures;
@property (nonatomic) NSArray<OAFeature *> *planTypeFeatures;
@property (nonatomic) NSArray<OAFeature *> *selectedOsmLiveFeatures;
@property (nonatomic) NSArray<OAFeature *> *selectedPlanTypeFeatures;

@end

@implementation OAChoosePlanAllMapsViewController

@synthesize osmLiveFeatures = _osmLiveFeatures, planTypeFeatures = _planTypeFeatures;
@synthesize selectedOsmLiveFeatures = _selectedOsmLiveFeatures, selectedPlanTypeFeatures = _selectedPlanTypeFeatures;

- (void) commonInit
{
    [super commonInit];
    
    self.osmLiveFeatures = @[[[OAFeature alloc] initWithFeature:EOAFeatureDailyMapUpdates],
                             [[OAFeature alloc] initWithFeature:EOAFeatureUnlimitedDownloads],
                             [[OAFeature alloc] initWithFeature:EOAFeatureWikipediaOffline],
                             //[[OAFeature alloc] initWithFeature:EOAFeatureWikivoyageOffline],
                             [[OAFeature alloc] initWithFeature:EOAFeatureContourLinesHillshadeMaps]
                             //[[OAFeature alloc] initWithFeature:EOAFeatureSeaDepthMaps]
                             ];
    
    self.selectedOsmLiveFeatures = @[[[OAFeature alloc] initWithFeature:EOAFeatureDailyMapUpdates],
                                     [[OAFeature alloc] initWithFeature:EOAFeatureUnlimitedDownloads]];
    
    self.planTypeFeatures = @[[[OAFeature alloc] initWithFeature:EOAFeatureUnlimitedDownloads],
                              [[OAFeature alloc] initWithFeature:EOAFeatureMonthlyMapUpdates]];
    
    self.selectedPlanTypeFeatures = @[];
}

- (NSString *) getPlanTypeHeaderTitle
{
    return OALocalizedString(@"product_title_allworld");
}

+ (OAProduct *) getPlanTypeProduct
{
    return [OAIAPHelper sharedInstance].allWorld;
}

@end
