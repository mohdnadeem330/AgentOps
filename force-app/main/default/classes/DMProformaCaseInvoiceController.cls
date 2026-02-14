/*Class     : DMProformaCaseInvoiceController
Author      : Smaartt
Description : 
TestClass   : 
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.        V1.0              10/12/25          Initial Version 
****************************************************************************************************************/
public class DMProformaCaseInvoiceController {
 public List<Payment_Request__c> payrecords { get; private set; }
    public Payment_Request__c payrecord { get; private set; }
    public Case caseRecord { get; private set; }
    
    public Decimal vatAmount { get; private set; }
    public Decimal amountWithoutVAT { get; private set; }
    public String amntinwords { get; private set; }
    
    public Map<Id, Decimal> vatAmountMap { get; private set; }
    public Map<Id, Decimal> amountWithoutVATMap { get; private set; }
    
    public Date TodaysDate { get; set; }
    public String TodaysDateFormatted { get; set; }
    public Date DateAfterThreeDays { get; set; }
    public String DateAfterThreeDaysFormatted { get; set; }
    public String transactionNumber { get; set; }
    public DateTime CurrentDateTime { get; set; }
    public String CurrentDateTimeFormatted { get; set; }
    
    public DMProformaCaseInvoiceController() {
        Id caseId = ApexPages.currentPage().getParameters().get('caseId');
        
        // Fetch the Case record separately
        if (caseId != null) {
            caseRecord = [SELECT Id, CaseNumber, Type, Account.Name, 
                         Account.BillingStreet, Account.BillingCity,
                         Account.BillingState, Account.BillingPostalCode,
                         Account.BillingCountry, Account.P_O_Box__c,
                         Account.Fax, Account.MobileNumber1__c,
                         Account.RegistrationNumber__c, Development_Name__c
                         FROM Case 
                         WHERE Id = :caseId 
                         LIMIT 1];
        }

        // Fetch all Payment Request records
        payrecords = [SELECT Id, Case__c, Case__r.Account.Name, Case__r.Account.BillingStreet,
                      Case__r.Development_Name__c, Case__r.Account.BillingCity, 
                      Case__r.Account.BillingState, Case__r.Account.BillingPostalCode,
                      Case__r.Account.BillingCountry, Case__r.Account.P_O_Box__c,
                      Case__r.Account.Fax, Case__r.Account.MobileNumber1__c, Case__r.Type,
                      Case__r.Account.RegistrationNumber__c, Amount__c, Name, Status__c,
                      Transaction_No__c, Transaction_Date__c, Payment_Date__c, 
                      Payment_Reference_No__c, Payment_Type__c, Case__r.CaseNumber,
                      Remittance_Name__c, ERP_Invoice_Number__c,Instalment_Date__c 
                      FROM Payment_Request__c 
                      WHERE Case__c = :caseId
                      ORDER BY CreatedDate];
        
        // Set first record for reference
        if (!payrecords.isEmpty()) {
            payrecord = payrecords[0];
        }
        
        // Initialize maps
        vatAmountMap = new Map<Id, Decimal>();
        amountWithoutVATMap = new Map<Id, Decimal>();
        
        TodaysDate = Date.today();
        CurrentDateTime = DateTime.now();
        CurrentDateTimeFormatted = formatDateTime(CurrentDateTime);
        
        if (payrecord != null) {
            if (payrecord.Payment_Type__c == 'online') {
                transactionNumber = ApexPages.currentPage().getParameters().get('transactionNo');
                TodaysDateFormatted = formatDate(TodaysDate);
            } else if (payrecord.Payment_Type__c == 'Wire Transfer') {
                transactionNumber = payrecord.Payment_Reference_No__c;
                TodaysDateFormatted = formatDate(payrecord.Payment_Date__c);
            } else {
                transactionNumber = payrecord.Payment_Reference_No__c;
                TodaysDateFormatted = formatDate(TodaysDate);
            }
        } else {
            TodaysDateFormatted = formatDate(TodaysDate);
        }
        
        DateAfterThreeDays = TodaysDate.addDays(3);
        DateAfterThreeDaysFormatted = DateAfterThreeDays.day() + '/' + 
                                      DateAfterThreeDays.month() + '/' + 
                                      DateAfterThreeDays.year();
        
        // Calculate VAT for each Payment Request and grand totals
        Decimal vatRate = Decimal.valueOf(Label.DM_VatPercentage);
        Decimal totalAmountSum = 0;
        Decimal totalVATSum = 0;
        Decimal totalWithoutVATSum = 0;
        
        for (Payment_Request__c pr : payrecords) {
            Decimal totalAmount = pr.Amount__c;
            Decimal amtWithoutVAT = totalAmount.divide((1 + vatRate), 2, RoundingMode.HALF_UP);
            Decimal vat = totalAmount - amtWithoutVAT;
            
            amountWithoutVATMap.put(pr.Id, amtWithoutVAT);
            vatAmountMap.put(pr.Id, vat);
            
            totalAmountSum += totalAmount;
            totalVATSum += vat;
            totalWithoutVATSum += amtWithoutVAT;
        }
        
        // Set properties for the single Case row in main table
        amountWithoutVAT = totalWithoutVATSum.setScale(2);
        vatAmount = totalVATSum.setScale(2);
        amntinwords = Utilities.amountInWords(totalAmountSum, 'Dirhams', 'Fils');
    }
    
    // Get total amount from all payment requests
    public Decimal getGrandTotal() {
        Decimal total = 0;
        for (Payment_Request__c pr : payrecords) {
            total += pr.Amount__c;
        }
        return total.setScale(2);
    }
    
    private String formatDate(Date dates) {
        return DateTime.newInstance(dates, Time.newInstance(0, 0, 0, 0)).format('dd-MMM-yyyy', 'en_US').toUpperCase();
    }
    
    private String formatDateTime(DateTime dateTimes) {
        return dateTimes.format('dd/MM/yyyy HH:mm');
    }
}