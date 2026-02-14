public with sharing class RETL_AccountMetricsController {

    private static Set<Id> getAllRelatedAccountIds(Id accountId) {
        Set<Id> allAccountIds = new Set<Id>();
        Set<Id> customerIds = new Set<Id>();
        try {
        for (Account acc : [
            SELECT Id FROM Account WHERE ParentId = :accountId AND Type = 'Customer' WITH USER_MODE
        ]) {
            customerIds.add(acc.Id);
            allAccountIds.add(acc.Id);
        }
        if (!customerIds.isEmpty()) {
            for (Account acc : [
                SELECT Id FROM Account 
                WHERE ParentId IN :customerIds 
                AND Type IN ('Brand', 'Trade License') WITH USER_MODE
            ]) {
                allAccountIds.add(acc.Id);
            }
        }
         } catch (Exception ex) {
            throw new AuraHandledException('Error fetching related accounts: ' + ex.getMessage());
        }
        return allAccountIds;
    }

    @AuraEnabled(cacheable=true)
    public static Integer getActiveOrderCount(Id accountId) {
        try {
        Set<Id> allAccountIds = getAllRelatedAccountIds(accountId);
        return [
            SELECT COUNT() FROM Order WHERE AccountId IN :allAccountIds AND RETL_Status__c IN ('Active', 'Current') WITH USER_MODE
        ];
        } catch (Exception ex) {
            throw new AuraHandledException('Error fetching active order count: ' + ex.getMessage());
        }
    }

    private static Set<Id> getAllChildAccounts(Id groupId) {
        Set<Id> allAccountIds = new Set<Id>();
        try {
        if (!Schema.sObjectType.Account.isAccessible()) {
            return allAccountIds;
        }

        List<Account> customerAccounts = [
            SELECT Id FROM Account WHERE ParentId = :groupId AND Type = 'Customer' WITH USER_MODE
        ];

        Set<Id> customerIds = new Set<Id>();
        for (Account a : customerAccounts) {
            customerIds.add(a.Id);
            allAccountIds.add(a.Id);
        }

        if (!customerIds.isEmpty()) {
            List<Account> brands = [
                SELECT Id FROM Account WHERE ParentId IN :customerIds AND Type = 'Brand' WITH USER_MODE
            ];
            List<Account> licenses = [
                SELECT Id FROM Account WHERE ParentId IN :customerIds AND Type = 'Trade License' WITH USER_MODE
            ];

            for (Account acc : brands) {
                allAccountIds.add(acc.Id);
            }

            for (Account acc : licenses) {
                allAccountIds.add(acc.Id);
            }
        }
          } catch (Exception ex) {
            throw new AuraHandledException('Error fetching child accounts: ' + ex.getMessage());
        }
        return allAccountIds;
    }

    @AuraEnabled(cacheable=true)
    public static Decimal getTotalContractedArea(Id accountId) {
        try {
        Set<Id> allAccountIds = getAllChildAccounts(accountId);
        AggregateResult ar = [
            SELECT SUM(RETL_Contracted_Area__c) totalArea FROM Order WHERE AccountId IN :allAccountIds WITH USER_MODE
        ];
        return (Decimal) ar.get('totalArea');
        } catch (Exception ex) {
            throw new AuraHandledException('Error fetching total contracted area: ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Integer getExpiringLeasesCount(Id groupId) {
        try {
        Set<Id> allAccountIds = getAllChildAccounts(groupId);
        Date startOfMonth = Date.today().toStartOfMonth();
        Date endOfMonth = startOfMonth.addMonths(1).addDays(-1);

        return [
            SELECT COUNT() FROM Order WHERE AccountId IN :allAccountIds AND EndDate >= :startOfMonth AND EndDate <= :endOfMonth WITH USER_MODE
        ];
        } catch (Exception ex) {
            throw new AuraHandledException('Error fetching expiring leases: ' + ex.getMessage());
        }
    }

    public class RevenueMetricsWrapper {
        @AuraEnabled public Decimal monthlySales;
        @AuraEnabled public Decimal annualSales;
        @AuraEnabled public Decimal totalArea;
        @AuraEnabled public Integer expiringLeases;
    }

    @AuraEnabled(cacheable=true)
    public static RevenueMetricsWrapper getRevenueMetrics(Id accountId) {
        Set<Id> allAccountIds = getAllRelatedAccountIds(accountId);
         Try{
        List<Order> orders = [
            SELECT TotalAmount, EffectiveDate,OrderNumber, EndDate, RETL_Contracted_Area__c,RETL_Rent_Per_Month__c,RETL_Rent_per_year__c 
            FROM Order 
            WHERE AccountId IN :allAccountIds AND RETL_Status__c IN ('Active', 'Current') WITH USER_MODE
        ];

        RevenueMetricsWrapper wrapper = new RevenueMetricsWrapper();
        Decimal monthlySales = 0;
        Decimal annualSales = 0;
        Decimal totalArea = 0;
        Integer expiringLeases = 0;

        Date today = Date.today();
        Date startOfMonth = today.toStartOfMonth();
        Date endOfMonth = startOfMonth.addMonths(1).addDays(-1);
        Date startOfYear = Date.newInstance(today.year(), 1, 1);
        Date endOfYear = Date.newInstance(today.year(), 12, 31);

        for (Order o : orders) {
       
    if (o.RETL_Rent_Per_Month__c != null) {
        //if (o.EffectiveDate != null && o.EffectiveDate >= startOfMonth && o.EffectiveDate <= endOfMonth) {
        if ((o.EffectiveDate == null || o.EffectiveDate <= endOfMonth) &&
            (o.EndDate == null || o.EndDate >= startOfMonth)) {

            monthlySales += o.RETL_Rent_Per_Month__c;
        }
    }
       
    if (o.RETL_Rent_per_year__c != null) {
        if ((o.EffectiveDate == null || o.EffectiveDate <= endOfYear) &&
            (o.EndDate == null || o.EndDate >= startOfYear)) {
            annualSales += o.RETL_Rent_per_year__c;
        }
    }

            if (o.RETL_Contracted_Area__c != null) {
                totalArea += o.RETL_Contracted_Area__c;
            }

            if (o.EndDate != null && o.EndDate >= startOfMonth && o.EndDate <= endOfMonth) {
                expiringLeases++;
            }
        }

        wrapper.monthlySales = monthlySales.setScale(2);
        wrapper.annualSales = annualSales.setScale(2);
        wrapper.totalArea = totalArea.setScale(2);
        wrapper.expiringLeases = expiringLeases;
        
        return wrapper;
        } catch (Exception ex) {
            throw new AuraHandledException('Error fetching getRevenueMetrics  ' + ex.getMessage());
        }
    }

        @AuraEnabled(cacheable=true)
    public static List<Order> getAllLeasesUnderGroup(Id groupId) {
         try {
        Set<Id> allAccountIds = getAllRelatedAccountIds(groupId);
        return [
            SELECT Id, OrderNumber,RETL_Name__c, EffectiveDate, EndDate, TotalAmount, RETL_Status__c, AccountId, Account.Name,RETL_Rent_Per_Month__c,RETL_Rent_per_year__c
            FROM Order
            WHERE AccountId IN :allAccountIds 
            WITH USER_MODE
            ORDER BY EffectiveDate DESC 
        ];
        } catch (Exception ex) {
            throw new AuraHandledException('Error fetching leases under group: ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Order> getOrderNames(Id accountId) {
        try {
        Set<Id> allAccountIds = getAllRelatedAccountIds(accountId);
        return [
            SELECT Id,OrderNumber, RETL_Name__c, EffectiveDate, EndDate, TotalAmount, RETL_Rent_Per_Month__c
            FROM Order 
            WHERE AccountId IN :allAccountIds AND RETL_Status__c IN ('Activated', 'Current') 
            WITH USER_MODE
        ];
                } catch (Exception ex) {
            throw new AuraHandledException('Error fetching record names ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Integer getActiveCaseCount(Id accountId) {
        try {
        return [
            SELECT COUNT() FROM Case WHERE AccountId = :accountId AND Status = 'Active' WITH USER_MODE
        ];
         } catch (Exception ex) {
            throw new AuraHandledException('Error fetching case count ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Case> getActiveCaseSubjects(Id accountId) {
        try{
        return [
            SELECT Id, CaseNumber, Status, CustomerType__c,RETL_SR_Order__r.Name,RETL_SR_Category__c
            FROM Case 
            WHERE AccountId = :accountId AND Status = 'Active' 
            WITH USER_MODE
        ];
         } catch (Exception ex) {
            throw new AuraHandledException('Error fetching Case record' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Integer getCustomerAccountCount(Id accountId) {
        try{
        return [
            SELECT COUNT() 
            FROM Account 
            WHERE ParentId = :accountId AND Type = 'Customer' 
            WITH USER_MODE
        ];
         } catch (Exception ex) {
            throw new AuraHandledException('Error fetching  Customer record names ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Account> getCustomerAccounts(Id accountId) {
        try{
        return [
            SELECT Id, Name, RETL_Status__c, AccountNumber 
            FROM Account 
            WHERE ParentId = :accountId AND Type = 'Customer' 
            WITH USER_MODE
        ];
         } catch (Exception ex) {
            throw new AuraHandledException('Error fetching getCustomerAccounts ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Account> getBrandAccounts(Id accountId) {
        try{
        List<Account> customerAccounts = [
            SELECT Id FROM Account WHERE ParentId = :accountId AND Type = 'Customer' WITH USER_MODE
        ];
        if (customerAccounts.isEmpty()) return new List<Account>();

        List<Id> customerIds = new List<Id>();
        for (Account acc : customerAccounts) customerIds.add(acc.Id);

        return [
            SELECT Id, Name, RETL_Status__c, AccountNumber, RETL_Logo_Url__c 
            FROM Account 
            WHERE Id IN (SELECT RETL_Brand__c FROM RETL_Brand_Linkage__c WHERE RETL_Customer__c IN :customerIds)
            WITH USER_MODE
        ];
        } catch (Exception ex) {
            throw new AuraHandledException('Error fetching getBrandAccounts ' + ex.getMessage());
        }
    }

    public class BrandWrapper {
        @AuraEnabled public Integer brandCount;
        @AuraEnabled public List<Account> brandRecords;
    }

    @AuraEnabled(cacheable=true)
    public static BrandWrapper getBrandData(Id accountId) {
        BrandWrapper wrapper = new BrandWrapper();
        try{
        List<Account> customerAccounts = [
            SELECT Id FROM Account WHERE ParentId = :accountId AND Type = 'Customer' WITH USER_MODE
        ];
        if (customerAccounts.isEmpty()) {
            wrapper.brandCount = 0;
            wrapper.brandRecords = new List<Account>();
            return wrapper;
        }

        List<Id> customerIds = new List<Id>();
        for (Account acc : customerAccounts) customerIds.add(acc.Id);

        List<Account> brandAccounts = [
            SELECT Id, Name, RETL_Status__c, AccountNumber, RETL_Logo_Url__c 
            FROM Account 
            WHERE ParentId IN :customerIds AND Type = 'Brand' 
            WITH USER_MODE
        ];

        wrapper.brandCount = brandAccounts.size();
        wrapper.brandRecords = brandAccounts;
        return wrapper;
        } catch (Exception ex) {
            throw new AuraHandledException('Error fetching getCustomerAccounts ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Integer> getRelatedCounts(Id accountId) {
        try{
        Map<String, Integer> result = new Map<String, Integer>();
        result.put('customerCount', [
            SELECT COUNT() FROM Account WHERE ParentId = :accountId AND Type = 'Customer' WITH USER_MODE
        ]);
        result.put('brandCount', [
            SELECT COUNT() FROM Account WHERE ParentId = :accountId AND Type = 'Brand' WITH USER_MODE
        ]);
        result.put('contactCount', [
            SELECT COUNT() FROM Contact WHERE AccountId = :accountId WITH USER_MODE
        ]);
        result.put('caseCount', [
            SELECT COUNT() FROM Case WHERE AccountId = :accountId WITH USER_MODE
        ]);
        return result;
        } catch (Exception ex) {
            throw new AuraHandledException('Error fetching getRelatedCounts ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Order> getOrderName(Id accountId) {
        try{
        return [
            SELECT Id, RETL_Name__c, EffectiveDate, EndDate, TotalAmount 
            FROM Order 
            WHERE AccountId = :accountId 
            WITH USER_MODE
        ];
         } catch (Exception ex) {
            throw new AuraHandledException('Error fetching Order Names ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Integer getOrderCount(Id accountId) {
        try{
        return [
            SELECT COUNT() FROM Order WHERE AccountId = :accountId WITH USER_MODE
        ];
         } catch (Exception ex) {
            throw new AuraHandledException('Error fetching Order Count ' + ex.getMessage());
        }
    }
  

  //Customer
    @AuraEnabled(cacheable=true)
    public static List<Order> getActiveLeases(Id accountId) {
        try{
        return [
            SELECT Id, RETL_Name__c 
            FROM Order 
            WHERE AccountId = :accountId AND RETL_Status__c IN ('Active', 'Current') 
            WITH USER_MODE
        ];
         } catch (Exception ex) {
            throw new AuraHandledException('Error fetching get Active leases' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Account> getChildCustomers(Id accountId) {
        try{
        return [
            SELECT Id, Name 
            FROM Account 
            WHERE ParentId = :accountId AND Type = 'Customer' 
            WITH USER_MODE
            ORDER BY Name           
        ];
         } catch (Exception ex) {
            throw new AuraHandledException('Error fetching get child customers ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Account> getChildBrands(Id accountId) {
        try{
        return [
            SELECT Id, Name 
            FROM Account 
            WHERE ParentId = :accountId AND RecordType.Name = 'Brand Account' 
            WITH USER_MODE
        ];
         } catch (Exception ex) {
            throw new AuraHandledException('Error fetching child brands ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Case> getAccountCases(Id accountId) {
        try{
        return [
            SELECT Id, CaseNumber, Status, CustomerType__c, RETL_SR_Order__r.Name,RETL_SR_Category__c
            FROM Case 
            WHERE AccountId = :accountId 
            WITH USER_MODE
        ];
         } catch (Exception ex) {
            throw new AuraHandledException('Error fetching Account Cases ' + ex.getMessage());
        }
    }

    // Customers

        @AuraEnabled(cacheable=true)
    public static Map<String, Integer> getCustomerMetrics(Id accountId) {
        try{
        Map<String, Integer> result = new Map<String, Integer>();

        Integer leaseCount = [
            SELECT COUNT() 
            FROM Order 
            WHERE AccountId = :accountId AND RETL_Status__c IN ('Active', 'Current') 
            WITH USER_MODE
        ];
        result.put('activeLeases', leaseCount);

        Integer brandCount = [
            SELECT COUNT() 
            FROM RETL_Brand_Linkage__c 
            WHERE RETL_Customer__c = :accountId 
            WITH USER_MODE
        ];
        result.put('linkedBrands', brandCount);
        return result;
         } catch (Exception ex) {
            throw new AuraHandledException('Error fetching Customer metrix ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Decimal> getOrderRevenueByCustomer(Id accountId) {
        Decimal monthlyRevenue = 0;
        Decimal annualRevenue = 0;
        Decimal totalArea = 0;
        Integer expiringLeases = 0;
        try{
        List<Order> orders = [
            SELECT Id, EffectiveDate,OrderNumber, EndDate, TotalAmount, RETL_Contracted_Area__c,RETL_Rent_Per_Month__c,RETL_Rent_per_year__c
            FROM Order
            WHERE AccountId = :accountId 
            WITH USER_MODE
        ];

        Date today = Date.today();
        Date startOfMonth = today.toStartOfMonth();
        Date endOfMonth = startOfMonth.addMonths(1).addDays(-1);
         Date startOfYear = Date.newInstance(today.year(), 1, 1);
        Date endOfYear = Date.newInstance(today.year(), 12, 31);

        for (Order o : orders) {
       
    if (o.RETL_Rent_Per_Month__c != null) {
        //if (o.EffectiveDate != null && o.EffectiveDate >= startOfMonth && o.EffectiveDate <= endOfMonth) {
            
            if ((o.EffectiveDate == null || o.EffectiveDate <= endOfMonth) &&
            (o.EndDate == null || o.EndDate >= startOfMonth)) {
            monthlyRevenue += o.RETL_Rent_Per_Month__c;
        }
    }
       
    if (o.RETL_Rent_per_year__c != null) {
        if ((o.EffectiveDate == null || o.EffectiveDate <= endOfYear) &&
            (o.EndDate == null || o.EndDate >= startOfYear)) {
            annualRevenue += o.RETL_Rent_per_year__c;
        }
    }

            if (o.RETL_Contracted_Area__c != null) {
                totalArea += o.RETL_Contracted_Area__c;
            }

            if (o.EndDate != null && o.EndDate >= startOfMonth && o.EndDate <= endOfMonth) {
                expiringLeases++;
            }
        }

        return new Map<String, Decimal>{
            'monthlyRevenue' => monthlyRevenue.setScale(2),
            'annualRevenue' => annualRevenue.setScale(2),
            'totalArea' => totalArea.setScale(2),
            'expiringLeases' => Decimal.valueOf(expiringLeases)
        };
         } catch (Exception ex) {
            throw new AuraHandledException('Error fetching Revenue ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Integer> getCustomerExtras(Id accountId) {
        Map<String, Integer> result = new Map<String, Integer>();
        try{
        result.put('linkedBrands', [
            SELECT COUNT() FROM RETL_Brand_Linkage__c WHERE RETL_Customer__c = :accountId WITH USER_MODE
        ]);
        result.put('tradeLicenseAccounts', [
            SELECT COUNT() FROM Account WHERE ParentId = :accountId AND Type = 'Trade License' WITH USER_MODE
        ]);
        return result;
         } catch (Exception ex) {
            throw new AuraHandledException('Error fetching Customer extras ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Order> getActiveLeaseRecords(Id accountId) {
        try{
        return [
            SELECT Id, OrderNumber, EffectiveDate, EndDate, TotalAmount, RETL_Rent_Per_Month__c,RETL_Rent_Per_Year__c
            FROM Order 
            WHERE AccountId = :accountId AND RETL_Status__c IN ('Active', 'Current') 
            WITH USER_MODE
        ];
         } catch (Exception ex) {
            throw new AuraHandledException('Error fetching getRelatedCounts ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<RETL_Brand_Linkage__c> getLinkedBrands(Id accountId) {
        try{
        return [
            SELECT Id, Name, RETL_Customer__c, RETL_Customer__r.Name, RETL_Brand__c, RETL_Brand__r.Name, RETL_Brand__r.AccountNumber,RETL_Brand__r.RETL_Logo_Url__c
            FROM RETL_Brand_Linkage__c 
            WHERE RETL_Customer__c = :accountId 
            WITH USER_MODE
        ];
         } catch (Exception ex) {
            throw new AuraHandledException('Error fetching linked brands ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Account> getTradeLicenses(Id accountId) {
        try{
        return [
            SELECT Id, Name, RETL_Status__c, AccountNumber 
            FROM Account 
            WHERE ParentId = :accountId AND Type = 'Trade License' 
            WITH USER_MODE
        ];
         } catch (Exception ex) {
            throw new AuraHandledException('Error fetching trade license ' + ex.getMessage());
        }
    }

    // ---------------------- BRAND COMPONENT METHODS -------------------------

    @AuraEnabled(cacheable=true)
    public static List<Order> getOrdersForBrand(Id brandId) {
        try{
        return [
            SELECT Id, RETL_Name__c,OrderNumber,RETL_Rent_Per_Month__c, EffectiveDate, EndDate
            FROM Order 
            WHERE RETL_Brand__c = :brandId AND RETL_Status__c IN ('Active', 'Current')
            WITH USER_MODE
        ];
         } catch (Exception ex) {
            throw new AuraHandledException('Error fetching getOrdersForBrand ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<RETL_Brand_Linkage__c> getLicensesForBrand(Id brandId) {
        try{
        return [
            SELECT Id, Name, RETL_Brand__c, RETL_Brand__r.Name, RETL_Customer__c, RETL_Customer__r.Name,RETL_Brand__r.AccountNumber
            FROM RETL_Brand_Linkage__c 
            WHERE RETL_Brand__c = :brandId 
            WITH USER_MODE
        ];
        } catch (Exception ex) {
            throw new AuraHandledException('Error fetching getLicensesForBrand ' + ex.getMessage());
        }
        
    }

    @AuraEnabled(cacheable=true)
    public static Integer getOrderCountForBrand(Id brandId) {
        try{
        return [
            SELECT COUNT() 
            FROM Order 
            WHERE RETL_Brand__c = :brandId AND RETL_Status__c IN ('Active', 'Current')
            WITH USER_MODE
        ];
          } catch (Exception ex) {
            throw new AuraHandledException('Error fetching getOrderCountForBrand ' + ex.getMessage());
        }
        
    }

    @AuraEnabled(cacheable=true)
    public static Integer getLicenseCountForBrand(Id brandId) {
        try{
        return [
            SELECT COUNT() 
            FROM RETL_Brand_Linkage__c 
            WHERE RETL_Brand__c = :brandId 
            WITH USER_MODE
        ];
        } catch (Exception ex) {
            throw new AuraHandledException('Error fetching getLicenseCountForBrand ' + ex.getMessage());
        }

    }

 @AuraEnabled(cacheable=true)
public static String getBrandName(Id brandId) {
    try{
    List<Account> accList = [
        SELECT Name 
        FROM Account 
        WHERE Type = 'Brand' AND Id = :brandId 
        WITH USER_MODE 
        LIMIT 1
    ];
    if (!accList.isEmpty()) {
        return accList[0].Name;
    }
    return null;
     } catch (Exception ex) {
            throw new AuraHandledException('Error fetching getBrandName ' + ex.getMessage());
        }
    
}

}