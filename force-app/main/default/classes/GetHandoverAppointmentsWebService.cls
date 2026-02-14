@RestResource(urlMapping = '/LiveAldar/GetHandoverAppointments')
global without sharing class GetHandoverAppointmentsWebService {
    
    global static Map<Id, ServiceResource> resourceMap = new Map<Id, ServiceResource>();

    @HttpPost
    global static void doPost() {
        RestContextHandler handler = new RestContextHandler(true);
        try {
            RestRequest req = RestContext.request;
            GetAppointmentsRequestWrapper requestData = (GetAppointmentsRequestWrapper) JSON.deserialize(req.requestBody.toString(), GetAppointmentsRequestWrapper.class); 
            if (requestData == null || String.isBlank(requestData.unitId) || String.isBlank(requestData.serviceRequestId) || String.isBlank(requestData.resourceType)) {
                throw new CustomException('Invalid input');
            }
            handler.response.data = getAppointmentDetails(requestData.unitId, requestData.serviceRequestId, requestData.resourceType);
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
    
    public class GetAppointmentsRequestWrapper {
        public String unitId { get; set; }
        public String serviceRequestId { get; set; } 
        public String resourceType {get; set; }
    }
    
    public class HandoverAppointmentWrapper {
        public String serviceAppointmentId { get; set; }
        public DateTime schedStartTime { get; set; }
        public DateTime schedEndTime { get; set; }
        public String serviceResourceId { get; set; }
        public String serviceResourceName { get; set; }
        public String workTypeId { get; set; }
        public String territoryId { get; set; }
        public String appointmentStatus { get; set; }
        public String appointmentType { get; set; }

        // NEW FIELDS
        public String homeOrientationType { get; set; }
        public String virtualMeetingURL { get; set; }
        
        public HandoverAppointmentWrapper(String serviceAppointmentId, DateTime schedStartTime, DateTime schedEndTime, 
                                          String serviceResourceId, String workTypeId, String territoryId, String appointmentStatus, String appointmentType) {
                                              this.serviceAppointmentId = serviceAppointmentId;
                                              this.schedStartTime = schedStartTime;
                                              this.schedEndTime = schedEndTime;
                                              this.serviceResourceId = serviceResourceId;
            this.serviceResourceName = resourceMap.containsKey(serviceResourceId) ? resourceMap.get(serviceResourceId).Name : null;
                                              this.workTypeId = workTypeId;
                                              this.territoryId = territoryId;
                                              this.appointmentStatus = appointmentStatus;
                                              this.appointmentType = appointmentType;
                                          }
    }
    
    public class AppointmentResponseWrapper {
        public String unitId { get; set; }
        public String serviceRequestId { get; set; }  
        public List<HandoverAppointmentWrapper> appointmentList { get; set; }
       
        public AppointmentResponseWrapper(String unitId, String serviceRequestId, List<HandoverAppointmentWrapper> appointmentList) {
            this.unitId = unitId;
            this.serviceRequestId = serviceRequestId;
            this.appointmentList = appointmentList;
        }
    }
    
    public static AppointmentResponseWrapper getAppointmentDetails(String unitId, String sRId, String resourceType) {
        
        Map<String,String> getAppointmentType = new Map<String,String>{
            CustomerAPIConstants.APPOINTMENT_LABEL_HOME_ORIENTATION => 'Home Orientation Appointment',
            CustomerAPIConstants.APPOINTMENT_TYPE_SNAG_VERIFICATION => 'Desnagging Appointment',
            CustomerAPIConstants.STEP_KEY_HANDOVER => 'Key Handover Appointment'
        };
        
        List<HandoverAppointmentWrapper> appointmentList = new List<HandoverAppointmentWrapper>();
        try {
            List<HexaBPM__Service_Request__c> sRRec = [
                SELECT Id, HandoverDetail__c
                                                       FROM HexaBPM__Service_Request__c
                WHERE Id = :sRId
            ];     

            if (sRRec.isEmpty()) {
                throw new CustomException('No Service Request found.');
            }

            List<HandoverDetails__c> hDRec = [
                SELECT Id, 
                Home_Orientation_Appointment__c, 
                Home_Orientation_Appointment__r.SchedStartTime, 
                Home_Orientation_Appointment__r.SchedEndTime, 
                Home_Orientation_Appointment_Resource__c, 
                Home_Orientation_Appointment__r.WorkTypeId,
                Home_Orientation_Appointment__r.ServiceTerritoryId,
                Home_Orientation_Appointment_Status__c,
                    Home_Orientation_Type__c,
                    Virtual_Meeting_URL__c,
                Desnagging_Appointment__c,
                Desnagging_Appointment__r.SchedStartTime, 
                Desnagging_Appointment__r.SchedEndTime, 
                Desnagging_Appointment_Resource__c, 
                Desnagging_Appointment__r.WorkTypeId,
                Desnagging_Appointment__r.ServiceTerritoryId,
                Desnagging_Appointment_Status__c,
                Key_Handover_Appointment__c,
                Key_Handover_Appointment__r.SchedStartTime, 
                Key_Handover_Appointment__r.SchedEndTime, 
                Key_Handover_Appointment_Resource__c,
                Key_Handover_Appointment__r.WorkTypeId,
                Key_Handover_Appointment__r.ServiceTerritoryId,
                Key_Handover_Appointment_Status__c
                FROM HandoverDetails__c 
                WHERE Id = :sRRec[0].HandoverDetail__c 
            ];         

            if (hDRec.isEmpty()) {
                throw new CustomException('No Handover Detail Record found.');
            }          

            HandoverDetails__c record = hDRec[0];
            Set<Id> resourceIds = new Set<Id>();
            if(record.Home_Orientation_Appointment_Resource__c != null) resourceIds.add(record.Home_Orientation_Appointment_Resource__c);
            if(record.Desnagging_Appointment_Resource__c != null) resourceIds.add(record.Desnagging_Appointment_Resource__c);
            if(record.Key_Handover_Appointment_Resource__c != null) resourceIds.add(record.Key_Handover_Appointment_Resource__c);

            resourceMap = new Map<Id, ServiceResource>(
            	[SELECT	Id, Name FROM ServiceResource WHERE Id IN :resourceIds]
            );

            if (record.Home_Orientation_Appointment__c != null && resourceType == CustomerAPIConstants.APPOINTMENT_LABEL_HOME_ORIENTATION) {
                HandoverAppointmentWrapper wrapper = new HandoverAppointmentWrapper(
                    record.Home_Orientation_Appointment__c,
                    record.Home_Orientation_Appointment__r.SchedStartTime,
                    record.Home_Orientation_Appointment__r.SchedEndTime,
                    record.Home_Orientation_Appointment_Resource__c,
                    record.Home_Orientation_Appointment__r.WorkTypeId,
                    record.Home_Orientation_Appointment__r.ServiceTerritoryId,
                    record.Home_Orientation_Appointment_Status__c,
                    getAppointmentType.get(CustomerAPIConstants.APPOINTMENT_LABEL_HOME_ORIENTATION)
                );

                // Set new fields
                wrapper.homeOrientationType = record.Home_Orientation_Type__c;
                wrapper.virtualMeetingURL = record.Virtual_Meeting_URL__c;

                appointmentList.add(wrapper);
            }         

            if (record.Desnagging_Appointment__c != null && resourceType == CustomerAPIConstants.APPOINTMENT_TYPE_SNAG_VERIFICATION) {
                appointmentList.add(new HandoverAppointmentWrapper(
                    record.Desnagging_Appointment__c,
                    record.Desnagging_Appointment__r.SchedStartTime,
                    record.Desnagging_Appointment__r.SchedEndTime,
                    record.Desnagging_Appointment_Resource__c,
                    record.Desnagging_Appointment__r.WorkTypeId,
                    record.Desnagging_Appointment__r.ServiceTerritoryId,
                    record.Desnagging_Appointment_Status__c,
                    getAppointmentType.get(CustomerAPIConstants.APPOINTMENT_TYPE_SNAG_VERIFICATION)
                ));
            } 

            if (record.Key_Handover_Appointment__c != null && resourceType == CustomerAPIConstants.STEP_KEY_HANDOVER) {
                appointmentList.add(new HandoverAppointmentWrapper(
                    record.Key_Handover_Appointment__c,
                    record.Key_Handover_Appointment__r.SchedStartTime,
                    record.Key_Handover_Appointment__r.SchedEndTime,
                    record.Key_Handover_Appointment_Resource__c,
                    record.Key_Handover_Appointment__r.WorkTypeId,
                    record.Key_Handover_Appointment__r.ServiceTerritoryId,
                    record.Key_Handover_Appointment_Status__c,
                    getAppointmentType.get(CustomerAPIConstants.STEP_KEY_HANDOVER)
                ));
            }                    
        } catch (Exception e) {
            System.debug('Error in getAppointmentDetails: ' + e.getMessage());
        }

        return new AppointmentResponseWrapper(unitId, SRId, appointmentList); 
    }   
}