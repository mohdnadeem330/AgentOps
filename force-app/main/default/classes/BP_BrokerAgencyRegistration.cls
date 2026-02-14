@RestResource (urlMapping = '/createBrokerAgency')
global with sharing class BP_BrokerAgencyRegistration extends BP_BaseRestResource {
    static String BROKER_AGENT_RECORD_TYPE_ID = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByDeveloperName().get('BrokerAgent').getRecordTypeId();
    static String NEW_REGISTRATION = 'NEW_REGISTRATION';
    static String RESEND_OTP = 'RESEND_OTP';

    @HttpPost
    global static void start(){
        RestContextHandler handler = new RestContextHandler(false);
        try {
            Map<String, String> params = RestContext.request.params;
            System.debug('test '+RestContext.request.requestBody);
            String requestBody = RestContext.request.requestBody.toString();   
            system.debug('requestBody::::'+requestBody);
            
            if(!String.isEmpty(requestBody)){   
                BP_BrokerAgencyRegistration service = new BP_BrokerAgencyRegistration();
                ApiResponse response = service.processRequest(params, requestBody);
                
                handler.response.data = response.data;
                handler.response.success = response.success;
                handler.response.statusCode = response.statusCode;
                handler.response.message = response.message;
                
            }else {
                handler.response.success = false;
                handler.response.statusCode = 500;
                handler.response.message = 'Invalid Request Body';
            }
        } catch(Exception ex){ handler.response.success = false; handler.response.statusCode = 500; handler.response.message = ex.getMessage(); } 
        handler.finalize();
    }
    
    global override ApiResponse processRequest(Map<String, String> params, String requestBody) {
        try {
            AgencyRegistrationWrapper wrap = (AgencyRegistrationWrapper) System.JSON.deserialize(requestBody, AgencyRegistrationWrapper.class);
            
            if(String.isBlank(wrap.type)){
                if(String.isBlank(wrap.sObjectId)){
                    return new ApiResponse(false, 400, 'Broker Agency creation failed: ' + 'type can not be empty', null);
                }else{
                    return new ApiResponse(false, 400, 'Broker Agency Resend OTP failed: ' + 'type can not be empty', null);
                }
            }else{
                if(wrap.type.equalsIgnoreCase(NEW_REGISTRATION)){
                     // Determine if this is an update or an insert
                    Boolean isUpdate = wrap.serviceRequest.Id != null;
                    
                    // Perform validation only for insert operations
                    if (!isUpdate) {
                        ValidationWrapper validWrap = validationBeforeSubmit(wrap);
                        if (!validWrap.isSuccess) {
                            return new ApiResponse(false, 400, 'Broker Agency creation failed: ' + validWrap.message, null);
                        }
                    }
                    
                    return new ApiResponse(true, 200, isUpdate ? 'Broker Agency Updated Successfully' : 'Broker Agency Created Successfully', execute(wrap));
                }else if(wrap.type.equalsIgnoreCase(RESEND_OTP)){
                    if(String.isBlank(wrap.sObjectId)){
                        return new ApiResponse(false, 400, 'Broker Agency Resend OTP failed: ' + 'sObjectId can not be empty', null);
                    }else{
                        String status = resendOtp(wrap.sObjectId);
                        if(status == 'Success'){
                            return new ApiResponse(true, 200,'Broker Agency OTP Sent Successfully', null);
                        }else{
                            return new ApiResponse(false, 400, 'Broker Agency Resend OTP failed: ' + status, null);
                        }
                    }
                }else{
                    return new ApiResponse(false, 400, 'Broker Agency creation failed: ' + 'Invalid Type value', null);
                }
            }
        } catch (Exception e) {
            return new ApiResponse(false, 400, 'Broker Agency processing failed: ' + e.getMessage(), null);
        }
    }
    
    public static ValidationWrapper validationBeforeSubmit(AgencyRegistrationWrapper wrap){
        ValidationWrapper validWrap = new ValidationWrapper();

        if(String.isBlank(wrap?.serviceRequest?.TradeCommercialLicenseNumber__c)){ validWrap.isSuccess = false; validWrap.message = 'Trade License number is invalid'; return validWrap; }

        // should be false for agency registration (Cover SR Request and Agency both)
        Boolean hasActiveTRAgency = BrokerAgencyRegistrationController.validateTradeLicenseNumber(wrap?.serviceRequest?.TradeCommercialLicenseNumber__c?.deleteWhitespace());
        
        if(hasActiveTRAgency){ validWrap.isSuccess = false; validWrap.message = 'There is already have Agency with this Trade License number.'; return validWrap; }

        Set<String> setPartnerEmailIds = new Set<String>();
        Set<String> setPartnerMobileNumber = new Set<String>();

        if(validWrap.isSuccess && wrap.partnerOwners != null && !wrap.partnerOwners.isEmpty()){
            for(PartnerOwnerWrapper eachTeam : wrap.partnerOwners){
                if(String.isNotBlank(eachTeam.partnerOwner.EmailAddress__c)){
                    setPartnerEmailIds.add(eachTeam.partnerOwner.EmailAddress__c);
                }
                
                if(String.isNotBlank(eachTeam.partnerOwner.MobileNumber__c)){
                    setPartnerMobileNumber.add(eachTeam.partnerOwner.MobileNumber__c);
                }
            }
        }

        // BlacklistedDomains taking care by UI (Personal Email Domains)

        // check for admin email to check existing user
        if(validWrap.isSuccess && String.isNotBlank(wrap?.agencyAdmin?.EmailAddress__c)){
            Integer getActiveContacts = validateEmail(new Set<String>{wrap?.agencyAdmin?.EmailAddress__c});
            
            if(getActiveContacts > 0){ validWrap.isSuccess = false; validWrap.message = 'There is already Agency Admin/ User with Admin Email Address.'; return validWrap; }
        
            if(validWrap.isSuccess){
                getActiveContacts = validateEmailForSR(new Set<String>{wrap?.agencyAdmin?.EmailAddress__c});
                if(getActiveContacts > 0){ validWrap.isSuccess = false; validWrap.message = 'There is already Service Request associated with Admin/ User with Admin Email Address.'; return validWrap; }
            }
        }

        // check for Owner Email to check existing user
        if(validWrap.isSuccess && !setPartnerEmailIds.isEmpty()){
            Integer getActiveContacts = validateEmail(setPartnerEmailIds);
            
            if(getActiveContacts > 0){ validWrap.isSuccess = false; validWrap.message = 'There is already Agency Admin/ User with Partner Owner Email Address.'; return validWrap; }

            if(validWrap.isSuccess){
                getActiveContacts = validateEmailForSR(new Set<String>{wrap?.agencyAdmin?.EmailAddress__c});
                if(getActiveContacts > 0){ validWrap.isSuccess = false; validWrap.message = 'There is already Service Request associated with Admin/ User with Partner Owner Email Address.'; return validWrap; }
            }
        }

        // check for admin mobile to check existing user
        if(validWrap.isSuccess && String.isNotBlank(wrap?.agencyAdmin?.MobileNumber__c)){
            Integer getActiveContacts = validateMobile(new Set<String>{wrap?.agencyAdmin?.MobileNumber__c});

            if(getActiveContacts > 0){ validWrap.isSuccess = false; validWrap.message = 'There is already Agency Admin/ User with Admin Mobile Number.'; return validWrap; }
        
            if(validWrap.isSuccess){
                getActiveContacts = validateMobileForSR(new Set<String>{wrap?.agencyAdmin?.MobileNumber__c});
                if(getActiveContacts > 0){ validWrap.isSuccess = false; validWrap.message = 'There is already Service Request associated Admin/ User with Admin Mobile Number.'; return validWrap; }
            }
        }

        if(validWrap.isSuccess && !setPartnerMobileNumber.isEmpty()){
            Integer getActiveContacts = validateMobile(setPartnerMobileNumber);
            
            if(getActiveContacts > 0){ validWrap.isSuccess = false; validWrap.message = 'There is already Agency Admin/ User with Partner Mobile Number.'; return validWrap;  }
        
            if(validWrap.isSuccess){
                getActiveContacts = validateMobileForSR(new Set<String>{wrap?.agencyAdmin?.MobileNumber__c});
                if(getActiveContacts > 0){ validWrap.isSuccess = false; validWrap.message = 'There is already Service Request associated Admin/ User Partner Mobile Number.'; return validWrap; }
            }
        }

        return validWrap;
    }

    public static Id execute(AgencyRegistrationWrapper wrap){
        HexaBPM__Service_Request__c srRequest1;
        Boolean isUpdate = wrap.serviceRequest.Id != null;
        
        // if (isUpdate) {
        //     srRequest1 = [SELECT Id FROM HexaBPM__Service_Request__c WHERE Id = :wrap.serviceRequest.Id LIMIT 1];
        //     update wrap.serviceRequest;
        // }
        HexaBPM__Service_Request__c srRequest = BrokerAgencyRegistrationController.createServiceRequestRecord(wrap.serviceRequest);
        
        if(!isUpdate){
            Id AgencyTeamRecordTyepId = Utilities.getRecordTypeId('AgencyTeam__c', 'Partner');
            List<AgencyTeam__c> listAgencyTeams =  new List<AgencyTeam__c>();
            //Admin Agency Team Record Insert
            AgencyTeam__c agencyAdmin = wrap.agencyAdmin;
            agencyAdmin.ServiceRequest__c = srRequest.Id;
            agencyAdmin.Type__c = Constants.AGENCY_ADMIN;
            agencyAdmin.RecordTypeId = AgencyTeamRecordTyepId;
            agencyAdmin.PrimaryAgencyAdmin__c = true;
            agencyAdmin.MobileNumber__c = wrap.agencyAdmin.MobileNumber__c.deleteWhitespace();
            listAgencyTeams.add(agencyAdmin);

            if(wrap.partnerOwners != null && !wrap.partnerOwners.isEmpty()){
                for(PartnerOwnerWrapper eachWrapRecord : wrap.partnerOwners){
                    eachWrapRecord.partnerOwner.ServiceRequest__c = srRequest.Id;
                    eachWrapRecord.partnerOwner.RecordTypeId = AgencyTeamRecordTyepId;
                    eachWrapRecord.partnerOwner.Type__c = Constants.PARTNER_OWNER;
                    listAgencyTeams.add( eachWrapRecord.partnerOwner);
                }
            }
            
            if(!listAgencyTeams.isEmpty()){
                upsert listAgencyTeams;
            }
        }
        
        
        // Commented by Moh Sarfaraj to separte Agency Service Request and SR Related Documents APIs
        // if(wrap.partnerOwners != null && !wrap.partnerOwners.isEmpty()){
        //     for(PartnerOwnerWrapper eachWrapRecord : wrap.partnerOwners){
        //         getSRDocPlaceHolderAndUploadSRDocs(new Map<String,String>{'Emirates_ID_Passport_copy'=> eachWrapRecord.Emirates_ID_Passport_copy }, srRequest.Id);
        //     }
        // }
        // getSRDocPlaceHolderAndUploadSRDocs(wrap.srDocumentBase64, srRequest.Id);

        return srRequest.Id;
    } 

    public static Integer validateEmail(Set<String> setEmails){
        List <Contact> listContacts = [SELECT Id, Email FROM Contact WHERE Account.AgencyStatus__c != 'Closed' AND Email != null AND Email =: setEmails AND RecordTypeId = :BROKER_AGENT_RECORD_TYPE_ID];

        if(listContacts == null ||  listContacts.size() == 0 ){
            return 0;
        }
        return listContacts.size();
    }

    public static Integer validateMobile(Set<String> setPhones){
        List <Contact> listContacts = [SELECT Id, Email FROM Contact WHERE Account.AgencyStatus__c != 'Closed' AND (MobilePhone__c IN :setPhones OR MobilePhone IN :setPhones) AND RecordTypeId = :BROKER_AGENT_RECORD_TYPE_ID];

        if(listContacts == null || listContacts.size() == 0 ){
            return 0;
        }

        return listContacts.size();
    }

    public static Integer validateEmailForSR(Set<String> setEmails){
        List <AgencyTeam__c> listAgencyTeams = [SELECT Id, EmailAddress__c FROM AgencyTeam__c WHERE 
                                                ServiceRequest__r.HexaBPM__External_Status_Name__c != 'Closed' AND 
                                                EmailAddress__c != null AND EmailAddress__c =: setEmails AND 
                                                ServiceRequest__r.RecordType.DeveloperName = 'AgencyRegistration'];

        if(listAgencyTeams == null ||  listAgencyTeams.size() == 0 ){
            return 0;
        }
        return listAgencyTeams.size();
    }

    public static Integer validateMobileForSR(Set<String> setPhones){
        List <AgencyTeam__c> listAgencyTeams = [SELECT Id, MobileNumber__c FROM AgencyTeam__c WHERE 
                                               ServiceRequest__r.HexaBPM__External_Status_Name__c != 'Closed' AND 
                                               MobileNumber__c != null AND MobileNumber__c IN :setPhones AND 
                                               ServiceRequest__r.RecordType.DeveloperName = 'AgencyRegistration'];

        if(listAgencyTeams == null || listAgencyTeams.size() == 0 ){
            return 0;
        }

        return listAgencyTeams.size();
    }

    private static String resendOtp(String sObjectId){
        try{
            List <AgencyTeam__c> listAgencyTeams = [SELECT Id, EmailAddress__c, ResendOTPTrigger__c FROM AgencyTeam__c WHERE 
                                                    ServiceRequest__c = :sObjectId AND ServiceRequestRecordType__c = 'Agency Registration' 
                                                    AND Type__c = 'Partner/Owner' AND PrimaryOwner__c = true LIMIT 1];
        
            if(listAgencyTeams == null || listAgencyTeams.isEmpty()){
                return 'No Partner/Owner Found';
            }else if(!listAgencyTeams.isEmpty()){
                listAgencyTeams[0].ResendOTPTrigger__c = true;
                update listAgencyTeams;
                return 'Success';
            }
        }catch(Exception ex){
            return ex.getMessage();
        }
        
        return 'Unknown Error'; 
    }

    // Commented by Moh Sarfaraj to separte Agency Service Request and SR Related Documents APIs
    // @future
    // public static void getSRDocPlaceHolderAndUploadSRDocs(Map<String,String> srDocumentBase64, String serviceRequestId){
    //     // Set<String> setSRDocumentsName = new Set<String>(Label.BP_AgencyRegistrationSRDocs.split(','));
    //
    //     if(srDocumentBase64 != null && !srDocumentBase64.isEmpty()){
    //         Map<Id,HexaBPM__SR_Doc__c> mapSRDocs = new Map<Id,HexaBPM__SR_Doc__c>([SELECT Id,Name,DocumentMasterCode__c FROM HexaBPM__SR_Doc__c WHERE HexaBPM__Service_Request__c = :serviceRequestId
    //                                                 AND DocumentMasterCode__c IN: srDocumentBase64.keySet()]);
    //
    //         List<Map<String,Object>> filesToUpload = new List<Map<String, Object>>();
    //         for(HexaBPM__SR_Doc__c eachSRDocu : mapSRDocs.values()){
    //             if(srDocumentBase64.get(eachSRDocu.DocumentMasterCode__c) != null && srDocumentBase64.get(eachSRDocu.DocumentMasterCode__c) != '')
    //             filesToUpload.add(new Map<String, Object>{'base64'=> srDocumentBase64.get(eachSRDocu.DocumentMasterCode__c), 'fileName'=> eachSRDocu.Name, 'Id'=> eachSRDocu.Id});
    //         }
    //         if(!filesToUpload.isEmpty()){ 
    //             BrokerAgencyRegistrationController.uploadFiles(filesToUpload); 
    //         }
    //     }
    // }

    public class ValidationWrapper{
        @Testvisible Boolean isSuccess = true;
        @Testvisible String message = '';
    }

    public class AgencyRegistrationWrapper {
        public String type {set; get;}
        public String sObjectId {set; get;}
        public HexaBPM__Service_Request__c serviceRequest { get; set; } 
        public AgencyTeam__c agencyAdmin { set; get; }
        public List<PartnerOwnerWrapper> partnerOwners { get; set; }
        // public Map<String,String> srDocumentBase64 { set; get; }
    }

    public class PartnerOwnerWrapper{
        public AgencyTeam__c partnerOwner { get; set; }
        // public String Emirates_ID_Passport_copy { get; set; }
    }
}