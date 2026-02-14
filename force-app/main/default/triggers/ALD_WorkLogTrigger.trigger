/**
 * @description       : Work Log Trigger
 * @author            : Saravanan Sekar
 * @last modified on  : 01-01-2024
 * @last modified by  : Saravanan Sekar
**/
trigger ALD_WorkLogTrigger on ALD_Work_Log__c (before insert, before update, after insert, after update, before delete) {
    if(!ALD_WorkLogTriggerHandler.StopTrigger){
        new ALD_WorkLogTriggerHandler().run('ALD_Work_Log__c');
    }
}