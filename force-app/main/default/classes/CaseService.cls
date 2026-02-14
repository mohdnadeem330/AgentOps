public without sharing class CaseService {
    @AuraEnabled
    public static List<Case> getCaseRecord(Id recordId){
        try {
          List<Case> caseRec=[SELECT Id,Description, Status,Category__c,Subject from Case Where Id =:recordId];
            
            if(Test.isRunningTest())
                System.debug('caseRec '+caseRec[0].id); 
           
        return caseRec;
        
        }catch(Exception e){
            throw e ;
        } 
        
        
    }  
    
    @AuraEnabled
    public static void updateCaseRecord(Id caseId, String newSubStatus, String commentBody) {
        try {
            Case caseToUpdate = new Case(Id = caseId, Sub_Status__c = newSubStatus);
            update caseToUpdate;

            Case_Comment__c caseComment = new Case_Comment__c(Case__c = caseId, Body__c = commentBody);
            insert caseComment;
        } catch (Exception e) {
            throw new AuraHandledException('An error occurred: ' + e.getMessage());
        }      
    }
    
      //Added by Rajat Jain And this is used in UpdateClone Lwc Component
     @AuraEnabled
    public static List<case> checkUpdatePermission(Id caseId) {
        try {
            system.debug('CaseId'+caseId);
            List<User> UserDetails = [Select Id,Name,Email from User where Id = :UserInfo.getUserId() Limit 1];
            system.debug('UserDetails'+UserDetails);
            List<Case> checkUpdatePermissionList = [SELECT Escalation_level_1_Email__c, Escalation_level_3_Email__c, 
                                                    Escalation_level_2_Email__c, Escalation_level_4_Email__c, Id, 
                                                    CaseNumber, Status, Origin, Assigned_To__r.Email FROM Case where Id=:caseId and 
                                                    ( Escalation_level_1_Email__c = :UserDetails[0].Email 
                                                     OR Escalation_level_3_Email__c =:UserDetails[0].Email OR Escalation_level_2_Email__c =:UserDetails[0].Email OR 
                                                     Escalation_level_4_Email__c =:UserDetails[0].Email
                                                     OR Assigned_To__r.Email = :UserDetails[0].Email)];
            
           if(checkUpdatePermissionList.isEmpty()){
                checkUpdatePermissionList=[SELECT Escalation_level_1_Email__c, Escalation_level_3_Email__c, 
                Escalation_level_2_Email__c, Escalation_level_4_Email__c, Id, 
                CaseNumber, Status, Origin, Assigned_To__r.Email FROM Case where Id=:caseId and Status ='New'];
           }
            
            return checkUpdatePermissionList;
        }
        catch (Exception e) {
            System.debug('Error in checkDuplicate: ' + e.getMessage());
            throw new AuraHandledException('An error occurred while checking for duplicates: ' + e.getMessage());
        }
    }
    
    
    
    // Added by Faaiz for checking duplicate Cases
    @AuraEnabled
    public static List<case> checkDuplicate(String unitValue, String categoryValue, String subCategoryValue,string accountIdVal) {
        try {            
            List<Case> duplicateCases = new List<Case> ();
            if(unitValue != null && !String.isBlank(unitValue)){
             duplicateCases = [SELECT Id,CaseNumber,Origin FROM Case WHERE Unit__c = :unitValue AND CaseCategory__c = :categoryValue AND SubCategory__c = :subCategoryValue AND Status != 'Closed' order by Createddate LIMIT 1];
            //system.debug('DuplicateValue1'+duplicateCases);
            }            
            else if (accountIdVal!=null && unitValue== null){
             duplicateCases = [SELECT Id,CaseNumber,Origin FROM Case WHERE AccountId  =: accountIdVal AND Unit__c = null AND CaseCategory__c = :categoryValue AND SubCategory__c = :subCategoryValue AND Status != 'Closed' order by Createddate LIMIT 1];   
            }            
            return duplicateCases;
        } catch (Exception e) {
            System.debug('Error in checkDuplicate: ' + e.getMessage());
            throw new AuraHandledException('An error occurred while checking for duplicates: ' + e.getMessage());
        }
    }

    public static List<Case> getCases(Set<Id> accountId){
        try {
          List<Case> caseRec=[SELECT Id from Case Where AccountId IN:accountId];
            
            if(Test.isRunningTest())
                System.debug('caseRec '+caseRec[0].id); 
        return caseRec;
        
        }catch(Exception e){
            throw e;
        }
    } 
    
    public static List<Case> queryAllFieldsWithExtraFields(List<Id> caseIds) {
        Set<String> caseFieldList = Schema.getGlobalDescribe().get('Case').getDescribe().fields.getMap().keySet();
        List<String> strList = new List<String>();
        strList.addAll(caseFieldList);
        String fields = string.join(strList,',');

        String caseIdsStr = String.join(caseIds, '\',\'');
        String query = 'SELECT ' + fields + ', SalesOrder__r.TitleDeedRegistrationNumber__c, Unit__r.Name, Owner.Email, Owner.Name, Unit__r.ADMUnitNumber__c, Unit__r.Project__r.Name, Unit__r.Project__r.AsiteProjectName__c FROM Case WHERE Id IN (\'' + caseIdsStr + '\')';
        System.debug('***Case query***'+query);
        List<Case> cases = Database.Query(query);
        System.debug('***Case Queried***'+cases);
        return cases;
    }
  
    public static List<Case> getOldestCaseFromQueue(Id queueId, String newestCaseNumber) {
        
        List<Case> caseRec=[SELECT Id, OwnerId, CaseNumber from Case Where OwnerId =: queueId AND CaseNumber <= : newestCaseNumber and Status != 'Closed' ORDER By CreatedDate asc];
        return caseRec;
    }

    public static List<Case> getCasesByCaseNumber(List<String> casesNumbers) {
        
        Set<String> caseFieldList = Schema.getGlobalDescribe().get('Case').getDescribe().fields.getMap().keySet();
        List<String> strList = new List<String>();
        strList.addAll(caseFieldList);
        String fields = string.join(strList,',');

        String casesNumbersStr = String.join(casesNumbers, '\',\'');
        String query = 'SELECT ' + fields + ' FROM Case WHERE CaseNumber IN (\'' + casesNumbersStr + '\')';
        System.debug('***Case query***'+query);
        List<Case> cases = Database.Query(query);
        System.debug('***Case Queried***'+cases);
        return cases;
    }

    public static List<Case> getChildCases(List<Id> caseIds) {
        Set<String> caseFieldList = Schema.getGlobalDescribe().get('Case').getDescribe().fields.getMap().keySet();
        List<String> strList = new List<String>();
        strList.addAll(caseFieldList);
        String fields = string.join(strList,',');

        String caseIdsStr = String.join(caseIds, '\',\'');
        String query = 'SELECT ' + fields + ' FROM Case WHERE ParentId IN (\'' + caseIdsStr + '\')';
        System.debug('***Case query***'+query);
        List<Case> cases = Database.Query(query);
        System.debug('***Case Queried***'+cases);
        return cases;
    }
}