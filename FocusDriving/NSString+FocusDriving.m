//
//  NSString+FocusDriving.m
//  FocusDriving
//
//  Created by Timothy Brandt on 03/08/15.
//

#import "NSString+FocusDriving.h"

@implementation NSString (FocusDriving)

- (BOOL)isNotBlank {
  return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length > 0;
}

- (NSString *)trimWhitespace {
  return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

@end
