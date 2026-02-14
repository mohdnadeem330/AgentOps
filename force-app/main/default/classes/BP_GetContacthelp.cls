@RestResource(urlMapping = '/GetContactHelpInformation')  
global without sharing class BP_GetContacthelp extends BP_BaseRestResource {
    @HttpPost
    global static void execute() {
        RestContextHandler handler = new RestContextHandler(false);
        try {
            Map<String, String> params = RestContext.request.params;
            String requestBody = RestContext.request.requestBody.toString();
            BP_GetContacthelp service = new BP_GetContacthelp();
            ApiResponse response = service.processRequest(params, requestBody);
            
            handler.response.data = response.data;
            handler.response.success = response.success;
            handler.response.statusCode = response.statusCode;
            handler.response.message = response.message;
        } catch (Exception ex) {
            handler.response.success = false;
            handler.response.statusCode = 500;
            handler.response.message = ex.getMessage();
        }
        handler.finalize();
    }
    global override ApiResponse processRequest(Map<String, String> params, String requestBody) {
        try {
            Map<String, Object> requestData = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
            String accountName = (String) requestData.get('accountName');
            Integer limitVal = requestData.containsKey('limit') ? Integer.valueOf(requestData.get('limit')) : 100; // Default limit to 100
            Integer offsetVal = requestData.containsKey('offset') ? Integer.valueOf(requestData.get('offset')) : 0;
            
            List<User> users = Database.query(getBrokerManagersQuery(limitVal, offsetVal));
            List<Contact> sodicContacts = accountName != null ? getSodicTeamMembers(accountName) : new List<Contact>();
            
            List<Map<String, Object>> BrokerManagementTeam = new List<Map<String, Object>>();
            User loggedInUser = [SELECT Id, Account.BillingState FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            
            List<Map<String, Object>> SalesTeam = new List<Map<String, Object>>();
            List<Map<String, Object>> ResaleTeam = new List<Map<String, Object>>();
            List<Map<String, Object>> LSQSalesTeam = new List<Map<String, Object>>();
            List<Map<String, Object>> SodicMembers = new List<Map<String, Object>>();
            
            for (User userRec : users) {
                
                Map<String, Object> userMap = new Map<String, Object>{
                    'id' => userRec.Id,
                        'profileImage' => getProfilePhotoBase64(userRec.FullPhotoUrl),
                        'name' => userRec.FirstName + ' ' + userRec.LastName,
                        'email' => userRec.Email,
                        'mobilePhoneNumber' => userRec.MobilePhone,
                        'hasLinkedIn' => false,
                        'hasWhatsApp' => false
                        };
                            
                            String state = loggedInUser.Account.BillingState;
                String stateCode = '';
                if (state == 'Abu Dhabi') {
                    stateCode = 'AUH';
                } else if (state == 'Dubai') {
                    stateCode = 'DXB';
                }
                
                if (userRec.RoleName__c == 'Head of Broker Management') { 
                    userMap.put('position', userRec.RoleName__c);
                    BrokerManagementTeam.add(userMap);
                    
                } /* else if (userRec.ProfileName__c == 'Broker Sales Admin' &&
                           userRec.RoleName__c == 'Broker Management - Sales Admin') {
                               userMap.put('position', 'Admin Broker Management');
                               BrokerManagementTeam.add(userMap);
                               
                           } */ 
                else if (userRec.ProfileName__c == 'Broker Manager') {
                    
                    if (stateCode == 'AUH' &&
                        userRec.RoleName__c == 'Broker Relations Manager - AUH' &&
                        userRec.Team__c == 'AUH') {
                            userMap.put('position', userRec.BrokerTitle__c);
                            BrokerManagementTeam.add(userMap);
                            
                        } else if (stateCode == 'DXB' &&
                                   userRec.RoleName__c == 'Broker Relations Manager - DXB' &&
                                   userRec.Team__c == 'DXB') {
                                       userMap.put('position', userRec.BrokerTitle__c);
                                       BrokerManagementTeam.add(userMap);
                                   }
                    
                } else if (userRec.Region__c == 'Abu Dhabi' || userRec.Region__c == 'Dubai') {
                    if (userRec.ProfileName__c == 'Broker Manager') {
                        userMap.put('position', userRec.BrokerTitle__c);
                        BrokerManagementTeam.add(userMap);
                        
                        
                    }
                }  else if (userRec.ProfileName__c == 'Resale Relationship Manager') {
                    userMap.put('position', userRec.RoleName__c);
                    ResaleTeam.add(userMap);
                } else if (userRec.RoleName__c == 'LSQ - Sales Manager North' || userRec.RoleName__c == 'LSQ - Sales Manager South') {
                    userMap.put('position', userRec.RoleName__c);
                    LSQSalesTeam.add(userMap);
                }
                else if (loggedInUser.Account.BillingState == 'Abu Dhabi') {
                    if ( ( userRec.ProfileName__c == 'Sales Management' && ('Head of Sales - AUH' == userRec.RoleName__c || 'Associate Director of Sales' == userRec.RoleName__c)) 
                        || (userRec.ProfileName__c == 'Sales Manager' && userRec.RoleName__c == 'Sales Manager - AUH')) {
                        
                         userMap.put('position', userRec.RoleName__c );
                        SalesTeam.add(userMap);
                    }
                } else if (loggedInUser.Account.BillingState == 'Dubai') {
                    if ( (userRec.ProfileName__c == 'Sales Manager' && 'Head of Sales - DXB' == userRec.RoleName__c )
                        || (userRec.ProfileName__c == 'Sales Manager' && userRec.RoleName__c == 'Sales Manager - DXB')) {
                            userMap.put('position', userRec.RoleName__c);
                        
                        SalesTeam.add(userMap);
                    }
                }
                
            }
            
            for (Contact contactRec : sodicContacts) {
                Map<String, Object> contactMap = new Map<String, Object>{
                    'id' => contactRec.Id,
                        'profileImage' => getContactProfilePhoto(contactRec.Id),
                        
                        'name' => contactRec.Name,
                        'email' => contactRec.Email,
                        'mobilePhoneNumber' => contactRec.MobilePhone,
                        'hasLinkedIn' => false,
                        'hasWhatsApp' => false,
                        'position' => contactRec.Title
                        };
                            SodicMembers.add(contactMap);
            }
            
            
            Map<String, Object> responseData = new Map<String, Object>{
                'sfRecordCount' => new Map<String, Integer>{ 'user' => users.size(), 'sodicMembers' => sodicContacts.size() },
                    'data' => new Map<String, Object>{
                        'BrokerManagementTeam' => BrokerManagementTeam,
                            'SalesTeam' =>SalesTeam,
                            
                            'ResaleTeam' => ResaleTeam,
                            
                            'LSQSalesTeam' => LSQSalesTeam,
                            'SodicMembers' => SodicMembers
                            }
            };
                System.debug('responseData::'+responseData); 
            return new ApiResponse(true, 200, 'success', responseData);
        } catch (Exception e) {
            return new ApiResponse(false, 400, 'Failed to load data: ' + e.getMessage(), null);
        } 
    }
    
    
    public static List<Contact> getSodicTeamMembers(string accountName) {
        return [Select Id,FirstName,LastName,Name,Email,MobilePhone,Title,Description from Contact WHERE AgentStatus__c = 'Active' AND RecordType.Name = 'Broker Agent' AND Account.Name ='SODIC'];
    }
    public static String getBrokerManagersQuery(Integer limitVal, Integer offsetVal) {
        list<String> profileNameList = new List<String>{'Broker Sales Admin', 'Broker Manager', 'Resale Relationship Manager', 'Sales Management', 'Head of Sales - AUH','Head of Sales - DXB', 'Sales Manager' };
            List<String> RoleNameList = new List<String>{'Head of Broker Management',
                'Broker Relations Manager - AUH', 
                'Broker Relations Manager - DXB',
                'LSQ - Sales Manager North', 
                'LSQ - Sales Manager South',
                'Associate Director of Sales',
                'Head of Sales - AUH', 
                'Head of Sales - DXB',
                'Sales Manager - AUH',
                'Sales Manager - DXB'};
                    
        String profileNames = '\'' + String.join(profileNameList, '\', \'') + '\'';
        String roleNames = '\'' + String.join(roleNameList, '\', \'') + '\'';
        
        return 'SELECT Id, FirstName, LastName, Email, MobilePhone, Title, Region__c, RoleName__c, ' +
            'ProfileName__c, IsActive, FullPhotoUrl, Account.BillingCountry, Team__c, ' +
            'ShowOnBrokerPortal__c, BrokerTitle__c ' +
            'FROM User ' +
            'WHERE HideFromBrokerPortalContactUs__c = False AND IsActive = TRUE AND ' +
            '(ProfileName__c IN (' + profileNames + ') OR RoleName__c IN (' + roleNames + ')) ' +
            'ORDER BY LastModifiedDate DESC ' +
            'LIMIT ' + limitVal + ' OFFSET ' + offsetVal;
    }
    public static String getProfilePhotoBase64(String fullPhotoUrl) {
        try {
            if (String.isBlank(fullPhotoUrl)) {
                return null;
            }
            PageReference ref = new PageReference(fullPhotoUrl);
            Blob imageBlob = ref.getContent();
            return EncodingUtil.base64Encode(imageBlob);
        } catch (Exception e) {
            System.debug('Error fetching photo: ' + e.getMessage());
            return null;
        }
    }
    public static String getContactProfilePhoto(Id contactId) {
        try {
            
            List<ContentDocumentLink> docLinks = [
                SELECT ContentDocumentId 
                FROM ContentDocumentLink 
                WHERE LinkedEntityId = :contactId 
                
                LIMIT 1
            ];
            
            
            if (!docLinks.isEmpty() && docLinks[0].ContentDocumentId != null) {
                
                List<ContentVersion> versions = [
                    SELECT VersionData 
                    FROM ContentVersion 
                    WHERE ContentDocumentId = :docLinks[0].ContentDocumentId 
                    ORDER BY CreatedDate DESC 
                    LIMIT 1
                ];
                
                if (!versions.isEmpty()) {
                    return EncodingUtil.base64Encode(versions[0].VersionData);
                }
            }
        } catch (Exception ex) {
            System.debug('Error fetching contact profile photo: ' + ex.getMessage());
        }
        return null;
    }
    
    
}