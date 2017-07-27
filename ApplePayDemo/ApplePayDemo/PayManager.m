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
#import <UIKit/UIKit.h>

#define ToWeak(var, weakVar) __weak __typeof(&*var) weakVar = var

@interface PayManager ()

@property(nonatomic,copy) void(^payBack)(Boolean  ,NSError*);
@property(nonatomic,strong) dispatch_semaphore_t  semaphore;

@end

@implementation PayManager{
    
    AlipayService       * alipay;
    WechatPayService    * wechat;
    ApplePayService     * apple;
    id<PayProtocol>       currentPay;
}

+ (void)load
{
    __block id observer =
    [[NSNotificationCenter defaultCenter]
     addObserverForName:UIApplicationDidFinishLaunchingNotification
     object:nil
     queue:nil
     usingBlock:^(NSNotification *note) {
         PAY;//初始化 ApplePayService ， addTransactionObserver
         [[NSNotificationCenter defaultCenter] removeObserver:observer];
     }];
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
        self.semaphore = dispatch_semaphore_create(1);
        currentPay = self.apple;
        NSLog(@"do yours");
    }
    return self;
}

-(void)purchase:(NSString*) productID payType:(PayType) payType witchCallback:(void (^)(Boolean isSuccess ,NSError * error))callback
{
    ToServerLog(@"purchase %@",productID);
    
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
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
        [self creatServerOrder:productID];
    });

}

-(void)creatServerOrder:(NSString*) productID
{
    ToServerLog(@"creatServerOrder %@",productID);
    //-----------send server-------------
    //
    //      向自己服务器发送创建订单请求
    //
    //-----------from server-------------
    
    ToServerLog(@"creatOrder %@ success",productID);
    
    //  假设 money 是余额
    int money = 0;
    
    //假设订单 价格10元
    if (money > 10) {
        
        ToServerLog(@"use 余额 %@",productID);
        //-----------send server-------------
        //
        //      确认使用余额购买该订单
        //
        //-----------from server-------------
    }else{
        
        ToServerLog(@"假设使用App Store购买  %@",productID);
        ToWeak(self,weakSelf);
        [currentPay purchase:productID witchCallback:^(Boolean isSuccess, NSError *error) {
            dispatch_semaphore_signal(weakSelf.semaphore);
            
            ToServerLog(@"购买结果  %@",productID);
            
            if(weakSelf.payBack){
                weakSelf.payBack(isSuccess,error);
            }
        }];
    }

}

-(AlipayService*)    alipay{
    return  alipay?:[[AlipayService alloc]init];
}

-(WechatPayService*) wechat{
    return  wechat?:[[WechatPayService alloc]init];
}

-(ApplePayService*)  apple{
    return  apple?:[[ApplePayService alloc]init];
}
@end
