@RestResource(urlMapping='/addAgent') 
global class BP_AddAgent extends BP_BaseRestResource {
    static String contactId; static String profileName = 'Agency User Login'; static Boolean isInsert = true;
    
    @HttpPost
    global static void createContact() {
        RestContextHandler handler = new RestContextHandler(false);
        try {
            Map<String, Object> responseData = new Map<String, Object>();
            
            String requestBody = handler.getRequestBody();
            if (!String.isEmpty(requestBody)) {
                System.debug('requestBody:::' + requestBody);
                Map<String, Object> requestData = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
                System.debug('requestData-->' + requestData);
                
                // Process profile image
                if(requestData.containsKey('profilePhotoCopy') && String.isNotBlank((String) requestData.get('profilePhotoCopy'))){
                String baseData = (String) requestData.get('profilePhotoCopy');
                Map<String, String> uploadResponse = uploadUserPicture(baseData);
                String imageUrl = uploadResponse.get('data');
                responseData.put('profileImageUrl', imageUrl); // Store profile image URL
                }
                
                // Process agency details
                String agencyId = requestData.containsKey('agencyName') && (String) requestData.get('agencyName') != null
                    ? (String) requestData.get('agencyName') : '';
                
                isInsert = requestData.containsKey('contactId') && (String) requestData.get('contactId') != null && (String) requestData.get('contactId') != ''
                    ? false : true;
                
                List<Account> listAgency = new List<Account>();
                if (String.isNotBlank(agencyId)) {
                    listAgency = [SELECT Id, BillingCountry, BillingState, BillingCity FROM Account WHERE Id = :agencyId];
                }
                
                if (listAgency != null && !listAgency.isEmpty()) {
                    ValidationWrapper validatedFieldWrapper = fieldValidationSuccess(requestData, listAgency[0]);
                    
                    if (validatedFieldWrapper.isSuccess) {
                        contactId = UtilitiesWithoutSharing.createAgent(requestData);
                        if ((String) requestData.get('role') == 'Agency Admin') {
                            profileName = 'Agency Admin Login';
                        }
                        
                        if (String.isNotBlank(contactId) && contactId != 'Duplicate' && String.isNotBlank(profileName)) {
                            Map<String, String> params = RestContext.request.params;
                            BP_AddAgent service = new BP_AddAgent();
                            ApiResponse response = service.processRequest(params, null);
                            
                            // Upload document
                            uploadDocument(requestBody, listAgency[0].Id, contactId);
                            
                            // Ensure response.data is a Map before merging
                            if (response.data instanceof Map<String, Object>) {
                                responseData.putAll((Map<String, Object>) response.data);
                            }
                            
                            // Fetch User details
                            User createdUser = [SELECT Id, ContactId, Username, FirstName, LastName, Email, CommunityNickname, 
                                                Alias, ProfileId, EmailEncodingKey, LanguageLocaleKey, LocaleSidKey, 
                                                IsActive, TimeZoneSidKey 
                                                FROM User WHERE ContactId = :contactId LIMIT 1];
                            
                            // Merge user fields into response directly
                            responseData.putAll((Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(createdUser)));
                            
                            handler.response.data = responseData;
                            handler.response.success = true;
                            handler.response.statusCode = response.statusCode;
                            handler.response.message = response.message;
                            
                        } else if (contactId == 'Duplicate') {
                            handler.response.success = false;
                            handler.response.statusCode = 200;
                            handler.response.message = 'Duplicate User with this Email address.';
                            handler.response.data = responseData;
                        }
                    } else {
                        handler.response.success = false;
                        handler.response.statusCode = 200;
                        handler.response.message = validatedFieldWrapper.message;
                        handler.response.data = responseData;
                    }
                } else {
                    handler.response.success = false;
                    handler.response.statusCode = 200;
                    handler.response.message = 'No agency found';
                    handler.response.data = responseData;
                }
            } else {
                handler.response.success = false;
                handler.response.statusCode = 500;
                handler.response.message = 'Invalid Request Body';
            }
        } catch (Exception ex) {
            handler.response.success = false;
            handler.response.statusCode = 500;
            handler.response.message = ex.getMessage();
        } 
        
        handler.finalize();
    }
    
    
    global override ApiResponse processRequest(Map<String, String> params, String requestBody) {
      //  try {
            if (isInsert) {
                return new ApiResponse(true, 200, 'Agent is created Successfully',
                                       UtilitiesWithoutSharing.createUserFromContact(contactId, false, profileName));
            } else {
                return new ApiResponse(true, 200, 'Agent details are updated Successfully',
                                       returnMethod(contactId, false, profileName));
            }
      /*  } catch (Exception e) {
            return new ApiResponse(false, 500, 'Agent insert/update failed ' + e.getMessage(), null);
        } */
    }
    
    public static Map<String,String> uploadUserPicture(string baseData){
        Map<String,String> returnResponse = new Map<String,String>();
        returnResponse.put('success','false');
        try{
            blob picData = EncodingUtil.base64Decode(baseData);
            ConnectApi.BinaryInput fileUpload = new ConnectApi.BinaryInput(picData,'image/jpg', 'ProfileImage');
            ConnectApi.Photo photoProfile = ConnectApi.UserProfiles.setPhoto(ConnectApi.Communities.getCommunities().communities[0].id, UserInfo.getUserId(), fileUpload);
            returnResponse.put('success','true');
            returnResponse.put('data',photoProfile.mediumPhotoUrl);
            returnResponse.put('msg','Image updated successfully, please allow sometime to get it reflected at all places');
        }catch(exception e){
            returnResponse.put('msg',e.getMessage());
        }
        system.debug('return photo res'+ returnResponse);
        return returnResponse;
        
    }
    
    private static String returnMethod(String contactId, boolean isActive, String profile){
        updateUserDetails(contactId, false, profileName);
        return contactId;
    }
    
    @future
    private static void updateUserDetails(String contactId, boolean isActive, String profile){
        UtilitiesWithoutSharing.updateExistingCommunityUser(contactId, false, profileName);
    }
    
    private static ValidationWrapper fieldValidationSuccess(Map<String,Object> requestData, Account agency){
        ValidationWrapper wrap = new ValidationWrapper();
        
        for(String fieldName : requestData.keySet()){
            if(checkRequiredFields?.containsKey(fieldName) && ((((String) requestData?.get(fieldName)) == null) || (((String) requestData?.get(fieldName)) == ''))){ wrap.isSuccess = false; wrap.message = checkRequiredFields?.get(fieldName) + ' is Required.'; break; }
        }
        
        if(wrap.isSuccess){
            for(String fieldName : requestData.keySet()){
                if(checkRequiredDocuments.containsKey(fieldName)){
                    if(fieldName == 'passportCopy' && (String) requestData.get('passportCopy') == ''){
                        wrap.isSuccess = false; wrap.message = checkRequiredDocuments.get(fieldName); break; 
                    }
                    system.debug('fieldName::'+fieldName);
                    system.debug('emiratesOrVisaCopy::'+requestData.get('emiratesOrVisaCopy'));
                    system.debug('checkRequiredDocuments.get(fieldName):::'+checkRequiredDocuments.get(fieldName));
                    
                    if(agency?.BillingCountry == 'United Arab Emirates'){
                        if(fieldName == 'emiratesOrVisaCopy' && (String) requestData.get('emiratesOrVisaCopy') == ''){
                            wrap.isSuccess = false;
                            wrap.message = checkRequiredDocuments.get(fieldName); 
                            break; 
                        }
                        
                        /*else if(fieldName == 'admCopy' && (String) requestData.get('role') == 'Agent' && 
                        ((agency?.BillingCity != null && agency?.BillingCity?.equalsIgnoreCase('Abu Dhabi')) || agency?.BillingState == 'Abu Dhabi') && 
                        ((String) requestData?.get('admCopy') == null || (String) requestData?.get('admCopy') == '')){
                            wrap.isSuccess = false; wrap.message = checkRequiredDocuments.get(fieldName); break; 
                        }
                        
                        else if(fieldName == 'reraCopy' && (String) requestData.get('role') == 'Agent' && 
                        ((agency?.BillingCity != null && agency?.BillingCity?.equalsIgnoreCase('Dubai')) || agency?.BillingState == 'Dubai') && 
                        ((String) requestData?.get('reraCopy') == null || (String) requestData?.get('reraCopy') == '')){
                            wrap.isSuccess = false; wrap.message = checkRequiredDocuments.get(fieldName); 
                            break; 
                        }*/
                    }
                }
            }
        }
        
        return wrap;
    }
    
    // @future
    public static void uploadDocument(String requestBody, Id agencyId, String contactId){
        Map<String,Object> requestData = (Map<String,Object>) JSON.deserializeUntyped(requestBody);
        List<Account> listAgency = [SELECT Id,BillingCountry,BillingState FROM Account WHERE Id = :agencyId];
        
        Set<String> setDocumentType = new Set<String>{'Passport Copy'};
            if(listAgency[0].BillingCountry == 'United Arab Emirates'){
                setDocumentType.add('Emirates ID Copy');
                if(listAgency[0].BillingState == 'Abu Dhabi'){
                    setDocumentType.add('ADM Card');
                }else if(listAgency[0].BillingState == 'Dubai'){
                    setDocumentType.add('RERA Broker Card');
                }
            }
        if(!setDocumentType.isEmpty()){
            for(Document__c eachDoc : [SELECT Id,DocumentType__c FROM Document__c WHERE Contact__c =:contactId AND DocumentType__c IN :setDocumentType]){
                for(String  base64Data : new List<String>{(String)requestData.get(documentTypeToRequestAPIName.get(eachDoc.DocumentType__c))}){
                    if(String.isNotBlank(base64Data)){
                    String base64 = base64Data;
                    String fileName = eachDoc.DocumentType__c+' - ' + System.today()+'.pdf';
                    
                    ContentVersion cv = createContentVersion(base64, filename);
                    ContentDocumentLink cd1 = createContentLink(cv.Id, eachDoc.Id);
                }
            }
        }
    }
    }
    
    private static ContentVersion createContentVersion(String base64, String filename) {
        Network network =  [SELECT Name, UrlPathPrefix, Id FROM Network WHERE Name = :Constants.URL_PREFIX];
        ContentVersion cv = new ContentVersion();
        cv.VersionData = EncodingUtil.base64Decode(base64);
        cv.Title = filename;
        cv.PathOnClient = filename;
        cv.NetworkId = network.Id;
        insert cv;
        return cv;
    }
    
    private static ContentDocumentLink createContentLink(String contentVersionId, String recordId) {
        if (contentVersionId == null || recordId == null) { return null; }
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =: contentVersionId].ContentDocumentId;
        cdl.LinkedEntityId = recordId;
        cdl.ShareType = 'V';
        insert cdl;
        return cdl;
    }
    
    public class ValidationWrapper{
        Boolean isSuccess = true;
        String message = '';
    }
    
    static Map<String,String> checkRequiredFields = new Map<String,String>{
        'agencyName' => 'Agency Name',
            'title' => 'Title',
            'firstName' => 'First Name',
            'lastName' => 'Last Name',
            'emailId' => 'Email Id',
            'role' => 'Role',
            'country' => 'Country',
            'phoneNumber' => 'Phone Number',
            'countryCode' => 'Country Code',
            //'birthdate'=> 'Birthdate',
            'emiratesID' => 'Emirates ID',
            'expiryDate' => 'Expiry Date',
            'nationality' => 'Nationality',
            'passportNumber' => 'Passport Number',
            'passportExpiryDate' => 'Passport Expiry Date'
            };
                
                static Map<String,String> checkRequiredDocuments = new Map<String,String>{
                    'passportCopy' => 'Passport Copy Document is required.', // mendatory for all
                        'admCopy' => 'ADM Document is Required for Abu Dhabi Agency/Agent.', // mendatory for agent (ABU DHABI ONLY)
                        'reraCopy' => 'RERA Document is Required for Dubai Agency/Agent.', // mendatory for agent (DUBAI ONLY)
                        'emiratesOrVisaCopy' => 'Emirates Id/ Visa copy is required for UAE Agency/Agent.' // mendatory for all agent/owner admin (UAE ONLY)
                        };
                            
                            static Map<String,String> documentTypeToRequestAPIName = new Map<String,String>{
                                'Passport Copy' => 'passportCopy',
                                    'Emirates ID Copy' => 'emiratesOrVisaCopy',      
                                    'ADM Card' => 'admCopy',
                                    'RERA Broker Card' => 'reraCopy'              
                                    };
}