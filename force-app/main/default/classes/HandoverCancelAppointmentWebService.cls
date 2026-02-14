@RestResource(urlMapping = '/LiveAldar/CancelServiceAppointment')
global without sharing class HandoverCancelAppointmentWebService {
    
    @HttpPost
    global static void doPost() {
        RestContextHandler handler = new RestContextHandler(true);
        try {
            RestRequest req = RestContext.request;
            CancelAppointmentWrapper requestData = (CancelAppointmentWrapper) JSON.deserialize(req.requestBody.toString(), CancelAppointmentWrapper.class);           
            if (requestData == null || String.isBlank(requestData.serviceAppointmentId) || String.isBlank(requestData.workTypeId) || String.isBlank(requestData.territoryId) || String.isBlank(requestData.startTime) || String.isBlank(requestData.endTime) || String.isBlank(requestData.serviceResourceId) || String.isBlank(requestData.cancellationReason)|| String.isBlank(requestData.unitId) || String.isBlank(requestData.serviceRequestId)) {
                throw new CustomException('Invalid input');
            }
            handler.response.data = cancelAppointment(requestData);
            handler.response.success = true;
            handler.finalize();
            
        } catch (CustomException ex) {
            handler.response.success = false;
            handler.response.statusCode = 400;
            handler.response.message = ex.getMessage();
            handler.finalize(ex);
            
        } catch (Exception ex) {
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = CustomerAPIConstants.MESSAGE_GENERIC_ERROR;
            handler.finalize(ex);
        }
    }
    
    Public class CancelAppointmentWrapper {
        public String serviceAppointmentId { get; set; }
        Public String workTypeId { get; set; }
        Public String territoryId { get; set; }
        Public String startTime { get; set; }
        Public String endTime { get; set; }
        Public String serviceResourceId { get; set; }
        Public String cancellationReason { get; set; }
        Public String unitId { get; set; }
        Public String serviceRequestId { get; set; }
    }
    
    public static CancelAppointmentWrapper cancelAppointment(CancelAppointmentWrapper requestData){
        try{
            ServiceAppointment serApp = new ServiceAppointment();
            serApp.Id = requestData.serviceAppointmentId;
            serApp.cancellationReason = requestData.cancellationReason;
            serApp.Status = 'Canceled';
            update serApp;
            
            //Added by Tajinkumar 02-05-2025 (Making Service Appointment & Resource Lookup field Null on Appointment Cancellation)
            String whrClause = ' (Id = \'' + requestData.serviceRequestId + '\') ';
            List<HexaBPM__Service_Request__c> serviceRequestList = CustomerServiceUtility.getServiceRequestDetail(whrClause);
            if(!serviceRequestList.isEmpty() && serviceRequestList.size() > 0) {
                HandoverDetails__c handover =  serviceRequestList[0].HandoverDetail__r;
                Boolean isCancelled = false;
                if(handover != null) { 
                    if (handover.Home_Orientation_Appointment__c == requestData.serviceAppointmentId) {
                        handover.Home_Orientation_Appointment__c = null;
                        handover.Home_Orientation_Appointment_Resource__c = null;
                        isCancelled = true;
                    } else if (handover.Desnagging_Appointment__c == requestData.serviceAppointmentId) {
                        handover.Desnagging_Appointment__c = null;
                        handover.Desnagging_Appointment_Resource__c = null;
                        isCancelled = true;
                    } else if (handover.Key_Handover_Appointment__c == requestData.serviceAppointmentId) {
                        handover.Key_Handover_Appointment__c = null;
                        handover.Key_Handover_Appointment_Resource__c = null;
                        isCancelled = true;
                    } 
                    if(isCancelled)
                        update handover;
                }
            } 
            
        } catch (Exception e) {
            System.debug('Error in cancelAppointment: ' + e.getMessage());
            throw new CustomException('Error while cancelling the Service Appointment: ' + e.getMessage());
        }
        return requestData;
    }

}