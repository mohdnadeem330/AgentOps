@IsTest
private class RETL_RenewalOppLineServiceTest {

    private static Id standardPricebookId;

    @TestSetup
    static void setupTestData() {

        // Standard Pricebook
        standardPricebookId = Test.getStandardPricebookId();

        // Retail Pricebook
        Pricebook2 retailPB = new Pricebook2(
            Name = 'Retail Price Book',
            IsActive = true
        );
        insert retailPB;

        // Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Renewal Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Pricebook2Id = retailPB.Id
        );
        insert opp;

        // Retail Units
        Retail_Unit__c ru1 = new Retail_Unit__c(
            UnitID_External_ID__c = 'U1001',
            Unit_Code__c = 'U1001',
            Property_Code__c = 'PROP01'
        );
        Retail_Unit__c ru2 = new Retail_Unit__c(
            UnitID_External_ID__c = 'U1002',
            Unit_Code__c = 'U1002',
            Property_Code__c = 'PROP01'
        );
        insert new List<Retail_Unit__c>{ ru1, ru2 };

        // Products (pre-existing)
        Product2 p1 = new Product2(
            Name = 'Unit 1001',
            ProductCode = 'U1001',
            RETL_Yardi_Id__c = 'U1001',
            IsActive = true
        );
        Product2 p2 = new Product2(
            Name = 'Unit 1002',
            ProductCode = 'U1002',
            RETL_Yardi_Id__c = 'U1002',
            IsActive = true
        );
        insert new List<Product2>{ p1, p2 };

        // REQUIRED: Standard PBEs must exist
        insert new List<PricebookEntry>{
            new PricebookEntry(
                Pricebook2Id = standardPricebookId,
                Product2Id = p1.Id,
                UnitPrice = 0,
                IsActive = true
            ),
            new PricebookEntry(
                Pricebook2Id = standardPricebookId,
                Product2Id = p2.Id,
                UnitPrice = 0,
                IsActive = true
            )
        };

        // IMPORTANT:
        // DO NOT insert Retail PBEs here.
        // Let the service create them to avoid duplicate errors.
    }



    // -------------------------------------------------------------------------
    // SUCCESS TEST
    // -------------------------------------------------------------------------

    @IsTest
    static void testCreateOLIs_Success() {

        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        // Fetch Retail Unit IDs (THIS FIXES THE FAILURE)
        Retail_Unit__c ru1 = [
            SELECT Id FROM Retail_Unit__c WHERE Unit_Code__c='U1001' LIMIT 1
        ];
        Retail_Unit__c ru2 = [
            SELECT Id FROM Retail_Unit__c WHERE Unit_Code__c='U1002' LIMIT 1
        ];

        String reqJson = JSON.serialize(new Map<String, Object>{
            'opportunityId' => opp.Id,
            'propertyCode' => 'PROP01',
            'units' => new List<Map<String, Object>>{
                new Map<String, Object>{
                    'unitId' => ru1.Id,     // FIXED
                    'unitCode' => 'U1001',
                    'unitType' => 'Type A',
                    'floor' => '1',
                    'location' => 'North Wing',
                    'area' => '100',
                    'baseRent' => 150,
                    'marketingAmount' => 10,
                    'serviceCharge' => 5
                },
                new Map<String, Object>{
                    'unitId' => ru2.Id,     // FIXED
                    'unitCode' => 'U1002',
                    'unitType' => 'Type B',
                    'floor' => '2',
                    'location' => 'South Wing',
                    'area' => '120',
                    'baseRent' => 200,
                    'marketingAmount' => 15,
                    'serviceCharge' => 7
                }
            }
        });

        RestRequest req = new RestRequest();
        req.requestUri = '/Retail/OpportunityLineItems';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(reqJson);
        RestContext.request = req;

        RestContext.response = new RestResponse();

        Test.startTest();
        RETL_RenewalOppLineService.createOLIs();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);

        List<OpportunityLineItem> olis = [
            SELECT Id, UnitPrice, RETL_Selected_Unit__c
            FROM OpportunityLineItem
            WHERE OpportunityId = :opp.Id
        ];

        System.assertEquals(2, olis.size());
    }



    // -------------------------------------------------------------------------
    // TEST: Missing Unit Id
    // -------------------------------------------------------------------------

    @IsTest
    static void testCreateOLIs_MissingUnitId() {

        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        String reqJson = JSON.serialize(new Map<String, Object>{
            'opportunityId' => opp.Id,
            'propertyCode' => 'PROP01',
            'units' => new List<Map<String, Object>>{
                new Map<String, Object>{
                    'unitId' => '',  // INVALID
                    'unitCode' => 'U1003',
                    'unitType' => 'Type C',
                    'floor' => '3',
                    'location' => 'East Wing',
                    'area' => '130',
                    'baseRent' => 250,
                    'marketingAmount' => 20,
                    'serviceCharge' => 10
                }
            }
        });

        RestRequest req = new RestRequest();
        req.requestUri = '/Retail/OpportunityLineItems';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(reqJson);
        RestContext.request = req;

        RestContext.response = new RestResponse();

        Test.startTest();
        RETL_RenewalOppLineService.createOLIs();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
        System.assert(RestContext.response.responseBody.toString().contains('Invalid request'));
    }



    // -------------------------------------------------------------------------
    // TEST: Empty Units List
    // -------------------------------------------------------------------------

    @IsTest
    static void testCreateOLIs_EmptyUnits() {

        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        String reqJson = JSON.serialize(new Map<String, Object>{
            'opportunityId' => opp.Id,
            'propertyCode' => 'PROP01',
            'units' => new List<Object>()  // empty list
        });

        RestRequest req = new RestRequest();
        req.requestUri = '/Retail/OpportunityLineItems';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(reqJson);
        RestContext.request = req;

        RestContext.response = new RestResponse();

        Test.startTest();
        RETL_RenewalOppLineService.createOLIs();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
        System.assert(RestContext.response.responseBody.toString().contains('Invalid request'));
    }
}