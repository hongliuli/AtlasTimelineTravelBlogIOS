//
//  ATConstants.m
//  AtlasTimelineIOS
//
//  Created by Hong on 1/25/13.
//  Copyright (c) 2013 hong. All rights reserved.
//

#import "ATConstants.h"
#import "ATHelper.h"

@implementation ATConstants


//SETTINGS FOR PREFERENCE
+ (NSString*)selectedPeriodKey
{
    return @"selectedPeriod";
}
+ (NSString*)period7Day;
{
    return NSLocalizedString(@"7 Days",nil);
}
+ (NSString*)periodMonth;
{
    return NSLocalizedString(@"Month",nil);
}
+ (NSString*)periodYear
{
    return NSLocalizedString(@"Year",nil);
}
+ (NSString*)period10Year
{
    return NSLocalizedString(@"10 Years",nil);
}
+ (NSString*)period100Year
{
    return NSLocalizedString(@"100 Years",nil);
}
+ (NSString*)period1000Year
{
    return NSLocalizedString(@"1000 Years",nil);
}

//IMAGE NAME

+ (NSString*)DefaultAnnotationIdentifier
{
    return @"defaultAnnotationIdentifier";
}
+ (NSString*)SelectedAnnotationIdentifier
{
    return @"marker-selected.png";
}
+ (NSString*)Past1AnnotationIdentifier
{
    return @"marker-bf-1.png";
};
+ (NSString*)Past2AnnotationIdentifier
{
    return @"marker-bf-2.png";
}
+ (NSString*)Past3AnnotationIdentifier
{
    return @"marker-bf-3.png";
}
+ (NSString*)Past4AnnotationIdentifier
{
    return @"marker-bf-4.png";
}
+ (NSString*)After1AnnotationIdentifier
{
    return @"marker-af-1.png";
}
+ (NSString*)After2AnnotationIdentifier
{
    return @"marker-af-2.png";
}
+ (NSString*)After3AnnotationIdentifier
{
    return @"marker-af-3.png";
}
+ (NSString*)After4AnnotationIdentifier
{
    return @"marker-af-4.png";
}
+ (NSString*)WhiteFlagAnnotationIdentifier
{
    return @"small-white-flag.png";
}
+ (int) screenWidth
{
    CGRect screenBound = [[UIScreen mainScreen] bounds];
    CGSize screenSize = screenBound.size;
    if ([ATHelper isAtLeast8])
        return screenSize.width;
    else
    {
        UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
        
        if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight) {
            return [[UIScreen mainScreen] bounds].size.height;
        }
        else{
            return [[UIScreen mainScreen] bounds].size.width;
        }
    }
}
+ (int) screenHeight
{
    CGRect screenBound = [[UIScreen mainScreen] bounds];
    CGSize screenSize = screenBound.size;

    if ([ATHelper isAtLeast8])
        return screenSize.height;
    {
        UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
        
        if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight) {
            return [[UIScreen mainScreen] bounds].size.width;
        }
        else{
            return [[UIScreen mainScreen] bounds].size.height;
        }
    }
}
+ (int) timeSliderX
{
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight)
            return [self timeScrollWindowWidth]/2 + 35;
        else
            return [ATConstants timeScrollWindowWidth]/2 - 75;
    }
    else
    {
        if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight) {
            return 80;
        }
        else{
            return 40;
        }
    }
}
+ (int)timeScrollWindowWidth
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
        if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight) 
            return 900;
        else
            return 700;

    }
    else
        return 460;
}
+ (int) timeScrollWindowX
{
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight) 
            return 70;
        
        else
            return 30;
    }
    else
    {
        if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight) {
            return 10;
        }
        else{
            return -76;
        }
    }
}
+ (int)timeScrollWindowHeight
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        return 60;
    }
    else
        return 40;
}
+ (int) timeScrollCellWidth
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
        if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight)
            return 90;
        else
            return 80;
        
    }
    else
        return 55;
}
+ (int) timeScrollCellHeight
{
    return [self timeScrollWindowHeight];
}
+ (int) photoScrollCellWidth
{
    return 180;
}
+ (int) photoScrollCellHeight
{
    return 180;
}
+ (int)sliderWidth
{
    return 250;
}
+ (int)timeScrollNumOfDateLabels
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        return 9;
    else
        return 9;
}
+ (int) searchBarHeight{
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight) {
            return 34;
        }
        else{
            return 34;
        }
    }
    else
    {
        if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight) {
            return 34;
        }
        else{
            return 34;
        }
    }
}
+ (int) searchBarWidth{
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight) {
            return 300;
        }
        else{
            return 300;
        }
    }
    else
    {
        if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight) {
            return 240;
        }
        else{
            return 180;
        }
    }
}
+ (int) timeZoomerY {// = 18;
    return 6;
}
+ (int) timeScrollWindowY{// = 38;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        return 25;
    else
        return 0;
}
+ (int) defaultZoomLevel{ //currently used when app start and focused clicked in timeline view to map view
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        return 12;
    else
        return 12;
}
+ (int) timeScrollBigDateFont{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) 
        return 17;
    else
        return 15;
}
//Constants for Event List View
+ (int) eventListViewCellWidth{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        return 270;
    else
        return 160;
}
+ (int) eventListViewCellHeight{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        return 120;
    else
        return 100;
}
+ (int) eventListViewCellNum{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        if (UIDeviceOrientationIsPortrait([UIDevice currentDevice].orientation))
            return 6;
        else
            return 4;
    }
    else
    {
        if (UIDeviceOrientationIsPortrait([UIDevice currentDevice].orientation))
            return 4;
        else
            return 2;
    }
}
+ (int) eventListViewPhotoWidht{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        return 100;
    else
        return 60;
}
+ (int) eventListViewPhotoHeight{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        return 70;
    else
        return 40;
}



+ (BOOL) isLandscapeInPhone{
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight));
}
+ (NSString*) defaultSourceName
{
    return @"myEvents";
}
+ (NSString*) UserEmailKeyName
{
    return @"UserEmailKeyName";
}
+ (NSString*) UserSecurityCodeKeyName
{
    return @"UserSecurityCodeKeyName";
}
+ (NSString*) ServerURL
{
    return @"http://www.chroniclemap.com/atlastimelineapi";
}
+ (NSString*) EpisodeDictionaryKeyName
{
    return @"EpisodeDictionaryKeyName";
}
@end
