@isTest
public class RETL_OpptyUnitNumberTriggerHandlerTest {

    @isTest
    static void testOpportunityUnitNumberLogic() {

        Map<String, Schema.RecordTypeInfo> rtMap =
            Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName();

        System.assert(
            rtMap.containsKey('RETL_Opportunity'),
            'RETL_Opportunity record type must exist'
        );

        Id rtId = rtMap.get('RETL_Opportunity').getRecordTypeId();

        Test.startTest();

        Product2 p1 = new Product2(Name='Test Product A', ProductCode='A100', IsActive=true);
        Product2 p2 = new Product2(Name='Test Product B', ProductCode='B200', IsActive=true);
        insert new List<Product2>{ p1, p2 };

        Id stdPbId = Test.getStandardPricebookId();

        List<PricebookEntry> pbeList = new List<PricebookEntry>{
            new PricebookEntry(Pricebook2Id=stdPbId, Product2Id=p1.Id, UnitPrice=10, IsActive=true),
            new PricebookEntry(Pricebook2Id=stdPbId, Product2Id=p2.Id, UnitPrice=20, IsActive=true)
        };
        insert pbeList;

        Opportunity opp = new Opportunity(
            Name='Test Opportunity',
            StageName='Prospecting',
            CloseDate=Date.today(),
            RecordTypeId=rtId
        );
        insert opp;

        OpportunityLineItem oli1 = new OpportunityLineItem(
            OpportunityId=opp.Id,
            Quantity=1,
            UnitPrice=10,
            PricebookEntryId=pbeList[0].Id
        );
        OpportunityLineItem oli2 = new OpportunityLineItem(
            OpportunityId=opp.Id,
            Quantity=1,
            UnitPrice=20,
            PricebookEntryId=pbeList[1].Id
        );
        insert new List<OpportunityLineItem>{oli1, oli2};

        opp = [SELECT UnitNumber__c FROM Opportunity WHERE Id=:opp.Id];
        System.assert(opp.UnitNumber__c.contains('A100'));
        System.assert(opp.UnitNumber__c.contains('B200'));

        Product2 p3 = new Product2(Name='Test Product C', ProductCode='C300', IsActive=true);
        insert p3;

        PricebookEntry pbe3 = new PricebookEntry(
            Pricebook2Id=stdPbId, Product2Id=p3.Id, UnitPrice=30, IsActive=true
        );
        insert pbe3;

        delete oli1;

        OpportunityLineItem oliUpdated = new OpportunityLineItem(
            OpportunityId=opp.Id,
            Quantity=1,
            UnitPrice=30,
            PricebookEntryId=pbe3.Id
        );
        insert oliUpdated;

        opp = [SELECT UnitNumber__c FROM Opportunity WHERE Id=:opp.Id];
        System.assert(opp.UnitNumber__c.contains('C300'));
        System.assert(opp.UnitNumber__c.contains('B200'));

        delete oli2;

        opp = [SELECT UnitNumber__c FROM Opportunity WHERE Id=:opp.Id];
        System.assertEquals('C300', opp.UnitNumber__c);

        delete oliUpdated;

        opp = [SELECT UnitNumber__c FROM Opportunity WHERE Id=:opp.Id];
        System.assertEquals(null, opp.UnitNumber__c);

        Test.stopTest();
    }
}