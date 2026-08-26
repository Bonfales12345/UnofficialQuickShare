#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>

NS_ASSUME_NONNULL_BEGIN

@interface QSNotificationCenterHackery : NSObject

+ (void)removeDefaultAction:(UNMutableNotificationContent*) content;

@end

NS_ASSUME_NONNULL_END
