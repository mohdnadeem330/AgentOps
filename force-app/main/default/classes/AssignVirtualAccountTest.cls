@istest
public class AssignVirtualAccountTest {
	@isTest
    public static void AssignVirtualAccountNumberTest() {
        Test.startTest();
        
        Map<String,Id> recordTypeSR = new Map<String,Id>();
        for(Recordtype rtype : [SELECT Id,DeveloperName FROM Recordtype WHERE SObjectType = 'HexaBPM__Service_Request__c' AND DeveloperName = 'PropertyTransfer']){
            recordTypeSR.put(rtype.DeveloperName,rtype.Id);
        }
        
        HexaBPM__SR_Status__c srStatus = new HexaBPM__SR_Status__c();
        srStatus.HexaBPM__Code__c = 'Draft';
        srStatus.Name = 'Draft';
        insert srStatus;
        
        HexaBPM__SR_Status__c srStatus2 = new HexaBPM__SR_Status__c();
        srStatus2.HexaBPM__Code__c = 'Transfer Approved';
        srStatus2.Name = 'Transfer Approved';
        insert srStatus2 ;
        
        HexaBPM__SR_Status__c srStatus3 = new HexaBPM__SR_Status__c();
        srStatus3.HexaBPM__Code__c =  'Submitted';
        srStatus3.Name =  'Submitted';
        insert srStatus3 ;
       
        
        HexaBPM__SR_Template__c SR_Template = new HexaBPM__SR_Template__c();
        SR_Template.Name = 'Property Transfer';
        SR_Template.HexaBPM__SR_RecordType_API_Name__c='PropertyTransfer';
        insert SR_Template;
        
        HexaBPM__Step_Template__c ST = new HexaBPM__Step_Template__c();
        ST.Name = 'Validate the request by verifying the outstanding liabilities';
        ST.HexaBPM__Code__c = 'Validate the request by verifying the outstanding liabilities';
        ST.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert ST;
        
        HexaBPM__SR_Steps__c SRStep = new HexaBPM__SR_Steps__c();
        SRStep.HexaBPM__SR_Template__c = SR_Template.id;
        SRStep.HexaBPM__Step_No__c = 1;
        SRStep.HexaBPM__Step_Template__c = ST.Id;
        //SRStep.HexaBPM__Summary__c = 'Assignment of Broker Manager';
        //SRStep.HexaBPM__Group_Name__c = 'Assignment of Broker Manager';
        insert SRStep;
        
        Project__c projectRecord= TestObjectsFactory.getProjectRecord('Mayan');
         insert projectRecord;
         
         BuildingSection__c buildingRecord= TestObjectsFactory.getBuildingDetailRecord(projectRecord.id);
         insert buildingRecord;
         Unit__c unitrecord = TestObjectsFactory.getUnitDetail(projectRecord.id,buildingRecord.id);
        unitrecord.Status__c = 'Sold';
         insert unitrecord;
        
        BankVirtualAccounts__c va1 = TestObjectsFactory.getBankVirtualAccounts();
        va1.Project__c = projectRecord.id;
        va1.Unit__c = unitrecord.id;
        va1.BufferFlag__c = false;
        va1.Virtual_Account_Type__c = 'Escrow';
        insert va1;
        BankVirtualAccounts__c va2 = TestObjectsFactory.getBankVirtualAccounts();
        va2.Project__c = projectRecord.id;
        va2.Unit__c = unitrecord.id;
        va2.BufferFlag__c = false;
        va2.Virtual_Account_Type__c = 'Escrow';
        insert va2;
        BankVirtualAccounts__c va3 = TestObjectsFactory.getBankVirtualAccounts();
        va3.Project__c = projectRecord.id;
        va3.Unit__c = unitrecord.id;
        va3.BufferFlag__c = true;
        va3.Virtual_Account_Type__c = 'Escrow';
        insert va3;
        unitrecord.VirtualAccountNumber__c = va1.id;
        unitrecord.VirtualAccountNumberForSR__c = va2.id;
        update unitrecord;
        Account account = TestObjectsFactory.getOrganisationAccountRecord('companyName', 'registrationNo');
        insert account;
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(account.Id );
        opp.EnquiryTrigger__c=null;
        insert opp;
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, account.Id);
        salesOrder.Unit__c = unitrecord.Id;
        salesOrder.IsBookingCompleted__c = true;
        salesOrder.BookingDate__c = date.today();
        insert salesOrder;
        
        HexaBPM__Service_Request__c SR = new HexaBPM__Service_Request__c();
        SR.RecordTypeId = recordTypeSR.get('PropertyTransfer');
        SR.HexaBPM__External_SR_Status__c = srStatus.Id;
		SR.HexaBPM__Internal_SR_Status__c = srStatus.Id;
        SR.HexaBPM__Submitted_DateTime__c = Datetime.now();
        SR.HexaBPM__SR_Template__c = SR_Template.Id;
        SR.Unit__c = unitrecord.Id;
        SR.SRType__c = 'Property Transfer';
        insert SR;
        
        
        //UpdateVirtualAccountNumber.AssignVirtualAccountNumber(new List<id>{SR.id});
        srStatus = [select id, HexaBPM__Code__c from HexaBPM__SR_Status__c where id=:srStatus.Id];
        system.debug('srStatus '+srStatus);
        //srStatus.HexaBPM__Code__c = 'Transfer Approved';
        //srStatus.Name = 'Transfer Approved';
        //update srStatus;
        SR.HexaBPM__External_SR_Status__c = srStatus2.id;
        SR.HexaBPM__Internal_SR_Status__c = srStatus2.id;
        update sr;
        
        system.debug('srStatus '+srStatus);
        system.debug([select id,HexaBPM__External_Status_Code__c from HexaBPM__Service_Request__c ]);
        
        
        UpdateVirtualAccountNumber.AssignVirtualAccountNumber(new List<id>{SR.id});
        AssignVirtualAccount.AssignVirtualAccountNumber(new List<id>{SR.id});
        unitrecord.VirtualAccountNumber__c=va2.id;
        unitrecord.VirtualAccountNumberForSR__c=null;
        update unitrecord;
        
        va1.StatusFlag__c ='Transferred';
        va1.SalesOrder__c = salesorder.id;
        update va1;
        
        test.stopTest();
    }
}