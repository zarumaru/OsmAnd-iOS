//
//  OAGPXDatabase.h
//  OsmAnd
//
//  Created by Alexey Kulish on 15/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "OACommonTypes.h"

#define kDefaultTrackColor 0xFFFF0000
#define kDefaultWidthMultiplier 7

@class OAGPXTrackAnalysis;
@class OAGpxWpt;

@interface OAGPX : NSObject

@property (nonatomic) NSString *gpxFileName;
@property (nonatomic) NSString *gpxFilePath;
@property (nonatomic) NSString *gpxTitle;
@property (nonatomic) NSString *gpxDescription;
@property (nonatomic) NSDate   *importDate;

@property (nonatomic) OAGpxBounds  bounds;
@property (nonatomic, assign) BOOL newGpx;

@property (nonatomic) NSInteger color;

@property (nonatomic, assign) BOOL showStartFinish;
@property (nonatomic, assign) BOOL joinSegments;
@property (nonatomic, assign) BOOL showArrows;
@property (nonatomic) NSString *width;
@property (nonatomic) NSString *coloringType;

// Statistics
@property (nonatomic) float totalDistance;
@property (nonatomic) int   totalTracks;
@property (nonatomic) long  startTime;
@property (nonatomic) long  endTime;
@property (nonatomic) long  timeSpan;
@property (nonatomic) long  timeMoving;
@property (nonatomic) float totalDistanceMoving;

@property (nonatomic) double diffElevationUp;
@property (nonatomic) double diffElevationDown;
@property (nonatomic) double avgElevation;
@property (nonatomic) double minElevation;
@property (nonatomic) double maxElevation;

@property (nonatomic) float maxSpeed;
@property (nonatomic) float avgSpeed;

@property (nonatomic) int points;
@property (nonatomic) int wptPoints;
@property (nonatomic) NSSet<NSString *> *hiddenGroups;

@property (nonatomic) double   metricEnd;
@property (nonatomic) OAGpxWpt *locationStart;
@property (nonatomic) OAGpxWpt *locationEnd;

- (NSString *)getNiceTitle;

- (void)removeHiddenGroups:(NSString *)groupName;
- (void)addHiddenGroups:(NSString *)groupName;

@end

@interface OAGPXDatabase : NSObject

@property (nonatomic, readonly) NSArray *gpxList;

+ (OAGPXDatabase *)sharedDb;

-(OAGPX *)buildGpxItem:(NSString *)fileName title:(NSString *)title desc:(NSString *)desc bounds:(OAGpxBounds)bounds analysis:(OAGPXTrackAnalysis *)analysis;
-(OAGPX *)addGpxItem:(NSString *)filePath title:(NSString *)title desc:(NSString *)desc bounds:(OAGpxBounds)bounds analysis:(OAGPXTrackAnalysis *)analysis;
-(OAGPX *)getGPXItem:(NSString *)filePath;
-(OAGPX *)getGPXItemByFileName:(NSString *)fileName;
-(void)replaceGpxItem:(OAGPX *)gpx;
-(void)removeGpxItem:(NSString *)filePath;
-(void)removeGpxItem:(NSString *)filePath removeFile:(BOOL)removeFile;
-(BOOL)containsGPXItem:(NSString *)filePath;
-(BOOL)containsGPXItemByFileName:(NSString *)fileName;
-(BOOL)updateGPXItemPointsCount:(NSString *)filePath pointsCount:(int)pointsCount;
-(BOOL)updateGPXItemColor:(OAGPX *)item color:(int)color;
-(BOOL)updateGPXFolderName:(NSString *)newFilePath oldFilePath:(NSString *)oldFilePath;

-(NSString *)getFileDir:(NSString *)filePath;

- (void)load;
- (void)reloadGPXFile:(NSString *)filePath onComplete:(void (^)(void))onComplete;
- (void)save;

@end
