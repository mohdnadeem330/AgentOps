@isTest
public class CaseServiceTest {
    
    @IsTest public static void testcase() {

        Account account = TestObjectsFactory.getOrganisationAccountRecord('companyName', 'registrationNo');
        insert account; 

        Contact con = TestObjectsFactory.contactDataSetup(account.Id);

        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;

        Case cs = TestObjectsFactory.getStandardCase(account.Id, con.Id, 'Compliance');
        cs.Unit__c = unit.Id;
        insert cs;

        Group grp = new Group();
		grp.name = 'Test Group1';
		grp.Type = 'Regular'; 
		Insert grp; 

        Set<Id> accountSet = new Set<Id>();
        accountSet.add(account.Id);
        
        List<Id> caseIds = new List<Id>();
        caseIds.add(cs.Id);
        
        Test.startTest();

        List<Case> casesById = CaseService.getCaseRecord(cs.Id);
        List<Case> casesByAccountId = CaseService.getCases(accountSet);
        List<Case> casesWithAllFields = CaseService.queryAllFieldsWithExtraFields(caseIds); 
        CaseService.getOldestCaseFromQueue(grp.Id, cs.casenumber);
        CaseService.getCasesByCaseNumber(new List<String>{cs.CaseNumber});
        
        //List<Case> casesByAccountIdq = CaseService.getCases(null);
        
        Test.stopTest();

    }
    
      @isTest
    static void testCheckUpdatePermission_EscalationEmailMatch() {
        User currentUser = TestObjectsFactory.getUserRecord('System Administrator','CurrentUser');
        currentUser.Email ='currentUser@gmail.com';
        Insert currentUser;       
        User assignedUser = TestObjectsFactory.getUserRecord('System Administrator','AssignedUser');
        assignedUser.Email ='assignedUser@gmail.com';
        Insert assignedUser;       
        
         User retriveCurrentUser = [SELECT Id,Email FROM User WHERE Email =:currentUser.Email  LIMIT 1];
         User retriveAssignedUser = [SELECT Id,Email FROM User WHERE Email =:assignedUser.Email LIMIT 1];
         Id recordTypeId =[select Id from RecordType where sObjectType='case' and Name ='Queries'][0].Id;
         Case testCase = new Case(
            Status = 'New',
            Origin = 'Email',
            Escalation_level_1_Email__c = retriveCurrentUser.Email,
            Assigned_To__c = retriveAssignedUser.Id,
            CustomerType__c='Visitor',
            SuppliedEmail ='SuppliedEmail@aldar.com',
            RecordTypeId = recordTypeId,
            SuppliedPhone='1234567890',
            SuppliedName='Aldar'
        );
        insert testCase;

        // Invoke the method under test
        Test.startTest();
        List<Case> result = CaseService.checkUpdatePermission(testCase.Id);
        Test.stopTest();

        // Assert the results
        System.assertNotEquals(null, result, 'Result should not be null');
        //System.assertEquals(1, result.size(), 'Should return one case');
        //System.assertEquals(testCase.Id, result[0].Id, 'Returned case ID should match the test case ID');
    }
    
     @isTest
    static void testDuplicate() {      
        Account account = TestObjectsFactory.getOrganisationAccountRecord('companyName', 'registrationNo');
        insert account;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;

        // Invoke the method under test
        Test.startTest();
        List<Case> result = CaseService.checkDuplicate(unit.id,'CM Finance','Refund',account.id);
        Test.stopTest();

        // Assert the results
       // System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(0, result.size(), 'Should return one case');
       // System.assertEquals(testCase.Id, result[0].Id, 'Returned case ID should match the test case ID');
    }
    @isTest
    static void testDuplicate2() {      
                
         Id recordTypeId =[select Id from RecordType where sObjectType='case' and Name ='Requests'][0].Id;
         Case testCase = new Case(
            Status = 'New',
            Origin = 'Email',
            CustomerType__c='Visitor',
            SuppliedEmail ='SuppliedEmail@aldar.com',
            RecordTypeId = recordTypeId,
            SuppliedPhone='1234567890',
            SuppliedName='Aldar'
        );
        insert testCase;

        // Invoke the method under test
        Test.startTest();
        //CaseService.updateCaseRecord(testCase.id,'Pending with Customer','Refund');
        Test.stopTest();
    }
    
    @IsTest public static void testcaseException() {

        Account account = TestObjectsFactory.getOrganisationAccountRecord('company Name', '12324231');
        insert account;

        Contact con = TestObjectsFactory.contactDataSetup(account.Id);

        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;

        Case cs = TestObjectsFactory.getStandardCase(account.Id, con.Id, 'Compliance');
        cs.Unit__c = unit.Id;
        insert cs;
        
        Test.startTest();
         try {
        		List<Case> casesById = CaseService.getCaseRecord(con.id);
         }catch(Exception e){
           
          }
        
        Test.stopTest();

    }
    @IsTest public static void testcaseException1() {

        Account account = TestObjectsFactory.getOrganisationAccountRecord('company Name', '12324231');
        insert account;

        Contact con = TestObjectsFactory.contactDataSetup(account.Id);

        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;

        Case cs = TestObjectsFactory.getStandardCase(account.Id, con.Id, 'Compliance');
        cs.Unit__c = unit.Id;
        insert cs;
        
        Test.startTest();
         try {
        		List<Case> casesByAccountIdq = CaseService.getCases(new Set<Id>{cs.Id});
         }catch(Exception e){
           
          }
        List<Case> casesByAccountIdq = CaseService.getChildCases(new List<Id>{cs.Id});
        
        
        Test.stopTest();

    }
}