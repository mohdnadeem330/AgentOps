/*Class     : DMCaseOVERSTAYPdfHandler
Author      : Smaartt
Description : 
TestClass   : 
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.        V1.0              23/02/24           Initial Version 
****************************************************************************************************************/
public class DMCaseOVERSTAYPdfHandler {
    public Case caseRecord { get; private set; } 
    public Date TodaysDate { get; set; }
    public string TodaysDateFormatted { get; set; }
    public Date DateAfterThreeDays { get; set; }
    public String DateAfterThreeDaysFormatted { get; set; }
    public string amntinwords{get; private set; }
    public Decimal vatAmount { get; private set; }
    public Decimal amountWithoutVAT { get; private set; }
    public Payment_Request__c paymentRequest { get; private set; }
    public DMCaseOVERSTAYPdfHandler() {
        // Retrieve the Case record
        caseRecord = [SELECT Id, CaseNumber,Account.Name, Account.BillingStreet, Account.BillingCity, Account.BillingState, 
                      Account.BillingPostalCode,Account.BillingCountry,Account.P_O_Box__c,Account.Fax, Account.MobileNumber1__c, Project_Name__c, Request_Type__c, Service_Type__c,
                      CreatedDate,Development_Name__c,Type,
                      Account.RegistrationNumber__c,Total_Overstay_Amount__c,
CreatedBy.Email,CreatedBy.Name,CreatedBy.MobilePhone,(SELECT Id, Name, Amount__c, Status__c 
                                                                            FROM Payment_Requests__r where Pay_For__c ='Overstay')
                      FROM Case
                      WHERE Id = :ApexPages.currentPage().getParameters().get('id')];
         if (caseRecord.Payment_Requests__r.isEmpty()) {
            paymentRequest = null;
        } else {
            paymentRequest = caseRecord.Payment_Requests__r[0];
        }
        vatAmount = caseRecord.Total_Overstay_Amount__c * 0.05; // 5% of the total amount
        vatAmount = vatAmount.setScale(2);
        amountWithoutVAT = caseRecord.Total_Overstay_Amount__c  - vatAmount;
        amountWithoutVAT = amountWithoutVAT.setScale(2);
        TodaysDate = Date.today();
        TodaysDateFormatted = formatDate(TodaysDate);
         DateAfterThreeDays = TodaysDate.addDays(3);    
        DateAfterThreeDaysFormatted =  DateAfterThreeDays.day() + '/' + DateAfterThreeDays.month() + '/' + DateAfterThreeDays.year();
        amntinwords = Utilities.amountInWords((caseRecord.Total_Overstay_Amount__c), 'Dhirams', 'Fils');
    }
   
    private String formatDate(Date dates) {
        return DateTime.newInstance(dates, Time.newInstance(0, 0, 0, 0)).format('dd/MM/yyyy');
    }}