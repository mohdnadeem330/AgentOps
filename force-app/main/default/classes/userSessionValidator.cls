/***
Class       : userSessionValidator
Author      : Smaartt
Description : 
TestClass   : userSessionValidatorTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.       V1.0              09/05/24           Initial Version 
****************************************************************************************************************/
@RestResource (urlMapping = '/usersessionvalidator/*')
global with sharing class userSessionValidator {
    @HttpGET
    global static void doPost(){        
        RestRequest req = RestContext.request;
        String userid = RestContext.request.params.get('userid');     
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        if(userid == null || userid==''){           
            gen.writeStringField('message', 'userid is missing');
            gen.writeStringField('errorCode', 'Invalid_Data');
            Integer notFoundStatusCode = Integer.valueOf('400');
            RestContext.response.statusCode = notFoundStatusCode;
            
        }else{
            list<AuthSession> auth = [SELECT Id from AuthSession WHERE UsersId=:userid AND SessionType ='InternalServiceCall'];
               
            if(auth.size()>0){
                gen.writeBooleanField('isValid', true);
            }else{
                gen.writeBooleanField('isValid', false);
            }
                
        }
        gen.writeEndObject();
        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.responseBody = Blob.valueOf(gen.getAsString());
       
        
    }
    
}