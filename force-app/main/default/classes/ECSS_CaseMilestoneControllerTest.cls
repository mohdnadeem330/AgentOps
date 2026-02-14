@isTest
public class ECSS_CaseMilestoneControllerTest {
    
    @testSetup
    static void createData(){
        TestObjectsFactory.createUser();
        User testUser = [select id from user where email='testuser@example.com'];
        System.runAs(testUser) {
            Account newAccount = TestObjectsFactory.getPersonAccountRecord(181, 'United Arab Emirates', 'V1', 'P1');
            insert newAccount;
            
            
        Entitlement entl = new Entitlement(Name='ECSS Entitlement Provis&Khidmah', AccountId=newAccount.Id);
        insert entl;

            
            ECSS_Case_Assignment_SLA__c cSLA = TestObjectsFactory.getSiteAndObjectSLA();
            ECSS_Case_Assignment_SLA__c cSLA2 = TestObjectsFactory.getSiteAndCategorySLA();
            ECSS_Case_Assignment_SLA__c cSLA3 = TestObjectsFactory.getCategorySLA();
            List<ECSS_Case_Assignment_SLA__c> SLAList = new List<ECSS_Case_Assignment_SLA__c>();
            SLAList.add(cSLA);
            SLAList.add(cSLA2);
            SLAList.add(cSLA3);
            insert SLAList;
            List<SlaProcess> lstEntitlementProcess = [SELECT Id, Name FROM SlaProcess WHERE Name='entitlement process - provis & khidmah_v1' AND IsActive = true limit 1];

        
             entl.SlaProcessId = lstEntitlementProcess[0].id;

            update entl; 
            
            Group grp = TestObjectsFactory.getECSS_Group();
            insert grp;
            
            Case caseObj = TestObjectsFactory.getProvisCase(newAccount);
            caseObj.CaseCategory__c	= 'CRM';
            caseObj.ECSS_Object_Category__c='CRM';
            caseObj.EntitlementId = entl.Id;
            insert caseObj;
           
        }
        
    }
    @isTest
    public static void testMilestoneDetails(){
        Test.startTest();
        List<Case> caseList = new List<Case>([SELECT Id,ECSS_LatestEscalationLevel__c,FCR__c,
                                              AssetId,CaseCategory__c,ECSS_Object_Category__c,
                                              ECSS_Sub_Category_Text__c,RecordTypeId,ECSS_SLA_Level_1__c,EntitlementId from Case Limit 1]);
        
         List<CaseMilestone> milestones = [SELECT TargetDate, TargetResponseInMins, TargetResponseInHrs
                                          FROM CaseMilestone
                                         ];
        system.debug('CASE'+caseList);
        ECSS_CaseMilestoneController.milestoneDetails(caseList[0].Id);
        Test.stopTest();
    }
    @isTest
    public static void testCetCaseTotalResolution(){
        Test.startTest();
        List<Case> caseList = new List<Case>([SELECT Id,ECSS_LatestEscalationLevel__c,FCR__c,
                                              AssetId,CaseCategory__c,ECSS_Object_Category__c,
                                              ECSS_Sub_Category_Text__c,RecordTypeId from Case Limit 1]);
        ECSS_CaseMilestoneController.getCaseTotalResolution(caseList[0].Id);
        Test.stopTest();
    }
    
    
}