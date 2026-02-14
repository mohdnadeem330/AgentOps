/**********************************************************************************************************************
* Name              : ContentDocumentTriggerHandler                                                        
* Description       : This Apex class is the handler for ContentDocumentTrigger
* Method			: beforeDeleteMethod
* Created By        : tdontha@aldar.com - Tharun
* Last Modified By	: tdontha@aldar.com - Tharun
******************************************************************************************************************/
public without sharing class ContentDocumentTriggerHandler extends TriggerHandler {
	/**-------------------------------------------------------------------
	* Description: used to control the after delete logic 
	* -------------------------------------------------------------------**/
    public override void beforeDeleteMethod(List<SObject> oldList, Map<Id, SObject> oldMap) 
    {
        System.Debug('Run Before Delete'+oldList);
        Set<Id> relatedContactIds = new Set<Id>();
        for(ContentDocumentLink CDL : [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId IN :oldMap.keyset()]){
            if(CDL.LinkedEntityId != null){
                if(Schema.Contact.SObjectType == CDL.LinkedEntityId.getSObjectType()){
                    relatedContactIds.add(CDL.LinkedEntityId);
                }
            }
        }
        //Added by Tharun
        if(relatedContactIds.size() > 0){
            UpdateCountOfFiles(relatedContactIds);
        }
    }
    
    public static void UpdateCountOfFiles(Set<Id> contactsToUpdateCountIds)
    {
        Id brokerConRecTypeId = Schema.SobjectType.Contact.getRecordTypeInfosByDeveloperName()
                                        .get('BrokerAgent')
                                        .getRecordTypeID();
        List<Contact> conToUpdate = new List<Contact>();
        for(Contact conRecord : [SELECT Id, (SELECT Id FROM ContentDocumentLinks) 
                                 FROM Contact 
                                 WHERE Id IN :contactsToUpdateCountIds AND RecordTypeId =:brokerConRecTypeId]){
            conRecord.FileUploadedCount__c = conRecord.ContentDocumentLinks.size() - 1;
            conToUpdate.add(conRecord);
        }
        update conToUpdate;
    }
    
}