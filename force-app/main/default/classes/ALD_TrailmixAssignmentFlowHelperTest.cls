/******************************************************************************************************************
* Name              : ALD_TrailmixAssignmentFlowHelperTest                                                        
* Description       : 
* Created By        : SF   
* Last Modified By	: SF
******************************************************************************************************************/
@isTest
public class ALD_TrailmixAssignmentFlowHelperTest 
{
    //Create setup data
    @testSetup
    public static void setupData()
    {
        trailheadapp__Trailmix__c trailMix 				= new trailheadapp__Trailmix__c();
        trailMix.Name 									= 'Test TrailMix 1';
        trailMix.trailheadapp__Description__c			= 'Description of TrailMix';
        trailMix.CreatedDate							= Date.today();
        trailMix.trailheadapp__URL__c					= 'www.google.com';
        trailMix.trailheadapp__External_Id__c			= '02b98640-9a3d-f0df-b63c-8005d90fdcc4';
        trailMix.trailheadapp__Slug__c					= 'test-trailmix-1';
       	trailMix.trailheadapp__Created_By_Profile__c	= 'https://trailhead.salesforce.com/users/profiles/tdontha4';
        insert trailMix;
        
        Account accountRecord = TestObjectsFactory.getOrganisationAccountRecord('CompanyName', 'Ysjs657');
        insert accountRecord;

        System.runAs(new User(Id = UserInfo.getUserId())){
        	User internalUser = TestObjectsFactory.getUserRecord(Constants.SALES_MANAGER, 'agencyUser@aldar.com');
        	internalUser.Email = 'test@gmail.com';
        	insert internalUser;
            
            User internalUser2 = TestObjectsFactory.getUserRecord(Constants.SALES_MANAGER, 'agencyUser2@aldar.com');
        	internalUser2.Email = 'test2@gmail.com';
        	insert internalUser2;
            
            User internalUser3 = TestObjectsFactory.getUserRecord(Constants.SALES_MANAGER, 'agencyUser2@aldar.com');
        	internalUser3.Email = 'test2@gmail.com';
        	insert internalUser3;
            
            trailheadapp__Trailhead_User_Data__c trailUserDate = new trailheadapp__Trailhead_User_Data__c();
        	trailUserDate.trailheadapp__User__c = internalUser.Id;
            trailUserDate.trailheadapp__External_Id__c = internalUser.Id;
        	insert trailUserDate;
        
        	trailheadapp__Trailhead_User_Data__c trailUserDate2 = new trailheadapp__Trailhead_User_Data__c();
            trailUserDate2.trailheadapp__External_Id__c = internalUser2.Id;
            trailUserDate2.trailheadapp__User__c = internalUser2.Id;
            insert trailUserDate2;
            
            trailheadapp__Trailhead_User_Data__c trailUserDate3 = new trailheadapp__Trailhead_User_Data__c();
            trailUserDate3.trailheadapp__External_Id__c = internalUser3.Id;
            trailUserDate3.trailheadapp__User__c = internalUser3.Id;
            insert trailUserDate3;
        
            trailheadapp__Trailmix_Assignment__c trailAssignment = new trailheadapp__Trailmix_Assignment__c();
            trailAssignment.trailheadapp__Trailmix__c = trailMix.Id;
            trailAssignment.trailheadapp__Status__c = 'Processed';
            trailAssignment.trailheadapp__User__c = internalUser.Id;
            insert trailAssignment;
            
            trailheadapp__Trailmix_Assignment__c trailAssignment2 = new trailheadapp__Trailmix_Assignment__c();
            trailAssignment2.trailheadapp__Trailmix__c = trailMix.Id;
            trailAssignment2.trailheadapp__Status__c = 'Not Processed';
            trailAssignment2.trailheadapp__User__c = internalUser2.Id;
            insert trailAssignment2;
            
            trailheadapp__Trailmix_Assignment__c trailAssignment3 = new trailheadapp__Trailmix_Assignment__c();
            trailAssignment3.trailheadapp__Trailmix__c = trailMix.Id;
            trailAssignment3.trailheadapp__Status__c = 'Processed';
            trailAssignment3.trailheadapp__User__c = internalUser3.Id;
            insert trailAssignment3;
        }
    }
    
    @isTest
    static void testMethod1()
    {
        Test.startTest();
        Map <Id,trailheadapp__Trailmix__c> trailmixIdMap 
            = new Map<Id,trailheadapp__Trailmix__c>([SELECT ID 
                                                     FROM trailheadapp__Trailmix__c 
                                                     LIMIT 1]);
        List <Id> trailmixIdList = new List<Id>(trailmixIdMap.keyset());
        List<ALD_TrailmixAssignmentFlowHelper.ReturnVariable> responseWrapper 
            = ALD_TrailmixAssignmentFlowHelper.getUserIdList(trailmixIdList);
        System.assertEquals(responseWrapper[0].loggedUserIdList.size(), 3);
        System.assertEquals(responseWrapper[0].trailmixAssignedUseridList.size(), 2);
        Test.stopTest();
        
    }
    
    @isTest
    static void testMethod2()
    {
        Test.startTest();
        trailheadapp__Trailmix__c trailMix 
            = [SELECT ID 
               		FROM trailheadapp__Trailmix__c 
               		LIMIT 1];
        List<User> userList = [Select Id FROM User LIMIT 3];
        List<ALD_TrailmixAssignmentFlowHelperSecond.InputVariable> inputVariableList 
            = new List<ALD_TrailmixAssignmentFlowHelperSecond.InputVariable>();
        ALD_TrailmixAssignmentFlowHelperSecond.InputVariable inputVariable 
            = new ALD_TrailmixAssignmentFlowHelperSecond.InputVariable();
			inputVariable.userList = userList;
            inputVariable.dueDateTime = DateTime.now();
            inputVariable.dueDate = Date.today();
            inputVariable.trailMixId = trailMix.Id;
        inputVariableList.add(inputVariable); 
        List<ALD_TrailmixAssignmentFlowHelperSecond.ReturnVariable> responseWrapper 
            = ALD_TrailmixAssignmentFlowHelperSecond.getTAList(inputVariableList);
        System.assertEquals(responseWrapper[0].trailmixAssignmentList.size(), 3);
        Test.stopTest();
        
    }
}