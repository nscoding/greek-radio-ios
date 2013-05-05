//
//  GRCoreDataStack.h
//  Greek Radio
//
//  Created by Patrick on 4/30/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//


#define kManagedObjectContextKey @"ManagedObjectContextKey"

@interface GRCoreDataStack : NSObject
{
@private
	NSManagedObjectModel *_managedObjectModel;
	NSPersistentStoreCoordinator *_persistentStoreCoordinator;
}

@property(nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property(nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property(nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

+ (GRCoreDataStack *)shared;
- (void)saveChanges;
- (NSURL *)applicationDocumentsDirectoryURL;
- (NSArray *)fetchObjectsForEntityName:(NSString *)newEntityName withPredicate:(NSPredicate *)predicate;

@end