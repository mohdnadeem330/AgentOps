/**
* @File Name : ActivityMappingNotificationBatch.cls
* @Description :
* @Author :
* @Last Modified By : Dinesh Kumar
* @Last Modified On : August 6, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | August 6, 2025 |   | Initial Version
**/

global class ActivityMappingNotificationBatch implements Database.Batchable<SObject>, Database.Stateful {

    global List<ActivityMapping__c> listToProcess;
    global String process;

    global ActivityMappingNotificationBatch(List<ActivityMapping__c> listToProcess, String process){
        this.listToProcess = listToProcess;
        this.process = process;
    }

    global Iterable<SObject> start(Database.BatchableContext BC) {
        return listToProcess;
    }

    global void execute(Database.BatchableContext BC, List<SObject> scope) {
        List<ActivityMapping__c> records = (List<ActivityMapping__c>)scope;
        try {
            if(process == 'insert'){
                insert records;
            }
            else if(process == 'delete'){
                delete records;
            }
        } catch (DmlException e) {
            System.debug('Error during ' + process + ': ' + e.getMessage());
        }
    }

    global void finish(Database.BatchableContext BC) {
        System.debug('ActivityMappingNotificationBatch completed for process: ' + process);
    }
}