/*Class     : DMcaseInvoiceController
Author      : Smaartt
Description : 
TestClass   : DMcaseInvoiceControllerTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.        V1.0              23/02/24           Initial Version 
****************************************************************************************************************/
public class DMcaseInvoiceController {
    public  Payment_Request__c payrecord{ get; private set; }
    public Decimal vatAmount { get; private set; }
    public Decimal amountWithoutVAT { get; private set; }
    public string amntinwords{get; private set; }
    public Date TodaysDate { get; set; }
    public string TodaysDateFormatted { get; set; }
    public Date DateAfterThreeDays { get; set; }
    public String DateAfterThreeDaysFormatted { get; set; }
    public String transactionNumber { get; set; } 
    public DateTime CurrentDateTime { get; set; }
    public String CurrentDateTimeFormatted { get; set; }
    public DMcaseInvoiceController() {
        // Retrieve the Case record
        payrecord = [SELECT Id, Case__c,Case__r.Account.Name,Case__r.Account.BillingStreet,Case__r.Development_Name__c,Case__r.Account.BillingCity, Case__r.Account.BillingState, 
                     Case__r.Account.BillingPostalCode,Case__r.Account.BillingCountry,Case__r.Account.P_O_Box__c,Case__r.Account.Fax, Case__r.Account.MobileNumber1__c,Case__r.Type,Case__r.Account.RegistrationNumber__c,Case__r.Account.UAEVATRegisterNumber__c,Amount__c,Name, Status__c,Transaction_No__c,Transaction_Date__c,Payment_Date__c,
                     Payment_Reference_No__c,Payment_Type__c,Case__r.CaseNumber,Remittance_Name__c, ERP_Invoice_Number__c FROM Payment_Request__c 
                     WHERE Id = :ApexPages.currentPage().getParameters().get('id')];
        system.debug('Transaction number=='+payrecord.Payment_Reference_No__c);
        system.debug('Transacction date =='+payrecord.Payment_Date__c);
        TodaysDate = Date.today();
        
        CurrentDateTime = DateTime.now();
        CurrentDateTimeFormatted = formatDateTime(CurrentDateTime);
        if(payrecord.Payment_Type__c == 'online'){
        transactionNumber = ApexPages.currentPage().getParameters().get('transactionNo');     
          TodaysDateFormatted = formatDate(TodaysDate);
        }
        else if(payrecord.Payment_Type__c == 'Wire Transfer'){
          transactionNumber= payrecord.Payment_Reference_No__c;
          TodaysDateFormatted = formatDate(payrecord.Payment_Date__c);
        } 
        //added by Harsh@Aldar 29/09/2025
        else{
          transactionNumber= payrecord.Payment_Reference_No__c;
          TodaysDateFormatted = formatDate(TodaysDate);
        } 
        DateAfterThreeDays = TodaysDate.addDays(3);    
        DateAfterThreeDaysFormatted = formatDate(DateAfterThreeDays);
        //DateAfterThreeDaysFormatted =  DateAfterThreeDays.day() + '/' + DateAfterThreeDays.month() + '/' + DateAfterThreeDays.year();       
        /*vatAmount = payrecord.Amount__c * decimal.valueOf(label.DM_VatPercentage); // 5% of the total amount
        vatAmount = vatAmount.setScale(2);
        amountWithoutVAT = payrecord.Amount__c  - vatAmount;
        amountWithoutVAT = amountWithoutVAT.setScale(2);
        amntinwords = Utilities.amountInWords((payrecord.Amount__c), 'Dirhams', 'Fils');*/
        Decimal totalAmount = payrecord.Amount__c;
        Decimal vatRate = Decimal.valueOf(label.DM_VatPercentage); // 0.05
        
        amountWithoutVAT = totalAmount.divide((1 + vatRate), 2, RoundingMode.HALF_UP);
        vatAmount = totalAmount - amountWithoutVAT;
        
        amntinwords = Utilities.amountInWords(totalAmount, 'Dirhams', 'Fils');
    }
      private String formatDate(Date dates) {
        return DateTime.newInstance(dates, Time.newInstance(0, 0, 0, 0)).format('dd-MMM-yyyy', 'en_US').toUpperCase();
    }
      private String formatDateTime(DateTime dateTimes) {
        return dateTimes.format('dd/MM/yyyy HH:mm');
    }
}