//
//  OAOsmEditingViewController.m
//  OsmAnd
//
//  Created by Paul on 2/20/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAOsmEditingViewController.h"
#import "OABasicEditingViewController.h"
#import "OASizes.h"
#import "OAEditPOIData.h"
#import "OAEntity.h"
#import "OANode.h"
#import "OAPlugin.h"
#import "OAOsmEditingPlugin.h"
#import "OAOpenStreetMapLocalUtil.h"
#import "OAOpenStreetMapRemoteUtil.h"
#import "Localization.h"


typedef NS_ENUM(NSInteger, EditingTab)
{
    BASIC = 0,
    ADVANCED
};

@interface OAOsmEditingViewController () <UIPageViewControllerDataSource, UIPageViewControllerDelegate, OAOsmEditingDataProtocol>

@property (weak, nonatomic) IBOutlet UIView *navBarView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentControl;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIView *toolBarView;
@property (weak, nonatomic) IBOutlet UIButton *buttonDelete;
@property (weak, nonatomic) IBOutlet UIButton *buttonApply;

@end

@implementation OAOsmEditingViewController
{
    UIPanGestureRecognizer *_tblMoveRecognizer;
    
    UIPageViewController *_pageController;
    OABasicEditingViewController *_basicEditingController;
    
    OAEditPOIData *_editPoiData;
    OAOsmEditingPlugin *_editingPlugin;
    id<OAOpenStreetMapUtilsProtocol> _editingUtil;
    
    BOOL _isAddingNewPOI;
}

-(id) initWithLat:(double)latitude lon:(double)longitude
{
    _isAddingNewPOI = YES;
    OANode *node = [[OANode alloc] initWithId:-1 latitude:latitude longitude:longitude];
    self = [self initWithEntity:node];
    return self;
}

-(id) initWithEntity:(OAEntity *)entity
{
    self = [super init];
    if (self) {
        _editPoiData = [[OAEditPOIData alloc] initWithEntity:entity];
        _editingPlugin = (OAOsmEditingPlugin *) [OAPlugin getPlugin:OAOsmEditingPlugin.class];
        _editingUtil = [_editingPlugin getPoiModificationUtil];
    }
    return self;
}

+(void)commitEntity:(EOAAction)action
             entity:(OAEntity *)entity
         entityInfo:(OAEntityInfo *)info
            comment:(NSString *)comment shouldClose:(BOOL)closeCnageset
        editingUtil:(id<OAOpenStreetMapUtilsProtocol>)util
        changedTags:(NSSet *)changedTags
           callback:(void(^)())callback
{
    
    if (!info && CREATE != action && [util isKindOfClass:OAOpenStreetMapRemoteUtil.class]) {
        NSLog(@"Entity info was not loaded");
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [util commitEntityImpl:action entity:entity entityInfo:info comment:comment closeChangeSet:closeCnageset changedTags:changedTags];
    });
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setupView];
}

-(UIView *) getTopView
{
    return _navBarView;
}

-(UIView *) getMiddleView
{
    return _contentView;
}

-(UIView *) getBottomView
{
    return _toolBarView;
}

-(CGFloat) getToolBarHeight
{
    return customSearchToolBarHeight;
}

-(CGFloat) getNavBarHeight
{
    return osmAndLiveNavBarHeight;
}

-(void) applyLocalization
{
    _titleView.text = _isAddingNewPOI ? OALocalizedString(@"osm_add_place") : OALocalizedString(@"osm_modify_place");
    [_backButton setTitle:OALocalizedString(@"shared_string_back") forState:UIControlStateNormal];
    [_buttonDelete setTitle:OALocalizedString(@"shared_string_delete") forState:UIControlStateNormal];
    [_buttonApply setTitle:([_editingUtil isKindOfClass:OAOpenStreetMapLocalUtil.class] ?
                            OALocalizedString(@"shared_string_apply") : OALocalizedString(@"shared_string_upload")) forState:UIControlStateNormal];
}

- (void)setupPageController {
    _pageController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    _pageController.dataSource = self;
    _pageController.delegate = self;
    CGRect frame = CGRectMake(0, 0, _contentView.frame.size.width, _contentView.frame.size.height);
    _pageController.view.frame = frame;
    _pageController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addChildViewController:_pageController];
    [_contentView addSubview:_pageController.view];
    [_pageController didMoveToParentViewController:self];
}

- (void) setupView
{
    [self applySafeAreaMargins];
    
    [self setupPageController];
    
    _buttonApply.layer.cornerRadius = 9.0;
    _buttonDelete.layer.cornerRadius = 9.0;
    
    _basicEditingController = [[OABasicEditingViewController alloc] initWithFrame:_pageController.view.bounds];
    [_basicEditingController setDataProvider:self];
    
    [_pageController setViewControllers:@[_basicEditingController] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
}

- (IBAction)segmentChanged:(UISegmentedControl *)sender
{
//    [self moveGestureDetected:nil];
    switch (_segmentControl.selectedSegmentIndex)
    {
        case 0:
        {
            [_pageController setViewControllers:@[_basicEditingController] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
            break;
        }
        case 1:
        {
            [_pageController setViewControllers:@[_basicEditingController] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
            break;
        }
    }
//    [self processTabChange];
}

- (IBAction)deletePressed:(id)sender {
    OAPoiDeleteionHelper *deletionHelper = [[OAPoiDeleteionHelper alloc] initWithViewController:self editingUtil:_editingUtil];
    [deletionHelper deletePoiWithDialog:_editPoiData.getEntity];
}

- (IBAction)applyPressed:(id)sender {
}

#pragma mark - UIPageViewControllerDataSource

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
//    if (viewController == _historyViewController)
//        return nil;
//    else if (viewController == _addressViewController)
//        return _categoriesViewController;
//    else
//        return _historyViewController;
    return _basicEditingController;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
//    if (viewController == _addressViewController)
//        return nil;
//    else if (viewController == _categoriesViewController)
//        return _addressViewController;
//    else
//        return _categoriesViewController;
    return _basicEditingController;
}

#pragma mark - UIPageViewControllerDelegate

-(void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray<UIViewController *> *)previousViewControllers transitionCompleted:(BOOL)completed
{
    NSInteger prevTabIndex = _segmentControl.selectedSegmentIndex;
//    if (pageViewController.viewControllers[0] == _historyViewController)
//        _tabs.selectedSegmentIndex = 0;
//    else if (pageViewController.viewControllers[0] == _categoriesViewController)
//        _tabs.selectedSegmentIndex = 1;
//    else
//        _tabs.selectedSegmentIndex = 2;
//
//    if (prevTabIndex != _tabs.selectedSegmentIndex)
//        [self processTabChange];
}

- (IBAction)onBackPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - OAOsmEditingDataProtocol
-(OAEditPOIData *)getData
{
    return _editPoiData;
}

@end

@implementation OAPoiDeleteionHelper
{
    UIViewController *_viewController;
    id<OAOpenStreetMapUtilsProtocol> _editingUtil;
}

-(id)initWithViewController:(UIViewController *)controller editingUtil:(id<OAOpenStreetMapUtilsProtocol>)util
{
    self = [super init];
    if (self) {
        _viewController = controller;
        _editingUtil = util;
    }
    return self;
}

-(void) deletePoiWithDialog:(OAEntity *)entity
{
    if (!entity)
    {
        NSLog(@"Node or way couldn't be found");
        return;
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:OALocalizedString(@"osm_poi_delete_title") message:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alert.textFields.firstObject sizeToFit];
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [alert dismissViewControllerAnimated:YES completion:nil];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString* message = alert.textFields.firstObject.text;
        [self deleteEntity:entity comment:message ? message : @"" shouldClose:NO];
        [alert dismissViewControllerAnimated:YES completion:nil];
        [_viewController.navigationController popViewControllerAnimated:YES];
    }]];
    if ([_editingUtil isKindOfClass:OAOpenStreetMapRemoteUtil.class])
    {
        [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.placeholder = @"Please specify the message";
        }];
    }
    [_viewController presentViewController:alert animated:YES completion:nil];
}

-(void) deleteEntity:(OAEntity *)entity comment:(NSString *)comment shouldClose:(BOOL)closeChangeSet
{
    BOOL isLocalEdit = [_editingUtil isKindOfClass:OAOpenStreetMapLocalUtil.class];
    [OAOsmEditingViewController commitEntity:DELETE entity:entity entityInfo:[_editingUtil getEntityInfo:entity.getId] comment:comment shouldClose:NO editingUtil:_editingUtil changedTags:nil callback:^{
        // TODO add the rest if needed
    }];
//                     public boolean processResult(Entity result) {
//                         if (result != null) {
//                             if (callback != null) {
//                                 callback.poiDeleted();
//                             }
//                             if (isLocalEdit) {
//                                 Toast.makeText(activity, R.string.osm_changes_added_to_local_edits,
//                                                Toast.LENGTH_LONG).show();
//                             } else {
//                                 Toast.makeText(activity, R.string.poi_remove_success, Toast.LENGTH_LONG)
//                                 .show();
//                             }
//                             if (activity instanceof MapActivity) {
//                                 ((MapActivity) activity).getMapView().refreshMap(true);
//                             }
//                         }
//                         return false;
//                     }
//                 }, activity, openstreetmapUtil, null);
}

@end
