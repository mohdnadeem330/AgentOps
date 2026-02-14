public without sharing class RecaptchaController {
    private static String recaptchaSecretKey = Label.reCaptchaSecretKey;
    	public class CustomException extends Exception{}

    @AuraEnabled
    public static string insertRecord(SObject record, String recaptchaResponse){
        try {
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint('https://www.google.com/recaptcha/api/siteverify');
            request.setMethod('POST');
            request.setBody('secret=' + recaptchaSecretKey + '&response=' + recaptchaResponse );
            
            HttpResponse response = http.send( request );
            System.debug('Rohit recaptchacontroller: ' +response);
            if ( response.getStatusCode() == 200 ) {
                
                System.debug( 'Response Body is ' + response.getBody() );
                Map < String, Object > result = ( Map< String, Object > ) JSON.deserializeUntyped( response.getBody() );

                if ( result.containsKey( 'success' ) && result.get( 'success' ) == true) {

                    if ( result.containsKey( 'score' ) ) {
                        
                        String action = ( String )result.get( 'action' );
                        Decimal threshold = .4;
                        Decimal score = ( Decimal )result.get( 'score' );

                        if ( score > threshold ) {
                        
                            insert record;
                            return 'Success - v3';

                        }

                    } else {
                        
                        insert record;
                        return 'Success - v2';

                    }
                    
                } else {

                    return 'reCaptcha Failed';

                }
                
            }
            
            return 'Invalid Verification Request';

        }

        catch (Exception e) {
            system.debug('++ RECAPTHCA EXCEPTION - NAME '+e.getMessage());
            system.debug('++ RECAPTHCA EXCEPTION - '+e.getStackTraceString());
            throw new CustomException(e.getMessage());
            // throw new AuraHandledException(e.getMessage());
        }

    } 

}