@RestResource(urlMapping = '/LiveAldar/CancelRequest')
global class ALD_CancelServiceRequestWebService {
    @HttpPost
    global static void doPost() { 
        RestContextHandler handler = new RestContextHandler(true);
        try {
            RestRequest req = RestContext.request;
            Map<String, Object> reqBodyMap = (Map<String, Object>) JSON.deserializeUntyped(req.requestBody.toString());
            
            // Validate required fields
            if (reqBodyMap == null || !reqBodyMap.containsKey('reqId') || String.isBlank((String)reqBodyMap.get('reqId'))) {
                throw new CustomException('Parameter reqId is required and cannot be empty');
            }

            if (!reqBodyMap.containsKey('reason') || String.isBlank((String)reqBodyMap.get('reason'))) {
                throw new CustomException('Reason is required and cannot be empty');
            }

            handler.response.data = new Map<String,String>{'message'=>cancelRequest(reqBodyMap)};
            handler.response.success = true;
            handler.finalize();
        } catch (CustomException ex) {
            handler.response.success = false;
            handler.response.statusCode = 400; // Bad Request
            handler.response.message = ex.getMessage();
            handler.finalize(ex);
            System.debug('CustomException: ' + ex.getMessage());
        }catch (Exception ex){
            // Handle any other exceptions that occur
            handler.response.success = false; handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = CustomerAPIConstants.MESSAGE_GENERIC_ERROR; handler.finalize(ex);
        }
    }

    // Method to fetch configurations from various sources
    global static String cancelRequest(Map<String, Object> reqBodyMap) {
        
        String saId = ALD_LiveAldarUtilityCtrl.getServiceAppointmentByType((String)reqBodyMap.get('reqId'),'Assessment');
        if(saId != null){
            ServiceAppointment appt = [SELECT Id,ArrivalWindowStartTime ,ArrivalWindowEndTime,SchedStartTime,SchedEndTime  FROM ServiceAppointment WHERE Id=:saId];
             if(appt.SchedStartTime !=null ){ /* Convert milliseconds to hours*/ Decimal diffInHours = ((appt.SchedStartTime.getTime() - DateTime.now().getTime()) / (1000 * 60 * 60));
                // Calculate the difference in milliseconds
                 if(diffInHours < 24 ) { throw new CustomException('Appointments cannot be cancelled less than 24 hours in advance.');}
            }    
        } 
        Case cse = [SELECT Id, Status, DLP_Reason_for_Cancel__c FROM Case WHERE Id = : (String)reqBodyMap.get('reqId')]; 
        if(cse.Status == 'Cancelled' || cse.Status == 'Closed')
            throw new CustomException('Request is already cancelled or closed');
        cse.Status = 'Cancelled';
        cse.DLP_Reason_for_Cancel__c = (String)reqBodyMap.get('reason');  
        update cse;

        List<SObject> lstSobj = new List<SObject>();
        List<ServiceAppointment> lstSA = [SELECT Id, Status, FSSK__FSK_Work_Order__c FROM ServiceAppointment WHERE Case__c = :cse.Id];

        Set<Id> workOrderIds = new Set<Id>();
        for (ServiceAppointment sa : lstSA) {
            sa.Status = 'Canceled';
            workOrderIds.add(sa.FSSK__FSK_Work_Order__c);
            lstSobj.add(sa);
        }

        if (!workOrderIds.isEmpty()) {
            List<WorkOrder> workOrders = new List<WorkOrder>();
            for (Id workOrderId : workOrderIds) {
                workOrders.add(new WorkOrder(Id = workOrderId, Status = 'Canceled'));
            }
            lstSobj.addAll(workOrders);

            List<WorkOrderLineItem> lstWOLI = [SELECT Id, Status FROM WorkOrderLineItem WHERE WorkOrderId IN :workOrderIds];
            for (WorkOrderLineItem woli : lstWOLI) {
                woli.Status = 'Canceled';
                lstSobj.add(woli);
            }
        }

        if (!lstSobj.isEmpty()) {
            update lstSobj;
        }

        
        return 'Request was cancelled successfully!';
    }
  
}