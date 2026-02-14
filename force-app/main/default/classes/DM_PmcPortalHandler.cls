/***
Class       : DM_PmcPortalHandler
Author      : Smaartt
Description : This class is accessed from LWC component to retrieve PMC user related information in portal.
TestClass   : DM_PmcPortalHandlerTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.        V1.0              14/02/2024           Initial Version 
****************************************************************************************************************/
public with sharing class DM_PmcPortalHandler {
    @auraEnabled
    public static String getAllCases(Integer pageSize, Integer pageNumber, String filterCondition){
        System.debug('filterCondition: ' + filterCondition);
        User currentUser = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()];
        String jsonData = '';
        Integer offset = (pageNumber - 1) * pageSize; 
        String userId = UserInfo.getUserId();
        String countQuery = 'SELECT COUNT() FROM Case Where ProductId != null and Sub_Status__c != \'Draft\'';
        if (String.isNotBlank(filterCondition)) {
            countQuery += filterCondition;
        }
        if (currentUser.Profile.Name == System.Label.DM_PMCPortalProfile) {
            countQuery += ' AND RecordType.DeveloperName = \'District_Management\' AND Type IN (\'NOC\', \'Others\', \'Permit to Work\')';
        }
        System.debug('Count query: ' + countQuery);

        Integer totalRecords = database.countQuery(countQuery);
        Integer recordEnd = pageSize * pageNumber;        
        WrapperClass objcls =  new WrapperClass();  
        objcls.pageSize = pageSize;
        objcls.pageNumber = pageNumber;
        objcls.recordStart = offset + 1;
        objcls.recordEnd = totalRecords >= recordEnd ? recordEnd : totalRecords;
        objcls.totalRecords = totalRecords;
        
        String mainQuery = 'Select Id,CaseNumber,Sub_Status__c,status,Validity_Status__c,type,Product.Name,Createdby.Name,CreatedDate,Owner.Name,Assigned_To__r.Name,ClosedDate from Case Where ProductId != null and Sub_Status__c != \'Draft\'';
        if (String.isNotBlank(filterCondition)) {
            mainQuery += filterCondition;
        }
        if (currentUser.Profile.Name == System.Label.DM_PMCPortalProfile) {
            mainQuery += ' AND RecordType.DeveloperName = \'District_Management\' AND Type IN (\'NOC\', \'Others\', \'Permit to Work\') ORDER BY CaseNumber DESC LIMIT :pageSize OFFSET :offset';
        }else{
            mainQuery += ' Order by CaseNumber Desc LIMIT :pageSize OFFSET :offset';
        } 
        System.debug('Main query: ' + mainQuery);
        objcls.cs = database.query(mainQuery);
        jsonData = JSON.serialize(objcls);
        return jsonData;
    }
    @auraEnabled
    public static list<Case> getAllRequests(){
        
        User currentUser = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()];
        Id userId = UserInfo.getUserId();
        string queryStr = 'Select Id,CaseNumber,Sub_Status__c,status,type,Validity_Status__c,Product.Name,Createdby.Name,CreatedDate,Owner.Name,Assigned_To__r.Name from Case Where ProductId != null and Sub_Status__c != \'Draft\'';
        
        if (currentUser.Profile.Name == System.Label.DM_PMCPortalProfile) {
            queryStr += ' AND RecordType.DeveloperName = \'District_Management\' AND Type IN (\'NOC\', \'Others\', \'Permit to Work\') ORDER BY CaseNumber DESC LIMIT 10';
        }else{
            queryStr += ' Order by CaseNumber Desc LIMIT 10';
        }      
        system.debug('queryStr' + queryStr);       
        return dataBase.query(queryStr);
    }
    public class WrapperClass {
        public Integer pageSize {get;set;}
        public Integer pageNumber {get;set;}
        public Integer totalRecords {get;set;}
        public Integer recordStart {get;set;}
        public Integer recordEnd {get;set;}
        public List<Case> cs {get;set;}        
    }
    @auraEnabled
    public static list<Case> getDataToExport(String filterCondition){
        system.debug('filterCondition' + filterCondition); 
        User currentUser = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()];
        Id userId = UserInfo.getUserId();
        string queryStr = 'Select Id,CaseNumber,ClosedDate,Start_Date__c,End_Date__c,Purpose_of_Work__c,Sub_Status__c,Sector_and_Plot_No__c,Project_Name__c,Appointed_Contractor__c,Description,TLA_Duration__c,Validity_Status__c,status,type,Product.Name,Createdby.Name,CreatedDate,Owner.Name,Assigned_To__r.Name,ContactEmail,ContactMobile from Case Where ProductId != null and Sub_Status__c != \'Draft\'';
         if (String.isNotBlank(filterCondition)) {
            queryStr += filterCondition;
        }
        if (currentUser.Profile.Name == System.Label.DM_PMCPortalProfile) {
            queryStr += ' AND RecordType.DeveloperName = \'District_Management\' AND Type IN (\'NOC\', \'Others\', \'Permit to Work\') ORDER BY CaseNumber DESC LIMIT 40000';
        }else{
            queryStr += ' Order by CaseNumber Desc LIMIT 40000';
        }      
        system.debug('queryStr' + queryStr);       
        return dataBase.query(queryStr);
    }
    @auraEnabled
    public static Map<String, Integer> fetchDMCaseCount(String groupByFilter) {
        System.debug('groupByFilter ' + groupByFilter);
        User currentUser = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()];
        Id userId = UserInfo.getUserId();
        
        String queryStr = 'SELECT ' + groupByFilter + ', COUNT(Id) FROM Case WHERE ProductId != null AND Sub_Status__c != \'Draft\'';
        
        if (currentUser.Profile.Name == System.Label.DM_PMCPortalProfile) {
            queryStr += ' AND RecordType.DeveloperName = \'District_Management\' AND Type IN (\'NOC\', \'Others\', \'Permit to Work\')';
        } 
        queryStr += ' GROUP By '  + groupByFilter;
        System.debug('queryStr: ' + queryStr);

        List<AggregateResult> aggregateResults = Database.query(queryStr);
        Map<String, Integer> caseCountsMap = new Map<String, Integer>();
        for (AggregateResult aggr : aggregateResults) {
            String status = (String) aggr.get(groupByFilter);
            Integer count = (Integer) aggr.get('expr0');
            if (status != null) {
                caseCountsMap.put(status, count);
            }
        }
        System.debug('Case counts map: ' + caseCountsMap);
        return caseCountsMap;
    }  
}