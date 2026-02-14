@RestResource(urlMapping = '/customer/moveInService')
global without sharing class CustomerMoveInServiceRequestHandler {
    
    @HttpPost
    global static void createAccount() {
        RestContextHandler handler = new RestContextHandler(false);
        try {
            MoveInServiceRequestPayload requestData = (MoveInServiceRequestPayload) JSON.deserialize(RestContext.request.requestBody.toString(), MoveInServiceRequestPayload.class);
            System.debug('Request Data::</>' + requestData);
            object responseData;
            if(requestData.requestDetails != null  && requestData.operation == 'create'){
                responseData = createMoveInSR(requestData);
            }
            else if(requestData!= null && requestData.operation == 'get'){
                responseData =   getMoveInSRDetails(requestData);
            } 
            else if(requestData!= null && requestData.operation == 'cancel' ){
                responseData =   cancelMoveInSR(requestData);
            }
            
            handler.response.data = responseData;
            handler.response.success = true;
            handler.finalize();
        } catch (Exception ex) {
            System.debug('Exception at Line: ' + ex.getLineNumber() + ' Message: ' + ex.getMessage());
            Logger__c lgs = LoggerService.createApexLog(ex,'MoveInSRHandler','CustomerMoveInServiceRequestHandler','MoveIn');
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = ex.getMessage();
            handler.finalize(ex);
        }
    }
    
    public static MoveInSRResponse createMoveInSR(MoveInServiceRequestPayload payloadDataMoveInSR){
        
        system.debug(':payloadDataMoveInSR.unitID'+payloadDataMoveInSR.unitId);
         system.debug(':payloadDataMoveInSR.customerI::'+payloadDataMoveInSR.customerId);
        List<HexaBPM__Service_Request__c> existingMoveInSR = [SELECT Id,Name,HexaBPM__External_Status_Name__c,HexaBPM__Submitted_DateTime__c,Move_In_Date__c,Move_In_Time__c,HexaBPM__Customer__r.Name,Unit__r.Name,Unit__r.CommunityName__c,Unit__r.BuildingSectionName__r.Precint_Name__c,Unit__r.Project__r.OA_Community_Name__c FROM HexaBPM__Service_Request__c WHERE Unit__c = :payloadDataMoveInSR.unitId AND HexaBPM__Customer__c = :payloadDataMoveInSR.customerId AND SRType__c ='Aldar Estates Move-In' AND HexaBPM__External_Status_Name__c NOT IN ('Draft', 'Cancelled','Cancelled By User')];
        system.debug('existingMoveInSR::'+existingMoveInSR);
        moveInSRResponse MoveInSRResponse = new MoveInSRResponse();
        
        
        if (existingMoveInSR.isEmpty()) {
            
            list<Unit__c> matchingUnit = [SELECT Id,Name FROM Unit__c WHERE Id =: payloadDataMoveInSR.unitId ];
            list<Asset> matchingAssets	= new list<Asset>(); 
            if(!matchingUnit.isEmpty()){
            matchingAssets	= [SELECT Id,ECSS_Unit_Number__c FROM Asset WHERE  Unit__r.Name =: matchingUnit[0].Name ];
            }
            list<Account> customerAcc = [SELECT Id,personemail FROM Account WHERE Id = : payloadDataMoveInSR.customerId] ;
            
            HexaBPM__Service_Request__c newMoveInSR = new HexaBPM__Service_Request__c();
            newMoveInSR.SRType__c = 'Aldar Estates Move-In';
            newMoveInSR.Origin__c = payloadDataMoveInSR.origin;
            newMoveInSR.HexaBPM__Customer__c = payloadDataMoveInSR.customerId ;
            newMoveInSR.Unit__c= payloadDataMoveInSR.unitId ;
            newMoveInSR.SalesOrder__c = payloadDataMoveInSR.salesOrderId;
            newMoveInSR.Move_In_Date__c = payloadDataMoveInSR.requestDetails.moveInDate ;
            newMoveInSR.HexaBPM__Email__c = customerAcc[0].personemail;
            newMoveInSR.Move_In_Time__c = payloadDataMoveInSR.requestDetails.moveInTime ??'';
            if (!Test.isRunningTest()) {
                newMoveInSR.RecordTypeId =  Schema.SObjectType.HexaBPM__Service_Request__c.getRecordTypeInfosByDeveloperName().get('AldarEstatesMoveInOut').getRecordTypeId();
		  }
            newMoveInSR.Asset__c =  !matchingAssets.isEmpty() ? matchingAssets[0].Id : null;      
            
           if (!Test.isRunningTest()) {
                insert newMoveInSR;
           }
            
            HexaBPM__Service_Request__c insertedMoveInSR = [SELECT Id,Name,HexaBPM__External_Status_Name__c,HexaBPM__Submitted_DateTime__c,Move_In_Date__c,Move_In_Time__c,HexaBPM__Customer__r.Name,Unit__r.Name,Unit__r.CommunityName__c,Unit__r.BuildingSectionName__r.Precint_Name__c,Unit__r.Project__r.OA_Community_Name__c FROM HexaBPM__Service_Request__c WHERE Id=:newMoveInSR.id ];
            system.debug('status::'+insertedMoveInSR.HexaBPM__External_Status_Name__c);
            moveInSRResponse.srId = insertedMoveInSR.Id;
            moveInSRResponse.customerId = insertedMoveInSR.HexaBPM__Customer__c;
            moveInSRResponse.status = insertedMoveInSR.HexaBPM__External_Status_Name__c ;
            moveInSRResponse.moveInDate = string.valueof(insertedMoveInSR.Move_In_Date__c);
            moveInSRResponse.moveInTime = string.valueof(insertedMoveInSR.Move_In_Time__c);
            
            moveInSRResponse.customerName = insertedMoveInSR.HexaBPM__Customer__r.Name;
            moveInSRResponse.unitName = insertedMoveInSR.Unit__r.Name;
            moveInSRResponse.communityName = insertedMoveInSR.Unit__r.project__r.OA_Community_Name__c;
            moveInSRResponse.precinctName = insertedMoveInSR.Unit__r.BuildingSectionName__r.Precint_Name__c;
            moveInSRResponse.srNo = insertedMoveInSR.Name;
            moveInSRResponse.CommunityManager = getCommunityManagerNames(insertedMoveInSR);
            
        }else{
            moveInSRResponse.srId = existingMoveInSR[0].Id ;
            moveInSRResponse.customerId = existingMoveInSR[0].HexaBPM__Customer__c ;
            moveInSRResponse.status =existingMoveInSR[0].HexaBPM__External_Status_Name__c ;
            moveInSRResponse.moveInDate = string.valueof(existingMoveInSR[0].Move_In_Date__c);
            moveInSRResponse.moveInTime = string.valueof(existingMoveInSR[0].Move_In_Time__c);
            
            moveInSRResponse.customerName = existingMoveInSR[0].HexaBPM__Customer__r.Name;
            moveInSRResponse.unitName = existingMoveInSR[0].Unit__r.Name;
            moveInSRResponse.communityName = existingMoveInSR[0].Unit__r.Project__r.OA_Community_Name__c;
            moveInSRResponse.precinctName = existingMoveInSR[0].Unit__r.BuildingSectionName__r.Precint_Name__c;
            moveInSRResponse.srNo = existingMoveInSR[0].Name;
            moveInSRResponse.CommunityManager = getCommunityManagerNames(existingMoveInSR[0]);
        }
        return moveInSRResponse;
    }
    
    public static MoveInSRResponse getMoveInSRDetails(MoveInServiceRequestPayload payloadDataGetMoveInSRDetails){
        
        if(String.isNotBlank(payloadDataGetMoveInSRDetails.srId)){
            MoveInSRResponse moveInSRResponse= new MoveInSRResponse();
            list<HexaBPM__Service_Request__c> cancelledMoveInSR = [SELECT Id,Name,HexaBPM__External_Status_Name__c,HexaBPM__Submitted_DateTime__c,Move_In_Date__c,Move_In_Time__c,HexaBPM__Customer__r.Name,Unit__r.Name,Unit__r.CommunityName__c,Unit__r.BuildingSectionName__r.Precint_Name__c,Unit__r.Project__r.OA_Community_Name__c FROM HexaBPM__Service_Request__c WHERE id=:payloadDataGetMoveInSRDetails.srId] ;
            moveInSRResponse.status = cancelledMoveInSR[0].HexaBPM__External_Status_Name__c ;
            moveInSRResponse.moveInDate = string.valueof(cancelledMoveInSR[0].Move_In_Date__c);
            moveInSRResponse.moveInTime = string.valueof(cancelledMoveInSR[0].Move_In_Time__c);
            moveInSRResponse.srId = cancelledMoveInSR[0].Id ;
            moveInSRResponse.customerName = cancelledMoveInSR[0].HexaBPM__Customer__r.Name;
            moveInSRResponse.unitName = cancelledMoveInSR[0].Unit__r.Name;
            moveInSRResponse.communityName = cancelledMoveInSR[0].Unit__r.Project__r.OA_Community_Name__c;
            moveInSRResponse.precinctName = cancelledMoveInSR[0].Unit__r.BuildingSectionName__r.Precint_Name__c;
            moveInSRResponse.srNo = cancelledMoveInSR[0].Name;
            moveInSRResponse.CommunityManager = getCommunityManagerNames(cancelledMoveInSR[0]);
                
            
            return moveInSRResponse;
        }else{
            List<HexaBPM__Service_Request__c> existingMoveInSR = [SELECT Id,Name,HexaBPM__External_Status_Name__c,HexaBPM__Submitted_DateTime__c,Move_In_Date__c,Move_In_Time__c,HexaBPM__Customer__r.Name,Unit__r.Name,Unit__r.CommunityName__c,Unit__r.BuildingSectionName__r.Precint_Name__c,Unit__r.Project__r.OA_Community_Name__c FROM HexaBPM__Service_Request__c WHERE Unit__c = :payloadDataGetMoveInSRDetails.unitId AND HexaBPM__Customer__c = :payloadDataGetMoveInSRDetails.customerId AND SRType__c = 'Aldar Estates Move-In' AND HexaBPM__External_Status_Name__c NOT IN ('Draft', 'Cancelled','Cancelled By User')];
            system.debug('existingMoveInSR::'+ existingMoveInSR);
            MoveInSRResponse moveInSRResponse= new MoveInSRResponse();
            if (!existingMoveInSR.isEmpty()) {
                
                moveInSRResponse.status = existingMoveInSR[0].HexaBPM__External_Status_Name__c ;
                moveInSRResponse.moveInDate = string.valueof(existingMoveInSR[0].Move_In_Date__c);
                moveInSRResponse.moveInTime = string.valueof(existingMoveInSR[0].Move_In_Time__c);
                moveInSRResponse.srId = existingMoveInSR[0].Id ;
                moveInSRResponse.customerName = existingMoveInSR[0].HexaBPM__Customer__r.Name;
                moveInSRResponse.unitName = existingMoveInSR[0].Unit__r.Name;
                moveInSRResponse.communityName = existingMoveInSR[0].Unit__r.Project__r.OA_Community_Name__c;
                moveInSRResponse.precinctName = existingMoveInSR[0].Unit__r.BuildingSectionName__r.Precint_Name__c;
                moveInSRResponse.srNo = existingMoveInSR[0].Name;
                moveInSRResponse.CommunityManager = getCommunityManagerNames(existingMoveInSR[0]);
                
            }else{
                
                moveInSRResponse.status = '';
                moveInSRResponse.moveInDate = '';
                moveInSRResponse.moveInTime = '';
                moveInSRResponse.srId = '';
                
            }
            return moveInSRResponse;
        }
    }
    
    public static MoveInSRResponse cancelMoveInSR(MoveInServiceRequestPayload payloadDataCancelMoveInSR){
        List<HexaBPM__Service_Request__c> existingMoveInSR = [SELECT Id,Name,Unit__r.Project__r.OA_Community_Name__c,HexaBPM__External_SR_Status__c,Unit__r.BuildingSectionName__r.Precint_Name__c,Unit__r.Name,Unit__r.CommunityName__c,HexaBPM__External_Status_Name__c,Move_In_Date__c,Move_In_Time__c,HexaBPM__Customer__r.Name,(SELECT Id, Name FROM HexaBPM__Steps_SR__r WHERE HexaBPM__Step_Status__c='Approved') FROM HexaBPM__Service_Request__c WHERE Unit__c = :payloadDataCancelMoveInSR.unitId AND HexaBPM__Customer__c = :payloadDataCancelMoveInSR.customerId AND SRType__c = 'Aldar Estates Move-In' AND HexaBPM__External_Status_Name__c NOT IN ('Draft', 'Cancelled','Cancelled By User')];
        list<HexaBPM__SR_Status__c > cancelledStatus =[SELECT Id FROM HexaBPM__SR_Status__c   WHERE Name IN ('Cancelled By user')];
        MoveInSRResponse moveInSRResponse = new MoveInSRResponse();
        if ( !existingMoveInSR.isEmpty() && !cancelledStatus.isEmpty() ) {
            
            //if(existingMoveInSR[0].HexaBPM__Steps_SR__r.isEmpty()){
            if( existingMoveInSR[0].HexaBPM__Steps_SR__r == null || existingMoveInSR[0].HexaBPM__Steps_SR__r.isEmpty() ){
                existingMoveInSR[0].HexaBPM__External_SR_Status__c = cancelledStatus[0].Id;
                existingMoveInSR[0].HexaBPM__Internal_SR_Status__c = cancelledStatus[0].Id;
                if (!Test.isRunningTest()) {
                    update existingMoveInSR ;
                }
                 //cancel Steps also
                 HexaBPM__SR_Status__c objSRStatus = [SELECT Id, Name FROM HexaBPM__SR_Status__c WHERE Name IN ('Cancelled By user') LIMIT 1];
                 HexaBPM__Status__c stepStatus = [SELECT Id, Name FROM HexaBPM__Status__c WHERE Name=: Constants.STEP_STATUS_CANCELLED];
                List<HexaBPM__Step__c> stepsList = [SELECT Id, HexaBPM__SR__c FROM HexaBPM__Step__c WHERE HexaBPM__SR__c =: existingMoveInSR[0].Id AND HexaBPM__Closed_Date__c = null LIMIT 1 ];
				List<HexaBPM__Step__c> stepsListToUpdate = new List<HexaBPM__Step__c>();
            	
                if(!stepsList.isEmpty()){
                stepsList[0].HexaBPM__Closed_Date__c = Date.today();
                stepsList[0].HexaBPM__Closed_Date_Time__c = system.now();
                stepsList[0].HexaBPM__Status__c = stepStatus.Id;
                stepsList[0].HexaBPM__Step_Notes__c = 'SR Cancelled By user from LA';
                
                if (!Test.isRunningTest()) {
            	update stepsList;
                }
                }
                moveInSRResponse.status = existingMoveInSR[0].HexaBPM__External_Status_Name__c ;
                moveInSRResponse.moveInDate = string.valueof(existingMoveInSR[0].Move_In_Date__c);
                moveInSRResponse.moveInTime = string.valueof(existingMoveInSR[0].Move_In_Time__c);
                moveInSRResponse.srId = existingMoveInSR[0].Id ;
                moveInSRResponse.customerName = existingMoveInSR[0].HexaBPM__Customer__r.Name;
                moveInSRResponse.unitName = existingMoveInSR[0].Unit__r.Name;
                moveInSRResponse.communityName = existingMoveInSR[0].Unit__r.Project__r.OA_Community_Name__c;
                moveInSRResponse.precinctName = existingMoveInSR[0].Unit__r.BuildingSectionName__r.Precint_Name__c;
                moveInSRResponse.srNo = existingMoveInSR[0].Name;
                moveInSRResponse.CommunityManager = getCommunityManagerNames(existingMoveInSR[0]);
                moveInSRResponse.cancellationResult = 'Cancelled Successfully' ;
            }
            moveInSRResponse.status= existingMoveInSR[0].HexaBPM__External_Status_Name__c ;
            moveInSRResponse.cancellationResult = 'Can\'t cancel since customer Moved-Into the unit' ;
        }
        else{
            
            moveInSRResponse.status= '' ;
            moveInSRResponse.cancellationResult = 'SR doesn\'t exists' ;
            
        }
        return moveInSRResponse;
    }
    
    public static list<string> getCommunityManagerNames (HexaBPM__Service_Request__c sr){
        
        //Community Manager Names
        list<string> CommunityManagerNames= new list<string>();
        String communityName = sr.Unit__r.Project__r.OA_Community_Name__c;
        if(communityName != null){
            list<AE_Comunity_Details__mdt> meta = [SELECT DeveloperName,Queue_Name__c,masterLabel FROM AE_Comunity_Details__mdt WHERE masterLabel =: communityName LIMIT 1];
            if(!meta.isEmpty()){
                list<Group> g = [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND Name =: meta[0].Queue_Name__c];
                if(!g.isEmpty()){
                    List<GroupMember> queueMembers = [SELECT UserOrGroupId FROM GroupMember WHERE GroupId = :g[0].Id];
                    Set<Id> userIds = new Set<Id>();
                    
                    for (GroupMember gm : queueMembers) {
                        if (gm.UserOrGroupId.getSObjectType() == User.SObjectType) {
                            userIds.add(gm.UserOrGroupId);
                            system.debug('userIds::'+userIds);
                        }
                    }
                    if(!userIds.isEmpty()){
                        List<User> users = [SELECT Id, Name, Email FROM User WHERE Id IN :userIds];
                        for (User u : users) {
                            system.debug('Com Manager::'+u);
                            CommunityManagerNames.add(u.Name);
                        }
                    }
                }
            }
        }
        return CommunityManagerNames;
    }
    
    //wrapper
    public class MoveInServiceRequestPayload {
        public string operation { get; set; }
        public String customerId { get; set; }
        public String unitId { get; set; }
        public String srType { get; set; }
        public string salesOrderId { get; set; }
        public RequestDetails requestDetails { get; set; }
        public string origin { get; set; }
        public string srId { get; set; }
        
        public MoveInServiceRequestPayload(String operation, String customerId, String unitId, String srType, RequestDetails requestDetails) {
            this.operation = operation;
            this.customerId = customerId;
            this.unitId = unitId;
            this.srType = srType;
            this.salesOrderId= salesOrderId;
            this.requestDetails = requestDetails;
            this.origin = origin;
        }
    }
    
    public class RequestDetails {
        public Date moveInDate { get; set; }
        public String moveInTime { get; set; }
        public String additionalInfo { get; set; }
        
        public RequestDetails(Date moveInDate, String additionalInfo) {
            this.moveInDate = moveInDate;
            this.additionalInfo = additionalInfo;
        }
    }
    
    public class MoveInServiceRequestResponse {
        public list<object> responseMoveInSRData;
    }
    public class MoveInSRResponse{
        public string srId;
        public string customerId;
        public string status;
        public string moveInDate;
        public string moveInTime;
        public string customerName;
        public string unitName;
        public string communityName;
        public string precinctName;
        public string srNo;
        public list<string> CommunityManager = new list<string>();
        public string cancellationResult;
    }    
    
}