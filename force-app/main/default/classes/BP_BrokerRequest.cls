/**********************************************************************************
 * Name 			: BP_BrokerRequest
 * Description		: API Call for Broker Request
 * Created Date		: 12/02/25
 * Created By		: Nikhil Mehra
 * Test Class		: BP_BrokerRequestTest
 * -------------------------------------------------------------------------------*
Version		|	Date(DD/MM/YYYY)	|	Last Modified By	| Comments
----------------------------------------------------------------------------------
1.0			|	12/02/25			|	Nikhil Mehra		| Initial Draft
**********************************************************************************/
@RestResource (urlMapping = '/getBrokerRequest')
global with sharing class BP_BrokerRequest extends BP_BaseRestResource{

    @HttpPost
    global static void execute(){
        RestContextHandler handler = new RestContextHandler(false);
        try {
            Map<String, String> params = RestContext.request.params;
            String requestBody = RestContext.request.requestBody.toString();  
            BP_BrokerRequest service = new BP_BrokerRequest();
            ApiResponse response = service.processRequest(params, requestBody);
            handler.response.data = response.data;
            handler.response.success = true;
            handler.response.statusCode = response.statusCode;
            handler.response.message = response.message;
        }catch(Exception ex){
            handler.response.success = false;
            handler.response.statusCode = 500;
            handler.response.message = ex.getMessage();
        } 
        handler.finalize();
    }
    
    global override ApiResponse processRequest(Map<String, String> params, String requestBody) {
        try{
            Map<String, Object> requestBodyData = parseRequestBody(requestBody);
            List<Account> accList  = new List<Account>();
            List<String> conditions = new List<String>();
            String accountId = (String) requestBodyData.get('accountId');
			String typeName = (String) requestBodyData.get('type');
            List<String> recordTypeNames = new List<String>{'Activity','Event'};
                
            List<User> usersList = [SELECT Id, ContactId, IsActive, RoleName__c, Phone, Username, Profile.Name, AccountId FROM User WHERE Id =: UserInfo.getUserId()];
           	String brokerReqQuery = getBrokerRequestQuery();
            if(accountId != null){
                 conditions.add(' AgencyName__c  = :accountId ');
            }
            else{
              accList =  [SELECT Id FROM Account WHERE PersonContactId =: usersList[0].ContactId];
			  accountId =  accList[0].Id;
              conditions.add(' AgencyName__c  = :accountId ');
            }
            if(typeName != null){
                conditions.add(' Type__c  =:typeName  ');
            }
            String userId = usersList[0].Id;
            conditions.add(' CreatedById  = :userId ');
            //conditions.add(' RecordType.Name  IN :recordTypeNames ');
            if (conditions.size() > 0) {
                brokerReqQuery += String.join(conditions, ' AND ');
            }
			brokerReqQuery += ' ORDER BY CreatedDate DESC';
            List<BrokerRequest__c> brokerList = new List<BrokerRequest__c>();
			brokerList = Database.query(brokerReqQuery);
            return new ApiResponse(true, 200, brokerList.size() > 0 ? 'Broker Request details fetched. Total - '+brokerList.size():'No Broker Request data to fetch' , brokerList);
           } catch (Exception e){
               return new ApiResponse(false, 400,'Failed to load Broker Request details: ' + e.getMessage(), null);
           } 
    }
    
    public static String getBrokerRequestQuery(){
         String brokerReqQuery = 'SELECT Id, AgencyName__c, Name, Type__c, StartDate__c, EndDate__c, Location__c,'+ 
             					'InvoiceAmount__c, SodicInvoiceAmount__c, Comment__c, TaxAmount__c, InvoiceDate__c, Invoice__c,'+                                        
             					'TotalAmount__c, ApprovalStatus__c, Agency__c, (SELECT Id, LinkedEntityId,ContentDocumentId, ContentDocument.Title,'+
                               'IsDeleted, ContentDocument.createdDate,ContentDocument.FileType FROM ContentDocumentLinks) FROM BrokerRequest__c WHERE ';
        return brokerReqQuery;
    }
}