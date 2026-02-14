/**********************************************************************************************************************
* Name               : TransferHistoryTrigger                                                        
* Description        : 
* Created By         : Sanath H M                                                   
******************************************************************************************************************/

trigger TransferHistoryTrigger on TransferHistory__c (after insert) {
    new TransferHistoryTriggerHandler().run('TransferHistory__c');
}