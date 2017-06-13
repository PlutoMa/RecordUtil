//
//  RecordUtil.m
//  RecordUtilExample
//
//  Created by Dareway on 2017/6/13.
//  Copyright © 2017年 Pluto. All rights reserved.
//

#import "RecordUtil.h"
#import <AVFoundation/AVFoundation.h>
#import <Pluto/Pluto.h>

@interface RecordUtil ()
@property (nonatomic, strong) AVAudioRecorder *recorder;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) CFAbsoluteTime startTime;
@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, assign) double lowPassResults;
@end

@implementation RecordUtil

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if ([[[UIDevice currentDevice] systemVersion] compare:@"7.0"] != NSOrderedAscending) {
                // 7.0第一次运行会提示，是否允许使用麦克风
                AVAudioSession *session = [AVAudioSession sharedInstance];
                NSError *sessionError;
                [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&sessionError];
                if(session == nil) {
                    NSLog(@"Error creating session: %@", [sessionError description]);
                } else {
                    [session setActive:YES error:nil];
                    
                }
            }
        });
    });
}

static RecordUtil *util = nil;
+ (instancetype)standardRecordUtil {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        util = [[RecordUtil alloc] init];
    });
    return util;
}

#pragma mark - 录音相关

///开始录音
- (void)startRecord {
    if ([self canRecord]) {
        if (!self.recorder) {
            NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
            self.fileName = [NSString stringWithFormat:@"%@/play.aac",docDir];
            //录音设置
            NSDictionary *recorderSettingsDict =[[NSDictionary alloc] initWithObjectsAndKeys:
                                                 [NSNumber numberWithInt:kAudioFormatMPEG4AAC],AVFormatIDKey,
                                                 [NSNumber numberWithInt:1000.0],AVSampleRateKey,
                                                 [NSNumber numberWithInt:2],AVNumberOfChannelsKey,
                                                 [NSNumber numberWithInt:8],AVLinearPCMBitDepthKey,
                                                 [NSNumber numberWithBool:NO],AVLinearPCMIsBigEndianKey,
                                                 [NSNumber numberWithBool:NO],AVLinearPCMIsFloatKey,
                                                 nil];
            self.recorder = [[AVAudioRecorder alloc] initWithURL:[NSURL URLWithString:self.fileName] settings:recorderSettingsDict error:nil];
        }
        
        if (self.recorder) {
            
            self.recorder.meteringEnabled = YES;
            [self.recorder prepareToRecord];
            [self.recorder record];
            
            self.timer = PltTimerCommonModes(0.1, self, @selector(timerAction:), nil);
            [self.timer fire];
            
            self.startTime = CFAbsoluteTimeGetCurrent();
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(recordStartWithRecordUtil:)]) {
                [self.delegate recordStartWithRecordUtil:self];
            }
            
        } else {
            if (self.delegate && [self.delegate respondsToSelector:@selector(createRecordFailOnRecordUtil:)]) {
                [self.delegate createRecordFailOnRecordUtil:self];
            }
        }
    }
}

///结束录音
- (void)stopRecord {
    [self.recorder stop];
    self.recorder = nil;
    [self.timer invalidate];
    self.timer = nil;
    
    CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent();
    if (endTime - self.startTime < 0.5) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(timeNotEnoughWithRecordUtil:)]) {
            [self.delegate timeNotEnoughWithRecordUtil:self];
        }
    } else {
        if (self.delegate && [self.delegate respondsToSelector:@selector(recordUtil:didEndRecord:)] && self.fileName) {
            [self.delegate recordUtil:self didEndRecord:[NSData dataWithContentsOfFile:self.fileName]];
        }
    }
}

///取消录音
- (void)cancelRecord {
    [self.recorder stop];
    self.recorder = nil;
    [self.timer invalidate];
    self.timer = nil;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(recordCancelWithRecordUtil:)]) {
        [self.delegate recordCancelWithRecordUtil:self];
    }
}

- (void)timerAction:(NSTimer *)timer {
    [self.recorder updateMeters];
    double peakPowerForChannel = pow(10, (0.05 * [self.recorder peakPowerForChannel:0]));
    self.lowPassResults = 0.05 * peakPowerForChannel + (1.0 - 0.05) * self.lowPassResults;
    if (self.delegate && [self.delegate respondsToSelector:@selector(recordUtil:voiceChange:)]) {
        [self.delegate recordUtil:self voiceChange:self.lowPassResults];
    }
}

-(BOOL)canRecord
{
    __block BOOL bCanRecord = YES;
    if ([[[UIDevice currentDevice] systemVersion] compare:@"7.0"] != NSOrderedAscending) {
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        if ([audioSession respondsToSelector:@selector(requestRecordPermission:)]) {
            [audioSession performSelector:@selector(requestRecordPermission:) withObject:^(BOOL granted) {
                if (granted) {
                    bCanRecord = YES;
                }
                else {
                    bCanRecord = NO;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[[UIAlertView alloc] initWithTitle:nil
                                                    message:@"需要访问您的麦克风。\n请启用麦克风-设置/隐私/麦克风"
                                                   delegate:nil
                                          cancelButtonTitle:@"关闭"
                                          otherButtonTitles:nil] show];
                    });
                }
            }];
        }
    }
    
    return bCanRecord;
}


@end
