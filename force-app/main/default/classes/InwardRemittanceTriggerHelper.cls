public class InwardRemittanceTriggerHelper {
    
    public static void preventReceiptAcknowledgementUpdate(List<Inward_Remittance__c> newRemittances, Map<Id,Inward_Remittance__c> oldMap) {
        for(Inward_Remittance__c newRemittance : newRemittances) {
            Inward_Remittance__c oldRemittance = oldMap.get(newRemittance.Id);
            if(oldRemittance.Receipt_Acknowledgement__c != null && 
               newRemittance.Receipt_Acknowledgement__c != oldRemittance.Receipt_Acknowledgement__c) {
                newRemittance.addError('Receipt Acknowledgement already created for the given Inward Remittance record and cannot be updated once created');
            }
        }
    }

    public static void linkVirtualAccountsAndOrders(List<Inward_Remittance__c> newRemittances) {
        // Get all Virtual Account IBANs from inward remittances
        Set<String> virtualAccountIBANs = new Set<String>();
        for(Inward_Remittance__c remittance : newRemittances) {
            if(remittance.Virtual_Account_IBAN__c != null) {
                virtualAccountIBANs.add(remittance.Virtual_Account_IBAN__c);
            }
        }

        // Query Bank Virtual Accounts
        Map<String, BankVirtualAccounts__c> ibanToVirtualAccountMap = new Map<String, BankVirtualAccounts__c>();
        Set<Id> ibanToVirtualAccountIds = new Set<Id>();
        for(BankVirtualAccounts__c bva : [SELECT Id, VirtualIBANAccountNumber__c,BankName__c
                                         FROM BankVirtualAccounts__c 
                                         WHERE VirtualIBANAccountNumber__c IN :virtualAccountIBANs]) {
            ibanToVirtualAccountMap.put(bva.VirtualIBANAccountNumber__c, bva);
            ibanToVirtualAccountIds.add(bva.Id);
        }

        // Query Sales Orders and Units
        Map<Id, SalesOrder__c> virtualAccountToSalesOrderMap = new Map<Id, SalesOrder__c>();
        for(SalesOrder__c so : [SELECT Id, Unit__c, Unit__r.VirtualAccountNumber__c
                                FROM SalesOrder__c 
                                WHERE Unit__r.VirtualAccountNumber__c IN :ibanToVirtualAccountIds]) {
            virtualAccountToSalesOrderMap.put(so.Unit__r.VirtualAccountNumber__c, so);                            
        }

        // Link Virtual Accounts, Sales Orders and Units to Inward Remittances
        for(Inward_Remittance__c remittance : newRemittances) {
            if(remittance.Virtual_Account_IBAN__c != null) {
                BankVirtualAccounts__c virtualAccount = ibanToVirtualAccountMap.get(remittance.Virtual_Account_IBAN__c);
                
                if(virtualAccount != null) {
                    remittance.Virtual_Account__c = virtualAccount.Id;
                    remittance.Bank__c = virtualAccount.BankName__c;

                    SalesOrder__c salesOrder = virtualAccountToSalesOrderMap.get(virtualAccount.Id);
                    if(salesOrder != null) {
                        remittance.Sales_Order__c = salesOrder.Id;
                        remittance.Unit__c = salesOrder.Unit__c;
                    }
                }
            }
        }
    }
}