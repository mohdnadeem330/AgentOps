public with sharing class ResaleOfferApproveButtonController {
    @AuraEnabled
    public static String init(String recordId, String status) {
        if(!String.isBlank(recordId) || !String.isBlank(status)){
            try {
                update new Resale_Offers__c(
                        Id = recordId,
                        Status__c = status
                );
                return 'success';
            } catch (Exception e) {
                String errorMessage = e.getMessage(); // Get the exception message
                System.debug('#####errorMessage -- : '+errorMessage);
                String validationErrorMessage = '';
                String tothrowExpString = '';
                if (errorMessage.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                    validationErrorMessage = errorMessage.substringBetween('FIELD_CUSTOM_VALIDATION_EXCEPTION, ',': []'); // Extract the validation error message
                    System.debug('####validationErrorMessage: '+validationErrorMessage);
                    tothrowExpString = validationErrorMessage;
                // }else{
                //     tothrowExpString = errorMessage;
                }
                System.debug('###tothrowExpString: '+tothrowExpString);
                throw new AuraHandledException(tothrowExpString);
            }
        }
        return null;
    }
}