/*
CC_SRTransferSellerChequeReversalTask
Creates a Task record asking to Cancel/Return the Seller's DD/Cheque and assign it to the DM Finance Queue
*/
global  without sharing class CC_SRTransferSellerChequeReversalTask implements HexaBPM.iCustomCodeExecutable {
    
    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp) {

        try {
            Group grp = [SELECT Id,Name FROM Group WHERE Name='DM Finance Queue'];
            HexaBPM__Service_Request__c serviceRequest = [SELECT Id, Name, HexaBPM__Customer__r.Name, BuyerName__r.Name, Unit__r.Name, AppointmentDate__c  FROM HexaBPM__Service_Request__c WHERE Id = :stp.HexaBPM__SR__c];
            if(grp != null && serviceRequest != null) {
                Task chequeTransferTask = new Task();
                //chequeTransferTask.Subject = 'Cheque Reversal';
                chequeTransferTask.Subject = 'Transfer of unit '+serviceRequest.Unit__r.Name+' from '+serviceRequest.HexaBPM__Customer__r.Name+' to '+serviceRequest.BuyerName__r.Name;
                chequeTransferTask.WhatId = stp.HexaBPM__SR__c;
                chequeTransferTask.ActivityDate = Date.today().addDays(3);
                chequeTransferTask.OwnerId = grp.Id;
                //chequeTransferTask.Description = 'Kindly note that the transfer of unit '+serviceRequest.Unit__r.Name+' from '+serviceRequest.HexaBPM__Customer__r.Name+' to '+serviceRequest.BuyerName__r.Name+' has been initiated.'+serviceRequest.AppointmentDate__c!=null?' Appointment has been fixed on '+String.valueOf(serviceRequest.AppointmentDate__c):''+' Please prepare the seller\'s cheques/DD to be returned/cancelled.';
                chequeTransferTask.Description = 'Kindly note that the transfer of unit '+serviceRequest.Unit__r.Name+' from '+serviceRequest.HexaBPM__Customer__r.Name+' to '+serviceRequest.BuyerName__r.Name+' has been initiated.';
                chequeTransferTask.Description += serviceRequest.AppointmentDate__c!=null?' Appointment has been fixed on '+String.valueOf(serviceRequest.AppointmentDate__c):'';
                chequeTransferTask.Description += ' Please prepare the seller\'s cheques/DD to be returned/cancelled.';
                insert chequeTransferTask;                                                
            }else{
                System.debug('Group : '+grp);
                System.debug('Service Request : '+serviceRequest);
            }
            return null;
        } catch (Exception ex) {
            System.debug('Exception : '+ex.getMessage());
            return null;
        }
    }

}