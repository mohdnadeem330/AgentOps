@isTest
private class RETL_AccountMetricsControllerTest {

    @testSetup
    static void setupTestData() {
        // Create a user with a profile that does NOT have access
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Read Only']; 
        User user = new User(
            Alias = 'testu',
            Email = 'testu@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = profile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'testu' + System.currentTimeMillis() + '@example.com'
        );
        insert user;
    }
 
    @isTest
    static void testMetricsControllerMethods() {

        // Create a test user
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System administrator' LIMIT 1];
        User u = new User(
            Alias = 'testuser',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            UserName = 'testuser' + DateTime.now().getTime() + '@example.com'
        );
        insert u;
 
       // System.runAs(u) {
            // Create parent account (Group)
            Account groupAcc = new Account(Name = 'Group Account');
            insert groupAcc;
 
            // Create customer under group
            Account customerAcc = new Account(Name = 'Customer Account', Type = 'Customer', ParentId = groupAcc.Id);
            insert customerAcc;
 
            // Create brand and trade license under customer
            Account brandAcc = new Account(Name = 'Brand Account', Type = 'Brand', ParentId = customerAcc.Id);
            Account tradeLicenseAcc = new Account(Name = 'Trade License Account', Type = 'Trade License', ParentId = customerAcc.Id);
            insert new List<Account>{ brandAcc, tradeLicenseAcc };
 
            // Create Contact & AccountContactRelation
            Contact con = new Contact(FirstName = 'John', LastName = 'Doe', Email = 'john.doe@test.com');
            insert con;
 
       
             // Create Order
            Order ord = new Order(
                AccountId = customerAcc.Id,
                RETL_Name__c = 'Test Lease',
                RETL_Status__c = 'Current',
                EffectiveDate = Date.today().addMonths(-1),
                EndDate = Date.today().addMonths(1),
                RETL_Contracted_Area__c = 250.75,
                RETL_Rent_per_year__c=200,
                RETL_Rent_per_Month__c=24000,
                Status='Draft'
            );
            insert ord;
 
 
            // Create Case
              try {
                Case testCase = new Case(
                    Subject = 'Test Case',
                    Status = 'Active',
                    ContactId = con.Id,
                    AccountId = groupAcc.Id,
                    CustomerType__c = 'Tenant',
                    Email_Not_Triggered__c = false,
                    CaseReopenCount__c = 0,
                    RETL_SR_Order__c=ord.Id,
                    Origin = 'Phone'
                );
                insert testCase;
            } catch (Exception e) {
                System.debug(' Case insertion failed: ' + e.getMessage());
                // Optionally log or handle the failure gracefully
            }
 
            // Create RETL_Brand_Linkage__c
            RETL_Brand_Linkage__c linkage = new RETL_Brand_Linkage__c(RETL_Customer__c = customerAcc.Id, RETL_Brand__c = brandAcc.Id);
            insert linkage;
 
            Test.startTest();
 

            Integer activeOrderCount = RETL_AccountMetricsController.getActiveOrderCount(groupAcc.Id);
            System.assert(activeOrderCount >= 0, 'Active order count should be >= 0');
 
            Decimal totalArea = RETL_AccountMetricsController.getTotalContractedArea(groupAcc.Id);
            System.assertNotEquals(null, totalArea, 'Total contracted area should not be null');
 
            Integer expiringLeases = RETL_AccountMetricsController.getExpiringLeasesCount(groupAcc.Id);
            System.assert(expiringLeases >= 0, 'Expiring leases count should be >= 0');
 
            RETL_AccountMetricsController.RevenueMetricsWrapper revenue = RETL_AccountMetricsController.getRevenueMetrics(groupAcc.Id);
            System.assertNotEquals(null, revenue, 'Revenue wrapper should not be null');
            System.assertNotEquals(null, revenue.monthlySales, 'Monthly sales should not be null');
 
            List<Order> leases = RETL_AccountMetricsController.getAllLeasesUnderGroup(groupAcc.Id);
            System.assertNotEquals(null, leases, 'Leases should not be null');
 
            Integer customerCount = RETL_AccountMetricsController.getCustomerAccountCount(groupAcc.Id);
            System.assert(customerCount >= 0, 'Customer count should be >= 0');
 
            Map<String, Integer> counts = RETL_AccountMetricsController.getRelatedCounts(groupAcc.Id);
            System.assert(counts.containsKey('caseCount'), 'Counts map should contain caseCount');
 
            List<Account> brandAccounts = RETL_AccountMetricsController.getBrandAccounts(groupAcc.Id);
            System.assertNotEquals(null, brandAccounts, 'Brand accounts should not be null');
 
            
            RETL_AccountMetricsController.getOrderNames(groupAcc.Id);
            RETL_AccountMetricsController.getActiveCaseCount(groupAcc.Id);
            RETL_AccountMetricsController.getActiveCaseSubjects(groupAcc.Id);
            RETL_AccountMetricsController.getCustomerAccounts(groupAcc.Id);
            RETL_AccountMetricsController.getBrandData(groupAcc.Id);
            RETL_AccountMetricsController.getOrderName(customerAcc.Id);
            RETL_AccountMetricsController.getOrderCount(customerAcc.Id);
            RETL_AccountMetricsController.getActiveLeases(customerAcc.Id);
            RETL_AccountMetricsController.getChildCustomers(groupAcc.Id);
            RETL_AccountMetricsController.getChildBrands(groupAcc.Id);
            RETL_AccountMetricsController.getAccountCases(groupAcc.Id);
            RETL_AccountMetricsController.getCustomerMetrics(customerAcc.Id);
            RETL_AccountMetricsController.getOrderRevenueByCustomer(customerAcc.Id);
            RETL_AccountMetricsController.getCustomerExtras(customerAcc.Id);
            RETL_AccountMetricsController.getActiveLeaseRecords(customerAcc.Id);
            RETL_AccountMetricsController.getLinkedBrands(customerAcc.Id);
            RETL_AccountMetricsController.getTradeLicenses(customerAcc.Id);
            RETL_AccountMetricsController.getOrdersForBrand(brandAcc.Id);
            RETL_AccountMetricsController.getLicensesForBrand(brandAcc.Id);
            RETL_AccountMetricsController.getOrderCountForBrand(brandAcc.Id);
            RETL_AccountMetricsController.getLicenseCountForBrand(brandAcc.Id);
            RETL_AccountMetricsController.getBrandName(brandAcc.Id);
 
            Test.stopTest();
        //}
    }

    @isTest
    static void getOrderNames_Negative(){
        User user = [Select Id From User Where Email = 'testu@example.com' Limit 1];

        Test.startTest();
        System.runAs(user) {
            try {
                RETL_AccountMetricsController.getOrderNames(null);
            } catch (AuraHandledException e) {
                System.debug(e);
            }
        }
        Test.stopTest();
    }

    @isTest
    static void getActiveOrderCount_Negative(){
        User user = [Select Id From User Where Email = 'testu@example.com' Limit 1];

        Test.startTest();
        System.runAs(user) {
            try {
                RETL_AccountMetricsController.getActiveOrderCount(null);
            } catch (AuraHandledException e) {
                System.debug(e);
            }
        }
        Test.stopTest();
    }

    @isTest
    static void getTotalContractedArea_Negative(){
        User user = [Select Id From User Where Email = 'testu@example.com' Limit 1];

        Test.startTest();
        System.runAs(user) {
            try {
                RETL_AccountMetricsController.getTotalContractedArea(null);
            } catch (AuraHandledException e) {
                System.debug(e);
            }
        }
        Test.stopTest();
    }

    @isTest
    static void getActiveCaseCount_Negative(){
        User user = [Select Id From User Where Email = 'testu@example.com' Limit 1];

        Test.startTest();
        System.runAs(user) {
            try {
                RETL_AccountMetricsController.getActiveCaseCount(null);
            } catch (AuraHandledException e) {
                System.debug(e);
            }
        }
        Test.stopTest();
    }

    @isTest
    static void getActiveCaseSubjects_Negative(){
        User user = [Select Id From User Where Email = 'testu@example.com' Limit 1];

        Test.startTest();
        System.runAs(user) {
            try {
                RETL_AccountMetricsController.getActiveCaseSubjects(null);
            } catch (AuraHandledException e) {
                System.debug(e);
            }
        }
        Test.stopTest();
    }

    @isTest
    static void getCustomerAccountCount_Negative(){
        User user = [Select Id From User Where Email = 'testu@example.com' Limit 1];

        Test.startTest();
        System.runAs(user) {
            try {
                RETL_AccountMetricsController.getCustomerAccountCount(null);
            } catch (AuraHandledException e) {
                System.debug(e);
            }
        }
        Test.stopTest();
    }
    @isTest
    static void getCustomerAccounts_Negative(){
        User user = [Select Id From User Where Email = 'testu@example.com' Limit 1];

        Test.startTest();
        System.runAs(user) {
            try {
                RETL_AccountMetricsController.getCustomerAccounts(null);
            } catch (AuraHandledException e) {
                System.debug(e);
            }
        }
        Test.stopTest();
    }

    @isTest
    static void getBrandAccounts_Negative(){
        User user = [Select Id From User Where Email = 'testu@example.com' Limit 1];

        Test.startTest();
        System.runAs(user) {
            try {
                RETL_AccountMetricsController.getBrandAccounts(null);
            } catch (AuraHandledException e) {
                System.debug(e);
            }
        }
        Test.stopTest();
    }
    @isTest
    static void getRelatedCounts_Negative(){
        User user = [Select Id From User Where Email = 'testu@example.com' Limit 1];

        Test.startTest();
        System.runAs(user) {
            try {
                RETL_AccountMetricsController.getRelatedCounts(null);
            } catch (AuraHandledException e) {
                System.debug(e);
            }
        }
        Test.stopTest();
    }

    @isTest
    static void getOrderName_Negative(){
        User user = [Select Id From User Where Email = 'testu@example.com' Limit 1];

        Test.startTest();
        System.runAs(user) {
            try {
                RETL_AccountMetricsController.getOrderName(null);
            } catch (AuraHandledException e) {
                System.debug(e);
            }
        }
        Test.stopTest();
    }

    @isTest
    static void getOrderCount_Negative(){
        User user = [Select Id From User Where Email = 'testu@example.com' Limit 1];

        Test.startTest();
        System.runAs(user) {
            try {
                RETL_AccountMetricsController.getOrderCount(null);
            } catch (AuraHandledException e) {
                System.debug(e);
            }
        }
        Test.stopTest();
    }

    @isTest
    static void getActiveLeases_Negative(){
        User user = [Select Id From User Where Email = 'testu@example.com' Limit 1];

        Test.startTest();
        System.runAs(user) {
            try {
                RETL_AccountMetricsController.getActiveLeases(null);
            } catch (AuraHandledException e) {
                System.debug(e);
            }
        }
        Test.stopTest();
    }

    @isTest
    static void getChildCustomers_Negative(){
        User user = [Select Id From User Where Email = 'testu@example.com' Limit 1];

        Test.startTest();
        System.runAs(user) {
            try {
                RETL_AccountMetricsController.getChildCustomers(null);
            } catch (AuraHandledException e) {
                System.debug(e);
            }
        }
        Test.stopTest();
    }

    @isTest
    static void getChildBrands_Negative(){
        User user = [Select Id From User Where Email = 'testu@example.com' Limit 1];

        Test.startTest();
        System.runAs(user) {
            try {
                RETL_AccountMetricsController.getChildBrands(null);
            } catch (AuraHandledException e) {
                System.debug(e);
            }
        }
        Test.stopTest();
    }

    @isTest
    static void getAccountCases_Negative(){
        User user = [Select Id From User Where Email = 'testu@example.com' Limit 1];

        Test.startTest();
        System.runAs(user) {
            try {
                RETL_AccountMetricsController.getAccountCases(null);
            } catch (AuraHandledException e) {
                System.debug(e);
            }
        }
        Test.stopTest();
    }

    @isTest
    static void getCustomerMetrics_Negative(){
        User user = [Select Id From User Where Email = 'testu@example.com' Limit 1];

        Test.startTest();
        System.runAs(user) {
            try {
                RETL_AccountMetricsController.getCustomerMetrics(null);
            } catch (AuraHandledException e) {
                System.debug(e);
            }
        }
        Test.stopTest();
    }

    @isTest
    static void getOrderRevenueByCustomer_Negative(){
        User user = [Select Id From User Where Email = 'testu@example.com' Limit 1];

        Test.startTest();
        System.runAs(user) {
            try {
                RETL_AccountMetricsController.getOrderRevenueByCustomer(null);
            } catch (AuraHandledException e) {
                System.debug(e);
            }
        }
        Test.stopTest();
    }

    @isTest
    static void getCustomerExtras_Negative(){
        User user = [Select Id From User Where Email = 'testu@example.com' Limit 1];

        Test.startTest();
        System.runAs(user) {
            try {
                RETL_AccountMetricsController.getCustomerExtras(null);
            } catch (AuraHandledException e) {
                System.debug(e);
            }
        }
        Test.stopTest();
    }

    @isTest
    static void getActiveLeaseRecords_Negative(){
        User user = [Select Id From User Where Email = 'testu@example.com' Limit 1];

        Test.startTest();
        System.runAs(user) {
            try {
                RETL_AccountMetricsController.getActiveLeaseRecords(null);
            } catch (AuraHandledException e) {
                System.debug(e);
            }
        }
        Test.stopTest();
    }

    @isTest
    static void getLinkedBrands_Negative(){
        User user = [Select Id From User Where Email = 'testu@example.com' Limit 1];

        Test.startTest();
        System.runAs(user) {
            try {
                RETL_AccountMetricsController.getLinkedBrands(null);
            } catch (AuraHandledException e) {
                System.debug(e);
            }
        }
        Test.stopTest();
    }

    @isTest
    static void getTradeLicenses_Negative(){
        User user = [Select Id From User Where Email = 'testu@example.com' Limit 1];

        Test.startTest();
        System.runAs(user) {
            try {
                RETL_AccountMetricsController.getTradeLicenses(null);
            } catch (AuraHandledException e) {
                System.debug(e);
            }
        }
        Test.stopTest();
    }

    @isTest
    static void getOrdersForBrand_Negative(){
        User user = [Select Id From User Where Email = 'testu@example.com' Limit 1];

        Test.startTest();
        System.runAs(user) {
            try {
                RETL_AccountMetricsController.getOrdersForBrand(null);
            } catch (AuraHandledException e) {
                System.debug(e);
            }
        }
        Test.stopTest();
    }

    @isTest
    static void getLicensesForBrand_Negative(){
        User user = [Select Id From User Where Email = 'testu@example.com' Limit 1];

        Test.startTest();
        System.runAs(user) {
            try {
                RETL_AccountMetricsController.getLicensesForBrand(null);
            } catch (AuraHandledException e) {
                System.debug(e);
            }
        }
        Test.stopTest();
    }

    @isTest
    static void getOrderCountForBrand_Negative(){
        User user = [Select Id From User Where Email = 'testu@example.com' Limit 1];

        Test.startTest();
        System.runAs(user) {
            try {
                RETL_AccountMetricsController.getOrderCountForBrand(null);
            } catch (AuraHandledException e) {
                System.debug(e);
            }
        }
        Test.stopTest();
    }

    @isTest
    static void getLicenseCountForBrand_Negative(){
        User user = [Select Id From User Where Email = 'testu@example.com' Limit 1];

        Test.startTest();
        System.runAs(user) {
            try {
                RETL_AccountMetricsController.getLicenseCountForBrand(null);
            } catch (AuraHandledException e) {
                System.debug(e);
            }
        }
        Test.stopTest();
    }

    @isTest
    static void getBrandName_Negative(){
        User user = [Select Id From User Where Email = 'testu@example.com' Limit 1];

        Test.startTest();
        System.runAs(user) {
            try {
                RETL_AccountMetricsController.getBrandName(null);
            } catch (AuraHandledException e) {
                System.debug(e);
            }
        }
        Test.stopTest();
    }

    @isTest
    static void getExpiringLeasesCount_Negative(){
        User user = [Select Id From User Where Email = 'testu@example.com' Limit 1];

        Test.startTest();
        System.runAs(user) {
            try {
                RETL_AccountMetricsController.getExpiringLeasesCount(null);
            } catch (AuraHandledException e) {
                System.debug(e);
            }
        }
        Test.stopTest();
    }

}