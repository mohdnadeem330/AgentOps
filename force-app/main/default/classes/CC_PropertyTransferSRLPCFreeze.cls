/*
Name : CC_PropertyTransferSRLPCFreeze
Desc : Handles freezing of LPC dates when a Service Request Step is updated.
Author:
Date : 15/10/2025
*/

global without sharing class CC_PropertyTransferSRLPCFreeze implements HexaBPM.iCustomCodeExecutable {

    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp){
         string result ='Success';
         try{
            
            if(stp.HexaBPM__SR__c == null){
                result='CC_PropertyTransferSRLPCFreeze: Invalid SR or SR Step';
            }else{
                
                HexaBPM__Service_Request__c sRRecord = [SELECT Id, Name, RecordTypeId, HexaBPM__External_Status_Name__c, SalesOrder__c,SyncStatus__c FROM HexaBPM__Service_Request__c WHERE id =: stp.HexaBPM__SR__c  limit 1];
                System.debug('@@@stp.HexaBPM__Summary__c'+stp.HexaBPM__Summary__c);
                if(stp.HexaBPM__Summary__c.equalsIgnoreCase('Validate the request by verifying the outstanding liabilities') ){
                    
                    Id propertyTransferRecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', 'Property Transfer');
                    if (sRRecord.RecordTypeId == propertyTransferRecordTypeId) {

                        // ========== FREEZE INSTALLMENT LINES ==========
                        List<InstallmentLines__c> installmentLinesToFreeze = [
                            SELECT Id, InvoiceNumber__c, OutstandingAmount__c,
                                   LPCFreezeDate__c, LPCFreezeUntilDate__c,
                                   isFreezeByTransferSR__c, InstallmentPayoutDate__c,
                                   InstallmentNumber__c
                            FROM InstallmentLines__c
                            WHERE SalesOrder__c = :sRRecord.SalesOrder__c
                            AND InvoiceNumber__c != null
                            AND OutstandingAmount__c > 0
                            AND InstallmentPayoutDate__c < TODAY
                            AND LPCFreezeDate__c = null
                            AND InstallmentNumber__c > 1
                        ];

                        if (!installmentLinesToFreeze.isEmpty()) {
                            List<InstallmentLines__c> installmentLinesToUpdate = new List<InstallmentLines__c>();
                            Date currentDate = System.today();

                            for (InstallmentLines__c il : installmentLinesToFreeze) {
                                il.LPCFreezeDate__c = currentDate;
                                il.LPCFreezeUntilDate__c = currentDate.addDays(60);
                                il.isFreezeByTransferSR__c = true;
                                 il.SyncStatus__c = 'In Progress';
                                installmentLinesToUpdate.add(il);
                            }
                            update installmentLinesToUpdate;
                            System.debug('@@@ Successfully frozen ' + installmentLinesToUpdate.size() + ' InstallmentLines');
                            sRRecord.ServiceRequestComments__c ='The LPC is frozen from '+currentDate + ' to '+ currentDate.addDays(60); 
                            Update sRRecord;
                        } else {
                            System.debug('@@@ No InstallmentLines found to freeze');
                        }

                    } 
                            
                } // end summary check

                   
                              
            }
             
             
             
             return result;
    }
        catch(exception ex){
            return result;
        }
    }


}