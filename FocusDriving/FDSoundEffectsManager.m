//
//  FDSoundEffectsManager.m
//  FocusDriving
//
//  Created by Timothy Brandt on 3/08/15.
//

#import "FDSoundEffectsManager.h"
#import "SoundEffectTool.h"

NSString* const kPickupDeviceSound = @"buzzer.wav";

@interface FDSoundEffectsManager () {
  SoundEffectTool* _pickupDeviceSoundEffect;
}

@end

@implementation FDSoundEffectsManager

- (id)init {
  self = [super init];
  if(self) {
    _pickupDeviceSoundEffect = [[SoundEffectTool alloc] initWithSoundEffectName:kPickupDeviceSound];
  }
  return self;
}

- (void)playPickupDeviceSound {
  [_pickupDeviceSoundEffect play];
}

@end
