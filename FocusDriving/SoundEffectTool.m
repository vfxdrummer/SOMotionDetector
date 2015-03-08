//
//  SoundEffectTool.m
//  FocusDriving
//
//  Created by Timothy Brandt on 3/08/15.
//

#import "SoundEffectTool.h"

@implementation SoundEffectTool

- (id)initWithSoundEffectName:(NSString *)name {
  self = [super init];
  if(self) {
    NSURL* soundEffectURL = [[NSBundle mainBundle] URLForResource:name withExtension:nil];
    if(soundEffectURL) {
      _soundFileURL = (__bridge CFURLRef)soundEffectURL;
      AudioServicesCreateSystemSoundID(_soundFileURL, &_soundFileObject);
    }
  }
  return self;
}

- (BOOL)soundEnabled {
  return [[NSUserDefaults standardUserDefaults] boolForKey:@"sounds_enabled"];
}

- (void)play {
  if  (![self soundEnabled]) return;
  AudioServicesPlaySystemSound(_soundFileObject);
}

- (void)dealloc {
  AudioServicesDisposeSystemSoundID(_soundFileObject);
}

@end
