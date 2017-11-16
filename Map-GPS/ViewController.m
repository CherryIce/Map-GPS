//
//  ViewController.m
//  Map-GPS
//
//  Created by Macx on 2017/11/16.
//  Copyright © 2017年 Macx. All rights reserved.
//

#import "ViewController.h"

#import <CoreLocation/CoreLocation.h>

#import <MapKit/MapKit.h>

@interface ViewController ()<UITextFieldDelegate,CLLocationManagerDelegate>
{
    CLLocationManager * locationManager;
}

@property (weak, nonatomic) IBOutlet UILabel *currentLocation;
@property (weak, nonatomic) IBOutlet UITextField *endLocationTf;
@property (weak, nonatomic) IBOutlet UILabel *endLocationCode;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    /**遵循代理*/
    self.endLocationTf.delegate = self;
}

/**
 地理位置转地理编码
 */
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    NSString * oreillyAddress = textField.text;
    CLGeocoder * myGeocoder = [[CLGeocoder alloc] init];
    [myGeocoder geocodeAddressString:oreillyAddress completionHandler:^(NSArray *placemarks, NSError *error) {
        if ([placemarks count] > 0 && error == nil) {
            NSLog(@"Found %lu placemark(s).", (unsigned long)[placemarks count]);
            CLPlacemark *firstPlacemark = [placemarks objectAtIndex:0];
            NSString * message = [NSString stringWithFormat:@"经度:%f,纬度:%f",firstPlacemark.location.coordinate.latitude,firstPlacemark.location.coordinate.longitude];
            self.endLocationCode.text = message;
            [self showAlertWithMessage:message];
        }
        else if ([placemarks count] == 0 && error == nil) {
            [self showAlertWithMessage:@"没有找到此位置"];
        } else if (error != nil) {
            [self showAlertWithMessage:[NSString stringWithFormat:@"出错了:%@",error]];
        }
    }];
    return YES;
}

- (IBAction)buttonClick:(UIButton *)sender
{
    switch (sender.tag) {
        case 10:
            [self openLocation];
            break;
        case 11:
            [self openGPS];
            break;
        default:
            break;
    }
}

/**
 开启定位,定位当前位置
 */
- (void) openLocation
{
    //判断定位功能是否打开
    if ([CLLocationManager locationServicesEnabled]) {
        locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        
        locationManager.distanceFilter = 10.0;
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
        // 临时开启后台定位  iOS9新增方法  必须要配置info.plist文件 不然直接崩溃
        if (@available(iOS 9.0, *)) {
            locationManager.allowsBackgroundLocationUpdates = YES;
        } else {
            // Fallback on earlier versions
        }
        
        if ([locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
            [locationManager requestWhenInUseAuthorization];
        }
        
        //[locationManager requestAlwaysAuthorization];
        [locationManager startUpdatingLocation];
    }
}


/**
 开始导航
 */
- (void) openGPS
{
   NSArray * a1 = [self.endLocationCode.text componentsSeparatedByString:@","];
    if (a1.count <= 1) {
        return;
    }
   NSString * lat = [a1[0] componentsSeparatedByString:@":"][1];
   NSString * lon = [a1[1] componentsSeparatedByString:@":"][1];
   [self loadGPSWithLat:lat log:lon];
}

#pragma mark CoreLocation delegate
/**
 定位失败则执行此代理方法
 定位失败弹出提示框,点击"打开定位"按钮,会打开系统的设置,提示打开定位服务
 */
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    UIAlertController * alertVC = [UIAlertController alertControllerWithTitle:@"允许\"定位\"提示" message:@"请在设置中打开定位" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction * ok = [UIAlertAction actionWithTitle:@"打开定位" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        //打开定位设置
        NSURL *settingsURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        [[UIApplication sharedApplication] openURL:settingsURL];
    }];
    UIAlertAction * cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    [alertVC addAction:cancel];
    [alertVC addAction:ok];
    [self presentViewController:alertVC animated:YES completion:nil];
}

/**
 定位成功
 */
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    [locationManager stopUpdatingLocation];
    CLLocation *currentLocation = [locations lastObject];
    CLGeocoder * geoCoder = [[CLGeocoder alloc] init];
    
    //反编码
    [geoCoder reverseGeocodeLocation:currentLocation completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
        if (placemarks.count > 0) {
            CLPlacemark *placeMark = placemarks[0];
            self.currentLocation.text = placeMark.locality;
            if (!placeMark.locality) {
                [self showAlertWithMessage:@"无法定位当前城市"];
            }
            [self showAlertWithMessage:placeMark.name];

        }
        else if (error == nil && placemarks.count == 0) {
             [self showAlertWithMessage:@"无法定位"];
        }
        else if (error) {
            [self showAlertWithMessage:[NSString stringWithFormat:@"定位失败:%@",error]];
        }
        
    }];
}

/**
 地图导航
 */
- (void )loadGPSWithLat:(NSString *)latitude log:(NSString *)longitude
{
    //百度地图
    if ([[UIApplication sharedApplication]canOpenURL:[NSURL URLWithString:@"baidumap://map/"]])
    {
        NSString *urlString = [[NSString stringWithFormat:@"baidumap://map/direction?origin={{我的位置}}&destination=latlng:%f,%f|name=目的地&mode=driving&coord_type=gcj02",[latitude floatValue],[longitude floatValue]] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
    }
    //高德地图
    else if ([[UIApplication sharedApplication]canOpenURL:[NSURL URLWithString:@"iosamap://"]])
    {
        NSString *urlString = [[NSString stringWithFormat:@"iosamap://navi?sourceApplication=%@&backScheme=%@&lat=%f&lon=%f&dev=0&style=2",@"人才赢行",@"iosamap",[latitude floatValue],[longitude floatValue]] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
    }
    //谷歌地图
    else if ([[UIApplication sharedApplication]canOpenURL:[NSURL URLWithString:@"comgooglemaps://"]])
    {
        NSString *urlString = [[NSString stringWithFormat:@"comgooglemaps://?x-source=%@&x-success=%@&saddr=&daddr=%f,%f&directionsmode=driving",@"人才赢行",@"comgooglemaps",[latitude floatValue],[longitude floatValue]] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
    }
    //苹果地图
    else
    {
        //终点坐标
        CLLocationCoordinate2D coords1 = CLLocationCoordinate2DMake([latitude floatValue],[longitude floatValue]);
        //当前位置
        MKMapItem * currentLocation = [MKMapItem mapItemForCurrentLocation];
        //目的地的位置
        MKMapItem * toLocation = [[MKMapItem alloc] initWithPlacemark:[[MKPlacemark alloc] initWithCoordinate:coords1 addressDictionary:nil]];
        toLocation.name = @"目的地";
        
        //        NSString *myname=[dataSource objectForKey:@"name"];
        //
        //        if (![XtomFunction xfunc_check_strEmpty:myname])
        //
        //        {
        //            toLocation.name =myname;
        //        }
        
        [MKMapItem openMapsWithItems:@[currentLocation, toLocation]
                       launchOptions:@{MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving,
                                       MKLaunchOptionsShowsTrafficKey: [NSNumber numberWithBool:YES]}];
    }
}

/**
 提示信息
 */
- (void) showAlertWithMessage:(NSString *)message
{
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"温馨提示" message:message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction * cancle = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    
    [alert addAction:cancle];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
