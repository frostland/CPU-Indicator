/*
 * FLDefaultPaths.m
 * CPU Indicator (Originally from Logiblocs)
 *
 * Created by François on 27/07/05.
 * Copyright 2005 Frost Land. All rights reserved.
 */

#import "FLDefaultPaths.h"

@implementation NSFileManager (FLDefaultPaths)

- (NSString *)getNonExistantFileNameFrom:(NSString *)base withExtension:(NSString *)e
								 showOneForFirst:(BOOL)showFirst
{
	unsigned int i = 1;
	NSString *baseb, *retour;
	
	do {
		baseb = (((i == 1) && (! showFirst)) ? base : [base stringByAppendingFormat:@" %d", i]);
		if (e) retour = [baseb stringByAppendingPathExtension:e];
		else retour = baseb;
		i++;
	} while ([self fileExistsAtPath:retour]);
		
	return retour;
}

- (BOOL)createPathIfNecessary:(NSString *)path withAttrs:(NSDictionary *)attributes
						returnedErr:(NSString **)err
{
	BOOL dir;
	if (![self fileExistsAtPath:path isDirectory:&dir]) {
		if (![self createDirectoryAtPath:path withIntermediateDirectories:YES
									 attributes:attributes error:NULL]) {
			if (err)
				*err = @"Path doesn't exist and I can't create it";
			return NO;
		}
	} else if (!dir) {
		if (err)
			*err = @"Path exists but it is a file";
		return NO;
	}
	
	return YES;
}

- (NSString *)userLibraryPath
{
	NSString *err;
	NSString *path;
	NSMutableDictionary *attrs;
	NSArray *libraries = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,
																				NSUserDomainMask,
																				YES);
	if ([libraries count] == 0)
		return nil;
	path = [libraries objectAtIndex:0];
	attrs = [NSMutableDictionary dictionary];
	
	[attrs setValue:[NSNumber numberWithInt:0700] forKey:NSFilePosixPermissions];
	if (![self createPathIfNecessary:path withAttrs:attrs returnedErr:&err]) {
		NSLog(@"*** Can't create dir at path %@ (err msg \"%@\") ***", path, err);
		return nil;
	}
	
	return path;
}

- (NSString *)userAppSupportPath
{
	NSString *err;
	NSString *path;
	NSArray *dirsFound = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,
																				NSUserDomainMask,
																				YES);
	if ([dirsFound count] == 0)
		return nil;
	path = [dirsFound objectAtIndex:0];
	
	if (![self createPathIfNecessary:path withAttrs:nil returnedErr:&err]) {
		NSLog(@"*** Can't create dir at path %@ (err msg \"%@\") ***", path, err);
		return nil;
	}
	
	return path;
}

- (NSString *)userCPUIndicatorSupportFolder
{
	NSString *err;
	NSString *path = [self userAppSupportPath];
	path = [path stringByAppendingPathComponent:@"CPU Indicator"];
	if (![self createPathIfNecessary:path withAttrs:nil returnedErr:&err]) {
		NSLog(@"*** Can't create dir at path %@ (err msg \"%@\") ***", path, err);
		return nil;
	}
	
	return path;
}

- (NSString *)pathForListSkinsDescr:(BOOL *)exists
{
	NSString *path = [self userCPUIndicatorSupportFolder];
	if (!path) return nil;
	
	path = [path stringByAppendingPathComponent:@"Skins.sld"];
	if (exists) *exists = [self fileExistsAtPath:path];
	
	return path;
}

- (NSString *)pathForNewSkin
{
	NSString *base = [self userCPUIndicatorSupportFolder];
	if (!base) return nil;
	
	return [self getNonExistantFileNameFrom:[base stringByAppendingPathComponent:@"skin"] withExtension:@"cpuIndicatorSkin" showOneForFirst:YES];
}

@end
