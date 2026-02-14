@isTest(SeeAllData=false)
public class ServiceRequestServiceTest {
    @isTest static void setupData() {
        Test.startTest();
        HexaBPM__SR_Status__c Submitted = TestObjectsFactory.getSRStatus('Submitted');       
        insert Submitted;
        
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.BankEmail__c = 'ajay.thakur.tpr@pwc.com';
        acc.BankName__c = 'Abu Dhabi Commercial Bank';
        acc.CustomerBankName__c = 'Abu Dhabi Commercial Bank';
        acc.CustomerBankCountry__c = 'United Arab Emirates';
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Project__c projectRecord = TestObjectsFactory.getProjectRecord('Mayan');
        insert projectRecord;
        
        BuildingSection__c buildingRecord = TestObjectsFactory.getBuildingDetailRecord(projectRecord.id);
        insert buildingRecord;
        
        Unit__c unitrecord = TestObjectsFactory.getUnitDetail(projectRecord.id, buildingRecord.id);
        unitrecord.Status__c = Constants.UNIT_STATUS_SOLD;
        insert unitrecord;
        
        //SR TEMPLATE
        HexaBPM__SR_Template__c SR_Template = new HexaBPM__SR_Template__c();
        SR_Template.Name = Constants.DEFAULT_AND_TERMINATION;
        SR_Template.HexaBPM__SR_RecordType_API_Name__c=Constants.DEFAULT_AND_TERMINATION;
        insert SR_Template;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unitrecord.Id;
        salesOrder.HoldReasonCode__c = 'test123';
        insert salesOrder;
        
        HexaBPM__Service_Request__c propertyTransfer = new HexaBPM__Service_Request__c();
        propertyTransfer.RecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.PROPERTY_TRANSFER_RT);
        propertyTransfer.SRType__c =Constants.PROPERTY_TRANSFER_TYPE;
        propertyTransfer.HexaBPM__Customer__c = acc.Id;
        propertyTransfer.HexaBPM__Contact__c = acc.PersonContactId;
        propertyTransfer.HexaBPM__SR_Template__c = SR_Template.Id;
        propertyTransfer.Unit__c = unitrecord.Id;
        propertyTransfer.SalesOrder__c = salesOrder.Id;
        propertyTransfer.StepClosureDate__c = System.Today();
        propertyTransfer.TransferSellingPrice__c = 120000;
        //insert propertyTransfer;
        
        ServiceRequestService.queryAllFieldsWithExtraFields(new List<Id>{propertyTransfer.Id});
        ServiceRequestService.getOpenServiceRequestByType(new Set<String>{Constants.PROPERTY_TRANSFER_RT});
        ServiceRequestService.getOpenServiceRequestListByType(new Set<String>{Constants.PROPERTY_TRANSFER_RT});
        ServiceRequestService.getServiceRequestWithWhereClause(' Name =\'test\'');
        Test.stopTest();
    }
}