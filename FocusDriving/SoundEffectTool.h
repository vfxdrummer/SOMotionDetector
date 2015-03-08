//
//  SoundEffectTool.h
//  FocusDriving
//
//  Created by Timothy Brandt on 3/08/15.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface SoundEffectTool: NSObject {
  CFURLRef _soundFileURL;
  SystemSoundID _soundFileObject;
}

- (id)initWithSoundEffectName:(NSString *)name;

- (void)play;

@end
