@isTest
public class UserTrailmixTriggerHandlerTest 
{
    @testSetup 
    public static void setupMethod()
    {
        trailheadapp__Trailmix__c onBoardtrailMix 				= new trailheadapp__Trailmix__c();
        onBoardtrailMix.Name 									= 'Onboard Test TrailMix';
        onBoardtrailMix.trailheadapp__Description__c			= 'Description of TrailMix';
        onBoardtrailMix.CreatedDate								= Date.today().addDays(-4);
        onBoardtrailMix.trailheadapp__URL__c					= 'www.google.com';
        onBoardtrailMix.trailheadapp__External_Id__c			= '02b98640-9a3d-f0df-b63c-8005d90fdcc4';
        onBoardtrailMix.trailheadapp__Slug__c					= 'test-onboard-trailmix';
       	onBoardtrailMix.trailheadapp__Created_By_Profile__c		= 'https://trailhead.salesforce.com/users/profiles/tdontha4';
        insert onBoardtrailMix;
        
        Trailmix_Feature_Restriction__c  trailmixFeatureRest = new Trailmix_Feature_Restriction__c();
        trailmixFeatureRest.Trailmix__c = onBoardtrailMix.Id;
        trailmixFeatureRest.Onboarding_Restriction__c = true;
        trailmixFeatureRest.ProfileName__c = 'Agency Admin Login';
        insert trailmixFeatureRest;
        
        Account accountRecord = TestObjectsFactory.getOrganisationAccountRecord('CompanyName', 'Ysjs657');
        insert accountRecord;

        Contact con = TestObjectsFactory.contactDataSetup(accountRecord.Id);
		con.FirstName = 'Test';
        con.LastName = 'User';
        update con;
        
        User agencyAdmin = TestObjectsFactory.getUserRecord(Constants.AGENCY_ADMIN_PROFILE_LOGIN, 'agencyAdmin');
        agencyAdmin.ContactId = con.Id;
        agencyAdmin.Email = 'test@gmail.com';
        insert agencyAdmin;
        
        trailheadapp__User_Trailmix__c userTrailmix		= new trailheadapp__User_Trailmix__c();
        userTrailmix.trailheadapp__Trailmix__c			= onBoardtrailMix.Id;
        userTrailmix.trailheadapp__User__c				= agencyAdmin.Id;
        userTrailmix.trailheadapp__Status__c			= 'In Progress';
        insert userTrailmix;
        
    }
    
    @isTest
    static void callMethods1()
    {
        User userRec = [SELECT Id, Name FROM User WHERE Id = :UserInfo.getUserId()];
        Test.startTest();
        System.runAs(userRec){
            trailheadapp__User_Trailmix__c userTrailmixRec = [SELECT Id, trailheadapp__Status__c 
                                                              FROM trailheadapp__User_Trailmix__c];
            userTrailmixRec.trailheadapp__Status__c = 'Completed';
            update userTrailmixRec;
        }
        Test.stopTest();
    }
    
    @isTest
    static void callMethodsException()
    {
        User userRec = [SELECT Id, Name FROM User WHERE Id = :UserInfo.getUserId()];
        Test.startTest();
        System.runAs(userRec){
            trailheadapp__User_Trailmix__c userTrailmixRec = [SELECT Id, trailheadapp__Status__c 
                                                              FROM trailheadapp__User_Trailmix__c];
            userTrailmixRec.trailheadapp__User__c = null;
            update userTrailmixRec;
             
        }
        Test.stopTest();
    }

}