public class PropertyTransferBuyerTriggerFlowMigrate {
    
    @InvocableMethod(Label='Create Survey Tracker')
    public static void updateSRandCreateSurveyTracker( List<ServiceRequestClass> SrRequest ){
       //

       HexaBPM__Service_Request__c srReq = new HexaBPM__Service_Request__c(
            Id = SrRequest[0].srId,
            Survey_Required__c = false
        );
        ServiceRequestTriggerHandlerNew.isSkipSrRequestTrigger = true;
        update srReq;

        Survey_Tracker__c	st = new Survey_Tracker__c(
            Service_Request__c = SrRequest[0].srId,
            Touch_Point__c = SrRequest[0].srTouchPoint
        );

        insert st;
    }

    public class ServiceRequestClass{
        @InvocableVariable public String srId;
        @InvocableVariable public String srTouchPoint;
    }
}