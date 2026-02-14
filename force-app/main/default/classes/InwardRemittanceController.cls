public class InwardRemittanceController {
    public class RemittanceWrapper {
        @AuraEnabled public String id {get;set;}
        @AuraEnabled public String name {get;set;}
        @AuraEnabled public String virtualAccountNumber {get;set;}
        @AuraEnabled public String realAccountNumber {get;set;}
        @AuraEnabled public String bank {get;set;}
        @AuraEnabled public String transferType {get;set;}
        @AuraEnabled public Decimal amount {get;set;}
        @AuraEnabled public String paymentDetails {get;set;}
        @AuraEnabled public String transactionReference {get;set;}
        @AuraEnabled public String customerReference {get;set;}
        @AuraEnabled public String paymentStatus {get;set;}
        @AuraEnabled public String remittanceUrl {get;set;}
        @AuraEnabled public String salesOrderUrl {get;set;}
        @AuraEnabled public String salesOrderName {get;set;}
        @AuraEnabled public String unitUrl {get;set;}
        @AuraEnabled public String unitName {get;set;}
        @AuraEnabled public String projectUrl {get;set;}
        @AuraEnabled public String projectName {get;set;}
        @AuraEnabled public String customerUrl {get;set;}
        @AuraEnabled public String customerName {get;set;}
        @AuraEnabled public String receiptUrl {get;set;}
        @AuraEnabled public String receiptName {get;set;}
        @AuraEnabled public String receiptStatus {get;set;}
        @AuraEnabled public Boolean isUnidentifiedReceipt {get;set;}
    }
    
    public class PaginationWrapper {
        @AuraEnabled public List<RemittanceWrapper> records {get;set;}
        @AuraEnabled public Integer totalRecords {get;set;}
        @AuraEnabled public Integer totalPages {get;set;}
    }

    public class ReceiptWrapper {
        @AuraEnabled public String id {get;set;}
        @AuraEnabled public String name {get;set;}
        @AuraEnabled public Decimal amount {get;set;}
        @AuraEnabled public Date maturityDate {get;set;}
        @AuraEnabled public String status {get;set;}
    }

    @AuraEnabled(cacheable=true)
    public static List<Project__c> getProjects() {
        return [SELECT id,Name,AccountNumberEscrow__c,AccountNumberCorporate__c, BankNameCorporate__c 
        FROM Project__c WHERE IsActive__c =true  WITH SECURITY_ENFORCED order by Name ];
    }

    @AuraEnabled
    public static PaginationWrapper getInwardRemittances(
        String virtualAccountNumber, String virtualAccountIBAN, String realAccountNumber,
        String bank, String transferType, Decimal amount,
        String paymentDetails, Date startDate, Date endDate, String project,
        String unit, String salesOrder, String status, String receiptStatus,
        Integer pageSize, Integer pageNumber
    ) {
        String query = 'SELECT Id, Name, Virtual_Account_Number__c, ' +
                      'Real_Account_Number__c, Bank__c, Transfer_Type__c, ' +
                      'Amount__c, Payment_Details_Long__c, Transaction_Reference__c, ' +
                      'Customer_Reference__c, Payment_Status__c, ' +
                      'Sales_Order__c, Sales_Order__r.Name, Sales_Order__r.Unit__c, Sales_Order__r.Unit__r.Name, ' +
                      'Sales_Order__r.Unit__r.Project__c, Sales_Order__r.Unit__r.Project__r.Name, ' +
                      'Sales_Order__r.Account__c, Sales_Order__r.Account__r.Name, ' +
                      'Receipt_Acknowledgement__c, Receipt_Acknowledgement__r.Name, Receipt_Acknowledgement__r.Id, Receipt_Acknowledgement__r.Status__c, ' +
                      'Receipt_Acknowledgement__r.Account__c, Receipt_Acknowledgement__r.Account__r.Name ' +
                      'FROM Inward_Remittance__c WHERE Status__c = :status ';
        
        if (virtualAccountNumber != null && virtualAccountNumber != '') {
            query += ' AND Virtual_Account_Number__c LIKE \'%' + virtualAccountNumber + '%\'';
        }
        if (realAccountNumber != null && realAccountNumber != '') {
            query += ' AND Real_Account_Number__c LIKE \'%' + realAccountNumber + '%\'';
        }
        if (bank != null && bank != '') {
            query += ' AND Bank__c = \'' + bank + '\'';
        }
        if (transferType != null && transferType != '') {
            query += ' AND Transfer_Type__c = \'' + transferType + '\'';
        }
        if (amount != null) {
            query += ' AND Amount__c = ' + amount;
        }
        /*if (paymentDetails != null && paymentDetails != '') {
            query += ' AND Payment_Details_Long__c LIKE \'%' + String.escapeSingleQuotes(paymentDetails) + '%\'';
        }*/
        if (startDate != null) {
            query += ' AND Request_DateTime__c >= :startDate';
        }
        if (endDate != null) {
            query += ' AND Request_DateTime__c <= :endDate';
        }
        if (project != null && project != '') {
            query += ' AND Sales_Order__r.Unit__r.Project__r.Name = \'' + project + '\'';
        }
        if (unit != null && unit != '') {
            query += ' AND Sales_Order__r.Unit__r.Name LIKE \'%' + unit + '%\'';
        }
        if (salesOrder != null && salesOrder != '') {
            query += ' AND Sales_Order__r.Name LIKE \'%' + salesOrder + '%\'';
        }
        if (status == 'Processed' && receiptStatus != null && receiptStatus != '') {
            query += ' AND Receipt_Acknowledgement__r.Status__c = \'' + receiptStatus + '\'';
        }

        Integer totalRecords = Database.countQuery('SELECT COUNT() FROM Inward_Remittance__c ' + query.substringAfter('FROM Inward_Remittance__c'));
        Integer totalPages = Math.ceil(Decimal.valueOf(totalRecords) / Decimal.valueOf(pageSize)).intValue();
        
        Integer offset = (pageNumber - 1) * pageSize;
        query += ' ORDER BY lastmodifiedDate DESC LIMIT ' + pageSize + ' OFFSET ' + offset;
        
        List<Inward_Remittance__c> queryResults = Database.query(query);
        
        List<RemittanceWrapper> wrappers = new List<RemittanceWrapper>();
        for(Inward_Remittance__c record : queryResults) {
            RemittanceWrapper wrapper = new RemittanceWrapper();
            wrapper.id = record.Id;
            wrapper.name = record.Name;
            wrapper.virtualAccountNumber = record.Virtual_Account_Number__c;
            wrapper.realAccountNumber = record.Real_Account_Number__c;
            wrapper.bank = record.Bank__c;
            wrapper.transferType = record.Transfer_Type__c;
            wrapper.amount = record.Amount__c;
            wrapper.paymentDetails = record.Payment_Details_Long__c;
            wrapper.transactionReference = record.Transaction_Reference__c;
            wrapper.customerReference = record.Customer_Reference__c;
            wrapper.paymentStatus = record.Payment_Status__c;
            wrapper.receiptUrl = record.Receipt_Acknowledgement__c != null ? 
                               '/lightning/r/Receipt_Acknowledgement__c/' + record.Receipt_Acknowledgement__r.Id + '/view' : '';
            wrapper.receiptName = record.Receipt_Acknowledgement__c != null ? 
                                record.Receipt_Acknowledgement__r.Name : '';
            wrapper.receiptStatus = record.Receipt_Acknowledgement__c != null ? 
                                  record.Receipt_Acknowledgement__r.Status__c : '';
            wrapper.isUnidentifiedReceipt = record.Receipt_Acknowledgement__c != null && 
                                          record.Receipt_Acknowledgement__r.Account__r.Name == 'UNIDENTIFIED CUSTOMER';
            
            wrapper.remittanceUrl = '/lightning/r/Inward_Remittance__c/' + record.Id + '/view';
            
            if(record.Sales_Order__c != null) {
                wrapper.salesOrderUrl = '/lightning/r/Sales_Order__c/' + record.Sales_Order__c + '/view';
                wrapper.salesOrderName = record.Sales_Order__r?.Name;
                
                if(record.Sales_Order__r?.Account__c != null) {
                    wrapper.customerUrl = '/lightning/r/Account/' + record.Sales_Order__r.Account__c + '/view';
                    wrapper.customerName = record.Sales_Order__r.Account__r?.Name;
                }
            }
            
            if(record.Sales_Order__r?.Unit__c != null) {
                wrapper.unitUrl = '/lightning/r/Unit__c/' + record.Sales_Order__r.Unit__c + '/view';
                wrapper.unitName = record.Sales_Order__r.Unit__r?.Name;
            }
            
            if(record.Sales_Order__r?.Unit__r?.Project__c != null) {
                wrapper.projectUrl = '/lightning/r/Project__c/' + record.Sales_Order__r.Unit__r.Project__c + '/view';
                wrapper.projectName = record.Sales_Order__r.Unit__r.Project__r?.Name;
            }
            
            wrappers.add(wrapper);
        }
        
        PaginationWrapper paginationWrapper = new PaginationWrapper();
        paginationWrapper.records = wrappers;
        paginationWrapper.totalRecords = totalRecords;
        paginationWrapper.totalPages = totalPages;
        
        return paginationWrapper;
    }
    
    @AuraEnabled
    public static void updateRemittanceStatus(String remittanceId, String status) {
        try {
            Inward_Remittance__c remittance = [
                SELECT Id, Status__c 
                FROM Inward_Remittance__c 
                WHERE Id = :remittanceId
            ];
            remittance.Status__c = status;
            update remittance;
        } catch(Exception e) {
            throw new AuraHandledException('Error updating remittance: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static List<ReceiptWrapper> getExistingReceipts(String remittanceId) {
        Inward_Remittance__c remittance = [SELECT Id, Status__c, Sales_Order__c  FROM Inward_Remittance__c WHERE Id = :remittanceId];
        List<ReceiptAcknowledgement__c> receipts = [
            SELECT Id, Name, Amount__c, ReceiptDate__c, Status__c, MaturityDate__c
            FROM ReceiptAcknowledgement__c
            WHERE SalesOrder__c = :remittance.Sales_Order__c
            AND Status__c != 'Cleared'
            ORDER BY CreatedDate DESC
        ];

        List<ReceiptWrapper> wrappers = new List<ReceiptWrapper>();
        for(ReceiptAcknowledgement__c receipt : receipts) {
            ReceiptWrapper wrapper = new ReceiptWrapper();
            wrapper.id = receipt.Id;
            wrapper.name = receipt.Name;
            wrapper.amount = receipt.Amount__c;
            wrapper.maturityDate = receipt.MaturityDate__c;
            wrapper.status = receipt.Status__c;
            wrappers.add(wrapper);
        }
        return wrappers;
    }

    @AuraEnabled
    public static void linkReceiptToRemittance(String remittanceId, String receiptId) {
        try {
            // Create records for update
            Inward_Remittance__c remittance = new Inward_Remittance__c(
                Id = remittanceId,
                Status__c = 'Processed',
                Receipt_Acknowledgement__c = receiptId
            );

            ReceiptAcknowledgement__c receipt = new ReceiptAcknowledgement__c(
                Id = receiptId,
                Inward_Remittance__c = remittanceId
            );

            // Update both records
            update receipt;
            update remittance;
        } catch (Exception e) {
            throw new AuraHandledException('Error linking receipt: ' + e.getMessage());
        }
    }

}