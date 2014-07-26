//
//  GRCoreDataStack.h
//  Greek Radio
//
//  Created by Patrick on 4/30/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//


@interface GRCoreDataStack : NSObject

@property(nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property(nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property(nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

+ (GRCoreDataStack *)shared;

/// Saves changes on the core data context
- (void)saveChanges;

/// Method to retrieve the documents direcectory for this application, returns nil if it doesn't exist
- (NSURL *)applicationDocumentsDirectoryURL;

/// Exposed methods which is used from the DAO to fetch specific entities with a specific predicate.
- (NSArray *)fetchObjectsForEntityName:(NSString *)newEntityName withPredicate:(NSPredicate *)predicate;

@end