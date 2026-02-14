/******************************************************************************************************************
* Name              : ALD_trailheadProjectTM_RestrictionTest                                                        
* Description       : 
* Created By        : tdontha@aldar.com - Tharun    
* Last Modified By	: tdontha@aldar.com - Tharun
******************************************************************************************************************/
@isTest
public class ALD_trailheadProjectTM_RestrictionTest 
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
        
        Set<String> emailReminderMetadataConfigDays 	= new Set<String>([SELECT Id, DaysBefore__c FROM trailheadapp_Reminder__mdt WHERE CommunicationType__c = 'Email' AND DaysBefore__c != null LIMIT 1].DaysBefore__c.Split('\\|'));
        String dueDaysAdd = new List<String> (emailReminderMetadataConfigDays).get(0);
        
        trailheadapp__User_Trailmix__c userTrailmix		= new trailheadapp__User_Trailmix__c();
        userTrailmix.trailheadapp__Trailmix__c			= trailMix.Id;
        userTrailmix.trailheadapp__User__c				= UserInfo.getUserId();
        userTrailmix.trailheadapp__Status__c			= 'In Progress';
        userTrailmix.trailheadapp__Due_At__c			= Date.today().addDays(Integer.valueOf(dueDaysAdd));
        insert userTrailmix;
        
        TrailmixProjectRestriction__c trailmixProjRest = new TrailmixProjectRestriction__c();
        trailmixProjRest.Trailmix__c = trailMix.Id;
        trailmixProjRest.Project__c = 'Yas Park Views';
        insert trailmixProjRest;
        
        Account accountRecord = TestObjectsFactory.getAgencyAccountRecord('testCompanyName', 'YSC784590');
        insert accountRecord;

        Contact con = TestObjectsFactory.contactDataSetup(accountRecord.Id);
		con.FirstName = 'Test';
        con.LastName = 'Contact';
        con.Email = 'test@gmail.com';
        update con;
        
        User agencyAdmin = TestObjectsFactory.getUserRecord(Constants.AGENCY_ADMIN_PROFILE_LOGIN, 'agencyAdmin');
        agencyAdmin.ContactId = con.Id;
        agencyAdmin.Email = 'test@gmail.com';
        insert agencyAdmin;

    }
    
    @isTest
    static void callMethods1()
    {
        Test.startTest();
        ALD_trailheadappProjectTM_Restriction.allowBookingForSelectedProject('Yas Park Views');
        Test.stopTest();
    }
    
    
    @isTest
    static void callMethods2()
    {
        Test.startTest();
        Id trailmixProjRestId = [SELECT Id FROM TrailmixProjectRestriction__c].Id;
        TrailmixProjectRestrictionException__c trailmixProjEx = new TrailmixProjectRestrictionException__c();
        trailmixProjEx.TrailmixProjectRestriction__c = trailmixProjRestId;
        trailmixProjEx.User__c = UserInfo.getUserId();
        insert trailmixProjEx;
        ALD_trailheadappProjectTM_Restriction.allowBookingForSelectedProject('Yas Park Views');
        Test.stopTest();
    }
    
    @isTest
    static void userLevelExceptions()
    {
        Test.startTest();
        Id trailmixProjRestId = [SELECT Id FROM TrailmixProjectRestriction__c].Id;
        TrailmixProjectRestrictionException__c trailmixProjEx = new TrailmixProjectRestrictionException__c();
        trailmixProjEx.TrailmixProjectRestriction__c = trailmixProjRestId;
        trailmixProjEx.User__c = UserInfo.getUserId();
        trailmixProjEx.ValidFrom__c = Date.today().addDays(-5);
        trailmixProjEx.ValidTill__c = Date.today().addDays(2);
        insert trailmixProjEx;
        
        ALD_trailheadappProjectTM_Restriction.allowBookingForSelectedProject('Yas Park Views');
        Test.stopTest();
    }
    
    @isTest
    static void userTrailmixCompleted()
    {
        Test.startTest();
        trailheadapp__User_Trailmix__c utm = [SELECT Id, trailheadapp__Status__c FROM trailheadapp__User_Trailmix__c];
        utm.trailheadapp__Status__c = 'Completed';
        update utm;
        ALD_trailheadappProjectTM_Restriction.allowBookingForSelectedProject('Yas Park Views');
        Test.stopTest();
    }
    
    @isTest
    static void agencyLevelExceptions()
    {
        Test.startTest();
        User userId = [SELECT Id FROM User WHERE Email = 'test@gmail.com'];
        
        Id trailmixProjRestId = [SELECT Id FROM TrailmixProjectRestriction__c].Id;
        TrailmixProjectRestrictionException__c trailmixProjEx = new TrailmixProjectRestrictionException__c();
        trailmixProjEx.TrailmixProjectRestriction__c = trailmixProjRestId;
        trailmixProjEx.Agency__c = [SELECT Id FROM Account WHERE Name = 'testCompanyName'].Id;
        trailmixProjEx.ValidFrom__c = Date.today().addDays(-6);
        trailmixProjEx.ValidTill__c = Date.today().addDays(3);
        insert trailmixProjEx;
        System.runAs(userId){
            ALD_trailheadappProjectTM_Restriction.allowBookingForSelectedProject('Yas Park Views');
        }
        Test.stopTest();
    }
    
}