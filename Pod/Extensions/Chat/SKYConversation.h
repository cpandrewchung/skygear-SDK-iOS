//
//  Conversation.h
//  Pods
//
//  Created by Andrew Chung on 6/1/16.
//
//

#import "SKYChatRecord.h"
#import <SKYKit/SKYKit.h>

@class SKYChatUser;
@interface SKYConversation : SKYChatRecord

@property (strong, nonatomic) NSArray<NSString *> *participantIds;
@property (strong, nonatomic) NSArray<NSString *> *adminIds;
@property (strong, nonatomic) NSString *title;
@property (assign, nonatomic) BOOL isDirectMessage;
//@property (strong, nonatomic)NSString* updatedAt;
@property (strong, nonatomic) NSDate *updatedDate;
@property (strong, nonatomic) SKYChatUser *otherUser;
@property (strong, nonatomic) NSString *lastMessage;
@property (assign, nonatomic) int count;

//MK related
@property (assign, nonatomic) BOOL isActive;
@property (assign, nonatomic) BOOL isPickedUp;
@property (strong, nonatomic) SKYReference *pickedBy;
@property (strong, nonatomic) SKYReference *endBy;

- (NSString *)toString;
- (NSString *)getOtherUserUserId:(NSString *)myUserId;

@end
