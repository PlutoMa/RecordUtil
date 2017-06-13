//
//  RecordUtil.h
//  RecordUtilExample
//
//  Created by Dareway on 2017/6/13.
//  Copyright © 2017年 Pluto. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RecordUtil;

@protocol RecordUtilDelegate <NSObject>
- (void)createRecordFailOnRecordUtil:(RecordUtil *)util;
- (void)recordStartWithRecordUtil:(RecordUtil *)util;
- (void)recordUtil:(RecordUtil *)util didEndRecord:(NSData *)recordData;
- (void)timeNotEnoughWithRecordUtil:(RecordUtil *)util;
- (void)recordCancelWithRecordUtil:(RecordUtil *)util;
- (void)recordUtil:(RecordUtil *)util voiceChange:(double)newVoice;
@end

@interface RecordUtil : NSObject

@property (nonatomic, weak) id<RecordUtilDelegate> delegate;

///单利
+ (instancetype)standardRecordUtil;

///开始录音
- (void)startRecord;
///结束录音
- (void)stopRecord;
///取消录音
- (void)cancelRecord;
@end
