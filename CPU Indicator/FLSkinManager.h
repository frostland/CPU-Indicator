//
//  FLSkinManager.h
//  CPU Indicator
//
//  Created by François LAMBOLEY on 3/8/11.
//  Copyright 2011 Frost Land. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FLSkin.h"
#import "FLCPUIndicatorView.h"

@interface FLSkinManager : NSObject {
@private
	NSMutableArray *skinsDescriptions;
	NSMutableArray *cachedSkins;
	
	NSFileManager *fm;
}
- (NSUInteger)nSkins;
- (FLSkin *)skinAtIndex:(NSUInteger)idx;

- (NSUInteger)selectedSkinIndex;

- (BOOL)canRemoveSkinAtIndex:(NSUInteger)idx;
- (BOOL)installSkinAtPath:(NSString *)path useIt:(BOOL)use;
- (BOOL)removeSkinAtIndex:(NSInteger)idx;
- (void)selectSkinAtIndex:(NSUInteger)idx;

@end
