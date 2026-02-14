@RestResource(urlMapping = '/customer/moveOutService')
global without sharing class CustomerMoveOutServiceRequestHandler {
    
    @HttpPost
    global static void MoveOut() {
        RestContextHandler handler = new RestContextHandler(false);
        try {
            MoveOutServiceRequestPayload requestData = (MoveOutServiceRequestPayload) JSON.deserialize(RestContext.request.requestBody.toString(), MoveOutServiceRequestPayload.class);
            System.debug('Request Data::</>' + requestData);
            object responseData;
            if(requestData.requestDetails != null  && requestData.operation == 'create'){
                responseData = createMoveOutSR(requestData);
            }
            else if(requestData!= null && requestData.operation == 'get'){
                responseData =   getMoveOutSRDetails(requestData);
            } 
            else if(requestData!= null && requestData.operation == 'cancel' ){
                responseData =   cancelMoveOutSR(requestData);
            }
            
            handler.response.data = responseData;
            handler.response.success = true;
            handler.finalize();
        } catch (Exception ex) {
            System.debug('Exception at Line: ' + ex.getLineNumber() + ' Message: ' + ex.getMessage());
            Logger__c lgs = LoggerService.createApexLog(ex,'MoveOutSRHandler','CustomerMoveOutServiceRequestHandler','MoveOut');
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = ex.getMessage();
            handler.finalize(ex);
        }
    }
    
    public static moveOutSRResponse createMoveOutSR(MoveOutServiceRequestPayload payloadDataMoveInSR){
        
        List<HexaBPM__Service_Request__c> existingMoveOutSR = [SELECT Id,Name,HexaBPM__External_Status_Name__c,HexaBPM__Submitted_DateTime__c,Move_Out_Date__c,Move_Out_Time__c,HexaBPM__Customer__r.Name,Unit__r.Name,Unit__r.CommunityName__c,Unit__r.BuildingSectionName__r.Precint_Name__c,Unit__r.Project__r.OA_Community_Name__c FROM HexaBPM__Service_Request__c WHERE Unit__c = :payloadDataMoveInSR.unitId AND HexaBPM__Customer__c = :payloadDataMoveInSR.customerId AND SRType__c ='Aldar Estates Move-Out' AND  HexaBPM__External_Status_Name__c NOT IN ('Draft', 'Cancelled','Cancelled By User') ];
        List<HexaBPM__Service_Request__c> existingMoveInSR = [SELECT Id,Name,HexaBPM__External_Status_Name__c,HexaBPM__Submitted_DateTime__c,Move_In_Date__c,Move_In_Time__c,HexaBPM__Customer__r.Name,Unit__r.Name,Unit__r.CommunityName__c,Unit__r.BuildingSectionName__r.Precint_Name__c,Unit__r.Project__r.OA_Community_Name__c FROM HexaBPM__Service_Request__c WHERE Unit__c = :payloadDataMoveInSR.unitId AND HexaBPM__Customer__c = :payloadDataMoveInSR.customerId AND SRType__c ='Aldar Estates Move-In' AND HexaBPM__External_Status_Name__c NOT IN ('Draft', 'Cancelled','Cancelled By User','Closed')];
        system.debug('existingMoveOutSR::'+existingMoveOutSR);
        moveOutSRResponse moveOutSRResponse = new moveOutSRResponse();
        
        /*if ( !existingMoveInSR.isEmpty()) {
//NotifyCommunityManager
//once we have emailTemplate will update 
EmailTemplate et = [SELECT Id FROM EmailTemplate WHERE Name = 'Signed NOC Property NOC'];
List<string> toAddress = new List<string>();
Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
mail.setTemplateId(et.Id);
mail.setToAddresses(toAddress);
mail.setSubject('Close MoveIn Immediately');
mail.setTargetObjectId( existingMoveInSR[0].OwnerId );
mail.setWhatId(existingMoveInSR[0].Id);
mail.setSaveAsActivity(false);
mail.setUseSignature(false);
List<Messaging.SingleEmailMessage> allmsg = new List<Messaging.SingleEmailMessage>();
allmsg.add(mail);

Messaging.sendEmail(allmsg,false);


}*/
        
        if (existingMoveOutSR.isEmpty() ) {
            
            list<Unit__c> matchingUnit = [SELECT Id,Name FROM Unit__c WHERE Id =: payloadDataMoveInSR.unitId ];
            list<Asset> matchingAssets	= new list<Asset>(); 
            if(!matchingUnit.isEmpty()){
                matchingAssets	= [SELECT Id,ECSS_Unit_Number__c FROM Asset WHERE  Unit__r.Name =: matchingUnit[0].Name ];
            }
            list<Account> customerAcc = [SELECT Id,personemail FROM Account WHERE Id = : payloadDataMoveInSR.customerId] ;
            
            HexaBPM__Service_Request__c newMoveOutSR = new HexaBPM__Service_Request__c();
            newMoveOutSR.SRType__c = 'Aldar Estates Move-Out';
            newMoveOutSR.Origin__c = payloadDataMoveInSR.origin;
            newMoveOutSR.HexaBPM__Customer__c = payloadDataMoveInSR.customerId ;
            newMoveOutSR.Unit__c= payloadDataMoveInSR.unitId ;
            newMoveOutSR.SalesOrder__c = payloadDataMoveInSR.salesOrderId;
            newMoveOutSR.Move_Out_Date__c = payloadDataMoveInSR.requestDetails.moveOutDate ;
            newMoveOutSR.HexaBPM__Email__c = customerAcc[0].personemail;
            newMoveOutSR.Move_Out_Time__c = payloadDataMoveInSR.requestDetails.moveOutTime ??'';
            if (!Test.isRunningTest()) {
                newMoveOutSR.RecordTypeId =  Schema.SObjectType.HexaBPM__Service_Request__c.getRecordTypeInfosByDeveloperName().get('AldarEstatesMoveOut').getRecordTypeId();
            }
            newMoveOutSR.Asset__c =  !matchingAssets.isEmpty() ? matchingAssets[0].Id : null;      
            list<HexaBPM__SR_Status__c > draftStatus =[SELECT Id FROM HexaBPM__SR_Status__c   WHERE Name IN ('Draft')];
            newMoveOutSR.HexaBPM__External_SR_Status__c = draftStatus[0].Id;
            newMoveOutSR.HexaBPM__Internal_SR_Status__c = draftStatus[0].Id;
            if (!Test.isRunningTest()) {
                insert newMoveOutSR;
            }
            
            HexaBPM__Service_Request__c insertedMoveOutSR = [SELECT Id,Name,HexaBPM__External_Status_Name__c,HexaBPM__Submitted_DateTime__c,Move_Out_Date__c,Move_Out_Time__c,HexaBPM__Customer__r.Name,Unit__r.Name,Unit__r.CommunityName__c,Unit__r.BuildingSectionName__r.Precint_Name__c,Unit__r.Project__r.OA_Community_Name__c FROM HexaBPM__Service_Request__c WHERE Id=:newMoveOutSR.id ];
            system.debug('status::'+insertedMoveOutSR.HexaBPM__External_Status_Name__c);
            moveOutSRResponse.srId = insertedMoveOutSR.Id;
            moveOutSRResponse.customerId = insertedMoveOutSR.HexaBPM__Customer__c;
            moveOutSRResponse.status = insertedMoveOutSR.HexaBPM__External_Status_Name__c ;
            moveOutSRResponse.moveOutDate = string.valueof(insertedMoveOutSR.Move_Out_Date__c);
            moveOutSRResponse.moveOutTime = string.valueof(insertedMoveOutSR.Move_Out_Time__c);
            
            moveOutSRResponse.customerName = insertedMoveOutSR.HexaBPM__Customer__r.Name;
            moveOutSRResponse.unitName = insertedMoveOutSR.Unit__r.Name;
            moveOutSRResponse.communityName = insertedMoveOutSR.Unit__r.project__r.OA_Community_Name__c;
            moveOutSRResponse.precinctName = insertedMoveOutSR.Unit__r.BuildingSectionName__r.Precint_Name__c;
            moveOutSRResponse.srNo = insertedMoveOutSR.Name;
            moveOutSRResponse.CommunityManager = CustomerMoveInServiceRequestHandler.getCommunityManagerNames(insertedMoveOutSR);
            
        }else{
            moveOutSRResponse.srId = existingMoveOutSR[0].Id ;
            moveOutSRResponse.customerId = existingMoveOutSR[0].HexaBPM__Customer__c ;
            moveOutSRResponse.status =existingMoveOutSR[0].HexaBPM__External_Status_Name__c ;
            moveOutSRResponse.moveOutDate = string.valueof(existingMoveOutSR[0].Move_Out_Date__c);
            moveOutSRResponse.moveOutTime = string.valueof(existingMoveOutSR[0].Move_Out_Time__c);
            
            moveOutSRResponse.customerName = existingMoveOutSR[0].HexaBPM__Customer__r.Name;
            moveOutSRResponse.unitName = existingMoveOutSR[0].Unit__r.Name;
            moveOutSRResponse.communityName = existingMoveOutSR[0].Unit__r.Project__r.OA_Community_Name__c;
            moveOutSRResponse.precinctName = existingMoveOutSR[0].Unit__r.BuildingSectionName__r.Precint_Name__c;
            moveOutSRResponse.srNo = existingMoveOutSR[0].Name;
            moveOutSRResponse.CommunityManager = CustomerMoveInServiceRequestHandler.getCommunityManagerNames(existingMoveOutSR[0]);
            
        }
        return moveOutSRResponse;
    }
    
    public static moveOutSRResponse getMoveOutSRDetails(MoveOutServiceRequestPayload payloadDatagetMoveOutSRDetails){
        
        
       if(String.isNotBlank(payloadDatagetMoveOutSRDetails.srId)){
            moveOutSRResponse moveOutSRResponse= new moveOutSRResponse();
            list<HexaBPM__Service_Request__c> cancelledMoveInSR = [SELECT Id,Name,HexaBPM__External_Status_Name__c,HexaBPM__Submitted_DateTime__c,Move_Out_Date__c,Move_Out_Time__c,HexaBPM__Customer__r.Name,Unit__r.Name,Unit__r.CommunityName__c,Unit__r.BuildingSectionName__r.Precint_Name__c,Unit__r.Project__r.OA_Community_Name__c FROM HexaBPM__Service_Request__c WHERE id=:payloadDatagetMoveOutSRDetails.srId] ;
            moveOutSRResponse.status = cancelledMoveInSR[0].HexaBPM__External_Status_Name__c ;
            moveOutSRResponse.moveOutDate = string.valueof(cancelledMoveInSR[0].Move_Out_Date__c);
            moveOutSRResponse.moveOutTime = string.valueof(cancelledMoveInSR[0].Move_Out_Time__c);
            moveOutSRResponse.srId = cancelledMoveInSR[0].Id ;
            moveOutSRResponse.customerName = cancelledMoveInSR[0].HexaBPM__Customer__r.Name;
            moveOutSRResponse.unitName = cancelledMoveInSR[0].Unit__r.Name;
            moveOutSRResponse.communityName = cancelledMoveInSR[0].Unit__r.Project__r.OA_Community_Name__c;
            moveOutSRResponse.precinctName = cancelledMoveInSR[0].Unit__r.BuildingSectionName__r.Precint_Name__c;
            moveOutSRResponse.srNo = cancelledMoveInSR[0].Name;
            moveOutSRResponse.CommunityManager = CustomerMoveInServiceRequestHandler.getCommunityManagerNames( cancelledMoveInSR[0]);
            
            
            return moveOutSRResponse;
        }else{
            
            
        List<HexaBPM__Service_Request__c> existingMoveOutSR = [SELECT Id,Name,HexaBPM__External_Status_Name__c,HexaBPM__Submitted_DateTime__c,Move_Out_Date__c,Move_Out_Time__c,HexaBPM__Customer__r.Name,Unit__r.Name,Unit__r.CommunityName__c,Unit__r.BuildingSectionName__r.Precint_Name__c,Unit__r.Project__r.OA_Community_Name__c FROM HexaBPM__Service_Request__c WHERE Unit__c = :payloadDatagetMoveOutSRDetails.unitId AND HexaBPM__Customer__c = :payloadDatagetMoveOutSRDetails.customerId AND SRType__c = 'Aldar Estates Move-Out' AND HexaBPM__External_Status_Name__c NOT IN ('Draft', 'Cancelled','Cancelled By User')];
        system.debug('existingMoveOutSR::'+ existingMoveOutSR);
        moveOutSRResponse moveOutSRResponse= new moveOutSRResponse();
        if (!existingMoveOutSR.isEmpty()) {
            
            moveOutSRResponse.status = existingMoveOutSR[0].HexaBPM__External_Status_Name__c ;
            moveOutSRResponse.moveOutDate = string.valueof(existingMoveOutSR[0].Move_Out_Date__c);
            moveOutSRResponse.moveOutTime = string.valueof(existingMoveOutSR[0].Move_Out_Time__c);
            moveOutSRResponse.srId = existingMoveOutSR[0].Id ;
            moveOutSRResponse.customerName = existingMoveOutSR[0].HexaBPM__Customer__r.Name;
            moveOutSRResponse.unitName = existingMoveOutSR[0].Unit__r.Name;
            moveOutSRResponse.communityName = existingMoveOutSR[0].Unit__r.Project__r.OA_Community_Name__c;
            moveOutSRResponse.precinctName = existingMoveOutSR[0].Unit__r.BuildingSectionName__r.Precint_Name__c;
            moveOutSRResponse.srNo = existingMoveOutSR[0].Name;
            moveOutSRResponse.CommunityManager = CustomerMoveInServiceRequestHandler.getCommunityManagerNames( existingMoveOutSR[0]);
            
        }else{
            
            moveOutSRResponse.status = '';
            moveOutSRResponse.moveOutDate = '';
            moveOutSRResponse.moveOutTime = '';
            moveOutSRResponse.srId = '';
            
        }
        return moveOutSRResponse;
        }
        
    }
    
    public static moveOutSRResponse cancelMoveOutSR(MoveOutServiceRequestPayload payloadDatacancelMoveOutSR){
        List<HexaBPM__Service_Request__c> existingMoveOutSR = [SELECT Id,Name,Unit__r.Project__r.OA_Community_Name__c,HexaBPM__External_SR_Status__c,Unit__r.BuildingSectionName__r.Precint_Name__c,Unit__r.Name,Unit__r.CommunityName__c,HexaBPM__External_Status_Name__c,Move_Out_Date__c,Move_Out_Time__c,HexaBPM__Customer__r.Name,(SELECT Id, Name FROM HexaBPM__Steps_SR__r WHERE HexaBPM__Step_Status__c='Approved') FROM HexaBPM__Service_Request__c WHERE Unit__c = :payloadDatacancelMoveOutSR.unitId AND HexaBPM__Customer__c = :payloadDatacancelMoveOutSR.customerId AND SRType__c = 'Aldar Estates Move-Out' AND HexaBPM__External_Status_Name__c NOT IN ('Draft', 'Cancelled','Cancelled By User')];
        list<HexaBPM__SR_Status__c > cancelledStatus =[SELECT Id FROM HexaBPM__SR_Status__c   WHERE Name IN ('Cancelled By user')];
        moveOutSRResponse moveOutSRResponse = new moveOutSRResponse();
        
        
        if ( !existingMoveOutSR.isEmpty() && !cancelledStatus.isEmpty() ) {
            
            
            existingMoveOutSR[0].HexaBPM__External_SR_Status__c = cancelledStatus[0].Id;
            existingMoveOutSR[0].HexaBPM__Internal_SR_Status__c = cancelledStatus[0].Id;
            if (!Test.isRunningTest()) {
                update existingMoveOutSR ;
            }
            //cancel Steps also
            HexaBPM__SR_Status__c objSRStatus = [SELECT Id, Name FROM HexaBPM__SR_Status__c WHERE Name IN ('Cancelled By user') LIMIT 1];
            HexaBPM__Status__c stepStatus = [SELECT Id, Name FROM HexaBPM__Status__c WHERE Name=: Constants.STEP_STATUS_CANCELLED];
            List<HexaBPM__Step__c> stepsList = [SELECT Id, HexaBPM__SR__c FROM HexaBPM__Step__c WHERE HexaBPM__SR__c =: existingMoveOutSR[0].Id AND HexaBPM__Closed_Date__c = null LIMIT 1 ];
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
            moveOutSRResponse.status = existingMoveOutSR[0].HexaBPM__External_Status_Name__c ;
            moveOutSRResponse.moveOutDate = string.valueof(existingMoveOutSR[0].Move_Out_Date__c);
            moveOutSRResponse.moveOutTime = string.valueof(existingMoveOutSR[0].Move_Out_Time__c);
            moveOutSRResponse.srId = existingMoveOutSR[0].Id ;
            moveOutSRResponse.customerName = existingMoveOutSR[0].HexaBPM__Customer__r.Name;
            moveOutSRResponse.unitName = existingMoveOutSR[0].Unit__r.Name;
            moveOutSRResponse.communityName = existingMoveOutSR[0].Unit__r.Project__r.OA_Community_Name__c;
            moveOutSRResponse.precinctName = existingMoveOutSR[0].Unit__r.BuildingSectionName__r.Precint_Name__c;
            moveOutSRResponse.srNo = existingMoveOutSR[0].Name;
            moveOutSRResponse.cancellationResult = 'Cancelled Successfully' ;
            moveOutSRResponse.CommunityManager = CustomerMoveInServiceRequestHandler.getCommunityManagerNames( existingMoveOutSR[0]);
            
        }
        else{
            
            moveOutSRResponse.status= '' ;
            moveOutSRResponse.cancellationResult = 'SR doesn\'t exists' ;
            
        }
        return moveOutSRResponse;
    }
    
    
    //wrapper
    public class MoveOutServiceRequestPayload {
        public string operation { get; set; }
        public String customerId { get; set; }
        public String unitId { get; set; }
        public String srType { get; set; }
        public string salesOrderId { get; set; }
        public RequestDetails requestDetails { get; set; }
        public string origin { get; set; }
        public string srId { get; set; }
        
        public MoveOutServiceRequestPayload(String operation, String customerId, String unitId, String srType, RequestDetails requestDetails) {
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
        public Date moveOutDate { get; set; }
        public String moveOutTime { get; set; }
        public String additionalInfo { get; set; }
        
        public RequestDetails(Date moveOutDate, String additionalInfo) {
            this.moveOutDate = moveOutDate;
            this.additionalInfo = additionalInfo;
        }
    }
    
    public class MoveInServiceRequestResponse {
        public list<object> responseMoveInSRData;
    }
    public class moveOutSRResponse{
        public string srId;
        public string customerId;
        public string status;
        public string moveOutDate;
        public string moveOutTime;
        public string customerName;
        public string unitName;
        public string communityName;
        public string precinctName;
        public string srNo;
        public string cancellationResult;
        public list<string> CommunityManager = new list<string>();
    }    
    
}