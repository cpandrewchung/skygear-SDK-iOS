//
//  SKYFetchRecordsOperation.m
//  askq
//
//  Created by Kenji Pa on 21/1/15.
//  Copyright (c) 2015 Rocky Chan. All rights reserved.
//

#import "SKYFetchRecordsOperation.h"

#import "SKYUser.h"
#import "SKYUserRecordID.h"
#import "SKYRecordDeserializer.h"
#import "SKYRecordSerialization.h"
#import "SKYDataSerialization.h"

@implementation SKYFetchRecordsOperation

- (instancetype)initWithRecordIDs:(NSArray *)recordIDs
{
    self = [super init];
    if (self) {
        _recordIDs = recordIDs;
    }
    return self;
}

+ (instancetype)operationWithRecordIDs:(NSArray *)recordIDs
{
    return [[self alloc] initWithRecordIDs:recordIDs];
}

- (void)prepareForRequest
{
    NSMutableArray *stringIDs = [NSMutableArray array];
    [self.recordIDs enumerateObjectsUsingBlock:^(SKYRecordID *obj, NSUInteger idx, BOOL *stop) {
        [stringIDs addObject:[obj canonicalString]];
    }];
    NSMutableDictionary *payload = [@{
                                     @"ids": stringIDs,
                                     @"database_id": self.database.databaseID,
                                     } mutableCopy];
    if ([self.desiredKeys count]) {
        payload[@"desired_keys"] = self.desiredKeys;
    }
    self.request = [[SKYRequest alloc] initWithAction:@"record:fetch"
                                             payload:payload];
    self.request.APIKey = self.container.APIKey;
    self.request.accessToken = self.container.currentAccessToken;
}

- (NSDictionary *)processResultArray:(NSArray *)result
{
    NSMutableDictionary *recordsByRecordID = [NSMutableDictionary dictionary];
    
    [result enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL *stop) {
        NSError *error = nil;
        SKYRecord *record = nil;
        SKYRecordID *recordID = [SKYRecordID recordIDWithCanonicalString:obj[SKYRecordSerializationRecordIDKey]];
        
        if (recordID) {
            if ([obj[SKYRecordSerializationRecordTypeKey] isEqualToString:@"record"]) {
                SKYRecordDeserializer *deserializer = [SKYRecordDeserializer deserializer];
                record = [deserializer recordWithDictionary:obj];
                
                if (!record) {
                    NSLog(@"Error with returned record.");
                }
            } else if ([obj[SKYRecordSerializationRecordTypeKey] isEqualToString:@"error"]) {
                NSMutableDictionary *userInfo = [SKYDataSerialization userInfoWithErrorDictionary:obj];
                userInfo[NSLocalizedDescriptionKey] = @"An error occurred while modifying record.";
                error = [NSError errorWithDomain:(NSString *)SKYOperationErrorDomain
                                            code:0
                                        userInfo:userInfo];
            }
        } else {
            NSMutableDictionary *userInfo = [self errorUserInfoWithLocalizedDescription:@"Missing `_id` or not in correct format."
                                                                        errorDictionary:nil];
            error = [NSError errorWithDomain:(NSString *)SKYOperationErrorDomain
                                        code:0
                                    userInfo:userInfo];
        }
        
        if (!error && !record) {
            NSMutableDictionary *userInfo = [self errorUserInfoWithLocalizedDescription:@"Record does not conform with expected format."
                                                                        errorDictionary:nil];
            error = [NSError errorWithDomain:(NSString *)SKYOperationErrorDomain
                                        code:0
                                    userInfo:userInfo];
        }
        
        if (recordID && self.perRecordCompletionBlock) {
            self.perRecordCompletionBlock(record, recordID, error);
        }
        
        if (record) {
            [recordsByRecordID setObject:record forKey:recordID];
        }
    }];
    
    return recordsByRecordID;
}

- (void)handleRequestError:(NSError *)error
{
    if (self.fetchRecordsCompletionBlock) {
        self.fetchRecordsCompletionBlock(nil, error);
    }
}

- (void)handleResponse:(SKYResponse *)responseObject
{
    NSDictionary *response = responseObject.responseDictionary;
    NSDictionary *resultDictionary = nil;
    NSError *error = nil;
    NSArray *responseArray = response[@"result"];
    if ([responseArray isKindOfClass:[NSArray class]]) {
        resultDictionary = [self processResultArray:responseArray];
    } else {
        NSDictionary *userInfo = [self errorUserInfoWithLocalizedDescription:@"Server returned malformed result."
                                                             errorDictionary:nil];
        error = [NSError errorWithDomain:(NSString *)SKYOperationErrorDomain
                                    code:0
                                userInfo:userInfo];
    }
    
    if (self.fetchRecordsCompletionBlock) {
        self.fetchRecordsCompletionBlock(resultDictionary, error);
    }
}

@end