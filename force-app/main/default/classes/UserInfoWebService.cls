@RestResource (urlMapping = '/userinformation')
global with sharing class UserInfoWebService {
    
    @HttpGet
    global static void doGet() {

        RestContextHandler handler = new RestContextHandler(false);

        try {

            MobileConfigurationsUtility.MobileVersionModel version = handler.evaluateAppVersionForAllowed();

            if (!version.isLatest) {

                handler.response.StatusCode = Constants.STATUS_CODE_OLD_VERSION;
                handler.response.Message = Constants.MESSAGE_OLD_APP_VERSION;
                handler.response.Success = false;
                handler.response.data = version;
            }
            else{
                
                User userDetail = Utilities.getLoggedInUserDetail();

                UserInfoResponse response = new UserInfoResponse();
                response.success = true;
                response.userId = userDetail.Id;
                response.profileId = userDetail.ProfileId;
                response.profileName = userDetail.ProfileName__c;
                response.roleId = userDetail.UserRoleId;
                response.userFullName = userDetail.Name;
                response.userEmail = userDetail.Email;
                response.team = userDetail.Team__c;
                response.profileURL = userDetail.FullPhotoUrl;
                response.orgId = UserInfo.getOrganizationId();
                response.title = userDetail.Title;
                response.managerName = userDetail.Manager.Name;
                response.userPhone = userDetail.MobilePhone;
                response.isBlocked = OpportunityUnitSearchController.getUserStatus();
                response.blockedMessage = 'Temporary access restriction has been imposed. Please contact your Line Manager to resolve and reinstate access.';
                handler.response.data = response;
            }
            handler.finalize();
        }
        catch (Exception e) {
            
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = Constants.GENERIC_LOGIN_ERROR;
            handler.finalize(e);
        }
    }

    public with sharing class UserInfoResponse {
        
        public String userId {get; private set;}
        public String profileId {get; private set;}
        public String roleId {get; private set;}
        public String userFullName {get; private set;}
        public String userEmail {get; private set;}
        public String profileName {get; private set;}
        public String team {get; private set;}
        public Boolean success {get; private set;}
        public String orgId {get; private set;}
        public String profileURL {get; private set;}
        public String title {get; private set;}
        public String managerName {get; private set;}
        public String userPhone {get; private set;}
        public Boolean isBlocked{get; private set;}
        public String blockedMessage{get; private set;}
        
        public UserInfoResponse() {
            
            this.success = false;
            this.userId = '';
            this.profileId = '';
            this.roleId = '';
            this.userFullName = '';
            this.userEmail = '';    
            this.profileName = '';
            this.team = '';
            this.orgId = '';
            this.profileURL = '';
            this.title = '';
            this.managerName = '';
            this.userPhone = '';
            this.isBlocked = false;
            this.blockedMessage ='';
        }
    }
}