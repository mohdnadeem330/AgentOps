/**
* @File Name : Furniture_PaymentSplitDataWrapper.cls
* @Description :
* @Author : Harsh@Aldar
* @Last Modified By :
* @Last Modified On : June 11, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | June 11, 2025 |   | Initial Version
* 1.1 | June 11, 2025 |   | Updated VAT calculation for tax-inclusive amounts
**/
public class Furniture_PaymentSplitDataWrapper {
    
    // Wrapper class to hold payment split data
    public class PaymentSplitData {
        public Decimal totalAmountPaid { get; set; }
        public Decimal totalAmountReceived { get; set; }
        public Decimal totalStripeFee { get; set; }
        public Decimal vatAmount { get; set; }
        public Decimal vatPercentage { get; set; }
        public Decimal vendorAmount { get; set; }
        public Decimal vendorVAT { get; set; }
        public Decimal vendorStripeFee { get; set; }
        public Decimal vendorStripeFeeVAT { get; set; }
        public Decimal aldarAmount { get; set; }
        public Decimal aldarVAT { get; set; }
        public Decimal aldarStripeFee { get; set; }
        public Decimal aldarStripeFeeVAT { get; set; }
        public DateTime transactionDate { get; set; }
        public String remarks { get; set; }
        
        public PaymentSplitData() {
            // Initialize all amounts to 0
            this.totalAmountPaid = 0;
            this.totalAmountReceived = 0;
            this.totalStripeFee = 0;
            this.vatAmount = 0;
            this.vatPercentage = 0;
            this.vendorAmount = 0;
            this.vendorVAT = 0;
            this.vendorStripeFee = 0;
            this.vendorStripeFeeVAT = 0;
            this.aldarAmount = 0;
            this.aldarVAT = 0;
            this.aldarStripeFee = 0;
            this.aldarStripeFeeVAT = 0;
            this.remarks = '';
        }
    }
    
    // Inner classes for JSON deserialization
    public class StripeResponse {
        public Integer statusCode { get; set; }
        public String statusMessage { get; set; }
        public PaymentData data { get; set; }
    }
    
    public class PaymentData {
        public String id { get; set; }
        public Integer amount_received { get; set; }
        public String currencyCode { get; set; }
        public Long created { get; set; }
        public PaymentMetadata metadata { get; set; }
    }
    
    public class PaymentMetadata {
        public String orderTransactionId { get; set; }
        public String payerId { get; set; }
        public String salesforceRequestId { get; set; }
        public String Remarks { get; set; }
        public List<SplitData> splits { get; set; }
    }
    
    public class SplitData {
        public String id { get; set; }
        public Decimal amount { get; set; }
        public String currencyCode { get; set; }
        public String completedAt { get; set; }
        public SplitMetadata metadata { get; set; }
        public AccountSearchFields accountSearchFields { get; set; }
        public ClientData clientData { get; set; }
    }
    
    public class SplitMetadata {
        public String netAmount { get; set; }
        public String totalFee { get; set; }
        public String vatAmount { get; set; }
        public String chargeType { get; set; }
        public String clientData { get; set; }
    }
    
    public class AccountSearchFields {
        public String accountType { get; set; }
    }
    
    public class ClientData {
        public String trn { get; set; }
        public Integer marginPercent { get; set; }
        public String recipientName { get; set; }
        public String accountType { get; set; } 

    }
    
    public static PaymentSplitData deserializePaymentData(String jsonString) {
        try {
            // Parse the JSON response
            StripeResponse response = (StripeResponse) JSON.deserialize(jsonString, StripeResponse.class);
            
            if (response == null || response.data == null || response.data.metadata == null) {
                throw new IllegalArgumentException('Invalid JSON structure');
            }
            
            PaymentSplitData result = new PaymentSplitData();
            
            // Get VAT percentage from custom label
            Decimal vatPercentage = 5;// Decimal.valueOf(System.Label.DM_VatPercentage) / 100.0; // Convert to decimal (e.g., 5% = 0.05)
            
            // Total Amount Paid (amount_received in fils, convert to dirhams)
            result.totalAmountPaid = (response.data.amount_received / 100.0).setScale(2);
            
            // Convert Unix timestamp to DateTime
            result.transactionDate = DateTime.newInstance(response.data.created * 1000);

            //Remarks
            result.remarks = response.data.metadata.Remarks;
            
            // Initialize vendor and aldar margin percentages
            Decimal vendorMarginPercent = 0;
            Decimal aldarMarginPercent = 0;
            
            // Get total fees from splits data
            Decimal totalStripeFeeInFils = 0;
            Decimal totalStripeFeeVATInFils = 0;
            Decimal totalNetAmountInFils = 0;
            
            // Process splits data to get margin percentages and totals
            if (response.data.metadata.splits != null && !response.data.metadata.splits.isEmpty()) {
                
                for (SplitData split : response.data.metadata.splits) {
                    if (split.metadata != null && split.clientData != null) {
                        
                        // Get fees from first split (they should be same for all splits)
                        if (totalStripeFeeInFils == 0) {
                            totalStripeFeeInFils = Decimal.valueOf(split.metadata.totalFee);
                            totalStripeFeeVATInFils = Decimal.valueOf(split.metadata.vatAmount);
                            totalNetAmountInFils = Decimal.valueOf(split.metadata.netAmount);
                        }
                        
                        // Store margin percentages based on account type
                        //Updated by harsh@aldar 12/12/2025 - updated vendor margin%
                        if (split.clientData != null &&
                            split.clientData.accountType == 'vendor') {
                            vendorMarginPercent = split.clientData.marginPercent / 100.0;
                        }
                        if ( split.clientData != null) {
                            aldarMarginPercent = (100 - split.clientData.marginPercent)/100.0;
                        }
                       
                    }
                }
            }
            
            // Set total stripe fees (convert fils to dirhams)
            result.totalStripeFee = (totalStripeFeeInFils / 100.0).setScale(2);
            
            // Calculate Total Amount Received (Net) = Total Amount Paid - Total Stripe Fee
            result.totalAmountReceived = result.totalAmountPaid - result.totalStripeFee;
            
            // Calculate VAT Amount using tax-inclusive formula: VAT = Total Amount × VAT Rate / (100 + VAT Rate)
            // For 5% VAT: VAT = Total Amount × 5 / (100 + 5) = Total Amount × 5 / 105
            result.vatAmount = (result.totalAmountPaid * vatPercentage / (100 + vatPercentage)).setScale(2);
            result.vatPercentage = vatPercentage;
            
            // Calculate Gross Amount (Amount without VAT) = Total Amount Paid - VAT Amount
            Decimal grossAmount = result.totalAmountPaid - result.vatAmount;
            
            // Vendor calculations
            result.vendorAmount = (grossAmount * vendorMarginPercent).setScale(2);
            result.vendorVAT = (result.vatAmount * vendorMarginPercent).setScale(2);
            //result.vendorStripeFee = (result.totalStripeFee * vendorMarginPercent).setScale(2);
            //result.vendorStripeFeeVAT = ((totalStripeFeeVATInFils / 100.0) * vendorMarginPercent).setScale(2);
            
            // Update by Harsh@Aldar 25/08/2025 - Update Stripe fees to be handled by Aldar - Vendor Stripe fee contribution set to zero
            result.vendorStripeFee = 0;
            result.vendorStripeFeeVAT = 0;

            
            // Aldar calculations (remaining amounts)
            result.aldarAmount = (grossAmount - result.vendorAmount).setScale(2);
            result.aldarVAT = (result.vatAmount - result.vendorVAT).setScale(2);
            //result.aldarStripeFee = (result.totalStripeFee - result.vendorStripeFee).setScale(2);
            //result.aldarStripeFeeVAT = ((totalStripeFeeVATInFils / 100.0) - result.vendorStripeFeeVAT).setScale(2);

            // Update by Harsh@Aldar 25/08/2025 - Update Stripe fees VAT to be handled by Aldar - Vendor Stripe fee VAT contribution set to zero
            result.aldarStripeFee = (result.totalStripeFee).setScale(2);
            result.aldarStripeFeeVAT = (totalStripeFeeVATInFils / 100.0).setScale(2);
            
            return result;
            
        } catch (Exception e) {
            System.debug('Error deserializing payment data: ' + e.getMessage());
            // Log the exception
            Logger__c errorLog = LoggerService.addApexLog(
                e,
                'Furniture Payment Processing - Deserialization',
                'Furniture_PaymentSplitDataWrapper',
                'updatePaymentOnOrderAndQuote'
            );
            LoggerService.save(errorLog);
            throw new IllegalArgumentException('Failed to parse payment data: ' + e.getMessage());
        }
    }
}