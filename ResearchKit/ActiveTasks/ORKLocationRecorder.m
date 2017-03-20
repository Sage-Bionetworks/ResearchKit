/*
 Copyright (c) 2015, Apple Inc. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 3.  Neither the name of the copyright holder(s) nor the names of any contributors
 may be used to endorse or promote products derived from this software without
 specific prior written permission. No license is granted to the trademarks of
 the copyright holders even if such marks are included in this software.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


#import "ORKLocationRecorder.h"

#import "ORKDataLogger.h"

#import "ORKRecorder_Internal.h"
#import "ORKHelpers_Internal.h"

#import "CLLocation+ORKJSONDictionary.h"

#import <CoreLocation/CoreLocation.h>


NSString * const ORKTotalGPSDistanceKey = @"distance_gps";
const CLLocationAccuracy ORKLocationRequiredAccuracy = 20;

@interface ORKLocationRecorder () <CLLocationManagerDelegate> {
    NSError *_recordingError;
    BOOL _started;
    NSMutableArray<CLLocation *> *_locationData;
    CLLocationDistance _totalDistance;
    NSMutableArray<CLLocation *> *_recentLocations;
    dispatch_queue_t _processingQueue;
}

@property (nonatomic, strong, nullable) CLLocationManager *locationManager;

@property (nonatomic) NSTimeInterval uptime;

@end


@implementation ORKLocationRecorder

- (instancetype)initWithIdentifier:(NSString *)identifier step:(ORKStep *)step outputDirectory:(NSURL *)outputDirectory {
    self = [super initWithIdentifier:identifier step:step outputDirectory:outputDirectory];
    if (self) {
        self.continuesInBackground = YES;
        NSString *processingQueueId = [@"org.ResearchKit.location.processing." stringByAppendingString:[[NSUUID UUID] UUIDString]];
        _processingQueue = dispatch_queue_create([processingQueueId cStringUsingEncoding:NSUTF8StringEncoding], DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (NSString *)recorderType {
    return @"location";
}

- (CLLocationManager *)createLocationManager {
    return [[CLLocationManager alloc] init];
}

- (void)start {
    [super start];
    
    self.locationManager = [self createLocationManager];
    if ([CLLocationManager authorizationStatus] <= kCLAuthorizationStatusDenied) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    self.locationManager.pausesLocationUpdatesAutomatically = NO;
    self.locationManager.delegate = self;
    
    if (!self.locationManager) {
        NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain
                                             code:NSFeatureUnsupportedError
                                         userInfo:@{@"recorder": self}];
        [self finishRecordingWithError:error];
        return;
    }
    
    _locationData = [NSMutableArray new];
    _recentLocations = [NSMutableArray new];
    self.uptime = [NSProcessInfo processInfo].systemUptime;
    [self.locationManager startUpdatingLocation];
}

- (void)doStopRecording {
    [self.locationManager stopUpdatingLocation];
    self.locationManager.delegate = nil;
    self.locationManager = nil;
}

- (void)stop {
    [self doStopRecording];
    
    [super stop];
}

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations {
    BOOL success = YES;
    BOOL relativeDistanceOnly = [self relativeDistanceOnly];
    NSParameterAssert(locations.count >= 0);
    NSError *error = nil;
    if (locations) {
        
        // Add the location data points to the log
        __block NSMutableArray *dictionaries = [NSMutableArray arrayWithCapacity:locations.count];
        dispatch_sync(_processingQueue, ^{
            [locations enumerateObjectsUsingBlock:^(CLLocation *obj, NSUInteger idx, BOOL *stop) {
                
                // Calculate time interval since start time
                NSTimeInterval timeInterval = [obj.timestamp timeIntervalSinceDate:self.startDate];
                
                // If there is a reference uptime or the data is consolidated then this uses a schema that
                // uses an NSTimeInterval to define the timestamp rather than a date. This remains compatible
                // with the V1 schema, while allowing the data to be compared to other recorders using the
                // same value for the timestamp.
                id timestamp = nil;
                BOOL consolidated = (self.sharedLogger != nil);
                if (consolidated || (self.referenceUptime > 0)) {
                    NSTimeInterval uptimeDelta = (self.referenceUptime > 0) ? (self.uptime - self.referenceUptime) : 0;
                    timestamp = [NSDecimalNumber numberWithDouble:(uptimeDelta + timeInterval)];
                }
                
                // Only include total distance traveled if the user is not supposed to be standing still
                // and the horizontal accuracy indicates that the user is outdoors
                if (!self.isStandingStill && (obj.horizontalAccuracy > 0) && (obj.horizontalAccuracy <= ORKLocationRequiredAccuracy)) {
                    if (timeInterval > 0) {
                        // If the time is after the start time, then add the distance traveled to the total distance.
                        // This is a rough measurement and does not (at this time) include any spline drawing to measure the
                        // actual curve of the distance traveled.
                        _totalDistance += [_locationData.lastObject distanceFromLocation:obj];
                    }
                    if (timeInterval > -60.0) {
                        // Save the accurate data objects to an array for calculating the distance traveled.
                        [_locationData addObject:obj];
                    }
                }
                
                // Save the data points
                NSMutableDictionary *dict = [[obj ork_JSONDictionaryWithRelativeDistanceOnly:relativeDistanceOnly
                                                                                previous:_mostRecentLocation
                                                                               timestamp:timestamp] mutableCopy];
                dict[ORKRecorderIdentifierKey] = self.identifier;
                if (!self.isStandingStill) {
                    dict[ORKTotalGPSDistanceKey] = [NSDecimalNumber numberWithDouble:_totalDistance];
                }
                [dictionaries addObject:[dict copy]];
                
                // If this is a valid location then store as the previous location
                if (obj.horizontalAccuracy >= 0) {
                    _mostRecentLocation = [obj copy];
                    if (timeInterval > 0) {
                        [_recentLocations addObject:[obj copy]];
                        if (_recentLocations.count > 5) {
                            [_recentLocations removeObjectAtIndex:0];
                        }
                    }
                }
            }];
        });
        
        success = (dictionaries.count == 0) || [self.logger appendObjects:dictionaries error:&error];
    }
    if (!success) {
        dispatch_async(dispatch_get_main_queue(), ^{
            _recordingError = error;
            [self stop];
        });
    }
}

- (void)finishRecordingWithError:(NSError *)error {
    [self doStopRecording];
    [super finishRecordingWithError:nil];
}

- (BOOL)isRecording {
    return [CLLocationManager locationServicesEnabled] && (self.locationManager != nil) && ([CLLocationManager authorizationStatus] > kCLAuthorizationStatusDenied);
}

- (NSString *)mimeType {
    return @"application/json";
}


#pragma mark - total distance tracking

- (BOOL)isStandingStill {
    return ((ORKLocationRecorderConfiguration *)self.configuration).isStandingStill;
}

- (BOOL)relativeDistanceOnly {
    return ((ORKLocationRecorderConfiguration *)self.configuration).relativeDistanceOnly;
}

- (NSTimeInterval)timestamp {
    __block NSTimeInterval timestamp = 0;
    dispatch_sync(_processingQueue, ^{
        NSTimeInterval timeInterval = [_locationData.lastObject.timestamp timeIntervalSinceDate:self.startDate];
        NSTimeInterval uptimeDelta = (self.referenceUptime > 0) ? (self.uptime - self.referenceUptime) : 0;
        timestamp = (uptimeDelta + timeInterval);
    });
    return timestamp;
}

- (CLLocationDistance)distanceTraveled {
    return _totalDistance;
}

- (BOOL)isOutdoors {
    __block BOOL isOutdoors = NO;
    dispatch_sync(_processingQueue, ^{
        if (_recentLocations.count > 0) {
            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:NSStringFromSelector(@selector(horizontalAccuracy)) ascending:YES];
            NSArray<CLLocation *> *sorted = [_recentLocations sortedArrayUsingDescriptors:@[sortDescriptor]];
            isOutdoors = (sorted[sorted.count / 2].horizontalAccuracy <= ORKLocationRequiredAccuracy);
        }
    });
    return isOutdoors;
}

- (void)resetTotalDistanceWithInitialLocation:(nullable CLLocation *)initialLocation {
    dispatch_sync(_processingQueue, ^{
        _totalDistance = 0;
        _mostRecentLocation = [initialLocation copy];
        [_recentLocations removeAllObjects];
        [_locationData removeAllObjects];
        if (_mostRecentLocation) {
            [_locationData addObject:_mostRecentLocation];
        }
    });
}

@end


@implementation ORKLocationRecorderConfiguration

- (instancetype)initWithIdentifier:(NSString *)identifier {
    return [super initWithIdentifier:identifier];
}

- (ORKRecorder *)recorderForStep:(ORKStep *)step outputDirectory:(NSURL *)outputDirectory {
    return [[ORKLocationRecorder alloc] initWithIdentifier:self.identifier step:step outputDirectory:outputDirectory];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    ORK_DECODE_BOOL(aDecoder, relativeDistanceOnly);
    ORK_DECODE_BOOL(aDecoder, standingStill);
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK_ENCODE_BOOL(aCoder, relativeDistanceOnly);
    ORK_ENCODE_BOOL(aCoder, standingStill);
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (NSUInteger)hash {
    return super.hash ^ self.relativeDistanceOnly ^ self.standingStill;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return isParentSame &&
        (self.relativeDistanceOnly == castObject.relativeDistanceOnly) &&
        (self.standingStill == castObject.standingStill);
}

- (ORKPermissionMask)requestedPermissionMask {
    return ORKPermissionCoreLocation;
}

@end
