// Without sharing to allow CCA to populate Opportunity on RA object.
public without sharing class DarnaCheckController {
    
    //--- to get related Case record deails.
    @AuraEnabled
    public static Case getCaseDetails(string recordId){
        return [select Id, ContactId, Contact.Email, Contact.MobilePhone, Contact.DarnaMembershipNumber__c, AccountId, SalesOrder__c, SalesOrder__r.Opportunity__c, Unit__r.Project__r.ConceptId__c FROM Case WHERE Id = :recordId];
    }

    //--- to update DarnaMembershipNumber__c field in Contact object.
    @AuraEnabled
    public static void updateContactMembershipNumber(Contact contactRecord, String membershipNumber){
        contactRecord.DarnaMembershipNumber__c = membershipNumber;
        update contactRecord;
    }

    
    //--- Create Receipt Acknowledgement record from case 
   /* @AuraEnabled
    public static ReceiptAcknowledgement__c createReceiptAcknowledgementForRedemption(Case caseRecord, String paymentType, Decimal amount, String referenceNumber, String receiptNumber, String remarks, DarnaServices.RedeemPointsResponseModel response){
        
        ReceiptAcknowledgement__c newRA = new ReceiptAcknowledgement__c();
        newRA.Account__c = caseRecord.AccountId;
        newRA.Contact__c = caseRecord.ContactId;
        newRA.Amount__c = amount;
        newRA.Case__c = caseRecord.Id;
        newRA.PaymentType__c = paymentType;
        newRA.ReferenceNumber__c = referenceNumber;
        newRA.RedemptionReferenceCode__c = receiptNumber;
        newRA.Opportunity__c = caseRecord.SalesOrder__r.Opportunity__c;
        newRA.SalesOrder__c = caseRecord.SalesOrder__c;
        newRA.Remarks__c = remarks;
        newRA.JSONResponse__c = response.toString();
        insert newRA;

        caseRecord.Status = Constants.AWAITING_ACTION_CASE;
        update caseRecord;
        return newRA;
    } */
}