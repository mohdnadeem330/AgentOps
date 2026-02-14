/**
* @File Name : Furniture_ReceiptHelper.cls
* @Description :
* @Author : Harsh@Aldar
* @Last Modified By :
* @Last Modified On : June 11, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | June 11, 2025 |   | Initial Version
* 1.1 | June 11, 2025 |   | Updated to support corrected VAT calculation
**/

public class Furniture_ReceiptHelper {
    
    /**
     * Process Stripe payment response and print payment split details
     * @param jsonString - Stripe payment response JSON
     */
    public static CustomerCreateReceiptController.PaymentModel processPaymentResponse(String jsonString, String cpqQuoteId, 
                                                                                        String accountId, String invoice,
                                                                                        String receiptNumber) {
        try {
            // Deserialize the payment data using the wrapper
            Furniture_PaymentSplitDataWrapper.PaymentSplitData paymentData = 
                Furniture_PaymentSplitDataWrapper.deserializePaymentData(jsonString);
            
            // Print all payment split values
            printPaymentDetails(paymentData);

            CustomerCreateReceiptController.PaymentModel paymentModel = new CustomerCreateReceiptController.PaymentModel();         
        
            List<SBQQ__Quote__c> quoteList = [SELECT Id, SBQQ__Status__c, Sales_Order__c, SBQQ__Account__c 
                                                FROM SBQQ__Quote__c 
                                                WHERE Id = :cpqQuoteId];
            
            List<Account> PaidbyAcc = [SELECT Id, Name FROM Account WHERE Id=: accountId LIMIT 1];

            Decimal aldarTotal = (paymentData.aldarAmount + paymentData.aldarVAT).setScale(2);
            
            ReceiptAcknowledgement__c receipt = new ReceiptAcknowledgement__c();
            receipt.PaymentType__c = 'Online';
            if(quoteList.size()>0){
                receipt.CPQQuote__c = quoteList[0].Id;
            }
            receipt.Account__c = AccountId;
            receipt.Remarks__c = paymentData.Remarks;
            //receipt.ReferenceNumber__c = paymentId;
            receipt.MaturityDate__c =  Date.today();
            receipt.Status__c = 'Received';            
            receipt.InvoiceNumber__c= invoice;
            receipt.Amount__c = aldarTotal;
            //receipt.ClearedDate__c = Date.today();
            receipt.Receipt_Type__c = 'Charge Fee';
            receipt.BankName__c = 'Abu Dhabi Commercial Bank';
            receipt.ReceiptDate__c = Date.Today();
            receipt.ReferenceNumber__c = 'CC-'+receiptNumber;
            receipt.ChequeReceived__c = true;
            receipt.OnlinePaymentCleared__c = true;
            receipt.JSONResponse__c = jsonString;
            receipt.Payment_Gateway__c ='Stripe';
            
            if(PaidbyAcc.size()>0){
                receipt.PaidBy__c = PaidbyAcc[0].Name;
                list<contact> con = [SELECT Id,Name FROM contact WHERE AccountId =: PaidbyAcc[0].Id];                   
                if(con.size()>0){                   
                    receipt.Contact__c = con[0].Id;
                } 
            }            
            insert receipt; 

            updatePaymentOnOrderAndQuote(paymentData, cpqQuoteId);

            ReceiptAcknowledgement__c newReceipt = CustomerServiceUtility.getReceiptAcknowledgementDetail(' (Id = \'' + receipt.Id + '\') ')[0];
            paymentModel.receiptId = newReceipt.Id;
            paymentModel.receiptDetails = newReceipt;
            return paymentModel;
            
        } catch (Exception e) {
            System.debug('Error processing payment response: ' + e.getMessage());
            // Log the exception
            Logger__c errorLog = LoggerService.addApexLog(
                e,
                'Furniture Payment Processing - Deserialization - Quote and Order Updation - Receipt Creation',
                'Furniture_ReceiptHelper',
                'processPaymentResponse'
            );
            LoggerService.save(errorLog);
            throw e;
        }
    }

    /**
    * Updates SBQQ__Quote__c record with payment split data from Stripe payment response
    * Maps payment amounts, fees, VAT calculations, and transaction details to quote fields
    * 
    * @param paymentData - Wrapper containing parsed payment split data including:
    *                     - Total amounts (paid/received), Stripe fees, VAT amounts
    *                     - Vendor split details (amount, VAT, Stripe fees)
    *                     - Aldar split details (amount, VAT, Stripe fees)
    *                     - Transaction timestamp
    * @param cpqQuoteId - Salesforce ID of the SBQQ__Quote__c record to update
    * 
    * @throws DmlException if quote update fails
    * 
    * Field Mappings:
    * - Total_Amount_Paid__c ← totalAmountPaid (tax inclusive amount)
    * - Total_Amount_Received__c ← totalAmountReceived (net amount after fees)
    * - Total_Stripe_Fee__c ← totalStripeFee (combined Stripe processing fees)
    * - VAT_Amount__c ← vatAmount (5% VAT calculated from total amount)
    * - Aldar_Amount__c ← aldarAmount (Aldar's portion of payment)
    * - Vendor_Amount__c ← vendorAmount (Vendor's portion of payment)
    * - Transaction_Date__c ← transactionDate (payment processing timestamp)
    */
    private static void updatePaymentOnOrderAndQuote(Furniture_PaymentSplitDataWrapper.PaymentSplitData paymentData, String cpqQuoteId){
        
        SBQQ__Quote__c thisQuote = new SBQQ__Quote__c();
        
        thisQuote.Id = cpqQuoteId;
        thisQuote.Total_Amount_Paid__c = paymentData.totalAmountPaid.setScale(2);
        thisQuote.Total_Amount_Received__c = paymentData.totalAmountReceived.setScale(2);
        thisQuote.Total_Stripe_Fee__c = paymentData.totalStripeFee.setScale(2);
        thisQuote.VAT_Amount__c = paymentData.vatAmount.setScale(2);
        //thisQuote.Total_Tax__c = paymentData.vatPercentage.setScale(2);

        thisQuote.Aldar_Amount__c = paymentData.aldarAmount.setScale(2);
        thisQuote.Aldar_Stripe_Fee__c = paymentData.aldarStripeFee.setScale(2);
        thisQuote.Aldar_Stripe_Fee_VAT__c = paymentData.aldarStripeFeeVAT.setScale(2);
        thisQuote.Aldar_VAT__c = paymentData.aldarVAT.setScale(2);

        thisQuote.Vendor_Amount__c = paymentData.vendorAmount.setScale(2);
        thisQuote.Vendor_Stripe_Fee__c = paymentData.vendorStripeFee.setScale(2);
        thisQuote.Vendor_Stripe_Fee_VAT__c = paymentData.vendorStripeFeeVAT.setScale(2);
        thisQuote.Vendor_VAT__c = paymentData.vendorVAT.setScale(2);

        thisQuote.Transaction_Date__c = paymentData.transactionDate;
        thisQuote.SBQQ__Status__c = 'Approved';
        try {
            update thisQuote;
            
            System.debug('Quote updated successfully: ' + cpqQuoteId);
        } catch (Exception e) {
            System.debug('Error updating quote: ' + e.getMessage());
            // Log the exception
            Logger__c errorLog = LoggerService.addApexLog(
                e,
                'Furniture Payment Processing - Deserialization - Update Payment on Quote - Receipt Creation',
                'Furniture_ReceiptHelper',
                'updatePaymentOnOrderAndQuote'
            );
            LoggerService.save(errorLog);
            throw e;
        }

        checkOrderandUpdate(paymentData, cpqQuoteId);
    }

    private static void checkOrderandUpdate(Furniture_PaymentSplitDataWrapper.PaymentSplitData paymentData, String cpqQuoteId){
        List<Order> orderList = [SELECT Id, SBQQ__Quote__c FROM Order WHERE SBQQ__Quote__c =: cpqQuoteId ORDER BY CreatedDate DESC];
        
        if(orderList != null && orderList.size() > 0){
            
            Order thisOrder = new Order();
            thisOrder.Id = orderList[0].Id;
            thisOrder.Total_Amount_Paid1__c = paymentData.totalAmountPaid.setScale(2);
            thisOrder.Total_Amount_Received1__c = paymentData.totalAmountReceived.setScale(2);
            thisOrder.Total_Stripe_Fee1__c = paymentData.totalStripeFee.setScale(2);
            thisOrder.VAT_Amount1__c = paymentData.vatAmount.setScale(2);
            //thisOrder.Total_Tax__c = paymentData.vatAmount.setScale(2);
            //thisOrder.Tax_Percentage__c = paymentData.vatPercentage.setScale(2);

            thisOrder.Aldar_Amount1__c = paymentData.aldarAmount.setScale(2);
            thisOrder.Aldar_Stripe_Fee1__c = paymentData.aldarStripeFee.setScale(2);
            thisOrder.Aldar_Stripe_Fee_VAT1__c = paymentData.aldarStripeFeeVAT.setScale(2);
            thisOrder.Aldar_VAT1__c = paymentData.aldarVAT.setScale(2);

            thisOrder.Vendor_Amount1__c = paymentData.vendorAmount.setScale(2);
            thisOrder.Vendor_Stripe_Fee1__c = paymentData.vendorStripeFee.setScale(2);
            thisOrder.Vendor_Stripe_Fee_VAT1__c = paymentData.vendorStripeFeeVAT.setScale(2);
            thisOrder.Vendor_VAT1__c = paymentData.vendorVAT.setScale(2);

            thisOrder.Transaction_Date1__c = paymentData.transactionDate;

            thisOrder.Expected_Delivery_Date__c = System.today().addDays(84);
            thisOrder.Sub_Status__c = 'Order Placed';
            
            try {
                update thisOrder;
                
                processReceiptAcknowledgements(new List<Order> {thisOrder}, new Set<Id> {cpqQuoteId});
                System.debug('Order updated successfully: ' + cpqQuoteId);
            } catch (Exception e) {
                System.debug('Error updating order: ' + e.getMessage());
                // Log the exception
                Logger__c errorLog = LoggerService.addApexLog(
                    e,
                    'Furniture Payment Processing - Deserialization - Update Payment on Order - Receipt Creation',
                    'Furniture_ReceiptHelper',
                    'checkOrderandUpdate'
                );
                LoggerService.save(errorLog);
                throw e;
            }
        }
    }
    
    /**
     * Print payment split details to debug log
     * @param paymentData - Deserialized payment split data
     */
    private static void printPaymentDetails(Furniture_PaymentSplitDataWrapper.PaymentSplitData paymentData) {
        System.debug('=== PAYMENT SPLIT DETAILS ===');
        System.debug('Total Amount Paid (Tax Inclusive): AED ' + formatAmount(paymentData.totalAmountPaid));
        System.debug('Total Amount Received (Net): AED ' + formatAmount(paymentData.totalAmountReceived));
        System.debug('Total Stripe Fee: AED ' + formatAmount(paymentData.totalStripeFee));
        System.debug('VAT Amount (Tax Inclusive Calculation): AED ' + formatAmount(paymentData.vatAmount));
        System.debug('Gross Amount (Excluding VAT): AED ' + formatAmount(paymentData.totalAmountPaid - paymentData.vatAmount));
        System.debug('');
        
        System.debug('=== VENDOR DETAILS ===');
        System.debug('Vendor Amount: AED ' + formatAmount(paymentData.vendorAmount));
        System.debug('Vendor VAT: AED ' + formatAmount(paymentData.vendorVAT));
        System.debug('Vendor Stripe Fee: AED ' + formatAmount(paymentData.vendorStripeFee));
        System.debug('Vendor Stripe Fee VAT: AED ' + formatAmount(paymentData.vendorStripeFeeVAT));
        System.debug('Vendor Total (Amount + VAT): AED ' + formatAmount(paymentData.vendorAmount + paymentData.vendorVAT));
        System.debug('');
        
        System.debug('=== ALDAR DETAILS ===');
        System.debug('Aldar Amount: AED ' + formatAmount(paymentData.aldarAmount));
        System.debug('Aldar VAT: AED ' + formatAmount(paymentData.aldarVAT));
        System.debug('Aldar Stripe Fee: AED ' + formatAmount(paymentData.aldarStripeFee));
        System.debug('Aldar Stripe Fee VAT: AED ' + formatAmount(paymentData.aldarStripeFeeVAT));
        System.debug('Aldar Total (Amount + VAT): AED ' + formatAmount(paymentData.aldarAmount + paymentData.aldarVAT));
        System.debug('');
        
        System.debug('=== VERIFICATION ===');
        Decimal totalGrossAmount = paymentData.vendorAmount + paymentData.aldarAmount;
        Decimal totalVATAmount = paymentData.vendorVAT + paymentData.aldarVAT;
        Decimal calculatedTotal = totalGrossAmount + totalVATAmount;
        System.debug('Total Gross Amount (Vendor + Aldar): AED ' + formatAmount(totalGrossAmount));
        System.debug('Total VAT Amount (Vendor + Aldar): AED ' + formatAmount(totalVATAmount));
        System.debug('Total VAT from Main Calculation: AED ' + formatAmount(paymentData.vatAmount));
        System.debug('VAT Calculation Verification: ' + formatAmount(paymentData.totalAmountPaid) + ' × 5% ÷ 105% = ' + formatAmount(paymentData.vatAmount));
        System.debug('Calculated Total (Should match Amount Paid): AED ' + formatAmount(calculatedTotal));
        System.debug('Amount Paid: AED ' + formatAmount(paymentData.totalAmountPaid));
        System.debug('Difference: AED ' + formatAmount(paymentData.totalAmountPaid - calculatedTotal));
        System.debug('');
        
        System.debug('Transaction Date: ' + paymentData.transactionDate.format('yyyy-MM-dd HH:mm:ss'));
        System.debug('=== END PAYMENT DETAILS ===');
    }
    
    /**
     * Format amount to 2 decimal places for display
     * @param amount - Decimal amount to format
     * @return formatted amount string
     */
    private static String formatAmount(Decimal amount) {
        if (amount == null) {
            return '0.00';
        }
        return amount.setScale(2).toPlainString();
    }
    
    /**
     * Get payment split data without printing (for external use)
     * @param jsonString - Stripe payment response JSON
     * @return PaymentSplitData object
     */
    public static Furniture_PaymentSplitDataWrapper.PaymentSplitData getPaymentSplitData(String jsonString) {
        return Furniture_PaymentSplitDataWrapper.deserializePaymentData(jsonString);
    }
    
    /**
     * Validate payment split calculations
     * @param paymentData - Payment split data to validate
     * @return true if calculations are correct, false otherwise
     */
    public static Boolean validatePaymentSplit(Furniture_PaymentSplitDataWrapper.PaymentSplitData paymentData) {
        if (paymentData == null) {
            return false;
        }
        
        // Verify that vendor + aldar amounts equal total gross amount
        Decimal totalGrossAmount = paymentData.vendorAmount + paymentData.aldarAmount;
        Decimal expectedGrossAmount = paymentData.totalAmountPaid - paymentData.vatAmount;
        
        // Verify that vendor + aldar VAT equals total VAT
        Decimal totalVATAmount = paymentData.vendorVAT + paymentData.aldarVAT;
        
        // Allow for small rounding differences (within 0.01 AED)
        Boolean grossAmountValid = Math.abs(totalGrossAmount - expectedGrossAmount) <= 0.01;
        Boolean vatAmountValid = Math.abs(totalVATAmount - paymentData.vatAmount) <= 0.01;
        
        if (!grossAmountValid || !vatAmountValid) {
            System.debug('Payment split validation failed:');
            System.debug('Gross Amount Valid: ' + grossAmountValid + ' (Expected: ' + expectedGrossAmount + ', Actual: ' + totalGrossAmount + ')');
            System.debug('VAT Amount Valid: ' + vatAmountValid + ' (Expected: ' + paymentData.vatAmount + ', Actual: ' + totalVATAmount + ')');
            return false;
        }
        
        return true;
    }

    /**
    * Processes receipt acknowledgements for orders with quotes
    * @param orders List of orders to process
    * @param quoteIds Set of quote IDs to query receipts for
    */
    public static void processReceiptAcknowledgements(List<Order> orders, Set<Id> quoteIds) {
        // Query all relevant receipts in one go
        Map<Id, List<ReceiptAcknowledgement__c>> quoteToReceiptsMap = new Map<Id, List<ReceiptAcknowledgement__c>>();
        
        List<ReceiptAcknowledgement__c> receipts = [
            SELECT Id, CPQQuote__c, Order__c
            FROM ReceiptAcknowledgement__c
            WHERE CPQQuote__c IN :quoteIds 
            AND Order__c = NULL
            LIMIT 10000 // Governor limit protection
        ];
        // Group receipts by quote ID
        for (ReceiptAcknowledgement__c receipt : receipts) {
            if (!quoteToReceiptsMap.containsKey(receipt.CPQQuote__c)) {
                quoteToReceiptsMap.put(receipt.CPQQuote__c, new List<ReceiptAcknowledgement__c>());
            }
            quoteToReceiptsMap.get(receipt.CPQQuote__c).add(receipt);
        }
        
        // Update receipts with order references
        List<ReceiptAcknowledgement__c> receiptsToUpdate = new List<ReceiptAcknowledgement__c>();
        
        for (Order order : orders) {
            if (order.SBQQ__Quote__c != null && quoteToReceiptsMap.containsKey(order.SBQQ__Quote__c)) {
                List<ReceiptAcknowledgement__c> relatedReceipts = quoteToReceiptsMap.get(order.SBQQ__Quote__c);
                
                for (ReceiptAcknowledgement__c receipt : relatedReceipts) {
                    receipt.Order__c = order.Id;
                    receiptsToUpdate.add(receipt);
                }
            }
        }

        
        // Perform DML operation with error handling
        if (!receiptsToUpdate.isEmpty()) {
            try {
                Database.SaveResult[] results = Database.update(receiptsToUpdate, false);
                // Log any partial failures
                for (Integer i = 0; i < results.size(); i++) {
                    if (!results[i].isSuccess()) {
                        System.debug(LoggingLevel.ERROR, 
                            'Failed to update receipt ' + receiptsToUpdate[i].Id + 
                            ': ' + results[i].getErrors()[0].getMessage());
                    }
                }
            } catch (DmlException e) {
                System.debug(LoggingLevel.ERROR, 'DML Error updating receipts: ' + e.getMessage());
                // Consider adding custom exception handling based on business requirements
            }
        }
    }
}