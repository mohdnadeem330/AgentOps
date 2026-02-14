/**********************************************************************************
* @description       : This class is used for all generic and reusable logic/methods.
* @coverage          : 
* @author            : mbajaria@aldar.com
* @group             : Aldar
* @last modified on  : June 27, 2025
* @last modified by  : mbajaria@aldar.com
* Modifications Log
* Ver   Date         Author                                    Modification
* 1.0   May 30, 2025   mbajaria@aldar.com             Initial Version | Story Number
************************************************************************************/
public with sharing class AldarUtilityClass {
    
    /*************************************************************************
    * @description Method to used for fetch queue map based on given parameters
    * Parameters : queuenames - Set of queue names to be queried 
	*			   queuenames - Set of queue developer name to be queried    
    * @author rrangrej@aldar.com | May 30, 2025 | Story Number
    * @return Map<String, Group>
    ****************************************************************************/
    public static Map<String, Group> fetchQueueMap (Set<String> queuenames,Set<String> queueDeveloperNames) {
        Map<String, Group> queueMap = new Map<String, Group>();
        
        try {  
            for(Group gr :[SELECT Id, Name, DeveloperName FROM Group WHERE Name =:queuenames OR (Type='Queue' and DeveloperName IN :queueDeveloperNames)]) {
                if(queueDeveloperNames.contains(gr.DeveloperName)) {
                    queueMap.put(gr.DeveloperName, gr);
                } else {
                    queueMap.put(gr.Name, gr);
                }
            }                
        } catch(exception e) {
            System.debug('Case query error' + e.getMessage());
        }
        return queueMap;  
    }
    /******************************************************************************
    * @description Method to used for fetch queue map based on given parameters
    *	Parameters : objectName - Object name for which record type details needs to be queried	
    *	keyName - Name or DeveloperName. Based on which map needs to be prepared.
    * @author rrangrej@aldar.com | May 30, 2025 | Story Number
    * @return Map<String, Group>
    ********************************************************************************/
    public static Map<String, Id> getRecordTypeIdByParam (String objectName,String keyName) {
        Map<String,Id> recordTypeByString = new Map<String,Id>();
        // Get the Describe result for the object (e.g., Account)
        Schema.DescribeSObjectResult describeResult = Schema.getGlobalDescribe().get(objectName).getDescribe();
        // Get map of record type Id to record type info
        Map<Id, Schema.RecordTypeInfo> recordTypeInfoMap = describeResult.getRecordTypeInfosById();
        for (Schema.RecordTypeInfo rtInfo : recordTypeInfoMap.values()) {
            String mapKey;
            if(keyName == 'Name'){
                mapKey = rtInfo.getName();
            }else if(keyName == 'DeveloperName'){
                mapKey = rtInfo.getDeveloperName();
            }else{
                return null;
            }
            recordTypeByString.put(mapKey,rtInfo.getRecordTypeId());
        }
        return recordTypeByString;        
    }
    
    public static Map<String,HexaBPM__SR_Template__c> fetchSRTemplate(Set<String> srTempNames){

        Map<String,HexaBPM__SR_Template__c> srTemplateMap = new Map<String,HexaBPM__SR_Template__c>();
        try{
            for(HexaBPM__SR_Template__c srTemp : [Select Id, Name from HexaBPM__SR_Template__c where Name IN:srTempNames]){
                srTemplateMap.put(srTemp.Name,srTemp);
            }
            return srTemplateMap;
        }
        catch(exception ex){
            system.debug(ex.getMessage());
            return null;
        }
    }

    public static Map<Id, InstallmentLines__c> fetchInstallmentLines(set<ID> installmentLineIds){
        if (!installmentLineIds.isEmpty()) {
            return new Map<Id, InstallmentLines__c> (
                [SELECT Id,OutstandingAmount__c,InstallmentDate__c 
                FROM InstallmentLines__c 
                WHERE Id IN:installmentLineIds]
            );
        }
        return new Map<Id, InstallmentLines__c>();
    }

    public static Map<String, ChargeRule__c> fetchChargeRule(Set<String> serviceChargeSRTypeSet){
        Map<String,ChargeRule__c> srTypeChargeDetailsMap = new Map<String,ChargeRule__c>();
        if (!serviceChargeSRTypeSet.isEmpty()) {
            for(ChargeRule__c chargeRule : [SELECT SRType__c,ChargePercentage__c,VATChanges__c,ChargeAmount__c from ChargeRule__c WHERE SRType__c IN :serviceChargeSRTypeSet AND ChargeType__c =:Constants.OTHER_CHARGES_TYPE_SERVICE_CHARGE AND IsActive__c = True]){
                srTypeChargeDetailsMap.put(chargeRule.SRType__c,chargeRule);
            }
        }
        return srTypeChargeDetailsMap;
    }

    public static Map<Id, SalesOrder__c> fetchSalesOrder(set<ID> saleorderIds){
        if (!saleorderIds.isEmpty()) {
            return new Map<Id, SalesOrder__c> (
                [SELECT id,Account__r.PersonEmail,Contact__c, Contact__r.Email,Account__r.Email__c 
                FROM SalesOrder__c 
                WHERE id in :saleorderIds]
            );
        }
        return new Map<Id, SalesOrder__c>();
    }

    public static Map<String,SystemMessages__mdt> getSystemMessages(Set<String> messageNames){
        Map<String,SystemMessages__mdt> systemMessagesMap = new Map<String,SystemMessages__mdt>();
        try{
            for(SystemMessages__mdt messageDetails : [SELECT DeveloperName, Message__c, MergeFieldsToReplace__c
                                                        FROM SystemMessages__mdt WHERE DeveloperName IN: messageNames]){
                systemMessagesMap.put(messageDetails.DeveloperName,messageDetails);
            }
        }
        catch(exception ex){
            system.debug(ex.getMessage());
            return null;
        }
        return systemMessagesMap ; 
    }

    public static Map<String, HexaBPM__Status__c> fetchStepStatus(){
        Map<String, HexaBPM__Status__c> stepStatusMap = new Map<String, HexaBPM__Status__c>();
        for (HexaBPM__Status__c tempRec : [SELECT Id, Name FROM HexaBPM__Status__c]) {
            stepStatusMap.put(tempRec.Name, tempRec);
        } 
        return stepStatusMap;
    }

    public static Map<String, HexaBPM__SR_Status__c> fetchSRStatus(){
        Map<String, HexaBPM__SR_Status__c> srStatusMap = new Map<String, HexaBPM__SR_Status__c>();
        for (HexaBPM__SR_Status__c tempRec : [SELECT Id, Name FROM HexaBPM__SR_Status__c]) {
            srStatusMap.put(tempRec.Name, tempRec);
        } 
        return srStatusMap;
    }   

    public static List<Case> fetchCaseByUnitsonInsert(Set<Id> unitIdsList,Set<String> casestatuses,Id dlpRecordTypeId) {
        if(!unitIdsList.isEmpty()) {
            return new List<Case> (
                                [Select Id, ParentId, CaseNumber,Single_DLP_slot__c, (select Id, SchedStartTime, SchedEndTime, RecordType.Name from Service_Appointments__r Where RecordType.Name = 'Assessment') 
                                From Case Where RecordTypeId = :dlpRecordTypeId and Unit__c In :unitIdsList and ParentId = null and Single_DLP_slot__c = true 
                                and Status In :casestatuses order by CreatedDate Desc]);
        }
        return new List<Case>();
    }

    public static List<Case> fetchCaseByUnitsonUpdate(List<Id> caseIdlist,List<Id> unitIdsList, DateTime csdatetime,Set<String> casestatuses,Id dlpRecordTypeId) {
        if(!unitIdsList.isEmpty()) {
            return new List<Case> (
                                [Select Id, ParentId, CaseNumber,Single_DLP_slot__c, (select Id, SchedStartTime, SchedEndTime, RecordType.Name from Service_Appointments__r Where RecordType.Name = 'Assessment') 
                                From Case Where Id Not In :caseIdlist and RecordTypeId = :dlpRecordTypeId and Unit__c In :unitIdsList and ParentId = null 
                                and Single_DLP_slot__c = true and CreatedDate < :csdatetime and Status In :casestatuses order by CreatedDate Desc]);
        }
        return new List<Case>();
    }

}