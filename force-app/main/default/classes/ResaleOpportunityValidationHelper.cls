public without sharing class ResaleOpportunityValidationHelper {
    @InvocableMethod(label='Validate Opportunity' description='Validates the Opportunity.' category='Opportunity')
    public static List<Result> validateOpportunity(List<Request> requestList) {
        List<Result> results = new List<Result>();
        Set<Id> oppToRetrieve = new Set<Id>();

        // collect info from requests
        Integer index = 0;
        for (Request request : requestList) {
            if(request.oppRec != null){
                try {
                    results.add( new Result( request.oppRec ) );
                } catch (Exception ex) {
                    results.add( new Result( 'Error while validating opportunity : ' + ex.getMessage() ) );
                }
            }else{
                results.add(
                    new Result(
                        'Invalid Opportunity Record'
                    )
                );
            }
        }
        return results;
    }
    
    public class Request {
        @InvocableVariable(label='Opportunity Record' description='Opportunity Record' required=true)
        public Opportunity oppRec;
    }
    
    public class Result {
        @InvocableVariable(label='Valid for Agreement Signature')
        public Boolean validForAgreementSign;
        @InvocableVariable(label='Error Message')
        public String error;
        public Result(){
            this.error = 'Invalid Request';
        }
        public Result(String error){
            this.error = error;
        }
        public Result(Opportunity opp){
            String validationResult = validateResaleOpportuntiy(opp);
            if(validationResult != null && validationResult!= ''){
                this.validForAgreementSign = false;
                this.error = validationResult;
            }else{
                this.validForAgreementSign = true;
            }
        }
    }

    private static String validateResaleOpportuntiy(Opportunity opp) {
        String returnMessage = '';
        
        List<String> oppErrors = validate(opp.Id, opp, 'Opportunity', true, false, null, null);
        List<String> buyerErrors = validate(opp.AccountId, null, 'Account', true, true, 'Account__c', System.Label.AccountDocsToValidateResale);
        List<String> sellerErrors = validate(opp.Seller__c, null, 'Account', true, true, 'Account__c', System.Label.AccountDocsToValidateResale);

        returnMessage += formatError('Opportunity Errors', oppErrors, '\n', (returnMessage != null && returnMessage != '') );
        returnMessage += formatError('Buyer Account', buyerErrors, '\n', (returnMessage != null && returnMessage != '') );
        returnMessage += formatError('Seller Account', sellerErrors, '\n', (returnMessage != null && returnMessage != '') );

        return returnMessage;
    }

    private static List<String> validate(Id recordId, SObject record, String ObjectType, Boolean validateFields, Boolean validateDocuments, String docRelationshipName, String docTypesToValidate) {
        List<String> errorMessages = new List<String>();
        if( recordId == null ){
            errorMessages.add('Not populated');
        }else{
            if( validateFields ){
                String requiredFieldsMessage;
                if( ObjectType.trim().equalsIgnoreCase('Account') ){
                    requiredFieldsMessage = AccountService.accountsFieldsValidation(recordId);
                }else if( ObjectType.trim().equalsIgnoreCase('Opportunity') ){
                    Opportunity opp = (Opportunity) record;
                    // code to validate opportunity : ToDo
                    if(opp.SecurityDepositReceivedBuyer__c == false || opp.SecurityDepositReceived__c == false){
                        errorMessages.add('Security deposit should be received from both Buyer and Seller to proceed with MOU signature.');
                    }
                }
                
                if( requiredFieldsMessage !=null && requiredFieldsMessage !='' ){
                    errorMessages.add( 'Please populate values for '+ requiredFieldsMessage +' field(s).' );
                }
            }
            if( validateDocuments && docTypesToValidate != null ){
                String incompleteDocumentMessage;
                List<String> docsToValidate =  !(docTypesToValidate.trim().equalsIgnoreCase('OFF')) ? docTypesToValidate.normalizeSpace().replaceAll(', ', ',').split(',') : null;
                
                incompleteDocumentMessage = validateDocuments(recordId, docRelationshipName, docsToValidate);
                
                if( incompleteDocumentMessage !=null && incompleteDocumentMessage !='' ){
                    errorMessages.add( 'Please upload '+ incompleteDocumentMessage +' document(s).' );
                }
            }
        }
        return errorMessages;
    }

    private static String validateDocuments(Id parentId, String relationshipName, List<String> docTypesToValidate) {
        List<String> missingsDocTypes = new List<String>();
        if( parentId != null && docTypesToValidate != null){
            String query = 'SELECT Id, DocumentType__c, (SELECT Id FROM ContentDocumentLinks) FROM Document__c'
                         + ' WHERE '+ relationshipName + ' =: parentId'
                         + (!docTypesToValidate.isEmpty() ? ' AND DocumentType__c IN: docTypesToValidate' : '') ;
            for( Document__c doc: Database.query(query) ){
                if( doc.ContentDocumentLinks == null || doc.ContentDocumentLinks.isEmpty() ){
                    missingsDocTypes.add(doc.DocumentType__c);
                }
            }
        }
        return String.join(missingsDocTypes, ', ');
    }

    private static String formatError(String header, List<String> errors, String separator, Boolean newLine) {
        String returnMessage = ''; 
        if( errors != null && !errors.isEmpty() ){
            returnMessage += (newLine != null && newLine == true ? '\n' : '' );
            returnMessage += '<b>' + header + ': </b>\n';
            returnMessage += '<span class="slds-text-color_destructive">'+ String.join(errors, separator) + '</span>';
            returnMessage += '\n';
            returnMessage = '<p>' + returnMessage + '</p>';
        }
        return returnMessage;
    }
}