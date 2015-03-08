//
//  FDSettingsManager.m
//  FocusDriving
//
//  Created by Timothy Brandt on 03/08/15.
//

#import "FDSettingsManager.h"
#import "NSString+FocusDriving.h"

typedef NS_ENUM(NSInteger, SPSettingsServer) {
  SPSettingsServerProduction,
  SPSettingsServerStaging,
  SPSettingsServerDevelopment
};

@implementation FDSettingsManager

+ (BOOL)forceDrivingMode {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"force_driving_mode"];
}

//+ (NSURL *)serverOverrideAPIURL {
//  NSString* url = [[NSUserDefaults standardUserDefaults] stringForKey:@"settings_override_url"];
//  
//  if ([url isNotBlank]) {
//    return [NSURL URLWithString:url];
//  }
//  
//  return nil;
//}
//
//+ (NSURL *)serverAPIURL {
//  NSString* url;
//  
//  switch ([self serverEnvironment]) {
//    case SPSettingsServerProduction:  url = kFocusDrivingApiURLProduction;  break;
//    case SPSettingsServerStaging:     url = kFocusDrivingApiURLStaging;     break;
//    case SPSettingsServerDevelopment: url = kFocusDrivingApiURLDevelopment; break;
//  }
//  
//  return [NSURL URLWithString:url];
//}
//
//+ (NSURL *)serverBaseURL {
//  NSString* url;
//  
//  switch ([self serverEnvironment]) {
//    case SPSettingsServerProduction:  url = kFocusDrivingBaseURLProduction;  break;
//    case SPSettingsServerStaging:     url = kFocusDrivingBaseURLStaging;     break;
//    case SPSettingsServerDevelopment: url = kFocusDrivingBaseURLDevelopment; break;
//  }
//  
//  return [NSURL URLWithString:url];
//}
//
//+ (SPSettingsServer)serverEnvironment {
//  NSString* server = [[NSUserDefaults standardUserDefaults] stringForKey:@"settings_server"];
//  
//  if ([server isEqualToString:@"settings_server_production"]) {
//    return SPSettingsServerProduction;
//  }
//  else if ([server isEqualToString:@"settings_server_staging"]) {
//    return SPSettingsServerStaging;
//  }
//  else if ([server isEqualToString:@"settings_server_development"]) {
//    return SPSettingsServerDevelopment;
//  }
//  
//  return SPSettingsServerProduction;
//}

@end
