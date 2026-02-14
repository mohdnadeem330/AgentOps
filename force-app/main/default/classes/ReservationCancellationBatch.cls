/**
* @File Name         : ReservationCancellationBatch.cls
* @Description       : Batch class to automate reservation cancellation workflow.
* @Author            : Rijwan Mohmmed
* @Last Modified On  : September 25, 2025
* @Modification Log  :
*============================================================================== 
* Ver | Date              | Author         | Modification 
*============================================================================== 
* 1.1 | September 25, 2025| Rijwan Mohmmed  | Inital Commit
**/

global class ReservationCancellationBatch implements Schedulable, Database.Batchable<SObject>, Database.Stateful {

    global Date todayDate = Date.today();
    global Date tomorrowDate = todayDate.addDays(1);
    global Date yesterdayDate = todayDate.addDays(-1);

    // Query locator to fetch eligible sales orders
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id, Cancellation_Deadline__c, ReservationStartDate__c,
                   Status__c, Approval_Status__c, Reservation_Cancellation_Stage__c,
                   DownPaymentAmount__c, Total_Collected_Amount__c,
                   SalesManager__r.Email, RAcknowledgementReservationAmount__c, Reservation_Agreement_Signed__c
            FROM SalesOrder__c
            WHERE Status__c = 'Reservation in Progress'
              AND (
                   Cancellation_Deadline__c = :todayDate OR 
                   Cancellation_Deadline__c = :tomorrowDate OR 
                   Cancellation_Deadline__c = :yesterdayDate
              )
              AND Unit__r.Project__r.Country__c != 'United Kingdom' AND Unit__r.Project__r.Skip_Reservation_Cancellation__c = FALSE
        ]);
    }

    global void execute(Database.BatchableContext BC, List<SalesOrder__c> scope) {
        List<SalesOrder__c> toUpdate = new List<SalesOrder__c>();
        List<Id> refundEmailIds = new List<Id>();
        List<Id> reminderEmailIds = new List<Id>();
        List<Id> autoApprovalIds = new List<Id>();

        for (SalesOrder__c so : scope) {
            if (!isEligibleForCancellation(so)) continue;

            if (isPendingLineManagerApproval(so)) {
                submitApprovalToLineManager(so);
                toUpdate.add(so);

            } else if (isLMApprovedAndDueToday(so)) {
                submitApprovalToSalesOps(so);
                toUpdate.add(so);

            } else if (isReminderConditionMet(so)) {
                reminderEmailIds.add(so.Id);

            } else if (isAutoApprovalDue(so)) {
                autoApprovalIds.add(so.Id);

            } else if (isAutoCancellationDue(so)) {
                so.Status__c = 'Cancelled';
                if (so.Total_Collected_Amount__c > 0 && so.Reservation_Agreement_Signed__c) {
                    refundEmailIds.add(so.Id);
                }
                toUpdate.add(so);
            }
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }

        if (!refundEmailIds.isEmpty()) {
            sendRefundEmails(refundEmailIds);
        }

        if (!reminderEmailIds.isEmpty()) {
            sendCancellationReminders(reminderEmailIds);
        }

        if (!autoApprovalIds.isEmpty()) {
            autoApproveRecords(autoApprovalIds);
        } 
    }

    global void finish(Database.BatchableContext BC) {
        System.debug('ReservationCancellationBatch finished execution.');
    }

    // === CONDITION HELPERS ===

    private Boolean isEligibleForCancellation(SalesOrder__c so) {
        return so.Total_Collected_Amount__c < so.RAcknowledgementReservationAmount__c;
    }

    private Boolean isPendingLineManagerApproval(SalesOrder__c so) {
        return so.Status__c == 'Reservation in Progress' &&
               so.Approval_Status__c == null &&
               so.Cancellation_Deadline__c == todayDate;
    }

    private Boolean isLMApprovedAndDueToday(SalesOrder__c so) {
        return so.Status__c == 'Reservation in Progress' &&
               so.Approval_Status__c == 'LM Approved' &&
               so.Cancellation_Deadline__c == todayDate &&
               so.Total_Collected_Amount__c >= 25000 &&
               so.Total_Collected_Amount__c < so.RAcknowledgementReservationAmount__c;
    }

    private Boolean isReminderConditionMet(SalesOrder__c so) {
        return so.Status__c == 'Reservation in Progress' &&
              (
                  (so.Approval_Status__c == 'LM Approved' && so.Total_Collected_Amount__c < 25000) ||
                   so.Approval_Status__c == 'SO Approved'
              ) &&
               so.Cancellation_Deadline__c == tomorrowDate;
    }

    private Boolean isAutoApprovalDue(SalesOrder__c so) {
        return so.Status__c == 'Reservation in Progress' &&
               (so.Approval_Status__c == 'Pending LM' || so.Approval_Status__c == 'Pending SO') &&
               so.Cancellation_Deadline__c == yesterdayDate;
    }

    private Boolean isAutoCancellationDue(SalesOrder__c so) {
        return so.Status__c == 'Reservation in Progress' &&
               (so.Approval_Status__c == 'LM Approved' || so.Approval_Status__c == 'SO Approved') &&
               so.Cancellation_Deadline__c == yesterdayDate;
    }

    // === EMAIL HANDLERS ===

    private void sendRefundEmails(List<Id> soIds) {
        Flow.Interview.Refund_Reminder_for_Sales_Manager flow = 
            new Flow.Interview.Refund_Reminder_for_Sales_Manager(new Map<String, Object>{
                'SalesOrderIds' => soIds
            });
        flow.start();
    }

    private void sendCancellationReminders(List<Id> soIds) {
        Flow.Interview.Reservation_Cancellation_24HR_Reminder_for_Sales_Manager flow =
            new Flow.Interview.Reservation_Cancellation_24HR_Reminder_for_Sales_Manager(new Map<String, Object>{
                'SalesOrderIds' => soIds
            });
        flow.start();
    }

    // === APPROVAL HANDLERS ===

    public static void submitApprovalToLineManager(SalesOrder__c so) {
        so.Approval_Status__c = 'Pending LM';
        so.Reservation_Cancellation_Stage__c = 'Awaiting LM Approval';

        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setObjectId(so.Id);
        req.setProcessDefinitionNameOrId('Reservation_Cancellation_Line_Manager');
        req.setComments('Auto-submitted for Reservation Cancellation to Line Manager');

        try {
            Approval.ProcessResult result = Approval.process(req);
            if (result.isSuccess()) {
                unlockRecord(so.Id);
            } else {
                System.debug('Line Manager approval submission failed: ' + so.Id);
            }
        } catch (Exception e) {
            System.debug('Exception during LM approval: ' + e.getMessage());
        }
    }

    public static void submitApprovalToSalesOps(SalesOrder__c so) {
        so.Approval_Status__c = 'Pending SO';
        so.Reservation_Cancellation_Stage__c = 'Escalated to SO';

        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setObjectId(so.Id);
        req.setProcessDefinitionNameOrId('Reservation_Cancellation_Sales_Ops');
        req.setComments('Auto-submitted for Reservation Cancellation to Sales Ops');

        try {
            Approval.ProcessResult result = Approval.process(req);
            if (result.isSuccess()) {
                unlockRecord(so.Id);
            } else {
                System.debug('Sales Ops approval submission failed: ' + so.Id);
            }
        } catch (Exception e) {
            System.debug('Exception during SO approval: ' + e.getMessage());
        }
    }

    public static void unlockRecord(Id recordId) {
        List<Approval.UnlockResult> results = Approval.unlock(new List<Id>{recordId});
        for (Approval.UnlockResult res : results) {
            if (!res.isSuccess()) {
                for (Database.Error err : res.getErrors()) {
                    System.debug('Unlock failed for ' + res.getId() + ': ' + err.getMessage());
                }
            }
        }
    }

    public static void autoApproveRecords(List<Id> recordIds) {
        List<ProcessInstanceWorkitem> items = [
            SELECT Id, ProcessInstance.TargetObjectId
            FROM ProcessInstanceWorkitem
            WHERE ProcessInstance.TargetObjectId IN :recordIds
              AND ProcessInstance.ProcessDefinition.DeveloperName IN ('Reservation_Cancellation_Sales_Ops', 'Reservation_Cancellation_Line_Manager')
        ];

        List<Approval.ProcessWorkitemRequest> requests = new List<Approval.ProcessWorkitemRequest>();

        for (ProcessInstanceWorkitem item : items) {
            Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
            req.setWorkitemId(item.Id);
            req.setAction('Reject');
            req.setComments('Auto-rejected via Apex');
            requests.add(req);
        }

        if (!requests.isEmpty()) {
            List<Approval.ProcessResult> results = Approval.process(requests);
            for (Approval.ProcessResult res : results) {
                if (!res.isSuccess()) {
                    System.debug('Auto-rejected failed. Status: ' + res.getInstanceStatus());
                } else {
                    System.debug('Auto-rejected successful.');
                }
            }
        } else {
            System.debug('No records eligible for auto-rejected.');
        }
    }
    
    global void execute(SchedulableContext sc) {
        ReservationCancellationBatch batch = new ReservationCancellationBatch();
        Database.executeBatch(batch, 10); // batch size
    }
}