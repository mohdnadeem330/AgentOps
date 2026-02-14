@IsTest
public class CloseServiceRequestControllerTest {
    
    @testSetup
    static void setupTestData() {
        
        //Project creation
        Project__c proj = new Project__c(
            Name = 'Balghaiylam',
            CurrencyIsoCode = 'AED',
            CommunityName__c = 'Al Marjan',
            Country__c = 'United Arab Emirates',
            OracleId__c = 'BAG',
            ProjectLocation__c = 'Project Location Balghaiylam',
            City__c = 'Dubai',
            Name_of_Seller__c = 'Aldar',
            Name_of_Seller_in_Arabic__c = 'Aldar _A',
            Project_Number__c = 'yes',
            BusinessUnitId__c = '1212332323',
            ProjectCode__c = 'BAG',
            EnableDocumentsCustomerPortal__c = true
        );
        
        insert proj;
        
		// building section creation
		RecordType buildingRT = [
            SELECT Id 
            FROM RecordType 
            WHERE SObjectType = 'BuildingSection__c' 
              AND DeveloperName = 'Building' 
            LIMIT 1
        ];
        
        // Create BuildingSection__c record with only meaningful values
        BuildingSection__c building = new BuildingSection__c(
            Name = 'BN-Zone_13',
            CurrencyIsoCode = 'AED',
            BuildingSectionCode__c = 'BN-Zone_13',
            Country__c = 'United Arab Emirates',
            Numberoffloors__c = 20,
            Project__c = proj.Id,
            RecordTypeId = buildingRT.Id
        );
        
        insert building;

        // ✅ Create a Unit record with unique Name (required by validation rule)
        Unit__c unit = new Unit__c(
            Name = 'TestUnit_' + System.now().getTime(),
            UnitType__c = 'villa',
            BuildingSectionName__c = building.Id,
            Project__c = proj.Id
        );
        insert unit;
        
        // ✅ Create a Sales Order linked to the Unit
        SalesOrder__c so = new SalesOrder__c(
            Unit__c = unit.Id
        );
        insert so;
        
        // ✅ Create SR Status records
        HexaBPM__SR_Status__c internalStatus = new HexaBPM__SR_Status__c(
            HexaBPM__Type__c = 'In Progress',
            HexaBPM__Code__c = 'Draft'
        );
        HexaBPM__SR_Status__c externalStatus = new HexaBPM__SR_Status__c(
            Name = 'Closed',
            HexaBPM__Type__c = 'Closed',
            HexaBPM__Code__c = 'End'
        );

        HexaBPM__SR_Status__c submittedStatus = new HexaBPM__SR_Status__c(
            Name = 'Submitted',
            HexaBPM__Type__c = 'End',
            HexaBPM__Code__c = 'Submitted'
        );
        insert new List<HexaBPM__SR_Status__c>{ internalStatus, externalStatus,submittedStatus };
            
            // ✅ Create a Service Request linked to the Sales Order
            HexaBPM__Service_Request__c sr = new HexaBPM__Service_Request__c(
                SalesOrder__c = so.Id,
                HexaBPM__Internal_SR_Status__c = internalStatus.Id,
                HexaBPM__External_SR_Status__c = internalStatus.Id
            );
        insert sr;
    }
    
    @IsTest
    static void testCloseServiceRequest_Success() {
        HexaBPM__Service_Request__c sr = [ SELECT Id FROM HexaBPM__Service_Request__c
            WHERE SalesOrder__c != NULL
            LIMIT 1];
        
        Test.startTest();
        String result = CloseServiceRequestController.closeServiceRequest(sr.Id);
        Test.stopTest();
        
        
        sr = [SELECT Id, HexaBPM__External_SR_Status__c
            FROM HexaBPM__Service_Request__c
            WHERE Id = :sr.Id];


        HexaBPM__SR_Status__c status = [
                    SELECT HexaBPM__Type__c 
                    FROM HexaBPM__SR_Status__c 
                    WHERE Id = :sr.HexaBPM__External_SR_Status__c
                ];
    }
    
    @IsTest
    static void testCloseServiceRequest_InvalidId() {
        try {
            Test.startTest();
            CloseServiceRequestController.closeServiceRequest(null);
            Test.stopTest();
            System.assert(false, 'Expected AuraHandledException');
        } catch (AuraHandledException e) {
            System.assert(String.isNotBlank(e.getMessage()));
        }
    }
    
    @IsTest
    static void testCloseServiceRequest_NoSalesOrder() {
        HexaBPM__Service_Request__c sr = new HexaBPM__Service_Request__c();
        insert sr;
        
        try {
            Test.startTest();
            CloseServiceRequestController.closeServiceRequest(sr.Id);
            Test.stopTest();
            System.assert(false, 'Expected AuraHandledException');
        } catch (AuraHandledException e) {
            System.assert(String.isNotBlank(e.getMessage()));
        }
    }
    
    // @IsTest
    // static void testCloseServiceRequest_WithInstallmentLines() {
    //     HexaBPM__Service_Request__c sr = [SELECT Id, SalesOrder__c FROM HexaBPM__Service_Request__c LIMIT 1];
        
    //     // ✅ Create an Installment Line linked to the same SalesOrder
    //     InstallmentLines__c inst = new InstallmentLines__c(
    //         SalesOrder__c = sr.SalesOrder__c
    //     );
    //     insert inst;
        
    //     try {
    //         Test.startTest();
    //         CloseServiceRequestController.closeServiceRequest(sr.Id);
    //         Test.stopTest();
    //         System.assert(false, 'Expected AuraHandledException');
    //     } catch (AuraHandledException e) {
    //         System.assert(e.getMessage().contains('pending Installment Lines'));
    //     }
    // }
    
    // @IsTest
    // static void testCloseServiceRequest_NoStatus() {
    //     // ✅ Create another Unit and Sales Order
    //     Unit__c unit = new Unit__c();
    //     insert unit;
        
    //     SalesOrder__c so = new SalesOrder__c(Unit__c = unit.Id);
    //     insert so;
        
    //     // ✅ Create SR without statuses
    //     HexaBPM__Service_Request__c sr = new HexaBPM__Service_Request__c(
    //         SalesOrder__c = so.Id
    //     );
    //     insert sr;
        
    //     try {
    //         Test.startTest();
    //         CloseServiceRequestController.closeServiceRequest(sr.Id);
    //         Test.stopTest();
    //         System.assert(false, 'Expected AuraHandledException');
    //     } catch (AuraHandledException e) {
    //         System.assert(e.getMessage().contains('No SR Status found to update'));
    //     }
    // }
}