/*
 * FLDefaultPaths.h
 * CPU Indicator (Originally from Logiblocs)
 *
 * Created by François on 27/07/05.
 * Copyright 2005 Frost Land. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

@interface NSFileManager (FLDefaultPaths)

- (NSString *)getNonExistantFileNameFrom:(NSString *)base withExtension:(NSString *)e
								 showOneForFirst:(BOOL)showFirst;
- (BOOL)createPathIfNecessary:(NSString *)path withAttrs:(NSDictionary *)attributes
						returnedErr:(NSString **)err;

- (NSString *)userLibraryPath;
- (NSString *)userAppSupportPath;
- (NSString *)userCPUIndicatorSupportFolder;

- (NSString *)pathForListSkinsDescr:(BOOL *)exists;
- (NSString *)pathForNewSkin;

@end
