//
//  HUDMainWindow.mm
//  TrollSpeed
//
//  Created by Lessica on 2024/1/24.
//

#import "HUDMainWindow.h"

@implementation HUDMainWindow

+ (BOOL)_isSystemWindow { return YES; }
- (BOOL)_isWindowServerHostingManaged { return NO; }
- (BOOL)_isSecure { return NO; }
- (BOOL)_shouldCreateContextAsSecure { return NO; }

// Enable touch reception for this SpringBoard-hosted overlay window
- (BOOL)_shouldReceiveTouch:(UITouch *)touch { return YES; }
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event { return YES; }

@end
