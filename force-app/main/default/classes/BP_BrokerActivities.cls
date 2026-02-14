@RestResource(urlMapping = '/getBrokerActivities')
global without sharing class BP_BrokerActivities extends BP_BaseRestResource {

    @HttpPost
    global static void execute() {
        RestContextHandler handler = new RestContextHandler(false);
        try {
            Map<String, String> params = RestContext.request.params;
            String requestBody = RestContext.request.requestBody.toString();  
            BP_BrokerActivities service = new BP_BrokerActivities();
            ApiResponse response = service.processRequest(params, requestBody);
            handler.response.data = response.data;
            handler.response.success = true;
            handler.response.statusCode = response.statusCode;
            handler.response.message = response.message;
        } catch(Exception ex) {
            handler.response.success = false;
            handler.response.statusCode = 500;
            handler.response.message = ex.getMessage();
        } 
        handler.finalize();
    }
    
    global override ApiResponse processRequest(Map<String, String> params, String requestBody) {
        String PENDING = 'Pending';
        List<String> conditions = new List<String>();
        Set<Id> relatedAccountIds = new Set<Id>();
        Set<Id> relatedActivityIds = new Set<Id>();
        Map<String, Id> recordTypeMap = new Map<String, Id>();
        Set<Id> recordTypeId = new Set<Id>();
        List<BrokerActivities__c> brokerActivityList = new List<BrokerActivities__c>();
        String brokerActivityQuery;
        Date twoMonthsBack = System.today().addMonths(-2);
        List<ActivityMapping__c> activityMappingList = new List<ActivityMapping__c>();

        Map<String, Object> requestMap = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
        List<Object> recordTypeNamesObj = (List<Object>) requestMap.get('recordTypeNames');
        List<String> recordTypeNames = new List<String>();
        for (Object obj : recordTypeNamesObj) {
            recordTypeNames.add((String) obj);
        }

        String year = (String) requestMap.get('year');
        String month = (String) requestMap.get('month');
        String searchKey = (String) requestMap.get('searchKey');
        String typeValue = (String) requestMap.get('type'); 
        Integer limitValue = (Integer) requestMap.get('pageSize');
        Integer offsetValue = (Integer) requestMap.get('page');
        String userId = UserInfo.getUserId();
        
        String brokerActivityQueryToCount;
        
            List<User> usersList = [SELECT Id, ContactId FROM User WHERE Id = :userId];
    
            if (usersList.isEmpty()) {
                return new ApiResponse(false, 400, 'Invalid User ID', null);
            }
    
            String contactId = usersList[0].ContactId;
            if (String.isEmpty(contactId)) {
                return new ApiResponse(false, 400, 'User does not have a Contact associated', null);
            }
        List<AccountContactRelation> relatedAccounts = [SELECT Id, AccountId 
                                                        FROM AccountContactRelation 
                                                        WHERE ContactId = :contactId];

        for (RecordType recObj : [SELECT Id, Name FROM RecordType WHERE SObjectType = 'BrokerActivities__c']) {
            recordTypeMap.put(recObj.Name, recObj.Id);
            recordTypeId.add(recObj.Id);
        }

        if (!relatedAccounts.isEmpty()) {
            for (AccountContactRelation accRelObj : relatedAccounts) {
                relatedAccountIds.add(accRelObj.AccountId);
            }
        }

        if (!relatedAccountIds.isEmpty()) {
            activityMappingList = [SELECT Id, Activity__c 
                                   FROM ActivityMapping__c 
                                   WHERE Agency__c IN :relatedAccountIds];
        }

        if (!activityMappingList.isEmpty()) {
            for (ActivityMapping__c activityMapObj : activityMappingList) {
                relatedActivityIds.add(activityMapObj.Activity__c);
            }
        }

        if (!relatedActivityIds.isEmpty() && recordTypeNames != null && !recordTypeNames.isEmpty()) {
            brokerActivityQuery = getBrokerActivityQuery();
            conditions.add(' StartDate__c > :twoMonthsBack ');
            conditions.add(' Id IN :relatedActivityIds ');
            conditions.add(' RecordTypeId IN :recordTypeId ');
            conditions.add(' Status__c != \'' + PENDING + '\' ');
            conditions.add(' RecordType.Name IN :recordTypeNames ');

            if (year != null) {                     
                conditions.add('CALENDAR_YEAR(StartDate__c) <= ' + year + ' AND CALENDAR_YEAR(EndDate__c) >= ' + year);
            }  

            if (month != null) {                     
                conditions.add('CALENDAR_MONTH(StartDate__c) <= ' + month + ' AND CALENDAR_MONTH(EndDate__c) >= ' + month);
            }

            if (searchKey != null && searchKey.trim() != '') {
                conditions.add(' Name LIKE \'%' + searchKey + '%\' ');
            }

            if (typeValue != null && typeValue.trim() != '') {
                conditions.add(' Type__c = \'' + typeValue + '\' ');
            }

            if (!conditions.isEmpty()) {
                brokerActivityQuery += String.join(conditions, ' AND ');
            }

            brokerActivityQuery += ' ORDER BY StartDate__c DESC';
            brokerActivityQueryToCount = brokerActivityQuery;
            
         
            if (limitValue != null) {
                brokerActivityQuery += ' LIMIT ' + limitValue;
            }
            if (offsetValue != null) {
                brokerActivityQuery += ' OFFSET ' + offsetValue;
            }
        }

        if (brokerActivityQuery != null) {
            brokerActivityList = Database.query(brokerActivityQuery);
        }

        // Fetch related Document__c records
      List<Document__c> docList = [SELECT Id, Activity__c FROM Document__c WHERE Activity__c IN :brokerActivityList];
Map<Id, List<Map<String, Object>>> brokerActivityFilesMap = new Map<Id, List<Map<String, Object>>>();

if (!docList.isEmpty()) {
    Set<Id> docIds = new Set<Id>();
    for (Document__c doc : docList) {
        docIds.add(doc.Id);
    }

    List<ContentDocumentLink> cdlList = [SELECT ContentDocumentId, LinkedEntityId 
                                         FROM ContentDocumentLink 
                                         WHERE LinkedEntityId IN :docIds];

    Map<Id, Id> docToContentDocMap = new Map<Id, Id>();
    for (ContentDocumentLink cdl : cdlList) {
        docToContentDocMap.put(cdl.LinkedEntityId, cdl.ContentDocumentId);
    }

    List<ContentVersion> contentVersionList = [SELECT Id, Title, FileExtension, ContentSize, CreatedDate, VersionData, ContentDocumentId 
                                               FROM ContentVersion 
                                               WHERE ContentDocumentId IN :docToContentDocMap.values()];

    for (Document__c doc : docList) {
        Id contentDocId = docToContentDocMap.get(doc.Id);
        List<Map<String, Object>> fileList = new List<Map<String, Object>>();

        for (ContentVersion cv : contentVersionList) {
            if (cv.ContentDocumentId == contentDocId) {
                Map<String, Object> fileData = new Map<String, Object>();
                fileData.put('Id', cv.Id);
                fileData.put('Title', cv.Title);
                fileData.put('FileExtension', cv.FileExtension);
                fileData.put('ContentSize', cv.ContentSize);
                fileData.put('CreatedDate', cv.CreatedDate);
                fileData.put('ContentDocumentId', cv.ContentDocumentId);
                fileData.put('imageData', EncodingUtil.base64Encode(cv.VersionData)); // Encode file data
                
                fileList.add(fileData);
            }
        }
        brokerActivityFilesMap.put(doc.Activity__c, fileList);
    }
}

// Attach document data to brokerActivityList
List<Map<String, Object>> brokerActivityData = new List<Map<String, Object>>();
for (BrokerActivities__c ba : brokerActivityList) {
    Map<String, Object> activityData = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(ba));
    activityData.put('Documents__r', brokerActivityFilesMap.get(ba.Id) != null ? brokerActivityFilesMap.get(ba.Id) : new List<Map<String, Object>>());
    brokerActivityData.add(activityData);
}

Integer totalRecordCount = Database.query(brokerActivityQueryToCount)?.size();
Map<String, Object> responseData = new Map<String, Object>();
responseData.put('totalRecordCount', totalRecordCount);
responseData.put('brokerActivities', brokerActivityData);

return new ApiResponse(true, 200, brokerActivityData.isEmpty() ? 
                       'No Broker Activities data to fetch' : 
                       'Broker Activities details fetched. Total - ' + totalRecordCount, 
                       responseData);
    }

    public static String getBrokerActivityQuery() {
        return 'SELECT Id, Name, RecordType.Name, Description__c, EndDate__c, EndTime__c, ExternalLink__c, ' +
               'Location__c, ShortDescription__c, SocialMediaLink1__c, StartDate__c, StartTime__c, Status__c, ' +
               'Type__c, VirtualTourLink__c FROM BrokerActivities__c WHERE ';
    }
}