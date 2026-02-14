@RestResource(urlMapping = '/getLoggedInUserDetails')
global with sharing class BP_LoggedInUserWebService extends BP_BaseRestResource {

    @HttpPost
    global static void excute() {
        RestContextHandler handler = new RestContextHandler(false);
        
        try {
            Map<String, String> params = RestContext.request.params;
            String requestBody = RestContext.request.requestBody.toString();

            if (!String.isEmpty(requestBody)) {
                BP_LoggedInUserWebService service = new BP_LoggedInUserWebService();
                ApiResponse response = service.processRequest(params, requestBody);
                handler.response.data = response.data;
                handler.response.success = true;
                handler.response.statusCode = response.statusCode;
                handler.response.message = response.message;
            } else {
                handler.response.success = false;
                handler.response.statusCode = 400;
                handler.response.message = 'Invalid Request Body';
            }
        } catch (Exception ex) {
            LoggerService.save(LoggerService.addApexLog(ex, 'Broker2.0 API', 'BP_LoggedInUserWebService', 'execute'));
            handler.response.success = false;
            handler.response.statusCode = 500;
            handler.response.message = 'Error: ' + ex.getMessage();
        }

        handler.finalize();
    }

    global override ApiResponse processRequest(Map<String, String> params, String requestBody) {
        try {
            Map<String, Object> requestBodyData = parseRequestBody(requestBody);
            String userId = (String) requestBodyData.get('userId');

            return new ApiResponse(true, 200, 'Logged in User details fetched', getLoggedInUserDetail(userId));
        } catch (Exception e) {
            LoggerService.save(LoggerService.addApexLog(e, 'Broker2.0 API', 'BP_LoggedInUserWebService', 'processRequest'));
            return new ApiResponse(false, 400, 'Failed to fetch details: ' + e.getMessage(), null);
        }
    }

    public static userWrapper getLoggedInUserDetail(String userId) {
        userWrapper wrap = new userWrapper();

        try {
            User userDetail = BP_UtilitiesWithoutSharing.getUser(userId);
            wrap.userDetail = userDetail;
            

            Contact contactToUse;
            List<Contact> contacts = [
                SELECT Id, Name, AccountId, BrokerType__c, PrimaryOwner__c
                FROM Contact
                WHERE 
                    (AccountId = :userDetail.AccountId AND BrokerType__c = 'Partner/Owner' AND PrimaryOwner__c = TRUE AND AgentStatus__c = 'Active')
                    OR (Id = :userDetail.ContactId)
                LIMIT 2
            ];

            for (Contact c : contacts) {
                if (c.AccountId == userDetail.AccountId && c.BrokerType__c == 'Partner/Owner' && c.PrimaryOwner__c) {
                    contactToUse = c;
                    break;
                } else if (c.Id == userDetail.ContactId) {
                    contactToUse = c;
                }
            }

            wrap.partnerOwnerName = (contactToUse != null) ? contactToUse.Name : 'Admin';

            try {
                if(String.isNotBlank(userDetail?.FullPhotoUrl) && userDetail?.FullPhotoUrl != null && (!userDetail?.FullPhotoUrl?.endsWithIgnoreCase('profilephoto/005/F'))){
                    PageReference ref = new PageReference(userDetail?.FullPhotoUrl);
                    Blob b = ref.getContent();
                    wrap.FullPhotoBase64 = EncodingUtil.base64Encode(b);
                }
            } catch (Exception photoEx) {
                LoggerService.save(LoggerService.addApexLog(photoEx, 'Broker2.0 API', 'BP_LoggedInUserWebService', 'getLoggedInUserDetail - Photo'));
                wrap.FullPhotoBase64 = null;
            }

        } catch (Exception e) {
            LoggerService.save(LoggerService.addApexLog(e, 'Broker2.0 API', 'BP_LoggedInUserWebService', 'getLoggedInUserDetail '+userId));
        }

        return wrap;
    }

    public class userWrapper {
        public User userDetail;
        public String FullPhotoBase64;
        public String partnerOwnerName;
    }
}