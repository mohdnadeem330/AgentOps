public without sharing class VFSSharingHelper {
    
    public static void shareInvoicesAndCommisionsWithVFSTeam(Set<Id> brokerAgencyIdSet) {
        
        List<InvoiceBundle__Share> invoiceShares = new List<InvoiceBundle__Share>();
        List<CommissionLineItem__Share> commissionShares = new List<CommissionLineItem__Share>();
        List<InvoiceBundle__Share> existingInvoiceShares = new List<InvoiceBundle__Share>();
        List<CommissionLineItem__Share> existingcommissionShares = new List<CommissionLineItem__Share>();
        Set<Id> invoiceIds = new Set<Id>();
        Set<Id> commissionIds = new Set<Id>();
        Map<Id, Id> invoiceToSubAccountManager = new Map<Id, Id>();
        Map<Id, Id> commissionToSubAccountManager = new Map<Id, Id>();
        Set<Id> subManagerIdSet = new Set<Id>();
        
        // Query Account records with related Invoices and SubAccountManager__c
        List<Account> accounts = [SELECT Id, SubAccountManager__c, 
                                  (SELECT Id FROM Invoice_Bundle__r),
                                  (SELECT Id From CommissionLineItems__r)
                                  FROM Account 
                                  WHERE Id IN : brokerAgencyIdSet AND SubAccountManager__c != NULL];
        
        for(Account acc: accounts){
            if(acc.SubAccountManager__c != null){
                subManagerIdSet.add(acc.SubAccountManager__c);
            }
        }
        
        Map<Id,Boolean> subManagerStatusMap = isUserActive(subManagerIdSet);
        
        for (Account account : accounts) {
            Id subAccountManagerId = account.SubAccountManager__c != null ? account.SubAccountManager__c : null;
            if(subManagerStatusMap.containsKey(subAccountManagerId) && subManagerStatusMap.get(subAccountManagerId)){
                if(subAccountManagerId != null && !account.Invoice_Bundle__r.isEmpty()){
                    for (InvoiceBundle__c invoice : account.Invoice_Bundle__r) {
                        invoiceIds.add(invoice.Id);
                        invoiceToSubAccountManager.put(invoice.Id, subAccountManagerId);
                    }
                }
                if(subAccountManagerId != null && !account.CommissionLineItems__r.isEmpty()){
                    for (CommissionLineItem__c commission : account.CommissionLineItems__r) {
                        commissionIds.add(commission.Id);
                        commissionToSubAccountManager.put(commission.Id, subAccountManagerId);
                    }
                }
            }                
        }
        
        if(invoiceToSubAccountManager.values() != null){
            existingInvoiceShares = [SELECT ParentId, UserOrGroupId FROM InvoiceBundle__Share 
                                     WHERE ParentId IN :invoiceIds AND UserOrGroupId IN :invoiceToSubAccountManager.values()];
        }
        
        if(commissionToSubAccountManager.values() != null){
            existingcommissionShares = [SELECT ParentId, UserOrGroupId FROM CommissionLineItem__Share 
                                        WHERE ParentId IN :commissionIds AND UserOrGroupId IN :commissionToSubAccountManager.values()];
        }
        
        
        Set<String> existingShareKeys = new Set<String>();
        for (InvoiceBundle__Share share : existingInvoiceShares) {
            existingShareKeys.add(share.ParentId + '-' + share.UserOrGroupId);
        }
        for (CommissionLineItem__Share share : existingcommissionShares) {
            existingShareKeys.add(share.ParentId + '-' + share.UserOrGroupId);
        }
        
        for (InvoiceBundle__c invoice : [SELECT Id FROM InvoiceBundle__c WHERE Id IN :invoiceIds]) {
            Id subAccountManagerId = invoiceToSubAccountManager.get(invoice.Id);
            String shareKey = invoice.Id + '-' + subAccountManagerId;
            
            if (!existingShareKeys.contains(shareKey)) {
                InvoiceBundle__Share invoiceShare = new InvoiceBundle__Share();
                invoiceShare.ParentId = invoice.Id;  
                invoiceShare.UserOrGroupId = subAccountManagerId;
                invoiceShare.AccessLevel = Constants.READ_ACCESS;    
                invoiceShare.RowCause = Schema.InvoiceBundle__Share.RowCause.Manual;
                invoiceShares.add(invoiceShare);
            }
        }
        
        for (CommissionLineItem__c commission : [SELECT Id FROM CommissionLineItem__c WHERE Id IN :commissionIds]) {
            Id subAccountManagerId = commissionToSubAccountManager.get(commission.Id);
            String shareKey = commission.Id + '-' + subAccountManagerId;
            
            if (!existingShareKeys.contains(shareKey)) {
                CommissionLineItem__Share commissionShare = new CommissionLineItem__Share();
                commissionShare.ParentId = commission.Id;  
                commissionShare.UserOrGroupId = subAccountManagerId;
                commissionShare.AccessLevel = Constants.READ_ACCESS;    
                commissionShare.RowCause = Schema.CommissionLineItem__Share.RowCause.Manual;
                commissionShares.add(commissionShare);
            }
        }
        
        // Insert the sharing records
        if (!invoiceShares.isEmpty()) {
            insert invoiceShares;
        }
        
        // Insert the Commission sharing records
        if (!commissionShares.isEmpty()) {
            insert commissionShares;
        }
    }
    
    public static void removeShareForVFSTeam(Map<Id,Id> accountIdWithSubManagerOld){
        List<InvoiceBundle__Share> invoiceSharesToDelete = new List<InvoiceBundle__Share>();
        List<CommissionLineItem__Share> commissionSharesToDelete = new List<CommissionLineItem__Share>();
        Set<Id> invoiceIds = new Set<Id>();
        Set<Id> commissionIds = new Set<Id>();
        Map<Id, Id> invoiceToSubAccountManager = new Map<Id, Id>();
        Map<Id, Id> commissionToSubAccountManager = new Map<Id, Id>();
        List<InvoiceBundle__Share> existingInvoiceShares = new List<InvoiceBundle__Share>();
        List<CommissionLineItem__Share> existingcommissionShares = new List<CommissionLineItem__Share>();
        
        // Query Account records with related Invoices,Commissions
        List<Account> accounts = [SELECT Id, SubAccountManager__c, 
                                  (SELECT Id FROM Invoice_Bundle__r),
                                  (SELECT Id From CommissionLineItems__r)
                                  FROM Account 
                                  WHERE Id IN : accountIdWithSubManagerOld.keySet()];
        for (Account account : accounts) {
            Id oldSubAccountManagerId = accountIdWithSubManagerOld.containsKey(account.Id) ? accountIdWithSubManagerOld.get(account.Id) : null;
            if(oldSubAccountManagerId != null && !account.Invoice_Bundle__r.isEmpty()){
                for (InvoiceBundle__c invoice : account.Invoice_Bundle__r) {
                    invoiceIds.add(invoice.Id);
                    invoiceToSubAccountManager.put(invoice.Id, oldSubAccountManagerId);
                }
            }
            if(oldSubAccountManagerId != null && !account.CommissionLineItems__r.isEmpty()){
                for (CommissionLineItem__c commission : account.CommissionLineItems__r) {
                    commissionIds.add(commission.Id);
                    commissionToSubAccountManager.put(commission.Id, oldSubAccountManagerId);
                }
            }     
        }
        
        if(invoiceToSubAccountManager.values() != null){
            invoiceSharesToDelete = [SELECT ParentId, UserOrGroupId FROM InvoiceBundle__Share 
                                     WHERE ParentId IN :invoiceIds AND UserOrGroupId IN :invoiceToSubAccountManager.values()];
        }
        
        if(commissionToSubAccountManager.values() != null){
            commissionSharesToDelete = [SELECT ParentId, UserOrGroupId FROM CommissionLineItem__Share 
                                        WHERE ParentId IN :commissionIds AND UserOrGroupId IN :commissionToSubAccountManager.values()];
        }
        
        if (!invoiceSharesToDelete.isEmpty()) {
            delete invoiceSharesToDelete;
        }
        if (!commissionSharesToDelete.isEmpty()) {
            delete commissionSharesToDelete;
        }
    }
    
    public static Map<Id,Boolean> isUserActive(Set<Id> subManagerIdSet) {
        Map<Id,Boolean> userStatusMap = new Map<Id,Boolean>();
        for(User u : [SELECT Id,IsActive FROM User WHERE Id IN :subManagerIdSet]){
            userStatusMap.put(u.Id, u.IsActive);
        }
        return userStatusMap;
    }
}