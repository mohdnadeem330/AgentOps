/**
  
 * This class processes receipt acknowledgements that have bulk installment allocation enabled
 * and creates separate receipt acknowledgements for other charge types while keeping
 * installments with the original receipt.
 */
public class BulkInstallmentAllocationQueueable implements Queueable, Database.AllowsCallouts {
    
    private Set<Id> receiptIds;
    
    /**
     * Constructor to initialize the queueable with receipt IDs
     * @param receiptIds Set of receipt acknowledgement IDs to process
     */
    public BulkInstallmentAllocationQueueable(Set<Id> receiptIds) {
        this.receiptIds = receiptIds;
    }
    
    /**
     * Execute method that processes the bulk installment allocation
     * @param context QueueableContext
     */
    public void execute(QueueableContext context) {
        try {
            // Check if the feature is enabled via custom label
            Boolean isEnabled = Boolean.valueOf(Label.EnableBulkInstallmentAllocation);
            System.debug('Bulk Installment Allocation Feature enabled: ' + isEnabled);
            
            if(!isEnabled) {
                System.debug('Bulk Installment Allocation feature is disabled. Exiting queueable.');
                return; // Exit early if feature is disabled
            }
            
            if(receiptIds == null || receiptIds.isEmpty()) {
                System.debug('No receipt IDs provided. Exiting queueable.');
                return;
            }
            
            System.debug('Processing receipt IDs: ' + receiptIds);
            
            // Query receipt acknowledgements that meet the criteria
            List<ReceiptAcknowledgement__c> bulkAllocationReceipts = [
                SELECT Id, Account__c, SalesOrder__c, Amount__c, PaymentType__c, Status__c, 
                       ReferenceNumber__c, Remarks__c, Bulk_Installment_Allocation__c, 
                       OnlinePaymentCleared__c, CurrencyIsoCode, ReceiptDate__c, 
                       ClearedDate__c, Payment_Gateway__c, Contact__c, Opportunity__c,
                       Sales_Manager__c, ServiceRequest__c, Receipt_Type__c, StopCallout__c,BankName__c
                FROM ReceiptAcknowledgement__c 
                WHERE Id IN :receiptIds
            ];
            
            if(bulkAllocationReceipts.isEmpty()) {
                System.debug('No receipts found matching bulk allocation criteria.');
                return;
            }
            
            System.debug('Found ' + bulkAllocationReceipts.size() + ' receipts for bulk allocation processing.');
            
            // Process the bulk allocation
            processBulkInstallmentAllocation(bulkAllocationReceipts);
            
        } catch(Exception e) {
            System.debug('Error in BulkInstallmentAllocationQueueable: ' + e.getMessage());
            LoggerService.save(LoggerService.addApexLog(e, 'BulkInstallmentAllocationQueueable', 'execute', 'Error processing bulk installment allocation'));
            throw new CustomException('Error in bulk installment allocation queueable: ' + e.getMessage());
        }
    }
    
    /**
     * Process bulk installment allocation for the given receipts
     * @param bulkAllocationReceipts List of receipt acknowledgements to process
     */
    private void processBulkInstallmentAllocation(List<ReceiptAcknowledgement__c> bulkAllocationReceipts) {
        Set<Id> receiptIds = new Set<Id>();
        for(ReceiptAcknowledgement__c ra : bulkAllocationReceipts) {
            receiptIds.add(ra.Id);
        }
        
        // Query receipt allocations with all custom fields
        List<ReceiptAllocation__c> allocations = [
            SELECT Id, ReceiptAcknowledgement__c, InstallmentLine__c, SalesOrderOtherCharges__c,
                   TypeOfInvoice__c, AmountApplied__c, Account__c, SalesOrder__c, 
                   DateOfApplication__c, DateOfUnapplication__c, Unapply__c, 
                   CurrencyIsoCode, ERPID__c, InstallmentNumberOrChargeType__c,
                   ReceiptWriteOff__c, SalesSupportCost__c, CreatedDate, LastModifiedDate,
                   CreatedById, LastModifiedById, SystemModstamp
            FROM ReceiptAllocation__c 
            WHERE ReceiptAcknowledgement__c IN :receiptIds
            AND AmountApplied__c > 0
        ];
        
        System.debug('Found ' + allocations.size() + ' allocations to process.');
        
        Map<Id, List<ReceiptAllocation__c>> receiptAllocationMap = new Map<Id, List<ReceiptAllocation__c>>();
        Map<Id, Decimal> originalAllocationAmounts = new Map<Id, Decimal>();
        
        // Group allocations by receipt and store original amounts
        for(ReceiptAllocation__c alloc : allocations) {
            if(!receiptAllocationMap.containsKey(alloc.ReceiptAcknowledgement__c)) {
                receiptAllocationMap.put(alloc.ReceiptAcknowledgement__c, new List<ReceiptAllocation__c>());
            }
            receiptAllocationMap.get(alloc.ReceiptAcknowledgement__c).add(alloc);
            
            // Store original amount for later use
            originalAllocationAmounts.put(alloc.Id, alloc.AmountApplied__c);
        }
        
        List<ReceiptAcknowledgement__c> newReceipts = new List<ReceiptAcknowledgement__c>();
        List<ReceiptAllocation__c> allocationsToUpdate = new List<ReceiptAllocation__c>();
        List<ReceiptAcknowledgement__c> originalReceiptsToUpdate = new List<ReceiptAcknowledgement__c>();
        
        // Map to store charge type to receipt mapping for allocation creation
        Map<String, ReceiptAcknowledgement__c> chargeTypeToReceiptMap = new Map<String, ReceiptAcknowledgement__c>();
        
        // Map to store original reference numbers before modification
        Map<Id, String> originalReferenceNumbers = new Map<Id, String>();
        
        for(ReceiptAcknowledgement__c originalReceipt : bulkAllocationReceipts) {
            System.debug('Processing receipt: ' + originalReceipt.Id);
            
            // Store the original reference number before any modifications
            originalReferenceNumbers.put(originalReceipt.Id, originalReceipt.ReferenceNumber__c);
            
            List<ReceiptAllocation__c> receiptAllocations = receiptAllocationMap.get(originalReceipt.Id);
            
            if(receiptAllocations == null || receiptAllocations.isEmpty()) {
                System.debug('No allocations found for receipt: ' + originalReceipt.Id);
                continue;
            }
            
            // Separate installment lines and other charges
            List<ReceiptAllocation__c> installmentAllocations = new List<ReceiptAllocation__c>();
            Map<String, List<ReceiptAllocation__c>> otherChargeTypeMap = new Map<String, List<ReceiptAllocation__c>>();
            
            for(ReceiptAllocation__c alloc : receiptAllocations) {
                if(alloc.TypeOfInvoice__c == 'Installment') {
                    installmentAllocations.add(alloc);
                } else if(alloc.TypeOfInvoice__c == 'DLD' || 
                         alloc.TypeOfInvoice__c == 'RAK Municipality Fee' || 
                         alloc.TypeOfInvoice__c == 'ADM Fee') {
                    if(!otherChargeTypeMap.containsKey(alloc.TypeOfInvoice__c)) {
                        otherChargeTypeMap.put(alloc.TypeOfInvoice__c, new List<ReceiptAllocation__c>());
                    }
                    otherChargeTypeMap.get(alloc.TypeOfInvoice__c).add(alloc);
                }
            }
            
            System.debug('Installment allocations: ' + installmentAllocations.size());
            System.debug('Other charge types: ' + otherChargeTypeMap.keySet());
            
            // Calculate total installment amount for the original receipt
            Decimal totalInstallmentAmount = 0;
            for(ReceiptAllocation__c alloc : installmentAllocations) {
                totalInstallmentAmount += alloc.AmountApplied__c;
            }
            
            // Update original receipt amount to reflect only installment amounts and add _1 to reference number
            if(totalInstallmentAmount > 0) {
                originalReceipt.Amount__c = totalInstallmentAmount;
                // Add _1 to the original receipt's reference number
                if(String.isNotBlank(originalReceipt.ReferenceNumber__c)) {
                    originalReceipt.ReferenceNumber__c = originalReceipt.ReferenceNumber__c + '_1';
                    originalReceipt.StopCallout__c = false;
                }
                originalReceiptsToUpdate.add(originalReceipt);
                System.debug('Updated original receipt amount to installment total: ' + totalInstallmentAmount + ' and added _1 to reference number');
            }
            
            // Create separate receipt for each type of other charge
            Integer sequenceNumber = 2; // Start from 2 since original receipt gets _1
            for(String chargeType : otherChargeTypeMap.keySet()) {
                List<ReceiptAllocation__c> chargeAllocations = otherChargeTypeMap.get(chargeType);
                System.debug('Processing charge type: ' + chargeType + ' with ' + chargeAllocations.size() + ' allocations');
                
                if(!chargeAllocations.isEmpty()) {
                    ReceiptAcknowledgement__c chargeReceipt = createReceiptCopy(originalReceipt, chargeType, sequenceNumber, originalReferenceNumbers.get(originalReceipt.Id));
                    Decimal chargeAmount = 0;
                    
                    for(ReceiptAllocation__c alloc : chargeAllocations) {
                        chargeAmount += alloc.AmountApplied__c;
                    }
                    
                    chargeReceipt.Amount__c = chargeAmount;
                    System.debug('Created new receipt for ' + chargeType + ' with amount: ' + chargeAmount + ' and sequence: ' + sequenceNumber + ' (reference: ' + chargeReceipt.ReferenceNumber__c + ')');
                    newReceipts.add(chargeReceipt);
                    
                    // Create unique key: {ReceiptId}_{ChargeType} to avoid conflicts across multiple receipts
                    String uniqueKey = originalReceipt.Id + '_' + chargeType;
                    chargeTypeToReceiptMap.put(uniqueKey, chargeReceipt);
                    
                    // Zero out the original allocations for other charges
                    for(ReceiptAllocation__c alloc : chargeAllocations) {
                        alloc.AmountApplied__c = 0;
                        allocationsToUpdate.add(alloc);
                    }
                    
                    sequenceNumber++;
                }
            }
        }
        
        // Update allocations to zero out other charge amounts
        System.debug('Updating ' + allocationsToUpdate.size() + ' allocations to zero out other charge amounts.');
        if(!allocationsToUpdate.isEmpty()) {
            update allocationsToUpdate;
        }
        
        // Update original receipts to reflect only installment amounts
        System.debug('Updating ' + originalReceiptsToUpdate.size() + ' original receipts to reflect installment amounts only.');
        if(!originalReceiptsToUpdate.isEmpty()) {
            update originalReceiptsToUpdate;
        }
        
        // Insert new receipts for other charges
        System.debug('Inserting ' + newReceipts.size() + ' new receipts for other charges.');
        if(!newReceipts.isEmpty()) {
            insert newReceipts;
        }
        
        // Create new allocations for the new receipts
        List<ReceiptAllocation__c> newAllocations = new List<ReceiptAllocation__c>();
        
        for(ReceiptAcknowledgement__c originalReceipt : bulkAllocationReceipts) {
            List<ReceiptAllocation__c> receiptAllocations = receiptAllocationMap.get(originalReceipt.Id);
            if(receiptAllocations == null || receiptAllocations.isEmpty()) continue;
            
            for(ReceiptAllocation__c alloc : receiptAllocations) {
                if(alloc.TypeOfInvoice__c != 'Installment' && 
                   (alloc.TypeOfInvoice__c == 'DLD' || 
                    alloc.TypeOfInvoice__c == 'RAK Municipality Fee' || 
                    alloc.TypeOfInvoice__c == 'ADM Fee')) {
                    
                    // Create unique key to match the one used when creating receipts
                    String uniqueKey = originalReceipt.Id + '_' + alloc.TypeOfInvoice__c;
                    ReceiptAcknowledgement__c newReceipt = chargeTypeToReceiptMap.get(uniqueKey);
                    if(newReceipt != null) {
                        ReceiptAllocation__c newAlloc = createAllocationCopy(alloc, newReceipt.Id);
                        // Restore the original amount applied from the map
                        if(originalAllocationAmounts.containsKey(alloc.Id)) {
                            newAlloc.AmountApplied__c = originalAllocationAmounts.get(alloc.Id);
                        }
                        newAllocations.add(newAlloc);
                    }
                }
            }
        }
        
        // Insert new allocations
        System.debug('Inserting ' + newAllocations.size() + ' new allocations for other charges.');
        if(!newAllocations.isEmpty()) {
            insert newAllocations;
        }
        
        // Call ReceiptCalloutHelper.PrepareDataForCallout after all DML operations are completed
        if(!originalReceiptsToUpdate.isEmpty()) {
            List<Id> originalReceiptIds = new List<Id>();
            for (ReceiptAcknowledgement__c rec : originalReceiptsToUpdate) {
                originalReceiptIds.add(rec.Id);
            }
            System.debug('Calling ReceiptCalloutHelper.PrepareDataForCallout for ' + originalReceiptIds.size() + ' original receipts after all DML operations.');
            ReceiptCalloutHelper.PrepareDataForCallout(originalReceiptIds);
        }
        
        System.debug('Bulk installment allocation processing completed successfully.');
        System.debug('Original receipts updated to reflect installment amounts only - new receipts created for other charge types.');
    }
    
    /**
     * Helper method to create a copy of receipt acknowledgement with sequential reference number
     * @param original Original receipt acknowledgement
     * @param chargeType Type of charge for the new receipt
     * @param sequenceNumber Sequential number for the reference number (starts from 2, as original gets _1)
     * @param originalReferenceNumber The original reference number before any modifications
     * @return ReceiptAcknowledgement__c New receipt copy
     */
    private ReceiptAcknowledgement__c createReceiptCopy(ReceiptAcknowledgement__c original, String chargeType, Integer sequenceNumber, String originalReferenceNumber) {
        ReceiptAcknowledgement__c copy = original.clone(false, true, false, false);
        copy.Id = null;
        
        // Update fields for the new receipt
        copy.Remarks__c = original.Remarks__c + ' - ' + chargeType;
        copy.Bulk_Installment_Allocation__c = false;
        copy.Status__c = Constants.RECEIVED_PAYMENT_STATUS; // Set status to Received since payment is already completed
        copy.ReceiptDate__c = Date.Today();
        copy.ChequeReceived__c = true; // Set status to Received since payment is already completed
        copy.OnlinePaymentCleared__c = true; // Set status to Received since payment is already completed

        // Use the original reference number (before _1 was added) and append the sequence number
        if(String.isNotBlank(originalReferenceNumber)) {
            copy.ReferenceNumber__c = originalReferenceNumber + '_' + sequenceNumber;
        }
        
        return copy;
    }
    
    /**
     * Helper method to create a copy of receipt allocation
     * @param original Original receipt allocation
     * @param newReceiptId New receipt acknowledgement ID
     * @return ReceiptAllocation__c New allocation copy
     */
    private ReceiptAllocation__c createAllocationCopy(ReceiptAllocation__c original, Id newReceiptId) {
        // Use Salesforce clone functionality
        ReceiptAllocation__c copy = original.clone(false, true, false, false);
        
        // Clear the Id to make it a new record
        copy.Id = null;
        
        // Update the receipt acknowledgement reference
        copy.ReceiptAcknowledgement__c = newReceiptId;
        //copy.ReceiptStatus__c = Constants.RECEIVED_PAYMENT_STATUS; // Set status to Received since payment is already completed
        
        return copy;
    }
}