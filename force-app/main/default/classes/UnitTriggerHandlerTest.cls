@isTest(SeeAllData=false)
public class UnitTriggerHandlerTest {
    @isTest static void setupMethod() {
        
        User userRecord = TestObjectsFactory.getUserRecord('System Administrator', 'userName');
        insert userRecord;
              
        Project__c projectRecord = TestObjectsFactory.getProjectRecord('25083');
        insert projectRecord;
        
        BuildingSection__c  buildingSectionRecord = TestObjectsFactory.getBuildingDetailRecord(projectRecord.id);
        insert buildingSectionRecord;

        Unit__c unit = TestObjectsFactory.getUnitDetail(projectRecord.id, buildingSectionRecord.id);
        //SR Status 
        insert new list<HexaBPM__SR_Status__c>{ TestObjectsFactory.getSRStatus(Constants.STEP_STATUS_APPOINTMENT_BOOKED),
                                                TestObjectsFactory.getSRStatus(Constants.STEP_STATUS_SENT),
                                                TestObjectsFactory.getSRStatus(Constants.SUBMITTED),
                                                TestObjectsFactory.getSRStatus(Constants.STATUS_DRAFT) , 
                                                TestObjectsFactory.getSRStatus(Constants.SR_STATUS_PENDING_FINANCE_VERIFICATION)};
                                                            
		Test.startTest();

        unit.AssignedToUser__c =  userRecord.id;  
        unit.status__c = Constants.UNIT_STATUS_NEW;  
        unit.SellingPrice__c = 1000;
        unit.SellingPriceComments__c = 'Comments';
        
        //unit.VirtualAccountNumber__c = va0.Id;
        insert unit;
        map<Id, SObject> oldMap = new map<Id, SObject>();
        oldMap.put(unit.Id, unit);
        List<unit__c> newList = new List<unit__c>();
        newList.add(unit);
        set<id> unitIdSet = new set<id>();
        unitIdSet.add(unit.Id);            
        UnitTriggerHandler.overrideSharing cls = new UnitTriggerHandler.overrideSharing();
        cls.validateUnitRelease(unitIdSet, newList,oldMap);
        
        BankVirtualAccounts__c va1 = TestObjectsFactory.getBankVirtualAccounts();
        va1.Project__c = projectRecord.id;
        va1.Unit__c = unit.id;
        va1.BufferFlag__c = false;
        va1.Virtual_Account_Type__c = 'Escrow';
        va1.EscrowIBANAccountNumber__c = 'TEST123';
        insert va1;
        
        BankVirtualAccounts__c va2 = TestObjectsFactory.getBankVirtualAccounts();
        va2.Project__c = projectRecord.id;
        va2.BufferFlag__c = false;
        va2.Virtual_Account_Type__c = 'Escrow';
        va2.EscrowIBANAccountNumber__c = 'TEST1234';
        insert va2;
        
        BankVirtualAccounts__c va3 = TestObjectsFactory.getBankVirtualAccounts();
        va3.Project__c = projectRecord.id;
        va3.Unit__c = unit.id;
        va3.BufferFlag__c = false;
        va3.Virtual_Account_Type__c = 'Aldar Corporate';
        va3.EscrowIBANAccountNumber__c = 'TEST4123';
        insert va3;
        
        BankVirtualAccounts__c va4 = TestObjectsFactory.getBankVirtualAccounts();
        va4.Project__c = projectRecord.id;
        //va4.Unit__c = unit.id;
        va4.BufferFlag__c = false;
        va4.Virtual_Account_Type__c = 'Aldar Corporate';
        va4.EscrowIBANAccountNumber__c = 'TEST5123';
        insert va4;
        
        TriggerHandler.processedIds = new Set<Id>();
        unit.status__c = Constants.UNIT_STATUS_AVAILABLE;  
        unit.WebFloorPlan__c = 'www.google.com';
        unit.SellingPrice__c = 10000;
        unit.SellingPriceComments__c = 'Commentss';
        unit.ASiteUnitStatus__c= Constants.ASITE_UNIT_CLEARED;
        unit.VirtualAccountNumber__c = va2.Id;
        unit.CorporateVirtualAccountNumber__c = va4.Id;
        unit.ReprocessCallout__c = 'Status';
        unit.UnitPlotArea__c =1000;
        update unit;
        
        unit.ReprocessCallout__c = 'Price';
        update unit;
        
        unit.AssignedToUser__c = UserInfo.getUserId();
        update unit;
        
        Unit__c unit1 = TestObjectsFactory.getUnitDetail(projectRecord.id, buildingSectionRecord.id);
        unit1.Name = 'Unique Name - 1';
        unit1.ResaleListed__c = false;
        insert unit1;

        try{
            
            unit1.VirtualAccountNumber__c = va2.Id;
            unit1.CorporateVirtualAccountNumber__c = va4.Id;
            unit1.ResaleListed__c = true;
            update unit1;
        } catch(Exception e){}
        Test.stopTest();
    }
    
}