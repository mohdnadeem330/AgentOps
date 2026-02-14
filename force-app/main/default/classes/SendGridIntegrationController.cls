/**********************************************************************************************************************
* Name               : SendGridIntegrationController                                                        
* Description        : Controller Class for the Payment Reminder Emails via SendGrid's REST API
* Created By         : Harsh@Aldar                                                    
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           hrohilla@aldar.com     15/09/2023      Initial Draft    
* 1.1           hrohilla@aldar.com     02/02/2024      Added Handover Microservice
* 1.2           hrohilla@aldar.com     14/03/2024      Added Fasttrack Microservice 
******************************************************************************************************************/
public with sharing class SendGridIntegrationController {

    //tpl6_1, tpl6_2, tpl6_4
    public static void sendPaymentReminder (Map<Id, Integer> docMap){

        //CHECK MAIN KILL SWITCH
        if(SendGridIntegrationUtilities.checkMainKillSwitch()){
            return;
        }

        List<Id> firstPaymentReminderList = new List<Id>();
        List<Id> secondPaymentReminderList = new List<Id>();
        List<Id> thirdPaymentReminderList = new List<Id>();

        if (docMap != null) {
            for (Id recordId : docMap.keySet()) {
                Integer reminderValue = docMap.get(recordId);
                if (reminderValue == 1) {
                    firstPaymentReminderList.add(recordId);
                } else if (reminderValue == 2) {
                    secondPaymentReminderList.add(recordId);
                } else if (reminderValue == 3) {
                    thirdPaymentReminderList.add(recordId);
                }
            }
        }

        if(firstPaymentReminderList.size() > 0){
            sendFirstPaymentReminder(firstPaymentReminderList);
        }
        if(secondPaymentReminderList.size() > 0){
            sendSecondPaymentReminder(secondPaymentReminderList);
        }
        if(thirdPaymentReminderList.size() > 0){
            sendThirdPaymentReminder(thirdPaymentReminderList);
        }
    }

    /**
     * Pass a list of Document Ids for which the Payment Reminder Emails are to be sent
     * It will take data, create, attach and ditribute the Proforma Invoice PDF and Statement of Account PDF files via SendGrid
     */
    private static void sendFirstPaymentReminder(List<Id> documentIdList){
        Map<Id, SendGridWrappers.PaymentMilestoneEmailWrapper> requestWrapperMap = SendGridIntegrationHelper.generateWrapper_PaymentReminder_1(documentIdList);
        
        if (requestWrapperMap != null && requestWrapperMap.size() > 0) {
            // Create an instance of a queueable class to execute the queueable method
            SendGridCalloutQueueable queueable = new SendGridCalloutQueueable(requestWrapperMap);
            // Enqueue the job to run asynchronously
            System.enqueueJob(queueable);
        }
    }

    /**
     * Pass a list of Document Ids for which the Payment Reminder Emails are to be sent
     * It will take data, create, attach and ditribute the Proforma Invoice PDF and Statement of Account PDF files via SendGrid
     */
    private static void sendSecondPaymentReminder(List<Id> documentIdList){
        Map<Id, SendGridWrappers.PaymentMilestoneEmailWrapper> requestWrapperMap = SendGridIntegrationHelper.generateWrapper_PaymentReminder_2(documentIdList);
        
        if (requestWrapperMap != null && requestWrapperMap.size() > 0) {
            // Create an instance of a queueable class to execute the queueable method
            SendGridCalloutQueueable queueable = new SendGridCalloutQueueable(requestWrapperMap);
            // Enqueue the job to run asynchronously
            System.enqueueJob(queueable);
        }
    }

    /**
     * Pass a list of Document Ids for which the Payment Reminder Emails are to be sent
     * It will take data, create, attach and ditribute the Proforma Invoice PDF and Statement of Account PDF files via SendGrid
     */
    private static void sendThirdPaymentReminder(List<Id> documentIdList){
        Map<Id, SendGridWrappers.PaymentMilestoneEmailWrapper> requestWrapperMap = SendGridIntegrationHelper.generateWrapper_PaymentReminder_3(documentIdList);
        
        if (requestWrapperMap != null && requestWrapperMap.size() > 0) {
            // Create an instance of a queueable class to execute the queueable method
            SendGridCalloutQueueable queueable = new SendGridCalloutQueueable(requestWrapperMap);
            // Enqueue the job to run asynchronously
            System.enqueueJob(queueable);
        }
    }

    /**
     * Called from Service Request Trigger Flow, replacing the existing Email Alert //tpl3_20, tpl3_21, tpl3_22
     * Accepts Map of Service Request record ids (HexaBPM__Service_Request__c) => ProcessName (Submitted / Accepted / Rejected)
     * Developed By Harsh@Aldar 28/09/2023
     */
    // @InvocableMethod(label='LPC Waiver Email via SendGrid' iconName='slds:standard:email')
    // public static void sendMail_LPCWaiverSuper (List<SendGridWrappers.LPCFlowInputParamsWrapper> inputParamList) {

    //     //CHECK MAIN KILL SWITCH
    //     if(SendGridIntegrationUtilities.checkMainKillSwitch()){
    //         return;
    //     }

    //     //Map of SRId and process name
    //     Map<String, String> paramMapGeneric = new Map<String, String>(); 

    //     for(SendGridWrappers.LPCFlowInputParamsWrapper thisParam : inputParamList){
    //         paramMapGeneric.put(thisParam.recordIdSR, thisParam.processName.toLowerCase());
    //     }

    //     Map<String, List<String>> paramMapList = new Map<String, List<String>>();

    //     for (String recordIdSR : paramMapGeneric.keySet()) {
    //         String processName = paramMapGeneric.get(recordIdSR);

    //         if (!paramMapList.containsKey(processName)) {
    //             paramMapList.put(processName, new List<String>{recordIdSR});
    //         } else {
    //             paramMapList.get(processName).add(recordIdSR);
    //         }
    //     }

    //     if(paramMapList != null){
    //         Map<Id, SendGridWrappers.PaymentMilestoneEmailWrapper> requestWrapperMap = SendGridIntegrationLPCHelper.generateWrapper_LPCWaiver(paramMapList);
    //         if (requestWrapperMap != null) {
    //             // Create an instance of a queueable class to execute the queueable method
    //             SendGridCalloutQueueable queueable = new SendGridCalloutQueueable(requestWrapperMap);
    //             // Enqueue the job to run asynchronously
    //             System.enqueueJob(queueable);
    //         }
    //     }     
    // }

    /**
     * Called from SendMilestoneChangeNotificationsBatch, replacing the existing Email Alert //tpl1_10
     * Accepts List of Service Request record ids (HexaBPM__Service_Request__c)
     * Developed By Harsh@Aldar 20/12/2023
     */
    // public static void sendPaymentRescheduleEmailReminder(List<Id> documentIdList){
    //     Map<Id, SendGridWrappers.PaymentMilestoneEmailWrapper> requestWrapperMap = SendGridPaymentMilestoneChangeHelper.generateWrapper_PaymentMilestoneChange(documentIdList);
        
    //     if (requestWrapperMap != null) {
    //         // Create an instance of a queueable class to execute the queueable method
    //         SendGridCalloutQueueable queueable = new SendGridCalloutQueueable(requestWrapperMap);
    //         // Enqueue the job to run asynchronously
    //         System.enqueueJob(queueable);
    //     }
    // }

    /**
     * Harsh@Aldar 05/01/2024 Send Handover Notice Email - 60 days prior - offplan
     */
    //tpl7_1
    // public static void sendProjectHandoverNoticeEmail_60Days (List<Id> serviceRequestIdList){

    //     //CHECK MAIN KILL SWITCH
    //     if(SendGridIntegrationUtilities.checkMainKillSwitch()){
    //         return;
    //     }

    //     Map<Id, SendGridWrappers.PaymentMilestoneEmailWrapper> requestWrapperMap = SendGridIntegrationHandoverHelper.generateWrapper_HandoverNotice_60Days(serviceRequestIdList);
    //     if (requestWrapperMap != null) {
    //         // Create an instance of a queueable class to execute the queueable method
    //         SendGridCalloutQueueable queueable = new SendGridCalloutQueueable(requestWrapperMap);
    //         // Enqueue the job to run asynchronously
    //         System.enqueueJob(queueable);
    //     }
    // }

    /**
     * Harsh@Aldar 15/01/2024 Send Different Handover Phasing Letter Emails 
     * typeString : tpl_ho1_1 / tpl_ho1_2 / tpl_ho4 / tpl_ho2_3 / tpl_ho2
     * tpl_ho1_1 => Phasing Letter // Collection => 40 Days Handover Notification  > Handover Batch
     * tpl_ho1_2 => ACD Extension // Collection => Handover Progress (Delay Handover)
     * tpl_ho4 => Home Orientation (Snagging)
     * tpl_ho2_3 => RFO Letter
     * tpl_ho2 => Home Orientation
     */
    public static void sendHandoverPhasingLetter (List<Id> serviceRequestDocIdList, String typeString){

        //CHECK MAIN KILL SWITCH
        if(SendGridIntegrationUtilities.checkMainKillSwitch()){
            return;
        }

        Map<Id, SendGridWrappers.PaymentMilestoneEmailWrapper> requestWrapperMap = SendGridHandoverPhasingHelper.generateWrapper_HandoverPhasing(serviceRequestDocIdList, typeString);
        if (requestWrapperMap != null) {
            // Create an instance of a queueable class to execute the queueable method
            SendGridCalloutQueueable queueable = new SendGridCalloutQueueable(requestWrapperMap);
            // Enqueue the job to run asynchronously
            System.enqueueJob(queueable);
        }
    }

    /**
     * Harsh@Aldar 02/02/2024 Send Different Handover Phasing Payment Reminder Letter Emails 
     * <DocId, 1> => tpl_ho1_3 => Handover Payment Reminder 20 Days
     * <DocId, 2> => Handover Payment Reminder 10 Days
     */
    // public static void sendHandoverPhasing_PaymentReminders (Map<Id, Integer> docMap){

    //     //CHECK MAIN KILL SWITCH
    //     if(SendGridIntegrationUtilities.checkMainKillSwitch()){
    //         return;
    //     }

    //     List<Id> firstPaymentReminderList = new List<Id>();
    //     List<Id> secondPaymentReminderList = new List<Id>();

    //     if (docMap != null) {
    //         for (Id recordId : docMap.keySet()) {
    //             Integer reminderValue = docMap.get(recordId);
    //             if (reminderValue == 1) {
    //                 firstPaymentReminderList.add(recordId);
    //             } else if (reminderValue == 2) {
    //                 secondPaymentReminderList.add(recordId);
    //             } else {
    //                 return;                
    //             }
    //         }
    //     }

    //     if(firstPaymentReminderList.size() > 0){
    //         sendFirstReminder_20Days(firstPaymentReminderList);
    //     }
    //     if(secondPaymentReminderList.size() > 0){
    //         sendSecondReminder_10Days(secondPaymentReminderList);
    //     }
    // }

    /**
     * tpl_ho1_3
     * Pass a list of Document Ids for which the Payment Reminder Emails are to be sent
     * It will take data, create, attach and ditribute the Proforma Invoice PDF and Statement of Account PDF files via SendGrid
     */
    // private static void sendFirstReminder_20Days(List<Id> documentIdList){
    //     Map<Id, SendGridWrappers.PaymentMilestoneEmailWrapper> requestWrapperMap = SendGridHandoverPaymentReminderHelper.generateWrapper_PaymentReminder_20Days(documentIdList);
        
    //     if (requestWrapperMap != null && requestWrapperMap.size() > 0) {
    //         // Create an instance of a queueable class to execute the queueable method
    //         SendGridCalloutQueueable queueable = new SendGridCalloutQueueable(requestWrapperMap);
    //         // Enqueue the job to run asynchronously
    //         System.enqueueJob(queueable);
    //     }
    // }

    /**
     * tpl_ho1_4
     * Pass a list of Document Ids for which the Payment Reminder Emails are to be sent
     * It will take data, create, attach and ditribute the Proforma Invoice PDF and Statement of Account PDF files via SendGrid
     */
    // private static void sendSecondReminder_10Days(List<Id> documentIdList){
    //     Map<Id, SendGridWrappers.PaymentMilestoneEmailWrapper> requestWrapperMap = SendGridHandoverPaymentReminderHelper.generateWrapper_PaymentReminder_10Days(documentIdList);
        
    //     if (requestWrapperMap != null && requestWrapperMap.size() > 0) {
    //         // Create an instance of a queueable class to execute the queueable method
    //         SendGridCalloutQueueable queueable = new SendGridCalloutQueueable(requestWrapperMap);
    //         // Enqueue the job to run asynchronously
    //         System.enqueueJob(queueable);
    //     }
    // }

    /**
     * Harsh@Aldar 27/02/2024 Send Fasttrack Onboarding Email //tpl_fo_1
     */
    // public static void sendFasttrackOnboardingEmail (Id accountId){

    //     //CHECK MAIN KILL SWITCH
    //     if(SendGridIntegrationUtilities.checkMainKillSwitch()){
    //         return;
    //     }

    //     Map<Id, SendGridWrappers.PaymentMilestoneEmailWrapper> requestWrapperMap = SendGridFasttrackHelper.generateWrapper(accountId);
        
    //     if (requestWrapperMap != null && requestWrapperMap.size() > 0) {
    //         // Create an instance of a queueable class to execute the queueable method
    //         SendGridCalloutQueueable queueable = new SendGridCalloutQueueable(requestWrapperMap);
    //         // Enqueue the job to run asynchronously
    //         System.enqueueJob(queueable);
    //     }
    // }
}