//
//  MotionDetecter.m
//  MotionDetection
//
// The MIT License (MIT)
//
// Created by : arturdev
// Copyright (c) 2014 SocialObjects Software. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
// the Software, and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE

#import "FDMotionDetector.h"
#import "FDSettingsManager.h"

CGFloat kMinimumSpeed        = 0.3f;
CGFloat kMaximumWalkingSpeed = 1.9f;
CGFloat kMaximumRunningSpeed = 7.5f;
CGFloat kMinimumRunningAcceleration = 3.5f;
CGFloat kPickupDetectionHoldTime = 10;

@interface FDMotionDetector()

@property (strong, nonatomic) NSDate *pickupDetectingTimerResumeDate;
@property (strong, nonatomic) NSTimer *pickupDetectingTimer;

@property (strong, nonatomic) CLLocation *currentLocation;
@property (strong, nonatomic) CLLocation *lastLocation;
@property (nonatomic) SOMotionType previousMotionType;

@property (nonatomic, assign) BOOL isDriving;
@property (nonatomic, assign) NSTimeInterval lastTotalDrivingTime;
@property (nonatomic, strong) NSDate* drivingStartTime;

@property (nonatomic, assign) NSUInteger locationSamples;

#pragma mark - Accelerometer manager
@property (strong, nonatomic) CMMotionManager *motionManager;
@property (strong, nonatomic) CMMotionActivityManager *motionActivityManager;


@end

@implementation FDMotionDetector

+ (FDMotionDetector *)sharedInstance
{
  static FDMotionDetector *instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[self alloc] init];
  });
  
  return instance;
}

- (id)init
{
  self = [super init];
  if (self)
  {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLocationChangedNotification:) name:LOCATION_DID_CHANGED_NOTIFICATION object:nil];
    self.motionManager = [[CMMotionManager alloc] init];
    _currentWalkingDistance = 0;
    _currentRunningDistance = 0;
    _currentDrivingDistance = 0;
    _locationSamples = 0;
    _currentLocation = nil;
    _lastLocation = nil;
    _totalDrivingTime = 0;
    _isDriving = NO;
  }
  
  return self;
}

+ (BOOL)motionHardwareAvailable
{
  static BOOL isAvailable = NO;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    isAvailable = [CMMotionActivityManager isActivityAvailable];
  });
  
  return isAvailable;
}

#pragma mark - Public Methods
- (void)startDetection
{
  [[FDLocationManager sharedInstance] start];
  
  self.pickupDetectingTimer = [NSTimer scheduledTimerWithTimeInterval:0.01f target:self selector:@selector(detectPickup) userInfo:Nil repeats:YES];
  _pickupDetectingTimerResumeDate = [NSDate date];
  
  [self.motionManager startAccelerometerUpdatesToQueue:[[NSOperationQueue alloc] init] withHandler:^(CMAccelerometerData *accelerometerData, NSError *error)
   {
     _acceleration = accelerometerData.acceleration;
     [self calculateMotionType];
     dispatch_async(dispatch_get_main_queue(), ^{
       if (self.delegate && [self.delegate respondsToSelector:@selector(motionDetector:accelerationChanged:)])
       {
         [self.delegate motionDetector:self accelerationChanged:self.acceleration];
       }
     });
   }];
  
  [self.motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMDeviceMotion *data, NSError *error)
   {
     _deviceMotion = data;
     dispatch_async(dispatch_get_main_queue(), ^{
       if (self.delegate && [self.delegate respondsToSelector:@selector(motionDetector:deviceMotionChanged:)])
       {
         [self.delegate motionDetector:self deviceMotionChanged:self.deviceMotion];
       }
     });
   }];
  
  if (self.useM7IfAvailable && [FDMotionDetector motionHardwareAvailable])
  {
    if (!self.motionActivityManager)
    {
      self.motionActivityManager = [[CMMotionActivityManager alloc] init];
    }
    
    [self.motionActivityManager startActivityUpdatesToQueue:[[NSOperationQueue alloc] init] withHandler:^(CMMotionActivity *activity) {
      dispatch_async(dispatch_get_main_queue(), ^{
        
        if (activity.walking)
        {
          _motionType = MotionTypeWalking;
        }
        else if (activity.running)
        {
          _motionType = MotionTypeRunning;
        }
        else if (activity.automotive)
        {
          _motionType = MotionTypeAutomotive;
        }
        else if (activity.stationary || activity.unknown)
        {
          _motionType = MotionTypeNotMoving;
        }
        
        // force driving mode override
        if ([FDSettingsManager forceDrivingMode]) {
          _motionType = MotionTypeAutomotive;
        }
        
        // If type was changed, then call delegate method
        if (self.motionType != self.previousMotionType)
        {
          self.previousMotionType = self.motionType;
          
          if (self.delegate && [self.delegate respondsToSelector:@selector(motionDetector:motionTypeChanged:)])
          {
            [self.delegate motionDetector:self motionTypeChanged:self.motionType];
          }
        }
      });
      
    }];
  }
}

- (void)stopDetection
{
  [self.pickupDetectingTimer invalidate];
  self.pickupDetectingTimer = nil;
  
  [[FDLocationManager sharedInstance] stop];
  [self.motionManager stopAccelerometerUpdates];
  [self.motionActivityManager stopActivityUpdates];
  [self stopDriving];
}

#pragma mark - Customization Methods
- (void)setMinimumSpeed:(CGFloat)speed
{
  kMinimumSpeed = speed;
}

- (void)setMaximumWalkingSpeed:(CGFloat)speed
{
  kMaximumWalkingSpeed = speed;
}

- (void)setMaximumRunningSpeed:(CGFloat)speed
{
  kMaximumRunningSpeed = speed;
}

- (void)setMinimumRunningAcceleration:(CGFloat)acceleration
{
  kMinimumRunningAcceleration = acceleration;
}
#pragma mark - Private Methods
- (void)calculateMotionType
{
  if (self.useM7IfAvailable && [FDMotionDetector motionHardwareAvailable])
  {
    return;
  }
  
  if (_currentSpeed < kMinimumSpeed)
  {
    _motionType = MotionTypeNotMoving;
  }
  else if (_currentSpeed <= kMaximumWalkingSpeed)
  {
    _motionType = _isPickedUp ? MotionTypeRunning : MotionTypeWalking;
  }
  else if (_currentSpeed <= kMaximumRunningSpeed)
  {
    _motionType = _isPickedUp ? MotionTypeRunning : MotionTypeAutomotive;
  }
  else
  {
    _motionType = MotionTypeAutomotive;
  }
  
  // If type was changed, then call delegate method
  if (self.motionType != self.previousMotionType)
  {
    self.previousMotionType = self.motionType;
    
    dispatch_async(dispatch_get_main_queue(), ^{
      if (self.delegate && [self.delegate respondsToSelector:@selector(motionDetector:motionTypeChanged:)])
      {
        [self.delegate motionDetector:self motionTypeChanged:self.motionType];
      }
    });
  }
}

- (void)updateDistanceAndTime {
  if (!_currentLocation || !_lastLocation) return;
  CLLocationDistance newDistanceSample = [self.currentLocation distanceFromLocation:self.lastLocation];
  
  switch (_motionType) {
    case MotionTypeNotMoving:
      break;
    case MotionTypeWalking:
      _currentWalkingDistance += newDistanceSample;
      _locationSamples++;
      break;
    case MotionTypeRunning:
      _currentRunningDistance += newDistanceSample;
      _locationSamples++;
      break;
    case MotionTypeAutomotive:
      if (!_isDriving) {
        [self startDriving];
      }
      [self updateDriving];
      _currentDrivingDistance += newDistanceSample;
      _locationSamples++;
      break;
  }
  if (_isDriving && (_motionType != MotionTypeAutomotive)) {
    [self stopDriving];
  }
}

- (void)detectPickup
{
  // pickups only valid when user is driving
  if (_motionType != MotionTypeAutomotive) {
    _isPickedUp = NO;
    return;
  }
  if ([[NSDate date] compare:_pickupDetectingTimerResumeDate] == NSOrderedAscending) {
    return;
  }
  _isPickedUp = NO;
  if ((fabs(_deviceMotion.rotationRate.x) > 1.f) || (fabs(_deviceMotion.rotationRate.y) > 1.f) || (fabs(_deviceMotion.rotationRate.z) > 1.f)) {
    _isPickedUp = YES;
    _pickupDetectingTimerResumeDate = [[NSDate date] dateByAddingTimeInterval:kPickupDetectionHoldTime];
  }
}

- (void)startDriving {
  _isDriving = YES;
  // cache last driving interval
  _lastTotalDrivingTime = self.totalDrivingTime;
  _drivingStartTime = [NSDate date];
}

- (void)updateDriving {
  _totalDrivingTime = _lastTotalDrivingTime + [[NSDate date] timeIntervalSinceDate:_drivingStartTime];
  _drivingPoints = ((_currentDrivingDistance / 1609.f) * 100.f) + ((_totalDrivingTime / 60.f) * 20.f);
}

- (void)stopDriving {
  if (!_isDriving) return;
  // push back new driving interval
  [self updateDriving];
  _isDriving = NO;
}

#pragma mark - LocationManager notification handler
- (void)handleLocationChangedNotification:(NSNotification *)note
{
  self.lastLocation = self.currentLocation;
  self.currentLocation = [FDLocationManager sharedInstance].lastLocation;
  _currentSpeed = self.currentLocation.speed;
  if (_currentSpeed < 0)
    _currentSpeed = 0;
  
  dispatch_async(dispatch_get_main_queue(), ^{
    if (self.delegate && [self.delegate respondsToSelector:@selector(motionDetector:locationChanged:)])
    {
      [self.delegate motionDetector:self locationChanged:self.currentLocation];
    }
  });
  
  [self calculateMotionType];
  [self updateDistanceAndTime];
}
@end
