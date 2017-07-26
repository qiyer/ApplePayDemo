//
//  PayManager.m
//  ApplePayDemo
//
//  Created by Zhi Zhuang on 2017/7/25.
//  Copyright © 2017年 Zhi Zhuang. All rights reserved.
//

#import "PayManager.h"
#import "AlipayService.h"
#import "WechatPayService.h"
#import "ApplePayService.h"

#define ToWeak(var, weakVar) __weak __typeof(&*var) weakVar = var

@interface PayManager ()

@property(nonatomic,copy) void(^payBack)(Boolean  ,NSError*);

@end

@implementation PayManager{
    
    AlipayService       * alipay;
    WechatPayService    * wechat;
    ApplePayService     * apple;
    id<PayProtocol>       currentPay;
    dispatch_semaphore_t  semaphore_t;
}

+(instancetype)instance{
    static PayManager * _instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if(!_instance){
            _instance = [[PayManager alloc] init];
        }
    });
    return _instance;
}

-(instancetype)init{
    if (self = [super init]) {
        NSLog(@"do yours");
    }
    return self;
}

-(void)purchase:(NSString*) productID payType:(PayType) payType witchCallback:(void (^)(Boolean isSuccess ,NSError * error))callback
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        self.payBack = callback;
        switch (payType) {
            case PayApple:
                currentPay = self.apple;
                break;
            case PayAlipay:
                currentPay = self.alipay;
                break;
            case PayWechat:
                currentPay = self.wechat;
                break;
            default:
                break;
        }
        
        ToWeak(self,weakSelf);
        [currentPay purchase:productID witchCallback:^(Boolean isSuccess, NSError *error) {
            if(weakSelf.payBack){
                weakSelf.payBack(isSuccess,error);
            }
        }];
    });

}

-(AlipayService*)    alipay{
    return  alipay?:[AlipayService new];
}

-(WechatPayService*) wechat{
    return  wechat?:[WechatPayService new];
}

-(ApplePayService*)  apple{
    return  apple?:[ApplePayService new];
}
@end
