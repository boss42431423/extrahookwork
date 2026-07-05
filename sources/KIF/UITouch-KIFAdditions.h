//
//  UITouch-KIFAdditions.h
//  KIF
//

#import <UIKit/UIKit.h>

@interface UITouch (KIFAdditions)

- (id)initTouch;
- (id)initAtPoint:(CGPoint)point inWindow:(UIWindow *)window;
- (id)initAtPoint:(CGPoint)point inWindow:(UIWindow *)window onView:(UIView *)view;
- (void)setPhaseAndUpdateTimestamp:(UITouchPhase)phase;
- (void)setLocationInWindow:(CGPoint)location;

@end
