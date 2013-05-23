//
//  ATDataController.m
//  AtlasTimelineIOS
//
//  Created by Hong on 1/9/13.
//  Copyright (c) 2013 hong. All rights reserved.
//

#import "ATDataController.h"
#import "CoreData/CoreData.h"
#import "ATEventEntity.h"
#import "ATPreferenceEntity.h"
#import "ATEventDataStruct.h"
#import "ATHelper.h"

@implementation ATDataController

#pragma mark -
#pragma mark Core Data stack

- (ATDataController*) initWithDatabaseFileName: (NSString*) dbFileName
{
    self = [super init];
    if (self)
    {
        databaseFileName = dbFileName;
    }
    return self;
}
/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *) managedObjectContext {
	
    if (managedObjectContext != nil) {
        return managedObjectContext;
    }
	
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator: coordinator];
    }
    return managedObjectContext;
}


/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created by merging all of the models found in the application bundle.
 */
- (NSManagedObjectModel *)managedObjectModel {
	
    if (managedObjectModel != nil) {
        return managedObjectModel;
    }
    managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    return managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
	
    if (persistentStoreCoordinator != nil) {
        return persistentStoreCoordinator;
    }
	
	NSString *storePath = [[ATHelper applicationDocumentsDirectory] stringByAppendingPathComponent: databaseFileName];
	NSFileManager *fileManager = [NSFileManager defaultManager];
    
    /***** this is for debug to remove sqlite file, especially after change model
     [fileManager removeItemAtPath:storePath error:nil];
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
     [userDefaults removeObjectForKey:@"SELECTED_DATA_SOURCE"];
    ************/
    
	// If the expected store doesn't exist, copy the default store.
	if (![fileManager fileExistsAtPath:storePath]) {
		NSString *defaultStorePath = [[NSBundle mainBundle] pathForResource:databaseFileName ofType:@"sqlite"];
		if (defaultStorePath) {
			[fileManager copyItemAtPath:defaultStorePath toPath:storePath error:NULL];
		}
	}
    
	NSURL *storeUrl = [NSURL fileURLWithPath:storePath];
	
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
    
	NSError *error;
	if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:options error:&error]) {
		// Update to handle the error appropriately.
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		exit(-1);  // Fail
    }
	
    return persistentStoreCoordinator;
}

#pragma mark -
#pragma mark Application's documents directory

/**
 Returns the path to the application's documents directory.
 */

- (NSArray*) fetchAllEventEntities {
    NSManagedObjectContext* context = self.managedObjectContext;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
        entityForName:@"ATEventEntity" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    NSError *error = nil;
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];

    NSLog(@"  ----- fetchAllEvents number is %u",[fetchedObjects count]);
    return fetchedObjects;
}

//The reason to have addEventEntityAddress instead of addEventEntity is http://stackoverflow.com/questions/8771866/first-parameter-name-in-objective-c
- (ATEventEntity*) addEventEntityAddress:(NSString*)addressPar description:(NSString*)descriptionPar date:(NSDate*)datePar lat:(double)latPar lng:(double)lngPar type:(int)eventType uniqueId:(NSString*)uniqueId{
    NSManagedObjectContext *context = self.managedObjectContext;
    ATEventEntity *eventEntity = [NSEntityDescription insertNewObjectForEntityForName:@"ATEventEntity" inManagedObjectContext:context];
    NSString* idVar = uniqueId; //when download, uniqueId is there already
    if (idVar == nil)
        idVar= [self stringWithUUID];
   // NSLog(@"unique id is %@ ", idVar);
    eventEntity.uniqueId = idVar;
    eventEntity.address = addressPar;
    eventEntity.eventDesc = descriptionPar;
    eventEntity.eventDate = datePar;
    eventEntity.lat = [NSNumber numberWithDouble: latPar];
    eventEntity.lng = [NSNumber numberWithDouble: lngPar];
    eventEntity.eventType = [NSNumber numberWithInt: eventType];
    
    NSError *error;
    if (![context save:&error]) {
        NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]); }
    return eventEntity;
}

- (ATEventEntity*) updateEvent:(NSString *)uniqueId EventData:(ATEventDataStruct*)data {
    NSManagedObjectContext* context = self.managedObjectContext;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"ATEventEntity" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(uniqueId == %@)", uniqueId];
    [fetchRequest setPredicate:predicate];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    ATEventEntity* newEntity = nil; //if return nil, means it is update, not added new
    if (fetchedObjects != nil && [fetchedObjects count] >0)
    {
        ATEventEntity *evt = fetchedObjects[0];
        [evt setValue:data.eventDesc forKey:@"eventDesc"];
        [evt setValue:data.address forKey:@"address"];
        [evt setValue:data.eventDate forKey:@"eventDate"];
        [evt setValue:[NSNumber numberWithInt:data.eventType] forKey:@"eventType"];
        if (![context save:&error]) {
            NSLog(@" ----- Whoops, couldn't update: %@", [error localizedDescription]); }
    }
    else
    {
        NSLog(@"------- update fail, now add new");
        newEntity = [self addEventEntityAddress:data.address description:data.eventDesc date: data.eventDate lat:data.lat lng:data.lng type:data.eventType uniqueId:nil];
    }
    return newEntity; //for update, newUniqueId will be nil so caller know this is new event
}

- (void) deleteEvent:(NSString *)uniqueId {
    NSManagedObjectContext* context = self.managedObjectContext;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"ATEventEntity" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(uniqueId == %@)", uniqueId];
    [fetchRequest setPredicate:predicate];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    
    if (fetchedObjects != nil && [fetchedObjects count] >0)
    {
        ATEventEntity *evt = fetchedObjects[0];
        [managedObjectContext deleteObject:evt];

        if (![context save:&error]) {
            NSLog(@" ----- Whoops, couldn't delete: %@", [error localizedDescription]); }
    }
    else
    {
        NSLog(@"------- delete fail because could not find key %@",uniqueId);
    }
}
-(void)deleteAllEvent {
    NSManagedObjectContext* context = self.managedObjectContext;
    NSFetchRequest * allEvents = [[NSFetchRequest alloc] init];
    [allEvents setEntity:[NSEntityDescription entityForName:@"ATEventEntity" inManagedObjectContext:context]];
    [allEvents setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    
    NSError * error = nil;
    NSArray * events = [context executeFetchRequest:allEvents error:&error];
    //error handling goes here
    for (NSManagedObject * event in events) {
        [context deleteObject:event];
    }
    NSError *saveError = nil;
    [context save:&saveError];
}
- (NSString*) stringWithUUID {
    CFUUIDRef	uuidObj = CFUUIDCreate(nil);//create a new UUID
    //get the string representation of the UUID
    NSString	*uuidString = (__bridge NSString*)CFUUIDCreateString(nil, uuidObj);
    return uuidString;
}


@end
