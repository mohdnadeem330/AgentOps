@isTest
public class CampaignMemberControllerTest {
	@isTest
    public static void testDuplicateEmail(){
        Account personAcc = TestObjectsFactory.getAccountRecord('Person Account',true,'1232344');
        personAcc.PersonEmail = 'campaignmember@gmail.com';   
        personAcc.MobileCountryCode__pc = '971' ;
        personAcc.MobilePhone__pc = '52887687' ;
        insert personAcc;
        
        personAcc.Sync_with_SFMC__pc = false;
        personAcc.Sync_with_SFMC__c = false;
        update personAcc;
        
        
        Lead leadRec3 = TestObjectsFactory.getLeadRecord(5,'Person');
        leadRec3.LeadSource = '800-Aldar';
        leadRec3.LastName = 'Chirag';
        leadRec3.EnquiryCategory__c = 'Aldar Database';
        leadRec3.EnquiryTrigger__c = 'Aldar SMS Campaign';
        leadRec3.Project__c = 'Balghaiylam';
        leadRec3.Email = 'campaignmember@gmail.com';
        leadRec3.InitiateDigitalBooking__c = true;
       	insert leadRec3;
        LeadCampaignSFMCBatch sf = new LeadCampaignSFMCBatch(1);
        Database.executeBatch(sf,1);
        CampaignMemberController.createCampaignMember(new List<Lead>{leadRec3});
        CampaignMemberController.creatAccount(leadRec3);
    }
    @isTest
    public static void testCreateAccount(){
       
        Lead leadRec3 = TestObjectsFactory.getLeadRecord(5,'Person');
        leadRec3.LeadSource = '800-Aldar';
        leadRec3.LastName = 'Chirag';
        leadRec3.EnquiryCategory__c = 'Aldar Database';
        leadRec3.EnquiryTrigger__c = 'Aldar SMS Campaign';
        leadRec3.Project__c = 'Balghaiylam';
        leadRec3.Email = 'campaignmember@gmail.com';
       	insert leadRec3;
        CampaignMemberController.createCampaignMember(new List<Lead>{leadRec3});
    }
    
    @isTest
    public static void testDuplicateEmail3(){
        Campaign_Custom__c camp = new Campaign_Custom__c();
        camp.Project_Name__c = 'Balghaiylam';
        insert camp;
        
        Account personAcc = TestObjectsFactory.getOrganisationAccountRecord('Person Account','1232344');
        insert personAcc;
        personAcc.Sync_with_SFMC__c = false;
        update personAcc;
        
        
        Lead leadRec3 = TestObjectsFactory.getLeadRecord(5,'Person');
        leadRec3.LeadSource = '800-Aldar';
        leadRec3.LastName = 'Chirag';
        leadRec3.EnquiryCategory__c = 'Aldar Database';
        leadRec3.EnquiryTrigger__c = 'Aldar SMS Campaign';
        leadRec3.Project__c = 'Balghaiylam';
        leadRec3.Email = 'campaignmember@gmail.com';
        leadRec3.ExistingAccount__c = personAcc.Id;
       	insert leadRec3;
        LeadCampaignSFMCBatch sf = new LeadCampaignSFMCBatch(1);
        Database.executeBatch(sf,1);
        CampaignMemberController.createCampaignMember(new List<Lead>{leadRec3});
        CampaignMemberController.creatAccount(leadRec3);
    }
}