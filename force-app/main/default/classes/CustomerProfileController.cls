public with sharing class CustomerProfileController {

    @AuraEnabled(cacheable=true)
    public static List<InstallmentLines__c> getInstallmentLines(Id salesOrderId) {
        return [
            SELECT InstallmentDate__c, convertCurrency(AmountReceived__c), convertCurrency(OutstandingAmount__c) 
            FROM InstallmentLines__c 
            WHERE SalesOrder__c = :salesOrderId 
            ORDER BY InstallmentDate__c
        ];
    }

    public class AccountSalesOrderWrapper {

        @AuraEnabled
        public Account account { get; set; }

        @AuraEnabled
        public List<SalesOrder__c> salesOrders { get; set; }

        @AuraEnabled
        public List<InstallmentLines__c> installmentLines { get; set; }

        @AuraEnabled
        public Integer holdFlagCount;

        @AuraEnabled
        public String currencyIsoCode;

        @AuraEnabled
        public List<HexaBPM__Service_Request__c> serviceRequests { get; set; }

        public AccountSalesOrderWrapper(Account acc, List<SalesOrder__c> sOrders, List<InstallmentLines__c> instLines, Integer flagCount, String currencyIsoCode, List<HexaBPM__Service_Request__c> serviceRequests) {
            this.account = acc;
            this.salesOrders = sOrders;
            this.installmentLines = instLines;
            this.holdFlagCount = flagCount;
            this.currencyIsoCode = currencyIsoCode;
            this.serviceRequests = serviceRequests;
        }
    }

    @AuraEnabled(cacheable=true)
    public static AccountSalesOrderWrapper getAccountSalesOrderData(Id accountId) {
        try {
/*          Account accountRec = [
            SELECT Id, Name, AccountNumber__c, Blacklisted__c, Risk_Score__c, CustomerSubType__c, Nationality__pc, 
                   Gender__pc, EmploymentStatus__pc, AnnualIncome__pc, PersonBirthdate, CountryOfResidence__pc, 
                   (SELECT Id, Name, ProjectName__c, AgentType__c, TotalInstallmentNo__c, BookingDate__c, TotalBilled__c, 
                   Unit__c, Unit__r.Name, UnitType__c, HoldFlag__c, SellingPrice__c, TotalInstallmentReceived__c, TotalOutstanding__c, 
                   (SELECT Id, InstallmentDate__c, AmountReceived__c, OutstandingAmount__c FROM InstallmentLines__r) 
                   FROM Opportunity_Units__r WHERE Status__c = 'Sold')
             FROM Account
             WHERE Id = :accountId
             LIMIT 1
            ]; */
            Account accountRec = [
            SELECT Id, Name, AccountNumber__c, Blacklisted__c, Risk_Score__c, CustomerSubType__c, Nationality__pc, 
                   Gender__pc, EmploymentStatus__pc, AnnualIncome__pc, CurrencyIsoCode, PersonBirthdate, CountryOfResidence__pc, 
                   (SELECT Id, Name, ProjectName__c, AgentType__c, TotalInstallmentNo__c, BookingDate__c, NetAmount__c, Status__c, 
                   convertCurrency(TotalBilled__c), Unit__c, Unit__r.Name, UnitType__c, HoldFlag__c, 
                   convertCurrency(SellingPrice__c), convertCurrency(TotalInstallmentReceived__c), 
                   convertCurrency(TotalOutstanding__c), (SELECT Id, InstallmentDate__c, convertCurrency(InstallmentAmount__c), convertCurrency(AmountReceived__c), 
                   convertCurrency(InvoicedAmount__c), convertCurrency(OutstandingAmount__c) FROM InstallmentLines__r) FROM Opportunity_Units__r WHERE 
                   Status__c != :Constants.SO_STATUS_CANCELLED AND Status__c != :Constants.SO_STATUS_CANCELLED_BY_USER),

                   (SELECT Id, convertCurrency(TransferSellingPrice__c) FROM HexaBPM__Service_Requests__r WHERE SRType__c = 'Property Transfer' 
                   AND HexaBPM__External_SR_Status__r.Name = 'Closed')
            FROM Account
            WHERE Id = :accountId
            LIMIT 1
            ];
            User usr = [SELECT Id, DefaultCurrencyIsoCode FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];            
            List<InstallmentLines__c> allInstallmentLines = new List<InstallmentLines__c>();
            Integer holdFlagCount = 0;

            for (SalesOrder__c sOrder : accountRec.Opportunity_Units__r) {
                if (sOrder.InstallmentLines__r != null) {
                    allInstallmentLines.addAll(sOrder.InstallmentLines__r);
                }
                if (sOrder.HoldFlag__c) {
                    holdFlagCount++;
                }
            }
            AccountSalesOrderWrapper ac=  new AccountSalesOrderWrapper(accountRec, accountRec.Opportunity_Units__r, allInstallmentLines, holdFlagCount, usr.DefaultCurrencyIsoCode, accountRec.HexaBPM__Service_Requests__r);
            System.debug('ac: ' + ac);
            return ac;
        } catch (Exception e) {
            System.debug('Error in returning AccountSalesOrderWrapper: ' + e.getMessage());
            return null;
        }
    }

}