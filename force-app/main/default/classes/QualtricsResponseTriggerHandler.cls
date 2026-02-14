/**********************************************************************************************************************
* Name               : QualtricsResponseTriggerHandler                                                        
* Description        : This class is used to handle trigger methods for QualtricsResponse__c objects
* Usage              : QualtricsResponse__c trigger
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           paras.bhatt@pwc.com     21 June 2022      Initial Draft       
******************************************************************************************************************/
public with sharing class QualtricsResponseTriggerHandler extends TriggerHandler {
    @TestVisible
    private static Boolean forceException = false;
    public override void beforeInsertMethod(list<SObject> newList,map<ID,SObject> newMap){
        populateRelatedLookup((list<QualtricsResponse__c>)newList);
        
        if((Test.IsRunningTest() && forceException)){
            throw new StringException('Exception forced from Unit Test');
        }
        
    }
    
    public override void AfterInsertMethod(list<SObject> newList,map<ID,SObject> newMap){
        Set<Id> brokerAgencySet = new Set<Id>(); 
        updateAccountData((list<QualtricsResponse__c>)newList);
        for(QualtricsResponse__c qualtricsResponse : (list<QualtricsResponse__c>) newList){
            if(qualtricsResponse.BrokerAgency__c != null){
                brokerAgencySet.add(qualtricsResponse.BrokerAgency__c);
            }
        }
if(!brokerAgencySet.isEmpty()){
            brokerAgencyCSATCalculation(brokerAgencySet);
        }
    }
    
    public override void afterUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap){ 
        updateAccountData((list<QualtricsResponse__c>)newList);
    }
    
    /**
* populateRelatedLookup 
*
* populate lookup field based on recived sObjectID__c
* 
* @param newRecords list of newly inserted records
* @return    none
* 
*/
    public static void populateRelatedLookup(list<QualtricsResponse__c> newRecords){
        for(QualtricsResponse__c tempRec : newRecords){
            //The Object Name shoul dexactly match the field API, for standard objects adding __c
            if(tempRec.sObjectID__c!=null){
                try{
                    String sObjectType = String.ValueOf(((ID)tempRec.sObjectID__c).getSObjectType());
                    sObjectType = sObjectType + (sObjectType.contains('__c')?'':'__c' );
                    if(sObjectType!=null && sObjectType.contains('Service_Request')){
                        tempRec.put('HexaBPM_Service_Request__c',tempRec.sObjectID__c);
                    }else{
                        tempRec.put(sObjectType,tempRec.sObjectID__c);
                    }
                }catch(Exception e){LoggerService.Save( LoggerService.addApexLog(e,'populateRelatedLookup','populateRelatedLookup','execute') );
                                   }
            }
            
        }
    }
    
    public static void updateAccountData(list<QualtricsResponse__c> newRecords){
        
        system.debug('Reached here');
        Map<Id, Decimal> AccountCSATMap = new Map<Id, Decimal>();
        Map<Id, Decimal> AccountNPSMap = new Map<Id, Decimal>();
        
        List<QualtricsResponse__c> ListRes = new List<QualtricsResponse__c>();
        
        try{
            for (QualtricsResponse__c val : newRecords)
            {
                Id AccountRecordId = val.AccountIdSobj__c;
                
                system.debug('AccountRecordId' + AccountRecordId);
                if(AccountRecordId != null)
                {
                    String AccRecordId = AccountRecordId.toString().substring(0, AccountRecordId.toString().length() - 3);
                    ListRes.add(new QualtricsResponse__c(Id = val.id, AccountId__c = AccountRecordId));
                    List<Map<String, String>> ListmapAnswerImpact = new List<Map<String, String>>();
                    for(QualtricsResponse__c relatedObj : [SELECT AccountId__c, AccountIdSobj__c, CreatedDate, Answer1__c,Answer2__c,Answer3__c,Answer4__c ,Answer5__c,Question1Impact__c, 
                                                           Question2Impact__c,Question3Impact__c,Question4Impact__c,Question5Impact__c FROM 
                                                           QualtricsResponse__c WHERE AccountIdSobj__c = :AccRecordId ORDER BY CreatedDate DESC LIMIT 5]) {
                                                               Map<String, String> mapAnswerImpact = new Map<String, String>();
                                                               mapAnswerImpact.put(relatedObj.Question1Impact__c,relatedObj.Answer1__c);
                                                               mapAnswerImpact.put(relatedObj.Question2Impact__c,relatedObj.Answer2__c);
                                                               mapAnswerImpact.put(relatedObj.Question3Impact__c,relatedObj.Answer3__c);
                                                               mapAnswerImpact.put(relatedObj.Question4Impact__c,relatedObj.Answer4__c);
                                                               mapAnswerImpact.put(relatedObj.Question5Impact__c,relatedObj.Answer5__c);
                                                               ListmapAnswerImpact.add(mapAnswerImpact);
                                                           }
                    
                    system.debug('mapAnswerImpact' + ListmapAnswerImpact);
                    // Query related object records and calculate sum
                    Integer CountNPS = 0;
                    Integer CountCSAT = 0;
                    Decimal CSATvalue = 0.0;
                    Decimal NPSValue = 0.0;
                    
                    for (Map<String, String> mapAnswerImpact : ListmapAnswerImpact)
                    {
                        // ++Count;
                        if(mapAnswerImpact.containsKey('CSAT') && mapAnswerImpact.get('CSAT') != null)
                        {
                            CSATvalue = CSATvalue + Decimal.ValueOf(mapAnswerImpact.get('CSAT'));
                            ++CountCSAT;
                        }
                        if(mapAnswerImpact.containsKey('NPS') && mapAnswerImpact.get('NPS') != null)
                        {
                            NPSValue = NPSValue + Decimal.ValueOf(mapAnswerImpact.get('NPS'));
                            ++CountNPS;
                        }
                    }
                    if(CountCSAT >= 1)
                    {
                        CSATvalue = (CSATvalue/CountCSAT).setScale(2);
                    }
                    if(CountNPS >= 1)
                    {
                        NPSValue = (NPSValue/CountNPS).setScale(2);
                    }
                    
                    AccountNPSMap.put(AccountRecordId,NPSValue);
                    AccountCSATMap.put(AccountRecordId,CSATvalue);
                }
            }
            
            // Update parent records with the calculated sum
            List<Account> AccountsToUpdate = new List<Account>();
            Set<Id> uniqueAccountIds = new Set<Id>();
            
            // Add all Account Ids from both CSAT and NPS maps
            uniqueAccountIds.addAll(AccountCSATMap.keySet());
            uniqueAccountIds.addAll(AccountNPSMap.keySet());
            
            // Iterate over unique Account Ids
            for (Id AccountId : uniqueAccountIds) {
                
                Account accToUpdate = new Account(Id = AccountId);
                if (AccountCSATMap.containsKey(AccountId)) {
                    accToUpdate.CSAT__c = AccountCSATMap.get(AccountId);
                }
                if (AccountNPSMap.containsKey(AccountId)) {
                    accToUpdate.NPS__c = AccountNPSMap.get(AccountId);
                }
                
                AccountsToUpdate.add(accToUpdate);
            }
            
            
            if (!AccountsToUpdate.isEmpty()) {
                update AccountsToUpdate;
                update ListRes;
            }
        }
        catch(Exception e){LoggerService.Save( LoggerService.addApexLog(e,'QualtricsResponseTriggerHandler_updateAccountData','QualtricsResponseTriggerHandler_updateAccountData','execute') );
                          }
        
    }

    public static void brokerAgencyCSATCalculation(Set<Id> brokerAgencySet){
        //BrokerCSATWeightage
        //BrokerKnowledgeWeightage
        //BrokerClarityWeightage
        //BrokerAttitudeWeightage
        try{
            List<Account> accountListToUpdate = new List<Account>();
            Id BrokerAgencyRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Broker Agency').getRecordTypeId();
            Map<String, Decimal>  avg_brokercsatMap = new  Map<String, Decimal>();      
            Map<String, Decimal>  avg_brokerKnowledgeMap = new  Map<String, Decimal>();
            Map<String, Decimal>  avg_brokerclarityMap = new  Map<String, Decimal>();
            Map<String, Decimal>  avg_brokerAttitudeMap = new  Map<String, Decimal>();
            Map<String, Decimal>  count_brokerSurveysMap = new  Map<String, Decimal>();
            Set<Id> brokerAgencyId_Set = new Set<Id>();
            
            AggregateResult[] aggregateResults = [SELECT  
                                                  BrokerAgency__c brokerAgency,
                                                  SUM(BrokerCSAT__c)sum_brokercsat,
                                                  SUM(BrokerKnowledge__c)sum_brokerKnowledge,
                                                  SUM(BrokerClarity__c)sum_brokerClarity,
                                                  SUM(BrokerAttitude__c)sum_brokerAttitude,
                                                  AVG(BrokerCSAT__c)avg_brokercsat,
                                                  AVG(BrokerKnowledge__c)avg_brokerKnowledge,
                                                  AVG(BrokerClarity__c)avg_brokerClarity,
                                                  AVG(BrokerAttitude__c)avg_brokerAttitude,
                                                  COUNT(Id) count_numberOfSurvey
                                                  FROM QualtricsResponse__c
                                                  WHERE SurveyName__c = 'Launch&BookingExperience'
                                                  AND BrokerAgency__c IN: brokerAgencySet
                                                  AND BrokerAgency__c != null
                                                  Group by BrokerAgency__c];
            
            for(AggregateResult ar: aggregateResults){
                brokerAgencyId_Set.add(String.valueOf(ar.get('brokerAgency')));
                avg_brokercsatMap.put(String.valueOf(ar.get('brokerAgency')), (Decimal)(ar.get('avg_brokercsat')));
                avg_brokerKnowledgeMap.put(String.valueOf(ar.get('brokerAgency')), (Decimal)(ar.get('avg_brokerKnowledge')));
                avg_brokerclarityMap.put(String.valueOf(ar.get('brokerAgency')), (Decimal)(ar.get('avg_brokerClarity')));
                avg_brokerAttitudeMap.put(String.valueOf(ar.get('brokerAgency')), (Decimal)(ar.get('avg_brokerAttitude')));
                count_brokerSurveysMap.put(String.valueOf(ar.get('brokerAgency')),(Decimal)(ar.get('count_numberOfSurvey')));
            }
            
            List<Account> BrokerAgencyAccountList = [SELECT
                                                     Id,
                                                     BrokerCSAT__c,
                                                     BrokerKnowledge__c,
                                                     BrokerClarity__c,
                                                     BrokerAttitude__c,
                                                     TotalNumberofSurveys__c
                                                     FROM 
                                                     Account
                                                     WHERE RecordTypeId =: BrokerAgencyRecordTypeId 
                                                     AND Id IN: brokerAgencyId_Set];
            
            for(Account brokerAgency: BrokerAgencyAccountList){
                Account account = new Account();
                account.id = brokerAgency.id;
                account.BrokerAttitude__c = avg_brokerAttitudeMap.get(brokerAgency.id);
                account.BrokerClarity__c = avg_brokerclarityMap.get(brokerAgency.id);
                account.BrokerCSAT__c = avg_brokercsatMap.get(brokerAgency.id);
                account.BrokerKnowledge__c = avg_brokerKnowledgeMap.get(brokerAgency.id);
                account.TotalNumberofSurveys__c = count_brokerSurveysMap.get(brokerAgency.id);
                accountListToUpdate.add(account);
            }
            
            if(!accountListToUpdate.isEmpty()){
                update accountListToUpdate;
            }
        }catch(Exception e){
            LoggerService.Save( LoggerService.addApexLog(e,'brokerAgencyCSATCalculation','brokerAgencyCSATCalculation','execute') );
        }
    }
}