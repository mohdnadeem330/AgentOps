@isTest(SeeAllData=false)
public class UnitServiceTest {
    @isTest static void setupMethod() {
        

        User userRecord = TestObjectsFactory.getUserRecord('System Administrator', 'userName');
        insert userRecord;

        User userRecord1 = TestObjectsFactory.getUserRecord('System Administrator', 'userName1');
        insert userRecord1;

        Account accountRecord = TestObjectsFactory.getOrganisationAccountRecord('CompanyName', 'Ysjs657');
        insert accountRecord;
        Contact contactRecord = TestObjectsFactory.contactDataSetup(accountRecord.Id);  
        //insert contactRecord;      
        Opportunity opportunityRecord = TestObjectsFactory.getOpportunityRecord(accountRecord.Id);
        insert opportunityRecord;

        BookingMemo__c bookingMemoRecord = TestObjectsFactory.getBookingMemoRecord(opportunityRecord.id);
        insert bookingMemoRecord;

        

        Project__c projectRecord = TestObjectsFactory.getProjectRecord('25083');
        insert projectRecord;

        BuildingSectionService buildingSection = new BuildingSectionService();
        
        BuildingSection__c  buildingSectionRecord = TestObjectsFactory.getBuildingDetailRecord(projectRecord.id);
        insert buildingSectionRecord;

        Unit__c unit = TestObjectsFactory.getUnitDetail(projectRecord.id, buildingSectionRecord.id);

        Set<Id> buildingSectionId = new Set<Id>();
        buildingSectionId.add(buildingSectionRecord.id);

        List<MemoLines__c> memoLinesList = new List<MemoLines__c>();

        String query = 'select id from Unit__c where id = \'';

        String whereCondition = 'UnitModel__c = \''+'1BHK'+'\'';

        Map<String,String> mapFieldApiFieldValues;  
        
        Map<Id,Unit__c> newUnitsMap = new Map<Id,Unit__c>();
        Map<Id,Unit__c> oldUnitsMap = new Map<Id,Unit__c>();

        Test.startTest();
        //unit.AssignedToUser__c = userRecord.Id;
        insert unit;
        newUnitsMap.put(unit.Id, unit);
        //unit.AssignedToUser__c = userRecord1.Id;
        //unit.Status__c = 'New';
        //update unit;
        oldUnitsMap.put(unit.Id, unit);

        query += unit.id+'\'';
        System.debug(query);

        MemoLines__c memoLineRecord = TestObjectsFactory.getMemoLineRecord(bookingMemoRecord.id,unit.id);
        insert memoLineRecord;

        System.debug('Ajay'+memoLineRecord.Unit__r);

        memoLinesList.add(memoLineRecord);
        

        Set<Id> untIdSet = new Set<Id>();
        Set<String> unitIdSet = new Set<String>();

        
        

        untIdSet.add(unit.id);
        unitIdSet.add(unit.id);

        UnitService unitServices = new UnitService();

        UnitService.getAllAvailableUnitsUnderBuilding(buildingSectionId);
        UnitService.getAllUnitsById(untIdSet);
        UnitService.prepareUnitId(unit.Name);
        UnitService.unitBookingMemoApproved(memoLinesList, userRecord.Id);
        unitService.prepareDropdownData(projectRecord.Name);
        unitService.prepareDropdownData('');
        unitService.prepareOptionList(projectRecord.Id,buildingSectionRecord.Id);
        unitService.prepareOptionList(projectRecord.Id,'');
        UnitService.getUnitQuery(query);
        UnitService.makeUnitsAvailable(untIdSet);
        UnitService.cancelUnitReservation(unitIdSet);
        UnitService.getUnitShare(unit.Id, userRecord.id, 'Edit');
        UnitService.fetchPropertyInventories(whereCondition);        
        UnitService.filterAvailableUnits(mapFieldApiFieldValues);
        UnitService.getAllUnitsBrokerPortal(projectRecord.Id);
        //UnitService.fetchPropertyInventories('testCondtion');

        UnitShareService.shareOrUnshareUnitAccess(newUnitsMap, oldUnitsMap);
        UnitService.getUnitsById(new List<Id>{unit.id});
        UnitService.getAllProjectsBrokerPortal();
        

        Test.stopTest();


    }
}