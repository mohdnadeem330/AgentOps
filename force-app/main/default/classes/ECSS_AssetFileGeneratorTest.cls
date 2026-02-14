@IsTest
public class ECSS_AssetFileGeneratorTest {

    @IsTest
    static void testGenerateCsvFile() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Project__c  proj = new Project__c (Name = 'TestP',BusinessUnitId__c='001',ProjectCode__c='001');
        insert proj;

        Zone__c  zone = new Zone__c (Name = 'TestZ',Project__c=proj.Id,Zone_External_Id__c='001');
        insert zone;

        	BuildingSection__c building = new 	BuildingSection__c(Name = 'TestB',Project__c=proj.Id,BuildingSectionCode__c='001');
        insert building;
        
         insert new Trigger_Enabler__c(
            Name = 'Asset',
            Is_After_Insert__c = true,
            Is_After_Update__c = true,
            Is_After_Delete__c = true,
            Is_Before_Insert__c = true,
            Is_Before_Update__c = true,
            Is_Before_Delete__c = true
        );

        Asset asset = new Asset(
            Name = 'Unit 101',
            AccountId = acc.Id,
            ExternalIdentifier = 'EXT-001',
            ECSS_Unit_Type__c = 'Apartment',
            ECSS_Floor_Number__c = '5',
            ECSS_Unit_Area__c = 'DXB',
            ECSS_Number_of_Bedrooms__c = '3',
            ECSS_Number_of_Baths__c = 2,
            ECSS_View__c = 'Sea',
            ECSS_Project__c = proj.Id,
            ECSS_Zone__c = zone.Id,
            ECSS_Building_Section__c = building.Id,
            ECSS_Unit_Usage__c = 'Residential'
        );
        insert asset;

        List<List<Id>> inputWrapper = new List<List<Id>>();
        inputWrapper.add(new List<Id>{ asset.Id });

        Test.startTest();
        List<ECSS_AssetFileGenerator.OutputWrapper> results =
            ECSS_AssetFileGenerator.generate(inputWrapper);
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return exactly one OutputWrapper');

        ContentVersion cv = [
            SELECT Id, Title, PathOnClient, VersionData
            FROM ContentVersion
            WHERE Id = :results[0].contentVersionId
            LIMIT 1
        ];
        System.assertEquals('Asset_Report', cv.Title, 'CSV file title should match');
        System.assertEquals('Asset_Report.csv', cv.PathOnClient, 'File name should match');
    }
}