/**********************************************************************************************************************
* Name               : ValidateCrateDandTSRBatch                                                         
* Description        : Class to Send reminder before the due date (Default Process)
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           paras.bhatt@pwc.com     06/09/2022      Initial Draft       
**********************************************************************************************************************/

global class ValidateCrateDandTSRBatch implements Database.Batchable<sObject>,Database.AllowsCallouts,Schedulable{
    set<ID> installmentIdsToProcess = new set<ID>();
    public ValidateCrateDandTSRBatch(set<ID> recordIDs){
        this.installmentIdsToProcess =recordIDs;
    }
    global void execute(SchedulableContext ctx) { 
        database.executebatch(this,1);
    }
    global Database.QueryLocator start(Database.BatchableContext bc) {
        //31 days post RFO
        //14 days for normal case
        // set<String> soldSR = HandoverUtility.soldSR; **** COMMENTED "APPROVAL PENDING" D&T Stopped *****
        set<String> soldSR = new set<String>{'RTO Sold', 'Sold'};
        //SS_TO_REMOVE_MORTGAGE_CHEQUE_ALLOCATED_IL_FROM_CREATING_DANDT_SR_03Aug23 //APPENDED ALLOCATION QUERY IN BELOW SOQL
        //*** COMMENTED FOR Modify **** String query='SELECT Id,SalesOrder__r.RecordTypeId,SalesOrder__r.RecordType.Name,SalesOrder__r.Account__r.PersonEmail,SalesOrder__r.Contact__c,SalesOrder__r.Contact__r.Email,SalesOrder__c,SalesOrder__r.Opportunity__r.Contact__c,(select id from Receipt_Allocations__r where ReceiptAcknowledgement__r.PaymentType__c=\'Mortgage Cheque\')  FROM InstallmentLines__c WHERE InstallmentNumber__c != 1 and OutstandingAmountToReceive__c > '+ System.Label.CommissionAmountBuffer +' and SalesOrder__r.Status__c in :soldSR and ( (PaymentInstallments__r.isHandoverPayment__c =false and InstallmentDate__c = N_DAYS_AGO:9 ) or (PaymentInstallments__r.isHandoverPayment__c =true and SalesOrder__r.HandoverRFOPayDueDate__c = TODAY))';
        String query='SELECT Id,SalesOrder__r.RecordTypeId,SalesOrder__r.RecordType.Name,SalesOrder__r.Account__r.PersonEmail,SalesOrder__r.Contact__c,SalesOrder__r.Contact__r.Email,SalesOrder__c,SalesOrder__r.Opportunity__r.Contact__c,(select id from Receipt_Allocations__r where ReceiptAcknowledgement__r.PaymentType__c=\'Mortgage Cheque\' AND ReceiptAcknowledgement__r.Status__c != \'Reversed\'), StopDefaultNotice__c FROM InstallmentLines__c WHERE Default_Date__c = TODAY';
        if(installmentIdsToProcess<>null && !installmentIdsToProcess.isEmpty()){
            query='SELECT  Id,SalesOrder__r.RecordTypeId,SalesOrder__r.RecordType.Name,SalesOrder__r.Account__r.PersonEmail,SalesOrder__r.Contact__c,SalesOrder__r.Contact__r.Email,SalesOrder__c,SalesOrder__r.Opportunity__r.Contact__c,(select id from Receipt_Allocations__r where ReceiptAcknowledgement__r.PaymentType__c=\'Mortgage Cheque\' AND ReceiptAcknowledgement__r.Status__c != \'Reversed\'),StopDefaultNotice__c FROM InstallmentLines__c WHERE id in :installmentIdsToProcess and ChequeReversalDefault__c = true';
        }
        if(Test.isRunningTest()){
            query='SELECT  Id,SalesOrder__r.RecordTypeId,SalesOrder__r.RecordType.Name,SalesOrder__r.Account__r.PersonEmail,SalesOrder__r.Contact__c,SalesOrder__r.Contact__r.Email,SalesOrder__c,SalesOrder__r.Opportunity__r.Contact__c,(select id from Receipt_Allocations__r where ReceiptAcknowledgement__r.PaymentType__c=\'Mortgage Cheque\' AND ReceiptAcknowledgement__r.Status__c != \'Reversed\') FROM InstallmentLines__c LIMIT 1';
            
        }
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext bc, List<InstallmentLines__c> scope){
        map<ID,InstallmentLines__c> installmentLineMap = new map<ID,InstallmentLines__c>(scope);
        //get the handover map associated with the installment
        map<id,Handoverdetails__c> hoDetailMap = new map<id,Handoverdetails__c>();
        for(Handoverdetails__c hoRec : [SELECT id,LastInstallment__c,KAR__c,KAR__r.Email FROM Handoverdetails__c WHERE KAR__c!=null and LastInstallment__c in :installmentLineMap.keySet()]){
            hoDetailMap.put(hoRec.LastInstallment__c,hoRec);
        }
        set<ID> soToProcess = new set<ID>();
        System.debug('##1 installmentLineMap.keySet() > '+installmentLineMap.keySet());
        System.debug('##1 installmentLineMap.values() > '+installmentLineMap.values());
        for(InstallmentLines__c tempRec : installmentLineMap.values()){
            soToProcess.add(tempRec.SalesOrder__c);
            //SS_TO_REMOVE_MORTGAGE_CHEQUE_ALLOCATED_IL_FROM_CREATING_DANDT_SR_03Aug23-START
            if(tempRec.Receipt_Allocations__r.size()>0) {
                installmentLineMap.remove(tempRec.Id);
                System.debug('installmentLineMap.remove() > '+tempRec.Id);
                
            }
            //SS_TO_REMOVE_MORTGAGE_CHEQUE_ALLOCATED_IL_FROM_CREATING_DANDT_SR_03Aug23-END
        }
        map<id,set<String>> soToJointOwnerMap =  DefaultAndTerminationUtility.getOwnerEmailList(soToProcess);
        //Get the Mortgage Cheques
        //SS_TO_REMOVE_MORTGAGE_CHEQUE_ALLOCATED_IL_FROM_CREATING_DANDT_SR_03Aug23-COMMENTED_BELOW10Lines
        /*map<id,ReceiptAcknowledgement__c> existingMortgageCheque = new map<id,ReceiptAcknowledgement__c>();
for(ReceiptAcknowledgement__c tempRA : [select id,SalesOrder__c from ReceiptAcknowledgement__c where SalesOrder__c in :soToProcess and PaymentType__c = :Constants.MORTGAGE_CHEQUE]){
existingMortgageCheque.put(tempRA.SalesOrder__c,tempRA);
}
for(InstallmentLines__c tempRec : installmentLineMap.values()){
//do not create Default SR
if(installmentIdsToProcess.isEmpty() && existingMortgageCheque.containsKey(tempRec.SalesOrder__c)){
installmentLineMap.remove(tempRec.SalesOrder__c);
}
}*/
        System.debug('##2 installmentLineMap.keySet() > '+installmentLineMap.keySet());
        map<id,HexaBPM__Service_Request__c > installmentToDefaultSRMap = DefaultAndTerminationUtility.createDandTSR(installmentLineMap.keySet());
        System.debug('installmentToDefaultSRMap> '+installmentToDefaultSRMap);
        ReceiptSalesOrderOtherCharge__c soChargeIsActive = ReceiptSalesOrderOtherCharge__c.getOrgDefaults();
        if(installmentIdsToProcess!=null && !installmentIdsToProcess.isEmpty() && soChargeIsActive.ActiveSOChargeCreation__c){
            List<HexaBPM__Service_Request__c> srsoList = new List<HexaBPM__Service_Request__c>();
            ChargeRule__c chargeRule = [SELECT Id,ChargeAmount__c,VATChanges__c FROM ChargeRule__c WHERE SRType__c =: ALD_Constants.CHARGE_RULE_SALES_ORDER_OTHER_CHARGES AND ChargeType__c =: ALD_Constants.CHARGE_RULE_REVERSAL_CHARGE_TYPE LIMIT 1];
            Decimal amountWithoutVAT = chargeRule.ChargeAmount__c;
            Decimal vatAmount = (amountWithoutVAT * chargeRule.VATChanges__c)/100;
            for(ReceiptAllocation__c rt : [select Id,InstallmentLine__c,ReceiptAcknowledgement__c from ReceiptAllocation__c where InstallmentLine__c in :installmentLineMap.keySet() and ReceiptAcknowledgement__r.Status__c ='Reversed']){
                if(installmentToDefaultSRMap.containsKey(rt.InstallmentLine__c)){ 
                    HexaBPM__Service_Request__c srReq = installmentToDefaultSRMap.get(rt.InstallmentLine__c);
                    SalesOrderOtherCharges__c soCharge = SRUtility.createSalesOrderOtherCharge(srReq, 'Service Charge', amountWithoutVAT+vatAmount); 
                    srReq.InstallmentLine__c = null;
                    srReq.Sales_Order_Other_Charges__c = soCharge.Id;
                    srReq.ReceiptAcknowledgement__c = rt.ReceiptAcknowledgement__c;
                    srsoList.add(srReq);
                }
            }
            System.debug('srsoList:'+srsoList);
            if(!srsoList.isEmpty())
                update srsoList;
        }
        //Email
        //get Document RecordType 
        map<id,Document__c> intallmentsForSOAReminder = new map<id,Document__c>();
        ID customerDocumentType = Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get('CustomerDocument').getRecordTypeId();
        //Attachment 1 SOA
        map<id,ContentVersion > contentVersionMap = new map<id,ContentVersion >();
        Boolean isRTO=false;
        for(InstallmentLines__c tempRec : installmentLineMap.values()){
            isRTO = tempRec.SalesOrder__r.RecordTypeId !=null && tempRec.SalesOrder__r.RecordType.Name.equalsIgnoreCase(Constants.SO_RECORD_TYPE_RTO);
            //Create Placeholder if not present
            intallmentsForSOAReminder.put(tempRec.Id, new Document__c(DocumentType__c = Constants.DOC_TYPE_DEFAULT_NOTICE,
                                                                      InstallmentLine__c = tempRec.Id,
                                                                      SalesOrder__c = tempRec.SalesOrder__c,
                                                                      RecordtypeId= customerDocumentType,
                                                                      Contact__c = tempRec.SalesOrder__r.Contact__c !=null ? tempRec.SalesOrder__r.Contact__c:null,
                                                                      RecipientEmail__c   = (tempRec.SalesOrder__r.Contact__c !=null ? tempRec.SalesOrder__r.Contact__r.Email : tempRec.SalesOrder__r.Account__r.PersonEmail) + (hoDetailMap.containskey(tempRec.Id)? ','+ hoDetailMap.get(tempRec.Id).KAR__r.Email : '' ) + (soToJointOwnerMap.containsKey(tempRec.SalesOrder__c) ?  ','+ string.join(new list<String>(soToJointOwnerMap.get(tempRec.SalesOrder__c)),',') : '' )));
        }
        
        if(!intallmentsForSOAReminder.isEmpty()){
            string deliveryOptionName= Constants.DOC_TYPE_DEFAULT_NOTICE + (isRTO ? ' '+Constants.SO_RECORD_TYPE_RTO : '') +' Email';
            list<Loop__DDP_Integration_Option__c> deliveryOption =  [select id,Name,Loop__DDP__c,Loop__DDP__r.Name from Loop__DDP_Integration_Option__c where name = :deliveryOptionName limit 1];
            //If Placeholder present then get the ID
            for(Document__c tempRec: [select id,InstallmentLine__c from Document__c where InstallmentLine__c in : intallmentsForSOAReminder.keySet() and DocumentType__c = :Constants.DOC_TYPE_DEFAULT_NOTICE]){
                intallmentsForSOAReminder.get(tempRec.InstallmentLine__c).Id = tempRec.Id;
            }
            upsert intallmentsForSOAReminder.values();
            
            map<id,Document__c> docMap = new map<id,Document__c>(intallmentsForSOAReminder.values());
            map<id,id> docToCDMap = DefaultAndTerminationUtility.generateSOA(docMap.keySet());
            for(ID docID :docToCDMap.keySet() ){
                //           docMap.get(docID).AttachmentID__c = docToCDMap.get(docID);
                docMap.get(docID).DocgenPackageId__c =  Test.isRunningTest()? null:  deliveryOption[0].Loop__DDP__c;
                docMap.get(docID).DeliveryOptionId__c =  Test.isRunningTest()? null:  deliveryOption[0].Id;
                docMap.get(docID).GenerateDocument__c = true;
                
            }
            System.debug('docMap: '+docMap.values());
            update docMap.values();
            
        }
        
    }    
    global void finish(Database.BatchableContext bc){}    
}