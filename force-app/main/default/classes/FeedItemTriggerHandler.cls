/*
*********************************************************
Apex Class Name    : FeedItemTriggerHandler
Created Date       : 2025-08-13
@description       : Class to handle Feed Item Trigger Business Logic
@author            : Daksh Sharma
Modification Log:
Ver   Date         Author                Modification
1.0   2025-08-13   Daksh Sharma          Initial Version
*********************************************************
*/
public class FeedItemTriggerHandler extends TriggerHandler {

    // Global variable declaration start
    public static Boolean isSkipFeedItemTrigger = false;
    // Global variable declaration end

    /*
    *********************************************************
    @Method Name    : afterInsertMethod
    @author         : 
    @description    : Method to handle after Insert logic for Feed Item
    @param          : FeedItems, newMap
    @return         : void
    ********************************************************
    */
    public override void afterInsertMethod(List<SObject> newList, Map<Id, SObject> newMap) {
        if (Trigger.isAfter && Trigger.isInsert) {
            FeedItemTriggerHelper.createCaseComment((List<FeedItem>)newList);
        }
    }
}