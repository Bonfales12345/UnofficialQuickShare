#import <UserNotifications/UserNotifications.h>
#import <AppKit/AppKit.h>
#import "QSNotificationCenterHackery.h"

@interface UNMutableNotificationCategory : UNNotificationCategory
@property(copy) NSString *actionsMenuTitle;
@property(copy) UNNotificationAction *alternateAction;
@property(copy) NSArray *minimalActions;
@property unsigned long long backgroundStyle;
@property(copy) NSArray *actions;
@end

@interface UNNotificationIcon : NSObject
+ (id)iconForApplicationIdentifier:(id)arg1;
+ (id)iconAtPath:(id)arg1;
+ (id)iconNamed:(id)arg1;
@end

@interface UNMutableNotificationContent (QSPrivateAPIs)
@property BOOL hasDefaultAction;
@property(copy) NSString *defaultActionTitle;
@property(copy) NSString *header;
@property (assign,nonatomic) BOOL shouldDisplayActionsInline;
@property (assign,nonatomic) BOOL shouldShowSubordinateIcon;
@property (nonatomic,copy) NSString * accessoryImageName;
@property(copy) UNNotificationIcon *icon;
@end

@implementation QSNotificationCenterHackery

+ (void)removeDefaultAction:(UNMutableNotificationContent*) content{
	content.hasDefaultAction=false;
}

@end
