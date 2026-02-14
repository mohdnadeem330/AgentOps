@isTest(SeeAllData=false)
public class UnitShareServiceTest {
    @isTest static void setupMethod() {
        
        User user = TestObjectsFactory.getUserRecord('Sales Manager', 'SM1');
        insert user;
        
        User user1 = TestObjectsFactory.getUserRecord('Sales Manager', 'SM2');
        insert user1;
        
        User sysAdmin = TestObjectsFactory.getUserRecord('System Administrator', 'SM2');
        insert sysAdmin;
         System.runAs (sysAdmin) {
        Account accountRecord = TestObjectsFactory.getOrganisationAccountRecord('CompanyName', 'Ysjs657');
        insert accountRecord;
        Contact contactRecord = TestObjectsFactory.contactDataSetup(accountRecord.Id);  
        
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
        
        
        unit.status__c = Constants.UNIT_STATUS_AVAILABLE;
        unit.AssignedToUser__c = user1.id;
        insert unit;  
        
        oldUnitsMap.put(unit.Id, unit);
        newUnitsMap.put(unit.Id, unit);      
        
        
        TriggerHandler.processedIds = new Set<Id>();      	        
        unit.AssignedToUser__c =  user.Id;
        update unit;               
        newUnitsMap.put(unit.Id, unit);
        
        UnitShareService.shareOrUnshareUnitAccess(newUnitsMap, oldUnitsMap);  
        
         AllocationGroup__c allocationGroup = TestObjectsFactory.getAllocationGroup('Dubai Team','DXB');
        insert allocationGroup ;
        AllocationGroup__c allocationGroupDetail = [SELECT Id,StartDate__c,EndDate__c,PublicGroupAssociated__c FROM AllocationGroup__c WHERE Id=:allocationGroup.Id];
        User userDetail = Utilities.getLoggedInUserDetail();
        
        AllocationGroupUser__c newGroupUser = TestObjectsFactory.getAllocationGroupUser(userDetail,allocationGroupDetail);
        insert newGroupUser ;
        
        TriggerHandler.processedIds = new Set<Id>();      	        
        unit.AssignedToUser__c =  null;
        unit.AllocationGroup__c = allocationGroupDetail.Id;        
        
        update unit;               
        newUnitsMap.put(unit.Id, unit);
        
        UnitShareService.shareOrUnshareUnitAccess(newUnitsMap, oldUnitsMap);  
        
        
        Test.stopTest();
         }
    } 
    
    @isTest static void setupMethod1() {
        
        User user = TestObjectsFactory.getUserRecord('Sales Manager', 'SM1');
        insert user;
         User sysAdmin = TestObjectsFactory.getUserRecord('System Administrator', 'SM2');
        insert sysAdmin;
         System.runAs (sysAdmin) {
        
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
        
        AllocationGroup__c allocationGroup = TestObjectsFactory.getAllocationGroup('Dubai Team','DXB');
        insert allocationGroup ;
        AllocationGroup__c allocationGroupDetail = [SELECT Id,StartDate__c,EndDate__c,PublicGroupAssociated__c FROM AllocationGroup__c WHERE Id=:allocationGroup.Id];
        User userDetail = Utilities.getLoggedInUserDetail();
        
        AllocationGroupUser__c newGroupUser = TestObjectsFactory.getAllocationGroupUser(userDetail,allocationGroupDetail);
        insert newGroupUser ;
        
        AllocationGroup__c allocationGroup1 = TestObjectsFactory.getAllocationGroup('Dubai Team1','DXB1');
        insert allocationGroup1 ;
        AllocationGroup__c allocationGroupDetail1 = [SELECT Id,StartDate__c,EndDate__c,PublicGroupAssociated__c FROM AllocationGroup__c WHERE Id=:allocationGroup1.Id];
        
        AllocationGroupUser__c newGroupUser1 = TestObjectsFactory.getAllocationGroupUser(user,allocationGroupDetail1);
        insert newGroupUser1 ;
        
        Test.startTest();
        
        
        unit.status__c = Constants.UNIT_STATUS_AVAILABLE;    
        unit.AllocationGroup__c = allocationGroupDetail.Id;
        insert unit;  
        
        oldUnitsMap.put(unit.Id, unit);
        newUnitsMap.put(unit.Id, unit);           
        
        //UnitShareService.shareOrUnshareUnitAccess(newUnitsMap, oldUnitsMap); 
        
        TriggerHandler.processedIds = new Set<Id>();
        unit.AllocationGroup__c = allocationGroup1.id;        
        unit.Status__c = Constants.UNIT_STATUS_BOOKING_INPROGRESS;
        unit.LockedBy__c = user.Id;
        update unit;        
        
        newUnitsMap.put(unit.Id, unit);
        UnitShareService.shareOrUnshareUnitAccess(newUnitsMap, oldUnitsMap);  
        
        
        
        
        
        
        Test.stopTest();
         }
    }
    
     @isTest static void approveLineByManager() {
        
        User userRecord = TestObjectsFactory.getUserRecord('System Administrator', 'userName');
        insert userRecord;
        
        Account accountRecord = TestObjectsFactory.getOrganisationAccountRecord('CompanyName', 'Ysjs657');
        insert accountRecord;
        
        Opportunity opportunityRecord = TestObjectsFactory.getOpportunityRecord(accountRecord.Id);
        insert opportunityRecord;
        
        BookingMemo__c bookingMemoRecord = TestObjectsFactory.getBookingMemoRecord(opportunityRecord.Id);
        insert bookingMemoRecord;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;
         
        MemoLines__c memoLineRecord = TestObjectsFactory.getMemoLineRecord(bookingMemoRecord.Id, unit.Id);
         memoLineRecord.Unit__c = unit.Id;
        insert memoLineRecord;
                
        List<MemoLines__c> memoLinesList = new List<MemoLines__c>();

        bookingMemoRecord.ApprovalProgress__c =  Constants.APPROVAL_PROGRESS_APPROVED;
        update bookingMemoRecord;

        memoLinesList.add(memoLineRecord);        
        UnitShareService.unitApprovedByLineManager(memoLinesList, userRecord.Name);
       
    }
    
    
    
}