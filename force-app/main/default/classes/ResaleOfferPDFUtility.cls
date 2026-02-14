public without sharing class ResaleOfferPDFUtility {
    /**
* SalesOfferDetails 
*
* Wrapper class used to store SalesOffer details
*/
    public class SalesOfferDetails{
        @AuraEnabled
        public Opportunity opportunityRecord {get; set;}
        @AuraEnabled
        public Unit__c unitRecord {get; set;}
        @AuraEnabled
        public Decimal originalPrice {get; set;} //Selling_Price__c
        @AuraEnabled
        public Decimal totalAmountPaidTillDate {get; set;} //TotalBilled__c
        @AuraEnabled
        public Decimal percentPaidTillDate {get; set;} // (Total Amount Paid till date / Original Price) x 100
        @AuraEnabled
        public Decimal outstandingAmount {get; set;} // Original Price - Total Amount Paid till date
        @AuraEnabled
        public Decimal listingPrice {get; set;} //Unit Listing Price
        
        @AuraEnabled
        public Decimal admFee {get; set;} //(Original Price x 2%) + 432 AED
        @AuraEnabled
        public Decimal transferAdminFee {get; set;} // 3969 AED
        @AuraEnabled
        public Decimal agencyFee {get; set;} // 2% of Listing Price
        @AuraEnabled
        public Decimal totalPayByBuyer {get; set;} // ListingPrice + ADM Fee + Transfer Admin  Fee + Agency Fee
        @AuraEnabled
        public Decimal payableToSeller {get; set;} // (Listing Price - Original Price) + Total Amount Paid till date
        @AuraEnabled
        public Decimal payableToAldar {get; set;} // Outstanding Amount + Agency Fees

        // @AuraEnabled
        // public List<InstallmentLines__c> installmentLinesList {get; set;}
        
        @AuraEnabled
        public List<InstallmentLine> installmentLinesList {get; set;}

        public SalesOfferDetails(){
        }
    }

    public class InstallmentLinesWrapper{
        @AuraEnabled
        public List<InstallmentLine> installmentLines {get; set;}
        
        public InstallmentLinesWrapper(List<InstallmentLines__c> installmentLinesList){
            this.installmentLines = this.installmentLines == null ? new List<InstallmentLine>() : this.installmentLines;
            if(installmentLinesList != null && !installmentLinesList.isEmpty()){
                for(InstallmentLines__c il : installmentLinesList){
                    this.installmentLines.add(new InstallmentLine(il));
                }
            }
            System.debug(this.installmentLines);
        }
    }

    public class InstallmentLine{
        @AuraEnabled
        public Id Id {get; set;}
        @AuraEnabled
        public Decimal InstallmentNumber {get; set;}
        @AuraEnabled
        public String InvoiceNumber {get; set;}
        @AuraEnabled
        public Decimal InstallmentPercentage {get; set;}
        @AuraEnabled
        public Date InstallmentDate {get; set;}
        @AuraEnabled
        public Decimal InstallmentAmount {get; set;}
        @AuraEnabled
        public Decimal AmountReceived {get; set;}
        @AuraEnabled
        public Decimal OutstandingAmount {get; set;}
        @AuraEnabled
        public String Description {get; set;}
        public InstallmentLine( InstallmentLines__c il ){
            this.Id = il.Id;
            this.InstallmentNumber = il.InstallmentNumber__c;
            this.InvoiceNumber = il.InvoiceNumber__c;
            this.InstallmentPercentage = il.InstallmentPercentage__c;
            this.InstallmentDate = il.InstallmentDate__c;
            this.InstallmentAmount = il.InstallmentAmount__c;
            this.AmountReceived = il.AmountReceived__c;
            this.OutstandingAmount = il.OutstandingAmount__c;
            this.Description = il.Description__c;
        }
    }

    @AuraEnabled(cacheable=false)
    public static void sendSalesOfferPDF(Id currentUnit, String customerName, Id opportunityId){

        Map<Id, Messaging.EmailFileAttachment> unitToAttachmentDetails = new Map<Id, Messaging.EmailFileAttachment>();

        PageReference pdf = Page.ResaleOfferPDF;

        pdf.getParameters().put('currentUnit',currentUnit);
        pdf.getParameters().put('customerName',customerName);
        pdf.getParameters().put('opportunityId',opportunityId);

        pdf.setRedirect(true);

        // Get Template
        String emailTemplateId = '';
        String relatedCustomerId = '';
        String orgWideEmailAddress = '';
        String unitCode = '';

        List<Opportunity> opportunityRecords = new List<Opportunity>();
    
        for(EmailTemplate tempRec:  [SELECT Id, DeveloperName FROM EmailTemplate WHERE DeveloperName = :Constants.ALDAR_OFFER_LETTER LIMIT 1]){
            emailTemplateId = tempRec.Id;
        }
    
        for(OrgWideEmailAddress tempRec: [SELECT Id, Address FROM OrgWideEmailAddress WHERE DisplayName= :Constants.ALDAR_PROPERTIES_ORGWIDEEMAIL LIMIT 1]){
            orgWideEmailAddress = tempRec.Id;
        }

        for(Opportunity thisOppRecord : [SELECT Id, Contact__c, StageName FROM Opportunity WHERE Id =:opportunityId LIMIT 1]){
            relatedCustomerId = thisOppRecord.Contact__c;
        }

        for(Unit__c thisUnit : [SELECT Id, PropertyId__c FROM Unit__c WHERE Id =: currentUnit LIMIT 1]){
            unitCode = thisUnit.PropertyId__c;
        }

        Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();

        efa.setFileName('Offer-'+unitCode+'-'+customerName+'-'+System.today().format()+'.pdf');

        efa.setBody(Test.isRunningTest()? blob.valueOf('Methods defined as TestMethod do not support getContent call') :pdf.getContent());
        unitToAttachmentDetails.put(currentUnit, efa);
        
        Messaging.SingleEmailMessage tempEmailInstance = new Messaging.SingleEmailMessage();

        tempEmailInstance = Utilities.getEmailInstance(relatedCustomerId,emailTemplateId,opportunityId,null,null,null,null,null,null,unitToAttachmentDetails.values(),orgWideEmailAddress);
        
        tempEmailInstance.setSaveAsActivity(true);
    
        Utilities.sendEmail(new list<Messaging.SingleEmailMessage>{tempEmailInstance});
    }
}