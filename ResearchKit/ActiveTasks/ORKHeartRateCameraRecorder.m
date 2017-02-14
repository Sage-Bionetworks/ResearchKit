/*
 Copyright (c) 2015, Brandon Lehner
 Copyright (c) 2017, Sage Bionetworks
 
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

#import "ORKHeartRateCameraRecorder.h"
@import AVFoundation;

#import "ORKDataLogger.h"

#import "ORKRecorder_Internal.h"

#import "ORKHelpers_Internal.h"

#import "ORKCodingObjects.h"

const NSTimeInterval ORKHeartRateSampleRate = 1.0;
const int ORKHeartRateFramesPerSecond = 30;
const int ORKHeartRateMaxWindowSeconds = 30;
const int ORKHeartRateMinWindowSeconds = 5;

NSString * const ORKTimestampKey = @"timestamp";
NSString * const ORKColorHueKey = @"hue";
NSString * const ORKColorSaturationKey = @"saturation";
NSString * const ORKColorBrightnessKey = @"brightness";
NSString * const ORKColorRedKey = @"red";
NSString * const ORKColorGreenKey = @"green";
NSString * const ORKColorBlueKey = @"blue";
NSString * const ORKCameraHeartRateKey = @"bpm";
NSString * const ORKWatchHeartRateKey = @"bpm_watch";

@interface ORKHeartRateCameraRecorder() <AVCaptureVideoDataOutputSampleBufferDelegate>

@end

@implementation ORKHeartRateCameraRecorder {
    BOOL _started;
    ORKDataLogger *_logger;
#if TARGET_OS_SIMULATOR
    NSTimer *_simulationTimer;
#else
    AVCaptureSession *_session;
#endif
    NSMutableArray *_dataPointsHue;
    NSMutableArray *_samples;
    NSTimeInterval _timestamp;
}

- (void)dealloc {
    ORK_Log_Debug(@"Remove session %p", self);
#if TARGET_OS_SIMULATOR
    [_simulationTimer invalidate];
    _simulationTimer = nil;
#else
    [_session stopRunning];
#endif
    [_logger finishCurrentLog];
}

#pragma mark - Data collection

- (NSString *)recorderType {
    return @"heartrate";
}

- (BOOL)isRecording {
#if TARGET_OS_SIMULATOR
    return (_simulationTimer != nil);
#else
    return _session.isRunning;
#endif
}

- (void)start {
    if (_started) {
        [super start];
        return;
    }
    _started = YES;
    
    if (!_logger) {
        NSError *error = nil;
        _logger = [self makeJSONDataLoggerWithError:&error];
        if (!_logger) {
            [self finishRecordingWithError:error];
            return;
        }
    }
    
    _timestamp = 0;
    self.startDate = [NSDate date];
    _dataPointsHue = [[NSMutableArray alloc] init];
    _samples = [[NSMutableArray alloc] init];
    
#if TARGET_OS_SIMULATOR
    _simulationTimer = [NSTimer scheduledTimerWithTimeInterval:ORKHeartRateSampleRate
                                                        target:self
                                                      selector:@selector(timerFired)
                                                      userInfo:nil
                                                       repeats:YES];
#else
    // Create the session
    _session = [[AVCaptureSession alloc] init];
    _session.sessionPreset = AVCaptureSessionPresetLow;
    
    // Retrieve the back camera
    NSArray *devices = [AVCaptureDevice devices];
    AVCaptureDevice *captureDevice;
    for (AVCaptureDevice *device in devices) {
        if ([device hasMediaType:AVMediaTypeVideo]) {
            if (device.position == AVCaptureDevicePositionBack) {
                captureDevice = device;
                break;
            }
        }
    }
    
    NSError *error;
    AVCaptureDeviceInput *input = [[AVCaptureDeviceInput alloc] initWithDevice:captureDevice error:&error];
    [_session addInput:input];
    
    if (error) {
        ORK_Log_Error(@"%@", error);
        [self finishRecordingWithError:error];
        return;
    }
    
    // Find the max frame rate we can get from the given device
    AVCaptureDeviceFormat *currentFormat;
    for (AVCaptureDeviceFormat *format in captureDevice.formats) {
        NSArray *ranges = format.videoSupportedFrameRateRanges;
        AVFrameRateRange *frameRates = ranges[0];
        
        // Find the lowest resolution format at the frame rate we want.
        if (frameRates.maxFrameRate == ORKHeartRateFramesPerSecond && (!currentFormat || (CMVideoFormatDescriptionGetDimensions(format.formatDescription).width < CMVideoFormatDescriptionGetDimensions(currentFormat.formatDescription).width && CMVideoFormatDescriptionGetDimensions(format.formatDescription).height < CMVideoFormatDescriptionGetDimensions(currentFormat.formatDescription).height))) {
            currentFormat = format;
        }
    }
    
    // Tell the device to use the max frame rate.
    [captureDevice lockForConfiguration:nil];
    captureDevice.torchMode=AVCaptureTorchModeOn;
    captureDevice.activeFormat = currentFormat;
    captureDevice.activeVideoMinFrameDuration = CMTimeMake(1, ORKHeartRateFramesPerSecond);
    captureDevice.activeVideoMaxFrameDuration = CMTimeMake(1, ORKHeartRateFramesPerSecond);
    [captureDevice unlockForConfiguration];
    
    // Set the output
    AVCaptureVideoDataOutput* videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    
    // create a queue to run the capture on
    dispatch_queue_t captureQueue=dispatch_queue_create("captureQueue", NULL);
    
    // setup our delegate
    [videoOutput setSampleBufferDelegate:self queue:captureQueue];
    
    // configure the pixel format
    videoOutput.videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA], (id)kCVPixelBufferPixelFormatTypeKey,
                                 nil];
    videoOutput.alwaysDiscardsLateVideoFrames = NO;
    
    [_session addOutput:videoOutput];
    
    // Start the video session
    [_session startRunning];
    
#endif
    
    [super start];
}

- (void)stop {
    if (!_started) {
        // Error has already been returned.
        return;
    }
    
    [self doStopRecording];
    
    [_logger finishCurrentLog];
    
    NSError *error = nil;
    __block NSURL *fileUrl = nil;
    [_logger enumerateLogs:^(NSURL *logFileUrl, BOOL *stop) {
        fileUrl = logFileUrl;
    } error:&error];
    
    [self reportFileResultWithFile:fileUrl error:error];
    
    [super stop];
}

- (void)doStopRecording {
    _started = NO;
    
#if TARGET_OS_SIMULATOR
    [_simulationTimer invalidate];
    _simulationTimer = nil;
    
#else
    if (self.isRecording) {
        [_session stopRunning];
    }
    _session = nil;
#endif
}

- (void)finishRecordingWithError:(NSError *)error {
    [self doStopRecording];
    [super finishRecordingWithError:error];
}

- (void)reset {
    [super reset];
    
    [self doStopRecording];
    
    _logger = nil;
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

#if TARGET_OS_SIMULATOR

- (void)timerFired {
    _bpm = 65;
    _timestamp += ORKHeartRateSampleRate;
    NSArray *samples = @[@{ORKTimestampKey       : @(_timestamp),
                           ORKCameraHeartRateKey : @(_bpm)
                          }];
    [self updateHeartRate:_bpm samples:samples displaySeconds:_timestamp];
}

#else

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    // only run if we're not already processing an image
    // this is the image buffer
    CVImageBufferRef cvimgRef = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    // Lock the image buffer
    CVPixelBufferLockBaseAddress(cvimgRef,0);
    
    // access the data
    NSInteger width = CVPixelBufferGetWidth(cvimgRef);
    NSInteger height = CVPixelBufferGetHeight(cvimgRef);
    
    // get the raw image bytes
    uint8_t *buf=(uint8_t *) CVPixelBufferGetBaseAddress(cvimgRef);
    size_t bprow=CVPixelBufferGetBytesPerRow(cvimgRef);
    float r = 0,g = 0,b = 0;
    
    long widthScaleFactor = width / 192;
    long heightScaleFactor = height / 144;
    
    // Get the average rgb values for the entire image.
    for (int y = 0; y < height; y += heightScaleFactor) {
        for (int x = 0; x < width * 4; x += (4 * widthScaleFactor)) {
            r += buf[x + 2];
            g += buf[x + 1];
            b += buf[x];
        }
        buf += bprow;
    }
    r /= 255 * (float)((width * height) / (widthScaleFactor * heightScaleFactor));
    g /= 255 * (float)((width * height) / (widthScaleFactor * heightScaleFactor));
    b /= 255 * (float)((width * height) / (widthScaleFactor * heightScaleFactor));
    
    // Unlock the image buffer
    CVPixelBufferUnlockBaseAddress(cvimgRef,0);
    
    // record the color
    [self recordColorWithRed:r green:g blue:b];
}

#endif

- (void)recordColorWithRed:(float)r green:(float)g blue:(float)b {
    
    // save the hue
    float hue, sat, bright;
    [self getHSVFromRed:r green:g blue:b hue:&hue saturation:&sat brightness:&bright];
    [_dataPointsHue addObject:@(hue)];

    // Only send UI updates once a second and only after min window of time
    if ((_dataPointsHue.count >= (ORKHeartRateMinWindowSeconds * ORKHeartRateFramesPerSecond)) &&
        (_dataPointsHue.count % ORKHeartRateFramesPerSecond == 0)) {
        
        CGFloat bpm = [self calculateBPM];
        _bpm = bpm;
        
        NSInteger displaySeconds = _dataPointsHue.count / ORKHeartRateFramesPerSecond;
        
        [_samples addObject:@{ORKTimestampKey       : @(_timestamp),
                              ORKCameraHeartRateKey : @(bpm),
                              ORKColorHueKey        : @(hue),
                              ORKColorSaturationKey : @(sat),
                              ORKColorBrightnessKey : @(bright),
                              ORKColorRedKey        : @(r),
                              ORKColorGreenKey      : @(g),
                              ORKColorBlueKey       : @(b),
                              }];
        
        NSArray *samples = [_samples copy];
        [_samples removeAllObjects];
        
        // If we have enough data points then remove from beginning
        if (_dataPointsHue.count >= (ORKHeartRateMaxWindowSeconds * ORKHeartRateFramesPerSecond)) {
            [_dataPointsHue removeObjectsInRange:NSMakeRange(0, ORKHeartRateFramesPerSecond)];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateHeartRate:bpm samples:samples displaySeconds:displaySeconds];
        });
        
    } else {
        // just save the samples in batch and send when the heart rate is updated
        [_samples addObject:@{ORKTimestampKey           : @(_timestamp),
                              ORKColorHueKey            : @(hue),
                              ORKColorSaturationKey     : @(sat),
                              ORKColorBrightnessKey     : @(bright),
                              ORKColorRedKey            : @(r),
                              ORKColorGreenKey          : @(g),
                              ORKColorBlueKey           : @(b),
                              }];
    }
    
    // increment the timestamp
    _timestamp += (1.0 / (NSTimeInterval)ORKHeartRateFramesPerSecond);
}

- (void)updateHeartRate:(CGFloat)bpm samples:(NSArray *)samples displaySeconds:(NSInteger)displaySeconds {
    
    NSError *error;
    if (![_logger appendObjects:samples error:&error]) {
        [self finishRecordingWithError:error];
        
    } else if ([self.delegate respondsToSelector:@selector(heartRateDidUpdate:sample:)]) {
        NSDate *endDate = [NSDate date];
        NSDate *startDate = [endDate dateByAddingTimeInterval:-1.0];
        HKQuantity *quantity = [HKQuantity quantityWithUnit:[HKUnit bpmUnit] doubleValue:bpm];
        HKQuantityType *quantityType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate];
        HKQuantitySample *sample = [HKQuantitySample quantitySampleWithType:quantityType
                                                                   quantity:quantity
                                                                  startDate:startDate
                                                                    endDate:endDate];
        [(id)self.delegate heartRateDidUpdate:self sample:sample];
    }
}

- (void)addWatchSamples:(NSArray<HKQuantitySample *> *)watchSamples {
    NSMutableArray *samples = [NSMutableArray new];
    HKUnit *unit = [HKUnit bpmUnit];
    for (HKQuantitySample *sample in watchSamples) {
        NSTimeInterval timestamp = [sample.endDate timeIntervalSinceDate:self.startDate];
        double bpm = [sample.quantity doubleValueForUnit:unit];
        [samples addObject:@{ ORKTimestampKey : @(timestamp),
                              ORKWatchHeartRateKey : @(bpm) }];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        NSError *error;
        if (![_logger appendObjects:samples error:&error]) {
            [self finishRecordingWithError:error];
        }
    });
}

#pragma mark - Data processing

// Algorithms adapted from: https://github.com/lehn0058/ATHeartRate (March 19, 2015)
// with additional modifications by: https://github.com/Litekey/heartbeat-cordova-plugin (July 30, 2015)

#define USE_LIGHT_KEY_ALGORITHM 1
#ifdef USE_LIGHT_KEY_ALGORITHM

- (CGFloat)calculateBPM {
    NSArray *bandpassFilteredItems = [self butterworthBandpassFilter:_dataPointsHue];
    NSArray *smoothedBandpassItems = [self medianSmoothing:bandpassFilteredItems];
    int peak = [self medianPeak:smoothedBandpassItems];
    int heartRate = 60 * ORKHeartRateFramesPerSecond / peak;
    return heartRate;
}

- (int)medianPeak:(NSArray *)inputData
{
    NSMutableArray *peaks = [[NSMutableArray alloc] init];
    int count = 4;
    for (int i = 3; i < inputData.count - 3; i++,count++)
    {
        if (inputData[i] > 0 &&
            [inputData[i] doubleValue] > [inputData[i-1] doubleValue] &&
            [inputData[i] doubleValue] > [inputData[i-2] doubleValue] &&
            [inputData[i] doubleValue] > [inputData[i-3] doubleValue] &&
            [inputData[i] doubleValue] >= [inputData[i+1] doubleValue] &&
            [inputData[i] doubleValue] >= [inputData[i+2] doubleValue] &&
            [inputData[i] doubleValue] >= [inputData[i+3] doubleValue]
            )
        {
            [peaks addObject:@(count)];
            i += 3;
            count = 3;
        }
    }
    [peaks setObject:@([peaks[0] integerValue] + count + 3) atIndexedSubscript: 0];
    [peaks sortUsingComparator:^(NSNumber *a, NSNumber *b){
        return [a compare:b];
    }];
    int medianPeak = (int)[peaks[peaks.count * 2 / 3] integerValue];
    return medianPeak;
}

#else

- (CGFloat)calculateBPM {

    NSArray *bandpassFilteredItems = [self butterworthBandpassFilter:_dataPointsHue];
    NSArray *smoothedBandpassItems = [self medianSmoothing:bandpassFilteredItems];
    NSInteger peakCount = [self peakCount:smoothedBandpassItems];
    
    CGFloat secondsPassed = smoothedBandpassItems.count / ORKHeartRateFramesPerSecond;
    CGFloat percentage = secondsPassed / 60;
    CGFloat bpm = peakCount / percentage;
    
    return bpm;
}


// Find the peaks in our data - these are the heart beats.
// At a 30 Hz detection rate, assuming 250 max beats per minute, a peak can't be closer than 7 data points apart.
- (NSInteger)peakCount:(NSArray *)inputData {
    if (inputData.count == 0) {
        return 0;
    }
    
    NSInteger count = 0;
    
    for (NSInteger i = 3; i < inputData.count - 3;) {
        if (inputData[i] > 0 &&
            [inputData[i] doubleValue] > [inputData[i-1] doubleValue] &&
            [inputData[i] doubleValue] > [inputData[i-2] doubleValue] &&
            [inputData[i] doubleValue] > [inputData[i-3] doubleValue] &&
            [inputData[i] doubleValue] >= [inputData[i+1] doubleValue] &&
            [inputData[i] doubleValue] >= [inputData[i+2] doubleValue] &&
            [inputData[i] doubleValue] >= [inputData[i+3] doubleValue]
            ) {
            count = count + 1;
            i = i + 4;
        } else {
            i = i + 1;
        }
    }
    
    return count;
}

#endif

- (void)getHSVFromRed:(float)r green:(float)g blue:(float)b hue:(float *)h saturation:(float *)s brightness:(float *)v {
    
    float min = MIN(r, MIN(g, b));
    float max = MAX(r, MAX(g, b));
    float delta = max - min;
    if (max == 0) {
        *h = -1;
        return;
    }
    
    float hue;
    if (r == max) {
        hue = (g - b) / delta;
    } else if (g == max) {
        hue = 2 + (b - r) / delta;
    } else {
        hue = 4 + (r - g) / delta;
    }
    hue *= 60;
    if (hue < 0) {
        hue += 360;
    }
    
    *v = max;
    *s = delta / max;
    *h = hue;
}

- (NSArray *)butterworthBandpassFilter:(NSArray *)inputData {
    const int NZEROS = 8;
    const int NPOLES = 8;
    static float xv[NZEROS+1], yv[NPOLES+1];
    
    // http://www-users.cs.york.ac.uk/~fisher/cgi-bin/mkfscript
    // Butterworth Bandpass filter
    // 4th order
    // sample rate - varies between possible camera frequencies. Either 30, 60, 120, or 240 FPS
    // corner1 freq. = 0.667 Hz (assuming a minimum heart rate of 40 bpm, 40 beats/60 seconds = 0.667 Hz)
    // corner2 freq. = 4.167 Hz (assuming a maximum heart rate of 250 bpm, 250 beats/60 secods = 4.167 Hz)
    // Bandpass filter was chosen because it removes frequency noise outside of our target range (both higher and lower)
    double dGain = 1.232232910e+02;
    
    NSMutableArray *outputData = [[NSMutableArray alloc] init];
    for (NSNumber *number in inputData) {
        double input = number.doubleValue;
        
        xv[0] = xv[1]; xv[1] = xv[2]; xv[2] = xv[3]; xv[3] = xv[4]; xv[4] = xv[5]; xv[5] = xv[6]; xv[6] = xv[7]; xv[7] = xv[8];
        xv[8] = input / dGain;
        yv[0] = yv[1]; yv[1] = yv[2]; yv[2] = yv[3]; yv[3] = yv[4]; yv[4] = yv[5]; yv[5] = yv[6]; yv[6] = yv[7]; yv[7] = yv[8];
        yv[8] = (xv[0] + xv[8]) - 4 * (xv[2] + xv[6]) + 6 * xv[4]
        + ( -0.1397436053 * yv[0]) + (  1.2948188815 * yv[1])
        + ( -5.4070037946 * yv[2]) + ( 13.2683981280 * yv[3])
        + (-20.9442560520 * yv[4]) + ( 21.7932169160 * yv[5])
        + (-14.5817197500 * yv[6]) + (  5.7161939252 * yv[7]);
        
        [outputData addObject:@(yv[8])];
    }
    
    return outputData;
}

// Smoothed data helps remove outliers that may be caused by interference, finger movement or pressure changes.
// This will only help with small interference changes.
// This also helps keep the data more consistent.
- (NSArray *)medianSmoothing:(NSArray *)inputData {
    NSMutableArray *newData = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < inputData.count; i++) {
        if (i == 0 ||
            i == 1 ||
            i == 2 ||
            i == inputData.count - 1 ||
            i == inputData.count - 2 ||
            i == inputData.count - 3)        {
            [newData addObject:inputData[i]];
        } else {
            NSArray *items = [@[
                                inputData[i-2],
                                inputData[i-1],
                                inputData[i],
                                inputData[i+1],
                                inputData[i+2],
                                ] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES]]];
            
            [newData addObject:items[2]];
        }
    }
    
    return newData;
}


@end

@implementation ORKHeartRateCameraRecorderConfiguration

- (instancetype)initWithIdentifier:(NSString *)identifier {
    return [super initWithIdentifier:identifier];
}

- (ORKRecorder *)recorderForStep:(ORKStep *)step outputDirectory:(NSURL *)outputDirectory {
    return [[ORKHeartRateCameraRecorder alloc] initWithIdentifier:self.identifier
                                                             step:step
                                                  outputDirectory:outputDirectory];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    return (isParentSame);
}

- (ORKPermissionMask)requestedPermissionMask {
    return ORKPermissionCamera;
}

@end
