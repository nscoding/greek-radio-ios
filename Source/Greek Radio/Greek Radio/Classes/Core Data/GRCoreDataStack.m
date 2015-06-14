//
//  GRCoreDataStack.m
//  Greek Radio
//
//  Created by Patrick on 4/30/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//

#import "GRCoreDataStack.h"

static const NSString *kManagedObjectContextKey = @"ManagedObjectContextKey";

@implementation GRCoreDataStack
{
@private
    NSManagedObjectModel *_managedObjectModel;
    NSPersistentStoreCoordinator *_persistentStoreCoordinator;
}

@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

#pragma mark - Singleton

+ (GRCoreDataStack *)shared
{
    static dispatch_once_t pred;
    static GRCoreDataStack *shared = nil;
    dispatch_once(&pred, ^() {
                      shared = [[GRCoreDataStack alloc] init];
                  });
    
    return shared;
}

#pragma mark - Initializer

- (instancetype)init
{
    if ((self = [super init])) {
        [self registerNotitifacations];
    }
    
    return self;
}

#pragma mark - Notifications

- (void)registerNotitifacations
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contextDidSave:)
                                                 name:NSManagedObjectContextDidSaveNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contextDidSave:)
                                                 name:NSManagedObjectContextObjectsDidChangeNotification
                                               object:nil];
}

- (void)contextDidSave:(NSNotification *)notification
{
    [self performSelectorOnMainThread:@selector(mergeChangesWithNotification:)
                           withObject:notification
                        waitUntilDone:NO];
}

- (void)mergeChangesWithNotification:(NSNotification *)notification
{
    [self.managedObjectContext mergeChangesFromContextDidSaveNotification:notification];
}

- (void)saveChanges
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
    [managedObjectContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
    
    if (managedObjectContext != nil)
    {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error])
        {
            /*
             Replace this implementation with code to handle the error appropriately.
             
             abort() causes the application to generate a crash log and terminate. You should not use this
             function in a shipping application, although it may be useful during development. If it is not
             possible to recover from the error, display an alert panel that instructs the user to quit the
             application by pressing the Home button.
             */
            
            DLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

#pragma mark - Core Data Stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext
{
    NSManagedObjectContext *managedObjectContext = nil;
    @synchronized(kManagedObjectContextKey)
    {
        managedObjectContext = [[[NSThread currentThread] threadDictionary] objectForKey:kManagedObjectContextKey];
        if (managedObjectContext == nil)
        {
            NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
            if (coordinator != nil)
            {
                managedObjectContext = [[NSManagedObjectContext alloc] init];
                [managedObjectContext setPersistentStoreCoordinator:coordinator];
                
                [[[NSThread currentThread] threadDictionary] setObject:managedObjectContext
                                                                forKey:kManagedObjectContextKey];
            }
        }
    }
    
    return managedObjectContext;
}

/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created from the application's model.
 */
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil)
    {
        return _managedObjectModel;
    }
    
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"GreekRadioModel" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    
    return _managedObjectModel;
}

/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil)
    {
        return _persistentStoreCoordinator;
    }
    
    NSURL *dbURL = [[self applicationDocumentsDirectoryURL] URLByAppendingPathComponent:@"GreekRadioModel.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc]
                                    initWithManagedObjectModel:[self managedObjectModel]];
    
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                   configuration:nil
                                                             URL:dbURL
                                                         options:[self migrationAndPersistenceOptions]
                                                           error:&error])
    {
        DLog(@"Add persistent store failed with error %@, %@", error, [error userInfo]);
        [self deleteDatabase];
        
        DLog(@"Trying to delete and recreate database...");
        if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                       configuration:nil
                                                                 URL:dbURL
                                                             options:[self migrationAndPersistenceOptions]
                                                               error:&error])
        {
            DLog(@"Add persistent store after delete and recreated failed with error %@, %@", error, [error userInfo]);
            _persistentStoreCoordinator = nil;
            
            // Something went terribly wrong, the application has to abort
            abort();
        }
    }
    
    return _persistentStoreCoordinator;
}



// ------------------------------------------------------------------------------------------
#pragma mark - Exposed Methods
// ------------------------------------------------------------------------------------------
- (NSArray *)fetchObjectsForEntityName:(NSString *)newEntityName withPredicate:(NSPredicate*)predicate
{
    NSEntityDescription *entity = [NSEntityDescription entityForName:newEntityName
                                              inManagedObjectContext:[self managedObjectContext]];
	
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    request.entity = entity;
    
	if (predicate)
    {
        request.predicate = predicate;
    }
	
    NSError *error = nil;
    NSArray *results = [[self managedObjectContext] executeFetchRequest:request
                                                                  error:&error];
    
    if (error != nil)
    {
        [NSException raise:NSGenericException format:@"Error: %@", [error description]];
    }
	else
	{
        results = [results sortedArrayUsingDescriptors:@[[[NSSortDescriptor alloc]
                                                          initWithKey:@"title" ascending:YES]]];
        
		return results;
	}
	
	return nil;
}

- (NSURL *)applicationDocumentsDirectoryURL
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                   inDomains:NSUserDomainMask] lastObject];
}

#pragma mark - Helpers

- (void)deleteDatabase
{
    // Delete our local SQLite db
    // Do not delete anything if we are using a in-memory persistent store.
    BOOL isInMemory = NO;
    
    for (NSPersistentStore *store in [_persistentStoreCoordinator persistentStores])
    {
        if ([[store type] isEqualToString:NSInMemoryStoreType])
        {
            isInMemory = YES;
        }
    }
    
    if (isInMemory) return;
    
    NSError *error = nil;
    NSURL *dbURL = [[self applicationDocumentsDirectoryURL] URLByAppendingPathComponent:@"GreekRadioModel.sqlite"];
    
    // [NSFileManager defaultManager] is not thread-safe.
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    if ([fileManager removeItemAtURL:dbURL error:&error] == NO)
    {
        DLog(@"Persistent store deletion failed with error %@, %@", error, [error userInfo]);
    }
}

- (NSDictionary *)migrationAndPersistenceOptions
{
    return  @{
              NSMigratePersistentStoresAutomaticallyOption : @YES,
              NSInferMappingModelAutomaticallyOption : @YES
             };
}

@end
