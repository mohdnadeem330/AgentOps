@isTest public class DocuSignWrapperTest {
    @isTest static void testDocuSignWrapper() {   
        DocuSignWrapper.RecipientTabs recTab = new DocuSignWrapper.RecipientTabs();
        recTab.recipientSignHolder = 'Test';
        recTab.recipientDateHolder = 'Test';
        recTab.recipientInitialHolder = 'Test';
        recTab.recipientNameHolder = 'Test';
        recTab.recipientStampHolder = null;
        DocuSignWrapper.RecipientWrapper recWrp = new DocuSignWrapper.RecipientWrapper();
        recWrp.name = 'Test';
        recWrp.email = 'Test';
        recWrp.routingOrder = 10;
        recWrp.typeOfRecipient = 'Test';
        recWrp.signatureType = 'Test';
        recWrp.role = 'Test';
        recWrp.residentStatus = 'Test';
        recWrp.typeOfCustomer = 'Test';
        recWrp.signerType = 'Test';
        recWrp.isStampRequired = false;
        recWrp.aldarSign = null;
        recWrp.recipientPlaceHolders= null;
        DocuSignWrapper.AldarSignatories aldAss = new DocuSignWrapper.AldarSignatories();
        aldAss.name = 'Test';
        aldAss.email = 'Test';
        aldAss.routingOrder = 10;
        aldAss.typeOfRecipient = 'Test';
        aldAss.signatureType = 'Test';
        aldAss.role = 'Test';
        aldAss.residentStatus = 'Test';
        aldAss.typeOfCustomer = 'Test';
        aldAss.signerType = 'Test';
        aldAss.isStampRequired = false;
        aldAss.recipientPlaceHolders = null;
        DocuSignWrapper.EnvelopeWrapper docEnvolope = new DocuSignWrapper.EnvelopeWrapper();
        docEnvolope.templateId = null;
        docEnvolope.templateName = 'Test';
        docEnvolope.documentRecordId = 'Test';  
        docEnvolope.emailSubject = 'Test';
        docEnvolope.emailBody = 'Test';
        docEnvolope.contentVersion = null;
        docEnvolope.relatedObjectId = 'Test';
        docEnvolope.isNormalSign = true;
        docEnvolope.recipients = null;
        docEnvolope.aldarSignatoryList= null;
        new DocuSignWrapper.Signer(null,null,'test');      
    }  
}