@isTest
public class ALD_trailheadappEmailReminderBatchTest 
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
        
            
    }
    
    @isTest
    static void sendEmailForReminder1()
    {
        Test.startTest();
        ALD_trailheadappEmailReminderBatch batchEmail1 = new ALD_trailheadappEmailReminderBatch();
        Database.executeBatch(batchEmail1,5);
        
        System.schedule('ALD_trailheadappEmailReminderBatch-Test', '0 0 * * * ?', new ALD_trailheadappEmailReminderBatch() );
        Test.stopTest();
        //Assert
    }

}