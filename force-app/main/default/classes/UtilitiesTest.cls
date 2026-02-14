@istest
public class UtilitiesTest {

    static Id userId = UserInfo.getUserId() ;
    static Lead leadRec ;

    static void init(){
        leadRec = TestObjectsFactory.getLeadRecord(4, 'Person');
        leadRec.LeadSource = '800-Aldar' ;
        leadRec.EnquiryCategory__c = 'Kiosk' ;
        leadRec.EnquiryTrigger__c = 'Aljimi Mall Kiosk' ;
        insert leadRec ;
		//Dummy Commit - SSP-348
    }

    static testmethod void testGenericMethods(){
        Test.startTest();  
        init();
        String responseBody = '';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
    Utilities.getServiceDetails('SMS');
        Utilities.getMuleSoftDetails('unitStatus');
        Utilities.getAramexDetails('AramexCreateShipments');
        List<SPAChecklistItem__mdt> checklist = Utilities.getChecklist();
        Utilities.getAllmdtRec('Person Account');
        Utilities.getSystemMessages('BUDGET_UNAVIALABLE');
        Utilities.getDarnaLoyaltyMatrix();
        Utilities.getOrganizationDetails();
        Utilities.getOrgWideEmailAddressId();
        User userDetail = Utilities.getLoggedInUserDetail();
        User userDetail1 = Utilities.getUserDetailByEmail(UserInfo.getUserEmail());
        Utilities.getRandomNumber(8);
        Utilities.getSystemMessages(new Set<String>{'BUDGET_UNAVIALABLE'});
        Utilities.getValidationFields();
        Utilities.getSystemInformation('Lead');
        Utilities.getQueueInformation('Agent Queue');
        Utilities.getRecordTypeId('Lead','Person');
        Utilities.getProfileIds(new Set<String>{'System Adminstrator'});
        Utilities.getRecordCount('AppFetchRecordCount',Utilities.getRecordCount('AppMaxRecordCount',0));
        Utilities.getConstant('EmailServiceSandbox');
        Utilities.getBrokerPortalUserDetails(userId);
        Utilities.isAgentAvailable(new set<Id>{userId});
        Utilities.getOwnersDetail(new set<Id>{userId});
        Utilities.getDependentPickListValues('SalesOrder__c','Status__c','SubStatus__c');
        Utilities.getVFDomainURL();
        Utilities.amountInWords(1000000.20,Constants.UAE_CURRENCY_UNIT,Constants.UAE_CURRENCY_SUBUNIT);
        Utilities.createLogAudit(leadRec.Id,leadRec.Name);
        Utilities.getEmailInstance(null, null, leadRec.Id, new List<String>{'pavithra.gajendra@pwc.com'}, null, null, 'Test Email', null, null, null, Utilities.getOrgWideEmailAddressId());
        Utilities.makeHHTTPCallout('POST','https://testsecureacceptance.cybersource.com/pay','',new map<String,string>());
        Utilities.getOfferLineService();
        Utilities.getMobileAppColorCode();
        Utilities.getTimer('Timer');
        String recordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c','Internal Mortgage Discharge');
        Utilities.getRecordTypeName('HexaBPM__Service_Request__c', recordTypeId);
        Utilities.getCaseFieldDependency();
        Test.stopTest();  
    }

    static testmethod void testExceptions(){
            
    Utilities.getServiceDetails('SMS1');
        Utilities.getMuleSoftDetails('unitStatus1');
        Utilities.getAramexDetails('AramexCreateShipments1');
        List<SPAChecklistItem__mdt> checklist = Utilities.getChecklist();
        Utilities.getAllmdtRec('Person Account1'); //--- check the use of this.
        Utilities.getSystemMessages('BUDGET_UNAVIALABLE1');
        Utilities.getSystemMessages(new Set<String>{'BUDGET_UNAVIALABLE1'});
        Utilities.getEmailTemplate('TestEmail');
        Utilities.getSystemInformation('Lead__c');
        Utilities.getQueueInformation('Agent Queue1');
        Utilities.getProfileIds(new Set<String>{'System Adminstrator New'});
        Utilities.getRecordCount('AppFetchRecordCount',Utilities.getRecordCount('AppMaxRecordCount',0));
        Utilities.getConstant('EmailServiceSandbox1');
        

    }

    static testmethod void testDynamicQueryLeadMap(){
            
    Utilities.objType = 'Lead';
        Map<String,String> mapFieldApiFieldValues = new Map<String,String>();
        mapFieldApiFieldValues.put('Name','Pavithra');
        Utilities.getWhereConditionfrmMap(mapFieldApiFieldValues);

        List<String> types = new List<String>{'Lead'};
        Schema.DescribeSobjectResult[] result = Schema.describeSObjects(types);
        Map<String, Schema.SObjectField> fieldsMap = result[0].fields.getMap();

        Utilities.getDependentPickListValues(fieldsMap.get('CustomerType__c').getDescribe(),fieldsMap.get('CustomerSubType__c').getDescribe());

    }

    static testmethod void testDynamicQueryAccountMap(){
            
    Utilities.objType = 'account';
        Map<String,String> mapFieldApiFieldValues = new Map<String,String>();
        mapFieldApiFieldValues.put('Email__c','Pavithra.gajendra@pwc.com');
        mapFieldApiFieldValues.put('mobilenumber__c','7030181809');
        mapFieldApiFieldValues.put('customertype__c','New Customer');
        mapFieldApiFieldValues.put('name','Pavithra');
        mapFieldApiFieldValues.put('residentstatus__pc','Resident');
        mapFieldApiFieldValues.put('AccountNumber__c','1234');
        Utilities.getWhereConditionfrmMap(mapFieldApiFieldValues);
    }

    static testmethod void testDynamicQueryOpportunityMap(){
            
    Utilities.objType = 'opportunity';
        Account acct = TestObjectsFactory.getPersonAccountRecord();
        insert acct;

        Utilities.createLogAudit(acct.Id,acct.Name);

        Map<String,String> mapFieldApiFieldValues = new Map<String,String>();
        mapFieldApiFieldValues.put('status','Open');
        mapFieldApiFieldValues.put('name','Pavithra');
        mapFieldApiFieldValues.put('accountid',acct.Id);
        Utilities.getWhereConditionfrmMap(mapFieldApiFieldValues);
    }

    static testmethod void testDynamicQueryInventoryMap(){
            
    Utilities.objType = 'inventory';
        Account acct = TestObjectsFactory.getPersonAccountRecord();
        insert acct;

        Map<String,String> mapFieldApiFieldValues = new Map<String,String>();
        mapFieldApiFieldValues.put('project','mayan');
        mapFieldApiFieldValues.put('building','building 1');
        mapFieldApiFieldValues.put('minimumprice','1000');
        mapFieldApiFieldValues.put('maximumprice','1000000');
        mapFieldApiFieldValues.put('name','mayan');
        Utilities.getWhereConditionfrmMap(mapFieldApiFieldValues);
    }

    static testmethod void testDynamicQueryOrderMap(){
            
    Utilities.objType = 'salesorder';

        Map<String,String> mapFieldApiFieldValues = new Map<String,String>();
        mapFieldApiFieldValues.put('orderFromDate',String.valueOf(Date.today().addDays(-2)));
        mapFieldApiFieldValues.put('orderToDate',String.valueOf(Date.today()));
        mapFieldApiFieldValues.put('salesmanager__c',userId);
        mapFieldApiFieldValues.put('Unit','Mayan');
        Utilities.getWhereConditionfrmMap(mapFieldApiFieldValues);
    }

    static testmethod void testDynamicQueryTaskMap(){
            
    Utilities.objType = 'Task';

        Map<String,String> mapFieldApiFieldValues = new Map<String,String>();
        mapFieldApiFieldValues.put('fromDate',String.valueOf(Date.today().addDays(-2)));
        mapFieldApiFieldValues.put('toDate',String.valueOf(Date.today()));
        mapFieldApiFieldValues.put('ownerid',userId);
        mapFieldApiFieldValues.put('opportunityid','');
        mapFieldApiFieldValues.put('leadid','');
        mapFieldApiFieldValues.put('Status','Open');
        Utilities.getWhereConditionfrmMap(mapFieldApiFieldValues);
    }

    @isTest(SeeAllData=true)
    static void testConnectedAPI(){
            
    Utilities.getContentByTopics(0, 25,new List<String>{'News'},'en_US','Aldar_NewsAnnouncements');
        Utilities.getContentByType(0, 25,'en_US','Aldar_NewsAnnouncements');
    }
    
    @isTest static void generatePdfAndSendEmailTest() {
        
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc;
        
        Contact con = TestObjectsFactory.contactDataSetup(acc.Id);
        con.Email = 'ajay.thakur.tpr@gmail.com';
        update con;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.MortgageApplicable__c = 'Yes';
        salesOrder.Contact__c = con.Id;
        insert salesOrder;
        
        HexaBPM__SR_Template__c SRTemplateDetailRecord = TestObjectsFactory.getSRTemplate(Constants.INTERNAL_MORTGAGE_DISCHARGE_RT);        
        insert SRTemplateDetailRecord;
        
        HexaBPM__Step_Template__c objStepTemplate = TestObjectsFactory.getStepTemplate('Internal Mortgage Discharge', 'InternalMortgageDischarge');
        insert objStepTemplate;
        
        HexaBPM__SR_Steps__c objSRSteps = TestObjectsFactory.getSRStep(SRTemplateDetailRecord.Id, objStepTemplate.Id);
        insert objSRSteps;
        
        HexaBPM__SR_Status__c draft = TestObjectsFactory.getSRStatus('Draft');       
        insert draft;
        
        HexaBPM__SR_Status__c Submitted = TestObjectsFactory.getSRStatus('Submitted');       
        insert Submitted;
        
        HexaBPM__SR_Status__c requestApproved = TestObjectsFactory.getSRStatus('Request Approved');       
        insert requestApproved;       
        
        Id mortgageDischargeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.INTERNAL_MORTGAGE_DISCHARGE_RT);
        
        HexaBPM__Service_Request__c newSR = TestObjectsFactory.getServiceRequest(draft.Id, unit.Id, Constants.INTERNAL_MORTGAGE_DISCHARGE_TYPE, mortgageDischargeId, SRTemplateDetailRecord.Id);
        newSR.SalesOrder__c = salesOrder.Id;
        insert newSR;
        
        HexaBPM__Step__c newStep = TestObjectsFactory.getServiceRequestStep(newSR.id, objSRSteps.Id, objStepTemplate.id);     
        insert newStep;
        
        TestObjectsFactory.createContentDocumentLink(newSR.Id);
        ContentVersion cv = [SELECT Id, VersionData, Title FROM contentversion LIMIT 1];
        
        CC_SRMortgageDischargeController mortageDischarge = new CC_SRMortgageDischargeController();
        
        Test.startTest();
        
        newSR.HexaBPM__External_SR_Status__c =  requestApproved.Id;
        newSR.HexaBPM__Internal_SR_Status__c =  requestApproved.Id;
        update newSR;
        
        mortageDischarge.EvaluateCustomCode(newSR,newStep);
        Utilities.setEmailFileAtt(cv);
        
        Test.StopTest();
        
    }
    @isTest static void insertRoles() {
        
        UserRole role = new UserRole(DeveloperName = 'SystemAdmin', Name = 'System Admin');
        insert role;        
        
        Utilities.getAllSubRoleIds(new Set<Id>{role.Id});
        Utilities.getParentRoleId(new Set<Id>{role.Id});
    }
}