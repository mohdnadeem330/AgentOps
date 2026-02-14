/**
 * This class processes receipt acknowledgements that have bulk installment allocation enabled
 * and creates entirely new receipt acknowledgements and allocations for both installment and 
 * other charge types, without modifying any existing records.
 */
public class BulkInstallmentAllocationNewQueueable implements Queueable, Database.AllowsCallouts {
    
    private Set<Id> receiptIds;
    
    /**
     * Constructor to initialize the queueable with receipt IDs
     * @param receiptIds Set of receipt acknowledgement IDs to process
     */
    public BulkInstallmentAllocationNewQueueable(Set<Id> receiptIds) {
        this.receiptIds = receiptIds;
    }
    
    /**
     * Execute method that processes the bulk installment allocation by creating new records
     * @param context QueueableContext
     */
    public void execute(QueueableContext context) {
        try {
            // Check if the feature is enabled via custom label
            /*Boolean isEnabled = Boolean.valueOf(Label.EnableBulkInstallmentAllocation);
            System.debug('Bulk Installment Allocation New Records Feature enabled: ' + isEnabled);
            
            if(!isEnabled) {
                System.debug('Bulk Installment Allocation New Records feature is disabled. Exiting queueable.');
                return; // Exit early if feature is disabled
            }*/
            
            if(receiptIds == null || receiptIds.isEmpty()) {
                System.debug('No receipt IDs provided. Exiting queueable.');
                return;
            }
            
            System.debug('Processing receipt IDs for new records creation: ' + receiptIds);
            
            // Query receipt acknowledgements that meet the criteria
            List<ReceiptAcknowledgement__c> bulkAllocationReceipts = [
                SELECT Id, Account__c, SalesOrder__c, Amount__c, PaymentType__c, Status__c, 
                       ReferenceNumber__c, Remarks__c, Bulk_Installment_Allocation__c, 
                       OnlinePaymentCleared__c, CurrencyIsoCode, ReceiptDate__c, 
                       ClearedDate__c, Payment_Gateway__c, Contact__c, Opportunity__c,
                       Sales_Manager__c, ServiceRequest__c, Receipt_Type__c, StopCallout__c,
                       BankName__c, CustomerBankAccount__c, MortgageCheque__c, MaturityDate__c,
                       ChequeReceived__c, ChequeReceivedBy__c, ChequeReceivedDate__c,
                       GLDate__c, StatusReason__c, UnidentifiedReceiptFlag__c,
                       PaymentSubType__c, ERPID__c, IsReceiptAcknowledgementChange__c,
                       IsReceiptAllocationChange__c, CreatedById, LastModifiedById
                FROM ReceiptAcknowledgement__c 
                WHERE Id IN :receiptIds
            ];
            
            if(bulkAllocationReceipts.isEmpty()) {
                System.debug('No receipts found matching bulk allocation criteria.');
                return;
            }
            
            System.debug('Found ' + bulkAllocationReceipts.size() + ' receipts for new records creation.');
            
            // Process the bulk allocation by creating new records
            processBulkInstallmentAllocationNewRecords(bulkAllocationReceipts);
            
        } catch(Exception e) {
            System.debug('Error in BulkInstallmentAllocationNewRecordsQueueable: ' + e.getMessage());
            LoggerService.save(LoggerService.addApexLog(e, 'BulkInstallmentAllocationNewRecordsQueueable', 'execute', 'Error processing bulk installment allocation new records'));
            throw new CustomException('Error in bulk installment allocation new records queueable: ' + e.getMessage());
        }
    }
    
    /**
     * Process bulk installment allocation by creating new records for the given receipts
     * @param bulkAllocationReceipts List of receipt acknowledgements to process
     */
    private void processBulkInstallmentAllocationNewRecords(List<ReceiptAcknowledgement__c> bulkAllocationReceipts) {
        // Get allocations for all receipts
        Map<Id, List<ReceiptAllocation__c>> receiptAllocationMap = getReceiptAllocations(bulkAllocationReceipts);
        
        // Create new receipts and allocations
        List<ReceiptAcknowledgement__c> newReceipts = new List<ReceiptAcknowledgement__c>();
        List<ReceiptAllocation__c> newAllocations = new List<ReceiptAllocation__c>();
        Map<String, ReceiptAcknowledgement__c> chargeTypeToReceiptMap = new Map<String, ReceiptAcknowledgement__c>();
        
        // Process each receipt to create new receipts
        for(ReceiptAcknowledgement__c originalReceipt : bulkAllocationReceipts) {
            processReceiptForNewRecords(originalReceipt, receiptAllocationMap, newReceipts, chargeTypeToReceiptMap);
        }
        
        // Insert new receipts
        insertNewReceipts(newReceipts);
        
        // Create and insert new allocations
        createNewAllocations(bulkAllocationReceipts, receiptAllocationMap, chargeTypeToReceiptMap, newAllocations);
        insertNewAllocations(newAllocations);
        
        // Call ReceiptCalloutHelper for new receipts
        callReceiptCalloutHelper(newReceipts);
        
        System.debug('Bulk installment allocation new records processing completed successfully.');
        System.debug('Created ' + newReceipts.size() + ' new receipts and ' + newAllocations.size() + ' new allocations.');
    }
    
    /**
     * Get receipt allocations grouped by receipt ID
     * @param bulkAllocationReceipts List of receipt acknowledgements
     * @return Map of receipt ID to list of allocations
     */
    private Map<Id, List<ReceiptAllocation__c>> getReceiptAllocations(List<ReceiptAcknowledgement__c> bulkAllocationReceipts) {
        Set<Id> receiptIds = new Set<Id>();
        for(ReceiptAcknowledgement__c ra : bulkAllocationReceipts) {
            receiptIds.add(ra.Id);
        }
        
        // Query receipt allocations with all custom fields
        List<ReceiptAllocation__c> allocations = [
            SELECT Id, ReceiptAcknowledgement__c, InstallmentLine__c, SalesOrderOtherCharges__c,
                   TypeOfInvoice__c, AmountApplied__c, InstallmentAmountOtherChargeAmount__c, Account__c, SalesOrder__c, 
                   DateOfApplication__c, DateOfUnapplication__c, Unapply__c, 
                   CurrencyIsoCode, ERPID__c, InstallmentNumberOrChargeType__c,
                   ReceiptWriteOff__c, SalesSupportCost__c, CreatedDate, LastModifiedDate,
                   CreatedById, LastModifiedById, SystemModstamp
            FROM ReceiptAllocation__c 
            WHERE ReceiptAcknowledgement__c IN :receiptIds
            
        ];
        
        System.debug('Found ' + allocations.size() + ' allocations to process for new records creation.');
        
        Map<Id, List<ReceiptAllocation__c>> receiptAllocationMap = new Map<Id, List<ReceiptAllocation__c>>();
        
        // Group allocations by receipt
        for(ReceiptAllocation__c alloc : allocations) {
            if(!receiptAllocationMap.containsKey(alloc.ReceiptAcknowledgement__c)) {
                receiptAllocationMap.put(alloc.ReceiptAcknowledgement__c, new List<ReceiptAllocation__c>());
            }
            receiptAllocationMap.get(alloc.ReceiptAcknowledgement__c).add(alloc);
        }
        
        return receiptAllocationMap;
    }
    
    /**
     * Process a single receipt to create new receipts
     * @param originalReceipt Original receipt to process
     * @param receiptAllocationMap Map of receipt allocations
     * @param newReceipts List to add new receipts to
     * @param chargeTypeToReceiptMap Map to store charge type to receipt mapping
     */
    private void processReceiptForNewRecords(ReceiptAcknowledgement__c originalReceipt, 
                                            Map<Id, List<ReceiptAllocation__c>> receiptAllocationMap,
                                            List<ReceiptAcknowledgement__c> newReceipts,
                                            Map<String, ReceiptAcknowledgement__c> chargeTypeToReceiptMap) {
        System.debug('Processing receipt for new records creation: ' + originalReceipt.Id);
        
        List<ReceiptAllocation__c> receiptAllocations = receiptAllocationMap.get(originalReceipt.Id);
        
        if(receiptAllocations == null || receiptAllocations.isEmpty()) {
            System.debug('No allocations found for receipt: ' + originalReceipt.Id);
            return;
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
        
        // Create new receipt for installments only
        if(!installmentAllocations.isEmpty()) {
            ReceiptAcknowledgement__c installmentReceipt = createNewReceiptForInstallments(originalReceipt, installmentAllocations);
            newReceipts.add(installmentReceipt);
            
            // Create unique key for installment receipt
            String installmentKey = originalReceipt.Id + '_Installment';
            chargeTypeToReceiptMap.put(installmentKey, installmentReceipt);
            
            System.debug('Created new installment receipt with amount: ' + installmentReceipt.Amount__c);
        }
        
        // Create separate receipt for each type of other charge
        Integer sequenceNumber = 2; // Start from 2 since installment receipt gets _1
        for(String chargeType : otherChargeTypeMap.keySet()) {
            List<ReceiptAllocation__c> chargeAllocations = otherChargeTypeMap.get(chargeType);
            System.debug('Processing charge type: ' + chargeType + ' with ' + chargeAllocations.size() + ' allocations');
            
            if(!chargeAllocations.isEmpty()) {
                // Calculate total amount for this charge type
                Decimal totalChargeAmount = 0;
                for(ReceiptAllocation__c alloc : chargeAllocations) {
                    totalChargeAmount += alloc.InstallmentAmountOtherChargeAmount__c;
                }
                ReceiptAcknowledgement__c chargeReceipt = createNewReceiptForOtherCharges(originalReceipt, chargeType, sequenceNumber, totalChargeAmount);
                newReceipts.add(chargeReceipt);
                
                // Create unique key: {ReceiptId}_{ChargeType} to avoid conflicts across multiple receipts
                String uniqueKey = originalReceipt.Id + '_' + chargeType;
                chargeTypeToReceiptMap.put(uniqueKey, chargeReceipt);
                
                System.debug('Created new receipt for ' + chargeType + ' with amount: ' + chargeReceipt.Amount__c + ' and sequence: ' + sequenceNumber);
                
                sequenceNumber++;
            }
        }
    }
    
    /**
     * Insert new receipts
     * @param newReceipts List of new receipts to insert
     */
    private void insertNewReceipts(List<ReceiptAcknowledgement__c> newReceipts) {
        System.debug('Inserting ' + newReceipts.size() + ' new receipts.');
        if(!newReceipts.isEmpty()) {
            insert newReceipts;
            System.debug('Successfully inserted ' + newReceipts.size() + ' new receipts.');
        }
    }
    
    /**
     * Create new allocations for the new receipts
     * @param bulkAllocationReceipts Original receipts
     * @param receiptAllocationMap Map of receipt allocations
     * @param chargeTypeToReceiptMap Map of charge type to receipt
     * @param newAllocations List to add new allocations to
     */
    private void createNewAllocations(List<ReceiptAcknowledgement__c> bulkAllocationReceipts,
                                    Map<Id, List<ReceiptAllocation__c>> receiptAllocationMap,
                                    Map<String, ReceiptAcknowledgement__c> chargeTypeToReceiptMap,
                                    List<ReceiptAllocation__c> newAllocations) {
        for(ReceiptAcknowledgement__c originalReceipt : bulkAllocationReceipts) {
            List<ReceiptAllocation__c> receiptAllocations = receiptAllocationMap.get(originalReceipt.Id);
            if(receiptAllocations == null || receiptAllocations.isEmpty()) {
                continue;
            }
            
            for(ReceiptAllocation__c alloc : receiptAllocations) {
                ReceiptAcknowledgement__c newReceipt = getNewReceiptForAllocation(originalReceipt, alloc, chargeTypeToReceiptMap);
                
                if(newReceipt != null) {
                    ReceiptAllocation__c newAlloc = createNewAllocation(alloc, newReceipt.Id);
                    newAllocations.add(newAlloc);
                    System.debug('Created new allocation for ' + alloc.TypeOfInvoice__c + ' with amount: ' + newAlloc.InstallmentAmountOtherChargeAmount__c);
                }
            }
        }
    }
    
    /**
     * Get the new receipt for an allocation
     * @param originalReceipt Original receipt
     * @param alloc Allocation to process
     * @param chargeTypeToReceiptMap Map of charge type to receipt
     * @return New receipt for the allocation
     */
    private ReceiptAcknowledgement__c getNewReceiptForAllocation(ReceiptAcknowledgement__c originalReceipt,
                                                               ReceiptAllocation__c alloc,
                                                               Map<String, ReceiptAcknowledgement__c> chargeTypeToReceiptMap) {
        ReceiptAcknowledgement__c newReceipt = null;
        
        if(alloc.TypeOfInvoice__c == 'Installment') {
            // Link to installment receipt
            String installmentKey = originalReceipt.Id + '_Installment';
            newReceipt = chargeTypeToReceiptMap.get(installmentKey);
        } else if(alloc.TypeOfInvoice__c == 'DLD' || 
                 alloc.TypeOfInvoice__c == 'RAK Municipality Fee' || 
                 alloc.TypeOfInvoice__c == 'ADM Fee') {
            // Link to other charge receipt
            String uniqueKey = originalReceipt.Id + '_' + alloc.TypeOfInvoice__c;
            newReceipt = chargeTypeToReceiptMap.get(uniqueKey);
        }
        
        return newReceipt;
    }
    
    /**
     * Insert new allocations
     * @param newAllocations List of new allocations to insert
     */
    private void insertNewAllocations(List<ReceiptAllocation__c> newAllocations) {
        System.debug('Inserting ' + newAllocations.size() + ' new allocations.');
        if(!newAllocations.isEmpty()) {
            insert newAllocations;
            System.debug('Successfully inserted ' + newAllocations.size() + ' new allocations.');
        }
    }
    
    /**
     * Call ReceiptCalloutHelper for new receipts
     * @param newReceipts List of new receipts
     */
    private void callReceiptCalloutHelper(List<ReceiptAcknowledgement__c> newReceipts) {
        if(!newReceipts.isEmpty()) {
            List<Id> newReceiptIds = new List<Id>();
            for (ReceiptAcknowledgement__c rec : newReceipts) {
                newReceiptIds.add(rec.Id);
            }
            System.debug('Calling ReceiptCalloutHelper.PrepareDataForCallout for ' + newReceiptIds.size() + ' new receipts.');
            ReceiptCalloutHelper.PrepareDataForCallout(newReceiptIds);
        }
    }
    
    /**
     * Helper method to create a new receipt acknowledgement for installments
     * @param original Original receipt acknowledgement
     * @param installmentAllocations List of installment allocations
     * @return ReceiptAcknowledgement__c New receipt for installments
     */
    private ReceiptAcknowledgement__c createNewReceiptForInstallments(ReceiptAcknowledgement__c original, List<ReceiptAllocation__c> installmentAllocations) {
        ReceiptAcknowledgement__c newReceipt = original.clone(false, true, false, false);
        newReceipt.Id = null;
        
        // Calculate total installment amount
        Decimal totalInstallmentAmount = 0;
        for(ReceiptAllocation__c alloc : installmentAllocations) {
            totalInstallmentAmount += alloc.InstallmentAmountOtherChargeAmount__c;
        }
        
        // Update fields for the new installment receipt
        newReceipt.Amount__c = totalInstallmentAmount;
        newReceipt.Remarks__c = original.Remarks__c + ' - Installments';
        newReceipt.Bulk_Installment_Allocation__c = false;
        newReceipt.Status__c = Constants.RECEIVED_PAYMENT_STATUS;
        newReceipt.ReceiptDate__c = Date.Today();
        newReceipt.ChequeReceived__c = true;
        newReceipt.OnlinePaymentCleared__c = true;
        newReceipt.StopCallout__c = false;
        
        // Add _1 to the reference number for installments
        if(String.isNotBlank(original.ReferenceNumber__c)) {
            newReceipt.ReferenceNumber__c = original.ReferenceNumber__c + '_1';
        }
        
        return newReceipt;
    }
    
    /**
     * Helper method to create a new receipt acknowledgement for other charges
     * @param original Original receipt acknowledgement
     * @param chargeType Type of charge for the new receipt
     * @param sequenceNumber Sequential number for the reference number
     * @param totalChargeAmount The total amount for this charge type (sum of allocations)
     * @return ReceiptAcknowledgement__c New receipt for other charges
     */
    private ReceiptAcknowledgement__c createNewReceiptForOtherCharges(ReceiptAcknowledgement__c original, String chargeType, Integer sequenceNumber, Decimal totalChargeAmount) {
        ReceiptAcknowledgement__c newReceipt = original.clone(false, true, false, false);
        newReceipt.Id = null;
        
        // Update fields for the new receipt
        newReceipt.Remarks__c = original.Remarks__c + ' - ' + chargeType;
        newReceipt.Bulk_Installment_Allocation__c = false;
        newReceipt.Status__c = Constants.RECEIVED_PAYMENT_STATUS;
        newReceipt.ReceiptDate__c = Date.Today();
        newReceipt.ChequeReceived__c = true;
        newReceipt.OnlinePaymentCleared__c = true;
        newReceipt.StopCallout__c = false;
        
        // Add sequence number to the reference number
        if(String.isNotBlank(original.ReferenceNumber__c)) {
            newReceipt.ReferenceNumber__c = original.ReferenceNumber__c + '_' + sequenceNumber;
        }
        
        // Set amount to the total charge amount for this charge type
        newReceipt.Amount__c = totalChargeAmount;
        
        return newReceipt;
    }
    
    /**
     * Helper method to create a new receipt allocation
     * @param original Original receipt allocation
     * @param newReceiptId New receipt acknowledgement ID
     * @return ReceiptAllocation__c New allocation
     */
    private ReceiptAllocation__c createNewAllocation(ReceiptAllocation__c original, Id newReceiptId) {
        ReceiptAllocation__c newAlloc = original.clone(false, true, false, false);
        
        // Clear the Id to make it a new record
        newAlloc.Id = null;
        
        // Update the receipt acknowledgement reference
        newAlloc.ReceiptAcknowledgement__c = newReceiptId;
        //newAlloc.DateOfApplication__c = Date.Today();
        //newAlloc.Unapply__c = false;
         // Set amount to the total charge amount for this charge type
         newAlloc.AmountApplied__c = original.InstallmentAmountOtherChargeAmount__c;
        
        return newAlloc;
    }
}