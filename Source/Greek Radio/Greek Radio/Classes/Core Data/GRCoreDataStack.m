//
//  GRCoreDataStack.m
//  Greek Radio
//
//  Created by Patrick on 4/30/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//

#import "GRCoreDataStack.h"

// ------------------------------------------------------------------------------------------


@implementation GRCoreDataStack

@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

// ------------------------------------------------------------------------------------------
#pragma mark - Singleton
// ------------------------------------------------------------------------------------------
+ (GRCoreDataStack *)shared
{
    static dispatch_once_t pred;
    static GRCoreDataStack *shared = nil;
    
    dispatch_once(&pred, ^()
                  {
                      shared = [[GRCoreDataStack alloc] init];
                  });
    
    return shared;
}


// ------------------------------------------------------------------------------------------
#pragma mark - Save
// ------------------------------------------------------------------------------------------
- (void)saveChanges
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
    
    if (managedObjectContext != nil)
    {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error])
        {
            
            /*
             Replace this implementation with code to handle the error appropriately.
             
             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
             */
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

- (void)reset
{
    [[self managedObjectContext] reset];
}

#pragma mark -
#pragma mark Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext
{
    NSManagedObjectContext *managedObjectContext = nil;
    
    
    if (managedObjectContext == nil)
    {
        NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
        
        if (coordinator != nil)
        {
            managedObjectContext = [[NSManagedObjectContext alloc] init];
            [managedObjectContext setPersistentStoreCoordinator:coordinator];
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
    
    NSBundle *bundle = [NSBundle mainBundle];
    
    NSURL *modelURL = [bundle URLForResource:@"GreekRadioModel" withExtension:@"momd"];
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
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:dbURL options:nil error:&error])
    {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}


// ------------------------------------------------------------------------------------------
#pragma mark - Helpers
// ------------------------------------------------------------------------------------------
- (NSArray *)fetchObjectsForEntityName:(NSString *)newEntityName withPredicate:(NSPredicate*)predicate
{
    NSEntityDescription *entity = [NSEntityDescription entityForName:newEntityName inManagedObjectContext:[self managedObjectContext]];
	
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entity];
    
	if(predicate)
    {
        [request setPredicate:predicate];
    }
	
    NSError *error = nil;
    NSArray *results = [[self managedObjectContext] executeFetchRequest:request error:&error];
    
    if (error != nil)
    {
        [NSException raise:NSGenericException format:@"Error: %@",[error description]];
    }
	else
	{
		return results;
	}
	
	return nil;
}


- (NSURL *)applicationDocumentsDirectoryURL
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                   inDomains:NSUserDomainMask] lastObject];
}



@end
