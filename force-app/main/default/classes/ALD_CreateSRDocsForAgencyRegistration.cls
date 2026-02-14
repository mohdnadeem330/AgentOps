/*
* Created By	: tdontha@aldar.com
* Purpose		: This batch class creates SR Docs for Agency Registration Service Requests
*/
public class ALD_CreateSRDocsForAgencyRegistration implements Database.Batchable<sObject>
{
    public List<HexaBPM__Service_Request__c> start(Database.BatchableContext bc)
    {
        Set<Id> seSetIds = new Set<Id>();
        List<HexaBPM__SR_Doc__c> srDocList = [select HexaBPM__Service_Request__c 
                                              from HexaBPM__SR_Doc__c
                                              where DocumentMasterCode__c IN ('NOC_Broker_Letter','Signed_NOC_Broker_Letter')];
        for(HexaBPM__SR_Doc__c srd :srDocList){
            seSetIds.add(srd.HexaBPM__Service_Request__c);
        }
        List<HexaBPM__Service_Request__c> srList = [SELECT Id, Name, HexaBPM__Customer__c
                                                    FROM HexaBPM__Service_Request__c
                                                    WHERE HexaBPM__SR_Template__r.Name  = 'Agency Registration'
                                                    AND Id NOT IN :seSetIds];
        System.debug('inStart---'+srList);
        return srList;
        
    }
    
    public void execute(Database.BatchableContext bc, List<HexaBPM__Service_Request__c> srList)
    {
        System.debug('InsideExecute---'+srList);
        //Create all placeholders **********
        list<HexaBPM__SR_Template_Docs__c> docTemplateList = [SELECT Id, Name, 
                                                              HexaBPM__Document_Master_Code__c,
                                                              HexaBPM__Document_Master__c, 
                                                              HexaBPM__Document_Description__c 
                                                              FROM HexaBPM__SR_Template_Docs__c 
                                                              WHERE HexaBPM__SR_Template__r.Name ='Agency Registration' 
                                                              AND HexaBPM__Document_Master_Code__c IN ('NOC_Broker_Letter','Signed_NOC_Broker_Letter')]; 
        list<HexaBPM__SR_Doc__c> docsToInsert = new list<HexaBPM__SR_Doc__c>();
        for(HexaBPM__Service_Request__c tempSR : srList ){
            for(HexaBPM__SR_Template_Docs__c tempDoc : docTemplateList){
                HexaBPM__SR_Doc__c tempRec = new HexaBPM__SR_Doc__c(Name = tempDoc.HexaBPM__Document_Description__c,HexaBPM__Customer__c = tempSR.HexaBPM__Customer__c,HexaBPM__Document_Master__c = tempDoc.HexaBPM__Document_Master__c,HexaBPM__Service_Request__c = tempSR.Id,HexaBPM__SR_Template_Doc__c = tempDoc.Id,HexaBPM__Is_Not_Required__c = true,HexaBPM__Document_Description_External__c = tempDoc.HexaBPM__Document_Description__c);
                docsToInsert.add(tempRec);
            }
        }
        if(!docsToInsert.isEmpty()){ insert docsToInsert;}
        
    }
    
    public void finish(Database.BatchableContext bc){
        System.debug('Batch finish -> ');
    }

}