//
//  OAWeatherSettingsViewController.mm
//  OsmAnd
//
//  Created by Skalii on 31.03.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OAWeatherSettingsViewController.h"
#import "OAWeatherBandSettingsViewController.h"
#import "OAWeatherCacheSettingsViewController.h"
#import "OAIconTitleValueCell.h"
#import "OASwitchTableViewCell.h"
#import "OsmAndApp.h"
#import "Localization.h"
#import "OAColors.h"
#import "OAWeatherBand.h"
#import "OAWeatherHelper.h"

@interface OAWeatherSettingsViewController () <OAWeatherBandSettingsDelegate, OAWeatherCacheSettingsDelegate, UITableViewDelegate, UITableViewDataSource>

@end

@implementation OAWeatherSettingsViewController
{
    NSArray<NSDictionary *> *_data;
    NSIndexPath *_selectedIndexPath;
    NSIndexPath *_onlineDataIndexPath;
    NSIndexPath *_useOfflineDataIndexPath;
}

- (instancetype)init
{
    self = [super initWithNibName:@"OABaseSettingsViewController" bundle:nil];
    return self;
}

- (void)applyLocalization
{
    [super applyLocalization];
    self.titleLabel.text = OALocalizedString(@"weather_plugin");
    self.subtitleLabel.text = OALocalizedString(@"shared_string_settings");
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.estimatedRowHeight = kEstimatedRowHeight;

    [self setupView];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self updateCacheSize:YES];
    [self updateCacheSize:NO];
}

- (void)updateCacheSize:(BOOL)localData
{
    if ((localData && _useOfflineDataIndexPath) || (!localData && _onlineDataIndexPath))
    {
        [[OAWeatherHelper sharedInstance] calculateCacheSize:localData onComplete:^(unsigned long long dbsSize)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSMutableArray<NSDictionary *> *cells = _data[localData ? _useOfflineDataIndexPath.section : _onlineDataIndexPath.section][@"cells"];
                NSString *sizeString = [NSByteCountFormatter stringFromByteCount:dbsSize countStyle:NSByteCountFormatterCountStyleFile];
                cells[localData ? _useOfflineDataIndexPath.row : _onlineDataIndexPath.row] = @{
                        @"key": localData ? @"offline_forecast" : @"online_cache",
                        @"title": OALocalizedString(localData ? @"weather_offline_forecast" : @"shared_string_online_cache"),
                        @"value": sizeString,
                        @"type": [OAIconTitleValueCell getCellIdentifier]
                };

                [self.tableView reloadRowsAtIndexPaths:@[localData ? _useOfflineDataIndexPath : _onlineDataIndexPath]
                                      withRowAnimation:UITableViewRowAnimationNone];
            });
        }];
    }
}

- (void)setupView
{
    NSMutableArray<NSDictionary *> *data = [NSMutableArray array];

    NSMutableArray<NSDictionary *> *measurementCells = [NSMutableArray array];
    for (OAWeatherBand *band in [OAWeatherHelper sharedInstance].bands)
    {
        [measurementCells addObject:@{
                @"key": [@"band_" stringByAppendingString:[band getMeasurementName]],
                @"band": band,
                @"type": [OAIconTitleValueCell getCellIdentifier]
        }];
    }
    [data addObject:@{
            @"header": OALocalizedString(@"measurement_units"),
            @"cells": measurementCells
    }];

    NSMutableArray<NSDictionary *> *forecastData = [NSMutableArray array];
    [forecastData addObject:@{
            @"key": @"offline_forecast_only",
            @"title": OALocalizedString(@"weather_offline_forecast_only"),
            @"selected": @([OsmAndApp instance].data.weatherUseOfflineData),
            @"type": [OASwitchTableViewCell getCellIdentifier]
    }];
    [data addObject:@{
            @"cells": forecastData,
            @"footer": OALocalizedString(@"weather_offline_forecast_only_desc")
    }];

    NSMutableArray<NSDictionary *> *cacheData = [NSMutableArray array];
    [data addObject:@{
            @"header": OALocalizedString(@"shared_string_data"),
            @"cells": cacheData,
            @"footer": OALocalizedString(@"weather_data_provider")
    }];

    NSString *sizeString = [NSByteCountFormatter stringFromByteCount:0 countStyle:NSByteCountFormatterCountStyleFile];
    [cacheData addObject:@{
            @"key": @"online_cache",
            @"title": OALocalizedString(@"shared_string_online_cache"),
            @"value": sizeString,
            @"type": [OAIconTitleValueCell getCellIdentifier]
    }];
    _onlineDataIndexPath = [NSIndexPath indexPathForRow:cacheData.count - 1 inSection:data.count - 1];

    [cacheData addObject:@{
            @"key": @"offline_forecast",
            @"title": OALocalizedString(@"weather_offline_forecast"),
            @"value": @"size",
            @"type": [OAIconTitleValueCell getCellIdentifier]
    }];
    _useOfflineDataIndexPath = [NSIndexPath indexPathForRow:cacheData.count - 1 inSection:data.count - 1];

    _data = data;
}

- (NSDictionary *)getItem:(NSIndexPath *)indexPath
{
    return _data[indexPath.section][@"cells"][indexPath.row];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return ((NSArray *) _data[section][@"cells"]).count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSDictionary *sectionData = _data[section];
    return sectionData[@"header"];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    NSDictionary *sectionData = _data[section];
    return sectionData[@"footer"];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    UITableViewCell *outCell = nil;

    if ([item[@"type"] isEqualToString:[OAIconTitleValueCell getCellIdentifier]])
    {
        OAIconTitleValueCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAIconTitleValueCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTitleValueCell getCellIdentifier] owner:self options:nil];
            cell = (OAIconTitleValueCell *) nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            cell.leftIconView.tintColor = UIColorFromRGB(color_tint_gray);
            cell.separatorInset = UIEdgeInsetsMake(0., [item[@"key"] hasPrefix:@"band"] ? 66. : 20., 0., 0.);
        }
        if (cell)
        {
            NSString *title;
            NSString *iconName;
            NSString *value;
            if ([item[@"key"] hasPrefix:@"band"])
            {
                OAWeatherBand *band = (OAWeatherBand *) item[@"band"];
                title = [band getMeasurementName];
                iconName = [band getIcon];

                NSMeasurementFormatter *formatter = [NSMeasurementFormatter new];
                formatter.locale = NSLocale.autoupdatingCurrentLocale;

                NSUnit *unit = [band getBandUnit];
                if (band.bandIndex == WEATHER_BAND_TEMPERATURE)
                    value = unit.name != nil ? unit.name : [formatter stringFromUnit:unit];
                else
                    value = [formatter stringFromUnit:unit];
            }
            else
            {
                title = item[@"title"];
                iconName = item[@"icon"];
                value = item[@"value"];
            }

            cell.textView.text = title;
            cell.descriptionView.text = value;

            BOOL hasLeftIcon = iconName && iconName.length > 0;
            cell.leftIconView.image = hasLeftIcon ? [UIImage templateImageNamed:iconName] : nil;
            [cell showLeftIcon:hasLeftIcon];
        }
        outCell = cell;
    }
    else if ([item[@"type"] isEqualToString:[OASwitchTableViewCell getCellIdentifier]])
    {
        OASwitchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OASwitchTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASwitchTableViewCell *) nib[0];
            cell.separatorInset = UIEdgeInsetsMake(0., 20., 0., 0.);
        }
        if (cell)
        {
            [cell.textView setText: item[@"title"]];
            cell.switchView.on = [item[@"selected"] boolValue];

            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView removeTarget:nil action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(onSwitchPressed:) forControlEvents:UIControlEventValueChanged];
        }
        outCell = cell;
    }

    if ([outCell needsUpdateConstraints])
        [outCell updateConstraints];

    return outCell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    _selectedIndexPath = indexPath;
    if ([item[@"key"] hasPrefix:@"band"])
    {
        OAWeatherBandSettingsViewController *controller =
                [[OAWeatherBandSettingsViewController alloc] initWithWeatherBand:item[@"band"]];
        controller.bandDelegate = self;
        [self presentViewController:controller animated:YES completion:nil];
    }
    else if ([item[@"key"] isEqualToString:@"online_cache"])
    {
        OAWeatherCacheSettingsViewController *controller = [[OAWeatherCacheSettingsViewController alloc] initWithCacheType:EOAWeatherOnlineData];
        controller.cacheDelegate = self;
        [self presentViewController:controller animated:YES completion:nil];
    }
    else if ([item[@"key"] isEqualToString:@"offline_forecast"])
    {
        OAWeatherCacheSettingsViewController *controller = [[OAWeatherCacheSettingsViewController alloc] initWithCacheType:EOAWeatherOfflineData];
        controller.cacheDelegate = self;
        [self presentViewController:controller animated:YES completion:nil];
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Selectors

- (void)onSwitchPressed:(id)sender
{
    UISwitch *switchView = (UISwitch *) sender;
    if (switchView)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:switchView.tag & 0x3FF inSection:switchView.tag >> 10];
        NSDictionary *item = [self getItem:indexPath];
        if ([item[@"key"] isEqualToString:@"offline_forecast_only"])
            [[OsmAndApp instance].data setWeatherUseOfflineData:switchView.isOn];
    }
}

#pragma mark - OAWeatherBandSettingsDelegate

- (void)onBandUnitChanged
{
    if (_selectedIndexPath)
    {
        [self.tableView reloadRowsAtIndexPaths:@[_selectedIndexPath]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

#pragma mark - OAWeatherCacheSettingsDelegate

- (void)onCacheClear:(EOAWeatherCacheType)type
{
    [self updateCacheSize:type == EOAWeatherOfflineData];
}

@end