//
//  GRCoreDataStack.h
//  Greek Radio
//
//  Created by Patrick on 4/30/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//


@interface GRCoreDataStack : NSObject

@property (nonatomic, strong, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

+ (GRCoreDataStack *)shared;

- (void)saveChanges;

- (NSURL *)applicationDocumentsDirectoryURL;

- (NSArray *)fetchObjectsForEntityName:(NSString *)newEntityName
                         withPredicate:(NSPredicate *)predicate;

@end
