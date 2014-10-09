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

@property(readonly, copy) NSString *userLibraryPath;
@property(readonly, copy) NSString *userAppSupportPath;
@property(readonly, copy) NSString *userCPUIndicatorSupportFolder;

- (NSString *)pathForListSkinsDescr:(BOOL *)exists;
- (NSString *)fullSkinPathFrom:(NSString *)skinFileName;
@property(readonly, copy) NSString *pathForNewSkin;

@end
