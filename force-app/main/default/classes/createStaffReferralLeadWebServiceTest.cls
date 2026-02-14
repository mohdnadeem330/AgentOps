@isTest
public class createStaffReferralLeadWebServiceTest {

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
    }
     @isTest
    public static void doPostTest() {
        TestObjectsFactory.initializeRestContext(null, '/create/staffReferralLead');
        String req = '{"FirstName":"Sanath","LastName":"HM","Email":"smanohar@aldar.com","MobileNumber1__c":"527583669","MobileCountryCode__c":"971","CountryOfResidence__c":"United Arab Emirates","Nationality__c":"United Arab Emirates","Referral_Relationship__c":"friend","EmployeeName__c":"Aldar Employee","EmployeeEmail__c":"emp@aldar.com","EmployeeId__c":"87654567","EmployeeDepartment__c":"GDS","Project__c":"Saadiyat Grove","PropertyUsage__c":"Residential Property","ResidentStatus__c":"Resident","Financing__c":"Yes"}';
        RestContext.request.requestBody = Blob.valueOf(req);

        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStatusCode(200);
        
        mock.setStaticResource('GetEmailValidationSuccess');
        Test.setMock(HttpCalloutMock.class, mock);
     
        StaticResourceCalloutMock mock1 = new StaticResourceCalloutMock();
        mock1.setStaticResource('GetPhoneNoValidationSuccess');
        mock1.setStatusCode(200);
        
        Test.setMock(HttpCalloutMock.class, mock1);
        createStaffReferralLeadWebService.doPost(); 
    }
    @isTest
    public static void doPostTest2(){
        
        init();
        Test.startTest();
        TestObjectsFactory.initializeRestContext(null, '/create/staffReferralLead');
        String req = '{"FirstName":"Sanath","LastName":"HM","Email":"smanohar@aldar.com","MobileNumber1__c":"527583669","MobileCountryCode__c":"971","CountryOfResidence__c":"United Arab Emirates","Nationality__c":"United Arab Emirates","Referral_Relationship__c":"friend","EmployeeName__c":"Aldar Employee","EmployeeEmail__c":"emp@aldar.com","EmployeeId__c":"87654567","EmployeeDepartment__c":"GDS","Project__c":"Saadiyat Grove","PropertyUsage__c":"Residential Property","ResidentStatus__c":"Resident","Financing__c":"Yes"}';
        RestContext.request.requestBody = Blob.valueOf(req);
        
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStatusCode(200);
        
        mock.setStaticResource('GetEmailValidationSuccess');
        Test.setMock(HttpCalloutMock.class, mock);
        
        StaticResourceCalloutMock mock1 = new StaticResourceCalloutMock();
        mock1.setStaticResource('GetPhoneNoValidationSuccess');
        mock1.setStatusCode(200);
        
        Test.setMock(HttpCalloutMock.class, mock1);
        createStaffReferralLeadWebService.doPost(); 
        Test.StopTest();
    }
    @isTest
    public static void doPostTest3(){
        
        init();
        TestObjectsFactory.initializeRestContext(null, '/create/staffReferralLead');
        String req = '{"FirstName":"Sanath","LastName":"HM","Email":"smanohar@aldar.com","MobileNumber1__c":"527583669","MobileCountryCode__c":"971","CountryOfResidence__c":"United Arab Emirates","Nationality__c":"United Arab Emirates","Referral_Relationship__c":"friend","EmployeeName__c":"Aldar Employee","EmployeeEmail__c":"emp@aldar.com","EmployeeId__c":"87654567","EmployeeDepartment__c":"GDS","Project__c":"Saadiyat Grove","PropertyUsage__c":"Residential Property","ResidentStatus__c":"Resident","Financing__c":"Yes"}';
        RestContext.request.requestBody = Blob.valueOf(req);
        
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStatusCode(200);
        
        mock.setStaticResource('GetEmailValidationSuccess');
        Test.setMock(HttpCalloutMock.class, mock);
        
        StaticResourceCalloutMock mock1 = new StaticResourceCalloutMock();
        mock1.setStaticResource('GetPhoneNoValidationSuccess');
        mock1.setStatusCode(200);
        
        Test.setMock(HttpCalloutMock.class, mock1);
        createStaffReferralLeadWebService.doPost(); 
    }
    @isTest
    public static void doPostTest4(){
      
        TestObjectsFactory.initializeRestContext(null, '/create/staffReferralLead');
        String req = '{"FirstName":"Sanath","LastName":"HM","Email":"abc@xyzj.com","MobileNumber1__c":"000000000","MobileCountryCode__c":"971","CountryOfResidence__c":"United Arab Emirates","Nationality__c":"United Arab Emirates","Referral_Relationship__c":"friend","EmployeeName__c":"Aldar Employee","EmployeeEmail__c":"emp@aldar.com","EmployeeId__c":"87654567","EmployeeDepartment__c":"GDS","Project__c":"Saadiyat Grove","PropertyUsage__c":"Residential Property","ResidentStatus__c":"Resident","Financing__c":"Yes"}';
        RestContext.request.requestBody = Blob.valueOf(req);
        
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        //mock.setStatusCode(200);
        
        mock.setStaticResource('GetEmailValidationFail');
        Test.setMock(HttpCalloutMock.class, mock);
        
        StaticResourceCalloutMock mock1 = new StaticResourceCalloutMock();
        mock1.setStaticResource('GetPhoneNoValidationSuccess');
        mock1.setStatusCode(200);
        
        Test.setMock(HttpCalloutMock.class, mock1);
        createStaffReferralLeadWebService.doPost();  
    }
    @isTest
    public static void doPostTest5(){
        Test.startTest();
        init();
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStatusCode(200);
        
        mock.setStaticResource('GetSMSNotificationSuccess');
        Test.setMock(HttpCalloutMock.class, mock);
        
        TestObjectsFactory.initializeRestContext(null, '/getLeadPicklistValues');
        getLeadPicklistValuesWebservice.doGet();
        Test.stopTest();
    }
    @isTest
    public static void doPostTest6(){
        Test.startTest();
        init();
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStatusCode(200);
        
        mock.setStaticResource('GetSMSNotificationSuccess');
        Test.setMock(HttpCalloutMock.class, mock);
        
        TestObjectsFactory.initializeRestContext(null, '/get/staffReferralLeads');
        List<Lead> leadList = [Select id, EmployeeEmail__c, EmployeeId__c, LeadNumber__c, Status FROM Lead];
        getStaffReferralLeadsWebService.doPost(leadList[0].EmployeeEmail__c, leadList[0].EmployeeId__c);
        Test.stopTest();
    }
    static Unit__c unitRec ;
    public static void doPostTest7(){
      Test.startTest();
        init();
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc;
        
        Contact con = TestObjectsFactory.contactDataSetup(acc.Id);
        con.Email = 'ali.athamneh@pwc.com';
        update con;
        List<Lead> leadList = [Select id, EmployeeEmail__c, EmployeeId__c, LeadNumber__c, Status FROM Lead];
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        opp.LeadNumber__c = leadList[0].LeadNumber__c;
        update opp;
        
        unitRec = TestObjectsFactory.unitDataSetup('25083');
        unitRec.Status__c = 'Sold';
        insert unitRec;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unitRec.Id;
        salesOrder.Contact__c = con.Id;
        salesOrder.MortgageApplicationNumber__c = '1234';
        salesOrder.MortgageApplicable__c = 'No';
        salesOrder.ADMFeeAmount__c = 20000;
        insert salesOrder;
        List<SalesOrder__c> soList = [Select Id, Status__c, Opportunity__c, Opportunity__r.LeadNumber__c FROM SalesOrder__c];
        system.debug('SoList::'+soList);
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStatusCode(200);
        
        mock.setStaticResource('GetSMSNotificationSuccess');
        Test.setMock(HttpCalloutMock.class, mock);
        
        TestObjectsFactory.initializeRestContext(null, '/get/staffReferralLeads');
        getStaffReferralLeadsWebService.doPost(leadList[0].EmployeeEmail__c, leadList[0].EmployeeId__c);
        getStaffReferralLeadsWebService.doPost(null, null);
        Test.stopTest();
    }
    
}