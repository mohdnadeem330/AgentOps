public with sharing class RETL_ChildAccountsController {

    public class BrandResponse {
        @AuraEnabled public Integer brandCount;
        @AuraEnabled public List<Account> brandRecords;
    }

    @AuraEnabled(cacheable=true)
    public static BrandResponse getBrandsViaJunction(Id groupId) {
        BrandResponse resp = new BrandResponse();

        try {
            if (groupId == null) return resp;

            List<Account> customers = [
                SELECT Id
                FROM Account
                WHERE ParentId = :groupId AND Type = 'Customer'
            ];

            if (customers.isEmpty()) {
                resp.brandCount = 0;
                resp.brandRecords = new List<Account>();
                return resp;
            }

            Set<Id> customerIds = new Set<Id>();
            for (Account acc : customers) customerIds.add(acc.Id);

            Set<Id> brandIds = new Set<Id>();
            for (RETL_Brand_Linkage__c linkage : [
                SELECT RETL_Brand__c, RETL_Customer__c
                FROM RETL_Brand_Linkage__c
                WHERE RETL_Customer__c IN :customerIds
                AND RETL_Brand__c != null
            ]) {
                brandIds.add(linkage.RETL_Brand__c);
            }

            if (brandIds.isEmpty()) {
                resp.brandCount = 0;
                resp.brandRecords = new List<Account>();
                return resp;
            }

            List<Account> brands = [
                SELECT Id, Name, AccountNumber, Type, Parent.Name, RETL_Status__c, RETL_Logo_Url__c
                FROM Account
                WHERE Id IN :brandIds
            ];

            resp.brandCount = brands.size();
            resp.brandRecords = brands;
            return resp;

        } catch (Exception ex) {
            // Optional: log to a custom object for admin visibility
            System.debug('Error in getBrandsViaJunction: ' + ex.getMessage());
            throw new AuraHandledException('Unable to fetch brand data. Please contact your administrator.');
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Account> getFilteredChildAccounts(Id parentId, String typeValue) {
        if (!Schema.sObjectType.Account.isAccessible()) {
            throw new AuraHandledException('Insufficient access to Account records.');
        }

        try {
            return [
                SELECT Id, Name, AccountNumber,AccountNumber__C, Type, CurrencyIsoCode, ParentId
                FROM Account
                WHERE ParentId = :parentId
                AND Type = :typeValue
                ORDER BY Name
            ];
        } catch (Exception ex) {
            System.debug('Error in getFilteredChildAccounts: ' + ex.getMessage());
            throw new AuraHandledException('Unable to fetch child accounts. Please contact your administrator.');
        }
    }
}