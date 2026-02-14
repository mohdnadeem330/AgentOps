public class EmiratesIdValidationController {
    
    public static Contact makeCallout(Contact con){
        String Nationality = 'united_arab_emirates';
        MuleSoftSetting__mdt mulesoftAPI = Utilities.getMuleSoftDetails('EmiratesIdValidation');
        Organization org = Utilities.getOrganizationDetails();
        String endPointURL = mulesoftAPI.SandboxURL__c ;
        if(!org.IsSandbox){
            endPointURL = mulesoftAPI.ProductionURL__c ; 
        }
        Map<String, Object> requestBodyMap = new Map<String, Object>();
        requestBodyMap.put('emiratesIdNumber', con.NationalIdNumber__c);
        requestBodyMap.put('dateOfBirth', con.Birthdate);
        requestBodyMap.put('currentNationality',(con.Nationality__c.replace(' ', '_')).toLowerCase());
        String requestBody = JSON.serialize(requestBodyMap);
        system.debug('requestBody:::'+requestBody);        
        
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setHeader('Content-Type','application/json');
        request.setHeader('Authorization', mulesoftAPI.APIKey__c);
        request.setHeader('Accept','application/json');
        request.setHeader('Content-Type','application/json');
        request.setTimeout(60000);
        request.setEndpoint(endPointURL);
        request.setMethod(mulesoftAPI.Method__c);
        request.setbody(requestBody);
        HttpResponse response = new HttpResponse();
        response = http.send(request);
        system.debug('response:::'+response.getBody());
        system.debug('response:::'+response);
        system.debug('response:::'+response.getStatusCode());
        
        contact contact = new Contact();
        contact.Id = con.Id;
        if(response.getStatusCode() == 200 || response.getStatusCode() == 201){
            responseWrapper wrap = (responseWrapper) JSON.deserialize(response.getBody(), responseWrapper.class);
            system.debug('wrap:::'+wrap);
            //system.debug('wrap:::'+wrap.result?.currentNationality?.toLowerCase());
            
            //Nationality String need to compare instead india
            if(wrap.result != null && wrap.result.currentNationality.toLowerCase() == Nationality && (Date.valueOf(wrap.result.issueDate) < system.today() && system.today() < Date.valueOf(wrap.result.expiryDate)) ){
                contact.UAENationalityVerified__c = 'Yes';
            }else{
                contact.UAENationalityVerified__c = 'No';
            }
        }
        return contact;
    }
    
    public class responseWrapper{
        public result result;
    }
    public class result{
        public String emiratesIdNumber;
        public String dateOfBirth;
        public String currentNationality;
        public String issueDate;
        public String expiryDate;
        public String eidCardNumber;
    }
    
    @future(callout=true)
    public static void makeCalloutFuture(Set<Id> contactIdSet){
        List<Contact> contactListToUpdate = new List<Contact>();
        String BrokerRecordTypeId = Schema.SObjectType.COntact.getRecordTypeInfosByName().get(Constants.BROKER_AGENT).getRecordTypeId();
        String BrokerAgentStatus = 'Active';
        List<Contact> contactList = [SELECT
                                     Birthdate,
                                     Name,
                                     NationalIdNumber__c,
                                     Nationality__c,
                                     UAENationalityVerified__c
                                     FROM CONTACT 
                                     WHERE  Birthdate != null
                                     AND NationalIdNumber__c != null
                                     AND Nationality__c != null 
                                     AND RecordTypeId =: BrokerRecordTypeId 
                                     AND AgentStatus__c =:BrokerAgentStatus
                                     AND Id in: contactIdSet];
        
        for(Contact con: contactList){
            contactListToUpdate.add(makeCallout(con));
        }

        if(!contactListToUpdate.isEmpty()){
            update contactListToUpdate;
        }
    }
}