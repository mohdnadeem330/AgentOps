@IsTest
public class RETL_OrderItemTriggerTest {

    @IsTest
    static void testOrderItemTrigger() {

        // Create Account (required for Order)
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Products
        Product2 p1 = new Product2(
            Name = 'Product A',
            ProductCode = 'PRA',
            IsActive = true
        );
        insert p1;

        Product2 p2 = new Product2(
            Name = 'Product B',
            ProductCode = 'PRB',
            IsActive = true
        );
        insert p2;

        // Standard Pricebook REQUIRED
        Id stdPbId = Test.getStandardPricebookId();

        // PricebookEntries
        PricebookEntry pbe1 = new PricebookEntry(
            Pricebook2Id = stdPbId,
            Product2Id = p1.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe1;

        PricebookEntry pbe2 = new PricebookEntry(
            Pricebook2Id = stdPbId,
            Product2Id = p2.Id,
            UnitPrice = 200,
            IsActive = true
        );
        insert pbe2;

        // Order with Pricebook
        Order ord = new Order(
            AccountId = acc.Id,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            Pricebook2Id = stdPbId
        );
        insert ord;

        // INSERT OrderItems
        OrderItem oi1 = new OrderItem(
            OrderId = ord.Id,
            Quantity = 1,
            UnitPrice = 100,
            PricebookEntryId = pbe1.Id
        );

        OrderItem oi2 = new OrderItem(
            OrderId = ord.Id,
            Quantity = 1,
            UnitPrice = 200,
            PricebookEntryId = pbe2.Id
        );

        insert new List<OrderItem>{ oi1, oi2 };
        ord = [SELECT Unit_Number__c FROM Order WHERE Id = :ord.Id];

        // UPDATE
        update oi1;
        ord = [SELECT Unit_Number__c FROM Order WHERE Id = :ord.Id];

        // DELETE
        delete oi2;
        ord = [SELECT Unit_Number__c FROM Order WHERE Id = :ord.Id];

        // NO UNDELETE (OrderItem cannot be undeleted)
    }
}