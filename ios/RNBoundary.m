
#import "RNBoundary.h"

@implementation RNBoundary

RCT_EXPORT_MODULE()

-(instancetype)init
{
    self = [super init];
    if (self) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
    }

    return self;
}

RCT_EXPORT_METHOD(add:(NSDictionary*)boundary addWithResolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
     if (CLLocationManager.authorizationStatus != kCLAuthorizationStatusAuthorizedAlways) {
         [self.locationManager requestAlwaysAuthorization];
     }

    // if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways) {
        NSString *id = boundary[@"id"];
        CLLocationCoordinate2D center = CLLocationCoordinate2DMake([boundary[@"lat"] doubleValue], [boundary[@"lng"] doubleValue]);
        CLRegion *boundaryRegion = [[CLCircularRegion alloc]initWithCenter:center
                                                                    radius:[boundary[@"radius"] doubleValue]
                                                                identifier:id];

        [self.locationManager startMonitoringForRegion:boundaryRegion];


        resolve(id);
    // } else {
    //     reject(@"PERM", @"Access fine location is not permitted", [NSError errorWithDomain:@"boundary" code:200 userInfo:@{@"Error reason": @"Invalid permissions"}]);
    // }
}

RCT_EXPORT_METHOD(remove:(NSString *)boundaryId removeWithResolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    if ([self removeBoundary:boundaryId]) {
        resolve(boundaryId);
    } else {
        reject(@"@no_boundary", @"No boundary with the provided id was found", [NSError errorWithDomain:@"boundary" code:200 userInfo:@{@"Error reason": @"Invalid boundary ID"}]);
    }
}

RCT_EXPORT_METHOD(removeAll:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    @try {
        [self removeAllBoundaries];
    }
    @catch (NSError *ex) {
        reject(@"failed_remove_all", @"Failed to remove all boundaries", ex);
    }
    resolve(NULL);
}

- (void) removeAllBoundaries
{
    for(CLRegion *region in [self.locationManager monitoredRegions]) {
        [self.locationManager stopMonitoringForRegion:region];
    }
}

- (bool) removeBoundary:(NSString *)boundaryId
{
    for(CLRegion *region in [self.locationManager monitoredRegions]){
        if ([region.identifier isEqualToString:boundaryId]) {
            [self.locationManager stopMonitoringForRegion:region];
            return true;
        }
    }
    return false;
}

- (NSArray<NSString *> *)supportedEvents
{
    return @[@"onEnter", @"onExit"];
}

-(void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region{
    
    NSLog(@"state ==== %ld for region %@",state,region);
    
    if(state == CLRegionStateInside){
        [self sendEventWithName:@"onEnter" body:region.identifier];
    }

}

//- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
//{
//    NSLog(@"didEnter : %@", region);
//    [self sendEventWithName:@"onEnter" body:region.identifier];
//}
//
- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    NSLog(@"didExit : %@", region);
    [self sendEventWithName:@"onExit" body:region.identifier];
}

+ (BOOL)requiresMainQueueSetup
{
  return YES;
}

@end
