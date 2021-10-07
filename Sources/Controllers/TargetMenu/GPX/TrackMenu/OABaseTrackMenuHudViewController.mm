//
//  OABaseTrackMenuHudViewController.h
//  OsmAnd
//
//  Created by Skalii on 25.09.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OABaseTrackMenuHudViewController.h"
#import "OARootViewController.h"
#import "OAMapHudViewController.h"
#import "OAMapRendererView.h"
#import "Localization.h"
#import "OAColors.h"
#import "OASavingTrackHelper.h"
#import "OAGPXDatabase.h"
#import "OAGPXDocument.h"

#define VIEWPORT_SHIFTED_SCALE 1.5f
#define VIEWPORT_NON_SHIFTED_SCALE 1.0f

@interface OABaseTrackMenuHudViewController()

@property (nonatomic) OAMapPanelViewController *mapPanelViewController;
@property (nonatomic) OAMapViewController *mapViewController;

@property (nonatomic) OsmAndAppInstance app;
@property (nonatomic) OAAppSettings *settings;
@property (nonatomic) OASavingTrackHelper *savingHelper;

@property (nonatomic) OAGPX *gpx;
@property (nonatomic) OAGPXDocument *doc;
@property (nonatomic) OAGPXTrackAnalysis *analysis;
@property (nonatomic) BOOL isCurrentTrack;
@property (nonatomic) BOOL isShown;

@property (nonatomic) CGFloat cachedYViewPort;
@property (nonatomic) NSArray<NSDictionary *> *data;

@end

@implementation OABaseTrackMenuHudViewController
{

}

- (instancetype)initWithGpx:(OAGPX *)gpx
{
    self = [super initWithNibName:@"OATrackMenuHudViewController" bundle:nil];
    if (self)
    {
        self.gpx = gpx;
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    self.app = [OsmAndApp instance];
    self.settings = [OAAppSettings sharedManager];
    self.savingHelper = [OASavingTrackHelper sharedInstance];
    self.mapPanelViewController = [OARootViewController instance].mapPanel;
    self.mapViewController = self.mapPanelViewController.mapViewController;

    self.isCurrentTrack = !self.gpx || self.gpx.gpxFilePath.length == 0 || self.gpx.gpxFileName.length == 0;
    if (self.isCurrentTrack)
    {
        if (!self.gpx)
            self.gpx = [self.savingHelper getCurrentGPX];

        self.gpx.gpxTitle = OALocalizedString(@"track_recording_name");
    }
    self.doc = self.isCurrentTrack ? (OAGPXDocument *) self.savingHelper.currentTrack
            : [[OAGPXDocument alloc] initWithGpxFile:[self.app.gpxPath stringByAppendingPathComponent:self.gpx.gpxFilePath]];

    self.analysis = [self.doc getAnalysis:self.isCurrentTrack ? 0
            : (long) [[OAUtilities getFileLastModificationDate:self.gpx.gpxFilePath] timeIntervalSince1970]];

    self.isShown = [self.settings.mapSettingVisibleGpx.get containsObject:self.gpx.gpxFilePath];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self setupView];
    if (![self isLandscape])
        [self goExpanded];
    else
        [self goFullScreen];

    [self.mapPanelViewController displayGpxOnMap:self.gpx];
    [self.mapPanelViewController setTopControlsVisible:NO
                              customStatusBarStyle:[OAAppSettings sharedManager].nightMode
                                      ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault];
    self.cachedYViewPort = self.mapViewController.mapView.viewportYScale;
    [self adjustMapViewPort];
}

- (void)firstShowing
{
    [self show:YES
         state:[self isLandscape] ? EOADraggableMenuStateFullScreen : EOADraggableMenuStateExpanded
    onComplete:^{
        [self.mapPanelViewController targetSetBottomControlsVisible:YES
                                                     menuHeight:[self isLandscape] ? 0
                                                             : [self getViewHeight] - [OAUtilities getBottomMargin]
                                                       animated:YES];
        [self changeMapRulerPosition];
        [self.mapPanelViewController.hudViewController updateMapRulerData];
    }];
}

- (void)hide:(BOOL)animated duration:(NSTimeInterval)duration onComplete:(void (^)(void))onComplete
{
    [super hide:YES duration:duration onComplete:^{
        [self.mapPanelViewController.hudViewController resetToDefaultRulerLayout];
        [self restoreMapViewPort];
        [self.mapPanelViewController hideScrollableHudViewController];
        [self.mapPanelViewController targetSetBottomControlsVisible:YES menuHeight:0 animated:YES];
        if (onComplete)
            onComplete();
    }];
}

- (void)dismiss:(void (^)(void))onComplete
{
    [self hide:YES duration:.2 onComplete:onComplete];
}

- (void)setupView
{
    [self.backButton setImage:[UIImage templateImageNamed:@"ic_custom_arrow_back"] forState:UIControlStateNormal];
    self.backButton.imageView.tintColor = UIColorFromRGB(color_primary_purple);
    [self.backButton addBlurEffect:YES cornerRadius:12. padding:0];

    [self.toolBarView addBlurEffect:YES cornerRadius:0. padding:0];

    [self generateData];
    [self setupHeaderView];
}

- (void)setupHeaderView
{
    //override
}

- (void)generateData
{
    //override
}

- (void)generateData:(NSInteger)section
{
    NSArray *newCellsData = [self getCellsDataForSection:section];
    if (newCellsData)
    {
        NSDictionary *sectionData = ((NSMutableArray *) self.data)[section];
        if (sectionData)
        {
            NSMutableDictionary *newSectionData = [sectionData mutableCopy];
            newSectionData[@"cells"] = newCellsData;
            NSMutableArray *newData = [self.data mutableCopy];
            newData[section] = newSectionData;
            self.data = newData;

            [UIView setAnimationsEnabled:NO];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:section]
                          withRowAnimation:UITableViewRowAnimationNone];
            [UIView setAnimationsEnabled:YES];
        }
    }
}

- (void)generateData:(NSInteger)section row:(NSInteger)row
{
    NSDictionary *newCellData = [self getCellDataForRow:row section:section];
    if (newCellData)
    {
        NSDictionary *sectionData = ((NSMutableArray *) self.data)[section];
        if (sectionData)
        {
            NSMutableDictionary *newSectionData = [sectionData mutableCopy];
            NSMutableArray *newRowsData = [newSectionData[@"cells"] mutableCopy];
            newRowsData[row] = newCellData;
            newSectionData[@"cells"] = newRowsData;
            NSMutableArray *newData = [self.data mutableCopy];
            newData[section] = newSectionData;
            self.data = newData;

            [UIView setAnimationsEnabled:NO];
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:row inSection:section]]
                                  withRowAnimation:UITableViewRowAnimationNone];
            [UIView setAnimationsEnabled:YES];
        }
    }
}

- (NSArray<NSDictionary *> *)getCellsDataForSection:(NSInteger)section
{
    return nil; //override
}

- (NSDictionary *)getCellDataForRow:(NSInteger)row section:(NSInteger)section
{
    return nil; //override
}

- (void)setupModeViewShadowVisibility
{
    self.topHeaderContainerView.layer.shadowOpacity = 0.0;
}

- (CGFloat)expandedMenuHeight
{
    return DeviceScreenHeight / 2;
}

- (BOOL)showStatusBarWhenFullScreen
{
    return YES;
}

- (void)doAdditionalLayout
{
    self.backButtonLeadingConstraint.constant = [self isLandscape] ? self.tableView.frame.size.width : [OAUtilities getLeftMargin] + 10.;
    self.backButtonContainerView.hidden = ![self isLandscape] && self.currentState == EOADraggableMenuStateFullScreen;
}

- (void)adjustMapViewPort
{
    self.mapViewController.mapView.viewportXScale = [self isLandscape] ? VIEWPORT_SHIFTED_SCALE : VIEWPORT_NON_SHIFTED_SCALE;
    self.mapViewController.mapView.viewportYScale = [self getViewHeight] / DeviceScreenHeight;
}

- (void)restoreMapViewPort
{
    OAMapRendererView *mapView = self.mapViewController.mapView;
    if (mapView.viewportXScale != VIEWPORT_NON_SHIFTED_SCALE)
        mapView.viewportXScale = VIEWPORT_NON_SHIFTED_SCALE;
    if (mapView.viewportYScale != self.cachedYViewPort)
        mapView.viewportYScale = self.cachedYViewPort;
}

- (void)changeMapRulerPosition
{
    CGFloat bottomMargin = [self isLandscape] ? 0 : (-[self getViewHeight] + [OAUtilities getBottomMargin] - 20.);
    [self.mapPanelViewController targetSetMapRulerPosition:bottomMargin
                                                  left:([self isLandscape] ? self.tableView.frame.size.width
                                                          : [OAUtilities getLeftMargin] + 20.)];
}

- (NSDictionary *)getItem:(NSIndexPath *)indexPath
{
    return self.data[indexPath.section][@"cells"][indexPath.row];
}

- (NSLayoutConstraint *)createBaseEqualConstraint:(UIView *)firstItem
                                   firstAttribute:(NSLayoutAttribute)firstAttribute
                                       secondItem:(UIView *)secondItem
                                  secondAttribute:(NSLayoutAttribute)secondAttribute
{
    return [NSLayoutConstraint constraintWithItem:firstItem
                                        attribute:firstAttribute
                                        relatedBy:NSLayoutRelationEqual
                                           toItem:secondItem
                                        attribute:secondAttribute
                                       multiplier:1.0f
                                         constant:0.f];
}
- (IBAction)onBackButtonPressed:(id)sender
{
    [self dismiss:nil];
}

#pragma mark - OADraggableViewActions

- (void)onViewHeightChanged:(CGFloat)height
{
    [self.mapPanelViewController targetSetBottomControlsVisible:YES
                                                 menuHeight:[self isLandscape] ? 0
                                                         : height - [OAUtilities getBottomMargin]
                                                   animated:YES];
    [self changeMapRulerPosition];
    [self adjustMapViewPort];
}

@end
