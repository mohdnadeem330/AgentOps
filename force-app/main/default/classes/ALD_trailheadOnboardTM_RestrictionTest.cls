/******************************************************************************************************************
* Name              : ALD_trailheadOnboardTM_RestrictionTest                                                        
* Description       : 
* Created By        : tdontha@aldar.com - Tharun    
* Last Modified By	: tdontha@aldar.com - Tharun
******************************************************************************************************************/
@isTest
public class ALD_trailheadOnboardTM_RestrictionTest 
{
    //Create setup data
    @testSetup
    public static void setupData()
    {
        trailheadapp__Trailmix__c trailMix 				= new trailheadapp__Trailmix__c();
        trailMix.Name 									= 'Test TrailMix';
        trailMix.trailheadapp__Description__c			= 'Description of TrailMix';
        trailMix.CreatedDate							= Date.today().addDays(-4);
        trailMix.trailheadapp__URL__c					= 'www.google.com';
        trailMix.trailheadapp__External_Id__c			= '02b98640-9a3d-f0df-b63c-8005d90fdcc4';
        trailMix.trailheadapp__Slug__c					= 'test-trailmix';
       	trailMix.trailheadapp__Created_By_Profile__c	= 'https://trailhead.salesforce.com/users/profiles/tdontha4';
        insert trailMix;
        
        
        trailheadapp__Trailmix__c onBoardtrailMix 				= new trailheadapp__Trailmix__c();
        onBoardtrailMix.Name 									= 'Onboard Test TrailMix';
        onBoardtrailMix.trailheadapp__Description__c			= 'Description of TrailMix';
        onBoardtrailMix.CreatedDate								= Date.today().addDays(-4);
        onBoardtrailMix.trailheadapp__URL__c					= 'www.google.com';
        onBoardtrailMix.trailheadapp__External_Id__c			= '02b98640-9a3d-f0df-b63c-8005d90fdcc4';
        onBoardtrailMix.trailheadapp__Slug__c					= 'test-onboard-trailmix';
       	onBoardtrailMix.trailheadapp__Created_By_Profile__c		= 'https://trailhead.salesforce.com/users/profiles/tdontha4';
        insert onBoardtrailMix;
        
        
        
        
        Set<String> emailReminderMetadataConfigDays 	= new Set<String>([SELECT Id, DaysBefore__c FROM trailheadapp_Reminder__mdt WHERE CommunicationType__c = 'Email' AND DaysBefore__c != null LIMIT 1].DaysBefore__c.Split('\\|'));
        String dueDaysAdd = new List<String> (emailReminderMetadataConfigDays).get(0);
        
        TrailmixProjectRestriction__c trailmixProjRest = new TrailmixProjectRestriction__c();
        trailmixProjRest.Trailmix__c = trailMix.Id;
        trailmixProjRest.Project__c = 'Yas Park Views';
        insert trailmixProjRest;
        
        
        Trailmix_Feature_Restriction__c  trailmixFeatureRest = new Trailmix_Feature_Restriction__c();
        trailmixFeatureRest.Trailmix__c = onBoardtrailMix.Id;
        trailmixFeatureRest.Onboarding_Restriction__c = true;
        trailmixFeatureRest.ProfileName__c = 'Agency Admin Login';
        trailmixFeatureRest.Feature__c = 'Book Appointment';
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
        
        
    }
    
    
    @isTest
    static void callMethods1()
    {
        User userRecord1 = [SELECT Id FROM User WHERE Email = 'test@gmail.com'];
        
        System.runAs(userRecord1){
            Test.startTest();
            ALD_trailheadappOnboardTM_Restriction.checkUserOnboarded('Book Appointment','Yas Park Views');
            Test.stopTest();
        }
    }
    
    @isTest
    static void callMethodsUserOnBoarded()
    {
        User userRecord1 = [SELECT Id FROM User WHERE Email = 'test@gmail.com'];
        userRecord1.trailheadapp_Onboarded__c = TRUE;
        update userRecord1;
        System.runAs(userRecord1){
            Test.startTest();
            ALD_trailheadappOnboardTM_Restriction.checkUserOnboarded('Book Appointment','Yas Park Views');
            Test.stopTest();
        }
    }
    
    @isTest
    static void callMethods2()
    {
        Id trailmixProjRestId = [SELECT Id FROM TrailmixProjectRestriction__c].Id;
        User userRecord1 = [SELECT Id FROM User WHERE Email = 'test@gmail.com'];
        
        TrailmixProjectRestrictionException__c trailmixProjEx = new TrailmixProjectRestrictionException__c();
        trailmixProjEx.TrailmixProjectRestriction__c = trailmixProjRestId;
        trailmixProjEx.User__c = userRecord1.Id;
        insert trailmixProjEx;
        
        trailheadapp__User_Trailmix__c userTrailmix		= new trailheadapp__User_Trailmix__c();
        userTrailmix.trailheadapp__Trailmix__c			= [SELECT Id FROM trailheadapp__Trailmix__c WHERE Name = 'Onboard Test TrailMix'].Id;
        userTrailmix.trailheadapp__User__c				= userRecord1.Id;
        userTrailmix.trailheadapp__Status__c			= 'In Progress';
        insert userTrailmix;

        System.runAs(userRecord1){
            Test.startTest();
            ALD_trailheadappOnboardTM_Restriction.checkUserOnboarded('Book Appointment','Yas Park Views');
            Test.stopTest();
        }
    }
    

}