@isTest
public class InterDepartmentLeadWebServiceTest {

     static void init(){
        Lead lead = new Lead();
        lead.FirstName = 'Sanath';
        lead.LastName = 'HM';
        lead.Email = 'smanohar@aldar.com';
        lead.MobileNumber1__c = '527583669';
        lead.MobileCountryCode__c = '971';
        lead.CountryOfResidence__c = 'United Arab Emirates';
        lead.Nationality__c = 'United Arab Emirates';
        lead.Referral_Relationship__c = 'friend';
        lead.EmployeeName__c = 'Aldar Employee';
        lead.EmployeeEmail__c = 'emp@aldar.com';
        lead.EmployeeId__c = '87654567';
        lead.EmployeeDepartment__c = 'GDS';
        lead.Project__c = 'Saadiyat Grove';
        lead.PropertyUsage__c = 'Residential Sale';
        lead.ResidentStatus__c = 'Resident';
        lead.Financing__c = 'Yes';
        lead.CustomerType__c = 'New Customer';
        lead.SalesType__c = 'Residential Sale';
        lead.LeadSource = 'Online';
        lead.SalesOrigin__c = lead.CountryOfResidence__c == 'United Arab Emirates' ? 'Domestic':'International';
        lead.EnquiryCategory__c = 'Internal Referral';
        lead.EnquiryTrigger__c = 'Staff Referral';
        insert lead;
         
        User userRecord = TestObjectsFactory.getUserRecord('Sales Manager', 'test123');
        //insert userRecord;
    }
    @isTest
    public static void doPostTest(){
        init();
        
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        List<Lead> leadList = [Select id, EmployeeEmail__c, EmployeeId__c, LeadNumber__c, Status FROM Lead];
        System.debug('LeadNumber '+leadList[0].LeadNumber__c);
        Opportunity oppRecord = TestObjectsFactory.getOpportunityRecord(acc.Id);
        oppRecord.LeadNumber__c = leadList[0].LeadNumber__c;
        upsert oppRecord;
        
        TestObjectsFactory.initializeRestContext(null, '/lead/referral'); 
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStatusCode(200);
        
        mock.setStaticResource('GetEmailValidationSuccess');
        Test.setMock(HttpCalloutMock.class, mock);
        
        StaticResourceCalloutMock mock1 = new StaticResourceCalloutMock();
        mock1.setStaticResource('GetPhoneNoValidationSuccess');
        mock1.setStatusCode(200);
        //RestContextHandler handler = new RestContextHandler(false);
        Test.startTest();
        InterDepartmentLeadRefferalWebService.doPost(oppRecord.id,  'AUH/DXB', 'Institutional', 'Corporate', 'Al Zeina');
        InterDepartmentLeadRefferalWebService.doPost(oppRecord.id, 'LAND', 'Commercial Land', 'Land', 'shams');
        InterDepartmentLeadRefferalWebService.doPost(oppRecord.id, 'Resales', null, null, null);
        InterDepartmentLeadRefferalWebService.doPost(null, null, null, null, null);
        Test.StopTest();
    }
    
}