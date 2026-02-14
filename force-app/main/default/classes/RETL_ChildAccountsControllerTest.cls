@isTest
private class RETL_ChildAccountsControllerTest {

    @isTest
    static void testGetFilteredChildAccounts_Positive() {
        Account parentAcc = new Account(Name = 'Parent Account');
        insert parentAcc;

        Account child1 = new Account(Name = 'Child A', ParentId = parentAcc.Id, Type = 'Customer', AccountNumber = 'C001');
        Account child2 = new Account(Name = 'Child B', ParentId = parentAcc.Id, Type = 'Partner', AccountNumber = 'C002');
        Account unrelated = new Account(Name = 'Unrelated', Type = 'Customer', AccountNumber = 'U001');

        insert new List<Account>{child1, child2, unrelated};

        Test.startTest();
        List<Account> result = RETL_ChildAccountsController.getFilteredChildAccounts(parentAcc.Id, 'Customer');
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Only one customer-type child should be returned');
        System.assertEquals(child1.Id, result[0].Id, 'Expected child account not matched');
    }

    @isTest
    static void testGetFilteredChildAccounts_NoMatch() {
        Account parent = new Account(Name = 'Parent');
        insert parent;

        insert new Account(Name = 'Child X', ParentId = parent.Id, Type = 'Partner');

        Test.startTest();
        List<Account> result = RETL_ChildAccountsController.getFilteredChildAccounts(parent.Id, 'Customer');
        Test.stopTest();

        System.assertEquals(0, result.size(), 'No matching type child accounts should return empty list');
    }

    @isTest
    static void testGetBrandsViaJunction_Positive() {
        Account groupAcc = new Account(Name = 'Group Account', Type = 'Group');
        insert groupAcc;

        Account customer = new Account(Name = 'Customer A', Type = 'Customer', ParentId = groupAcc.Id);
        insert customer;

        Account brand = new Account(Name = 'Brand A', Type = 'Brand', RETL_Logo_Url__c = 'https://example.com/logo.png');
        insert brand;

        RETL_Brand_Linkage__c linkage = new RETL_Brand_Linkage__c(
            RETL_Customer__c = customer.Id,
            RETL_Brand__c = brand.Id
        );
        insert linkage;

        Test.startTest();
        RETL_ChildAccountsController.BrandResponse result = RETL_ChildAccountsController.getBrandsViaJunction(groupAcc.Id);
        Test.stopTest();

        System.assertEquals(1, result.brandCount, 'Should return one brand');
        System.assertEquals(1, result.brandRecords.size(), 'brandRecords list should have one record');
        System.assertEquals(brand.Id, result.brandRecords[0].Id, 'Returned brand Id should match');
        System.assertEquals('Brand A', result.brandRecords[0].Name, 'Brand name should match');
        System.assertEquals('https://example.com/logo.png', result.brandRecords[0].RETL_Logo_Url__c, 'Logo URL should match');
    }

    @isTest
    static void testGetBrandsViaJunction_NoCustomers() {
        Account groupAcc = new Account(Name = 'Group Without Customers', Type = 'Group');
        insert groupAcc;

        Test.startTest();
        RETL_ChildAccountsController.BrandResponse result = RETL_ChildAccountsController.getBrandsViaJunction(groupAcc.Id);
        Test.stopTest();

        System.assertEquals(0, result.brandCount, 'Should return count 0 if no customers found');
        System.assertEquals(true, result.brandRecords.isEmpty(), 'brandRecords should be empty');
    }

    @isTest
    static void testGetBrandsViaJunction_NoBrands() {
        Account groupAcc = new Account(Name = 'Group Without Brands', Type = 'Group');
        insert groupAcc;

        Account customer = new Account(Name = 'Customer X', Type = 'Customer', ParentId = groupAcc.Id);
        insert customer;

        Test.startTest();
        RETL_ChildAccountsController.BrandResponse result = RETL_ChildAccountsController.getBrandsViaJunction(groupAcc.Id);
        Test.stopTest();

        System.assertEquals(0, result.brandCount, 'Should return count 0 if no brands linked');
        System.assertEquals(true, result.brandRecords.isEmpty(), 'brandRecords should be empty');
    }
}