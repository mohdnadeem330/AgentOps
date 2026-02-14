/**********************************************************************************************************************
* Name               : DefaultAndTerminationUtility                                                        
* Description        : Class to store all the methods related to Default and termination process.
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           paras.bhatt@pwc.com     06/09/2022      Initial Draft       
* 1.1           Saravanan Sekar       06/09/2023      DnT Revamp Work Phase 1 (Push Pull, Flag and UnFlag & Auto Transfer to Legal Restriction)
******************************************************************************************************************/
public without sharing class DefaultAndTerminationUtility {
    public static string LEGAL_FLAG = 'Legal';  
    //Method used to create default SR
    public static map<id,HexaBPM__Service_Request__c > createDandTSR(set<ID> installmentLineIds){
        map<id,HexaBPM__Service_Request__c > installmentToSRMap = new map<id,HexaBPM__Service_Request__c >();
        Set<Id> salesOrderIdset = new Set<Id>();
        map<id,InstallmentLines__c> installmentLineMap = new map<id,InstallmentLines__c>([select Id,Name,SalesOrder__r.Unit__c, SalesOrder__r.Account__r.Blacklisted__c, SalesOrder__r.HoldFlag__c, SalesOrder__r.Name,SalesOrder__c,SalesOrder__r.NumberOfDefaults__c,SalesOrder__r.Contact__c,SalesOrder__r.Account__c,SalesOrder__r.Opportunity__r.Contact__c,PaymentInstallments__r.isHandoverPayment__c from InstallmentLines__c where id in :installmentLineIds and SalesOrder__c !=null and  SalesOrder__r.Status__c in :HandoverUtility.soldSR]);//and SalesOrder__r.Account__r.BlacklistReason__c !='Legal' Removed by SARAN per Discussion with ROHIT on 111023
        map<id,Account> accToUpdate = new map<id,Account>(); 
        //Installment ID to Handover SR
        map<id,HexaBPM__Service_Request__c> installmentToHandover = HandoverUtility.getHandoverSR(installmentLineIds);
        //TO Create SR
        Id DandTRecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.DEFAULT_AND_TERMINATION);
        HexaBPM__SR_Status__c objSRStatus = [SELECT Id, Name FROM HexaBPM__SR_Status__c WHERE Name =: Constants.SUBMITTED LIMIT 1];
        List<Group> DandTQueueList = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'DTTeamQueue' LIMIT 1];
        list<HexaBPM__Service_Request__c> srListToInsert = new list<HexaBPM__Service_Request__c>();
        map<id,SalesOrder__c> soTOUpdate = new map<id,SalesOrder__c>();
        for(InstallmentLines__c tempRec : installmentLineMap.Values()){
            salesOrderIdset.add(tempRec.SalesOrder__c); 
        }
        List<InstallmentLines__c> installmentUpdateList = new List<InstallmentLines__c>();
        for(InstallmentLines__c tempRec : installmentLineMap.Values()){
            
            InstallmentLines__c insUpdate = new InstallmentLines__c();
            insUpdate.Id = tempRec.Id;
            insUpdate.Default_Send__c = true;
            installmentUpdateList.add(insUpdate);
            
            installmentToSRMap.put(tempRec.Id ,new HexaBPM__Service_Request__c(RecordTypeId =DandTRecordTypeId,
                                                                               OwnerId = DandTQueueList[0].Id,
                                                                               HexaBPM__Customer__c = tempRec.SalesOrder__r.Account__c,
                                                                               SalesOrder__c = tempRec.SalesOrder__c,
                                                                               InstallmentLine__c = tempRec.Id,
                                                                               Unit__c= tempRec.SalesOrder__r.Unit__c,
                                                                               HexaBPM__Contact__c= tempRec.SalesOrder__r.Contact__c,
                                                                               HexaBPM__Submitted_DateTime__c = system.Now(),
                                                                               HexaBPM__Submitted_Date__c = system.today(),
                                                                               StepClosureDate__c =system.today().addDays(Integer.valueof(System.label.TransfertoLegalDays)),
                                                                               DefaultType__c = tempRec.PaymentInstallments__r.isHandoverPayment__c ? Constants.HANDOVER_DEFAULT :Constants.MILESTONE_DEFAULT,
                                                                               HexaBPM__Parent_SR__c =  installmentToHandover.containsKey(tempRec.Id)?installmentToHandover.get(tempRec.Id).Id : null ));
            if(!tempRec.SalesOrder__r.HoldFlag__c){ 
                if(!soTOUpdate.containsKey(tempRec.SalesOrder__c)){ 
                    soTOUpdate.put(tempRec.SalesOrder__c , new SalesOrder__c(Id = tempRec.SalesOrder__c,HoldFlag__c=true,HoldReasonCode__c='Default '+tempRec.Name+' '+tempRec.SalesOrder__r.Name,RebateForfeitureLetterSent__c=true,Rebate_Forfeiture_Letter_Sent_Date__c=system.today() , NumberOfDefaults__c = (tempRec.SalesOrder__r.NumberOfDefaults__c !=null ? (tempRec.SalesOrder__r.NumberOfDefaults__c+1) : 1 )));
                }else{
                    soTOUpdate.get(tempRec.SalesOrder__c).NumberOfDefaults__c =  soTOUpdate.get(tempRec.SalesOrder__c).NumberOfDefaults__c+1;
                }
                //Ticket 4141 : Not setting default flag (Not updating account)
                //accToUpdate.put(tempRec.SalesOrder__r.Account__c , new Account(Id= tempRec.SalesOrder__r.Account__c , Blacklisted__c =true , BlacklistReason__c='Default'));
                if(!tempRec.SalesOrder__r.Account__r.Blacklisted__c){ 
                    accToUpdate.put(tempRec.SalesOrder__r.Account__c , new Account(Id= tempRec.SalesOrder__r.Account__c , BlacklistReason__c='Default'));
                }
            }else{
                  soTOUpdate.put(
                    tempRec.SalesOrder__c,
                    new SalesOrder__c( Id = tempRec.SalesOrder__c, NumberOfDefaults__c = tempRec.SalesOrder__r.NumberOfDefaults__c + 1 )
                );
            }
        }
        if(!installmentToSRMap.isEmpty()){
            insert installmentToSRMap.values();
            if(!installmentUpdateList.isEmpty()){
                update installmentUpdateList;
            }
            system.debug('SR Created' + installmentToSRMap.values());
            ShareHelper.shareServiceRequest(installmentToSRMap.values(),'edit');
            list<HexaBPM__Service_Request__c> srSubmit = new list<HexaBPM__Service_Request__c>();
           // List<HexaBPM__SR_Doc__c> formalList
            for(HexaBPM__Service_Request__c tempR : installmentToSRMap.values()){
               // sendFormalDemandLetter(tempR.Id); 
                srSubmit.add( new HexaBPM__Service_Request__c(Id= tempR.Id,
                                                              HexaBPM__External_SR_Status__c = objSRStatus.Id,
                                                              HexaBPM__Internal_SR_Status__c = objSRStatus.Id));
                //tempR.HexaBPM__External_SR_Status__c = objSRStatus.Id;
                //tempR.HexaBPM__Internal_SR_Status__c = objSRStatus.Id;
            }
            update srSubmit;
        }
        //Update SO with Rebate forfoite to true and On Hold
        if(!soTOUpdate.isEmpty()){
            update soTOUpdate.values();
            //Reverese the Rebate 
            list<ReceiptAcknowledgement__c> raToUpdate = new list<ReceiptAcknowledgement__c>();
            for(ReceiptAcknowledgement__c tempRA : [select id from ReceiptAcknowledgement__c where SalesOrder__c in :soTOUpdate.keySet() and PaymentType__c = :Constants.OTHER_CHARGES_TYPE_CREDIT_NOTE and PaymentSubType__c = :Constants.PAYMENT_SUB_TYPE_REBATE and Status__c != :Constants.REVERSED_PAYMENT_STATUS]){
                tempRA.Status__c= Constants.REVERSED_PAYMENT_STATUS;
                tempRA.StatusReason__c = Constants.REVERSAL_RESON_PAYMENTREVERSAL;
                raToUpdate.add(tempRA );
            }
            if(!raToUpdate.isEmpty()){
                update raToUpdate;
            }
            update accToUpdate.values();
            //Call the Default ERP Integration with SR IDs
            DefaultAndTerminationCalloutHelper.syncDefaultServiceRequest( (new map<id,HexaBPM__Service_Request__c>(installmentToSRMap.values()).keySet() ) );
        }
        
        return installmentToSRMap;
    } 
    
    //Method used to close the Default SR
    public static void closeDandTSR(set<ID> installmentLineIds){
        //get the D&T SR's 1st step if its still in pending state then close the SR and upate the flags
        list<HexaBPM__Service_Request__c> srToUpdate =  new list<HexaBPM__Service_Request__c> ();
        map<id,Account> accToUpdate = new map<id,Account>(); 
        
        map<string, HexaBPM__Status__c> closureStatusMap = new map<string, HexaBPM__Status__c>();
        for(HexaBPM__Status__c tempRec: [select id,name from HexaBPM__Status__c where name in ( :Constants.STEP_STATUS_CUSTOMER_SETTELED, :Constants.STEP_STATUS_TRANSFER_LEGAL  ) ]){
            closureStatusMap.put(tempRec.name,tempRec);
        }
        list<HexaBPM__Step__c> stepsToClose = [select id,HexaBPM__SR__r.SalesOrder__c,HexaBPM__SR__c,HexaBPM__SR__r.HexaBPM__Customer__c from HexaBPM__Step__c where HexaBPM__SR__r.InstallmentLine__c != null and HexaBPM__SR__r.InstallmentLine__c in :installmentLineIds and HexaBPM__SR__r.SalesOrder__c !=null and Step_Template_Code__c=:Constants.STEP_NAME_CUSTOMER_NEGOTIATION and HexaBPM__Status__c != :closureStatusMap.get(Constants.STEP_STATUS_TRANSFER_LEGAL).Id and HexaBPM__Status__c != :closureStatusMap.get(Constants.STEP_STATUS_CUSTOMER_SETTELED).Id/*HexaBPM__Step_Status__c =:Constants.STEP_STATUS_PENDING*/];
        
        HexaBPM__SR_Status__c srCloseStatus = [select id from HexaBPM__SR_Status__c where name = :Constants.SR_STATUS_CLOSED limit 1];
        for(HexaBPM__Step__c tempRec : stepsToClose){
            tempRec.HexaBPM__Status__c = closureStatusMap.get(Constants.STEP_STATUS_CUSTOMER_SETTELED).Id;
            srToUpdate.add(new HexaBPM__Service_Request__c(TitleDeedRegistrationFee__c= 0,Id = tempRec.HexaBPM__SR__c,HexaBPM__External_SR_Status__c = srCloseStatus.Id, HexaBPM__Internal_SR_Status__c = srCloseStatus.Id ));
        }
        if(!stepsToClose.isEmpty()){ update stepsToClose;
                                   }
        set<ID> srSetVals = new map<id,HexaBPM__Service_Request__c>(srToUpdate).keySet();
        if(!srToUpdate.isEmpty()){ update srToUpdate;
                                 }
        
        //Remove account level and SO flag
        checkAndAutoUnflag(srSetVals,'Default');
    }
    
    public static void checkAndAutoUnflag(set<ID> srSetVals, string flagType) {
        Id DandTRecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.DEFAULT_AND_TERMINATION);
        //Ticket 4141 : Not setting default flag (If its default treating it as blank)
        flagType = flagType.equalsIgnoreCase('Default')?'':flagType;
        map<Id,Account> accToUpdate = new map<Id,Account>();
        map<id,SalesOrder__c> soTOUpdate = new map<id,SalesOrder__c>();
        //Try clearing flag
        for(HexaBPM__Service_Request__c existingRecord : [select id,SalesOrder__c,HexaBPM__Customer__c from HexaBPM__Service_Request__c where  RecordTypeId = :DandTRecordTypeId and SalesOrder__c !=null and HexaBPM__Customer__r.BlacklistReason__c=:flagType and Id in :srSetVals ]){
            accToUpdate.put(existingRecord.HexaBPM__Customer__c, new Account(Id= existingRecord.HexaBPM__Customer__c , Blacklisted__c =false , BlacklistReason__c='') );
            soTOUpdate.put(existingRecord.SalesOrder__c, new SalesOrder__c(Id = existingRecord.SalesOrder__c,HoldFlag__c=false,HoldReasonCode__c=''));
        }
        //Remove cust with other default
        for(HexaBPM__Service_Request__c existingRecord : [select id,HexaBPM__Customer__c,SalesOrder__c,Unit__c from HexaBPM__Service_Request__c where  RecordTypeId = :DandTRecordTypeId and SalesOrder__c !=null and HexaBPM__IsClosedStatus__c =false and HexaBPM__Customer__c in :accToUpdate.keyset() and id not in :srSetVals ]){
            if(accToUpdate.containsKey(existingRecord.HexaBPM__Customer__c)){
                accToUpdate.remove(existingRecord.HexaBPM__Customer__c);
            }
            if(soTOUpdate.containsKey(existingRecord.SalesOrder__c)){
                soTOUpdate.remove(existingRecord.SalesOrder__c);
            }
        }
        if(!accToUpdate.isEmpty()){ update accToUpdate.values();
                                  }
        if(!soTOUpdate.isEmpty()){ update soTOUpdate.values();
                                 }
        //Call the Default ERP Integration with SR IDs
        DefaultAndTerminationCalloutHelper.syncDefaultServiceRequest( srSetVals);
    }
    
    //This method is called from batch to transfer the Default SR to Legal after 1 month
    public static void autoTransferToLeagal(Set<Id> srIds) {
        System.debug('autoTransferToLeagal srIds -> '+srIds);
        //get the D&T SR's 1st step if its still in pending state then close the SR and upate the flags
        list<HexaBPM__Step__c> stepsToClose = [select id,HexaBPM__SR__c from HexaBPM__Step__c where HexaBPM__SR__c in :srIds and Step_Template_Code__c=:Constants.STEP_NAME_CUSTOMER_NEGOTIATION and HexaBPM__Step_Status__c =:Constants.STEP_STATUS_PENDING];
        list<HexaBPM__Service_Request__c> srToUpdate =  new list<HexaBPM__Service_Request__c> ();
        //HexaBPM__Status__c closureStatus = [select id from HexaBPM__Status__c where name ='Completed' limit 1];
        map<string, HexaBPM__Status__c> closureStatusMap = new map<string, HexaBPM__Status__c>();
        for(HexaBPM__Status__c tempRec: [select id,name from HexaBPM__Status__c where name = :Constants.STEP_STATUS_TRANSFER_LEGAL ]){
            closureStatusMap.put(tempRec.name,tempRec);
        }
        HexaBPM__SR_Status__c srCloseStatus = ALD_DandTSR_Handler_CC.pubSrStatusSoql(new List<String>{Constants.STEP_STATUS_TRANSFER_LEGAL})[0];//[select id from HexaBPM__SR_Status__c where name = :Constants.STEP_STATUS_TRANSFER_LEGAL limit 1];
        for(HexaBPM__Step__c tempRec : stepsToClose){
            tempRec.HexaBPM__Status__c = closureStatusMap.get(Constants.STEP_STATUS_TRANSFER_LEGAL).Id;
            srToUpdate.add(new HexaBPM__Service_Request__c(Id = tempRec.HexaBPM__SR__c,HexaBPM__External_SR_Status__c = srCloseStatus.Id, HexaBPM__Internal_SR_Status__c = srCloseStatus.Id ));
        }
        if(!stepsToClose.isEmpty()){
            update stepsToClose;
        }
        if(!srToUpdate.isEmpty()){
            update srToUpdate;
        }
    }
    
    //CLoser of SR at specific Legal Status Update
    public static void closeDandTSRAfterLegal(Set<Id> srIds){
        //get the D&T SR's 1st step if its still in pending state then close the SR and upate the flags
        List<HexaBPM__Service_Request__c> srToUpdate =  new List<HexaBPM__Service_Request__c> ();
        Map<string, HexaBPM__Status__c> closureStatusMap = new Map<string, HexaBPM__Status__c>();
        HexaBPM__Status__c stepCompletedStatus = ALD_DandTSR_Handler_CC.pubStepStatusSoql(new List<String>{Constants.STEP_STATUS_COMPLETED})[0];
        HexaBPM__SR_Status__c srCloseStatus = ALD_DandTSR_Handler_CC.pubSrStatusSoql(new List<String>{Constants.SR_STATUS_CLOSED})[0];
        Map<Id, HexaBPM__Service_Request__c> srIdWithSR = new Map<Id, HexaBPM__Service_Request__c>();
        
        //SS-Get the Pending with Legal and External Counsel steps for the respective SR id to auto close
        List<HexaBPM__Step__c> stepsToClose = [SELECT Id,HexaBPM__SR__c,HexaBPM__SR__r.SalesOrder__c,HexaBPM__SR__r.HexaBPM__Customer__c,HexaBPM__SR__r.LegalFees__c 
                                               FROM HexaBPM__Step__c 
                                               WHERE HexaBPM__SR__c in :srIds and Step_Template_Code__c IN (:Constants.STEP_NAME_COURT_FILING,'External counsel') and 
                                               HexaBPM__Step_Status__c =:Constants.STEP_STATUS_PENDING and HexaBPM__SR__r.LegalStatus__c='Legal Cleared'];
        
        //SS-Close the SR and steps as its legal cleared
        for(HexaBPM__Step__c tempRec : stepsToClose) {
            tempRec.HexaBPM__Status__c = stepCompletedStatus.Id;
            srToUpdate.add(new HexaBPM__Service_Request__c(Id = tempRec.HexaBPM__SR__c,HexaBPM__External_SR_Status__c = srCloseStatus.Id, HexaBPM__Internal_SR_Status__c = srCloseStatus.Id ));
            if(tempRec.HexaBPM__SR__r.LegalFees__c > 0) {
                //SS-To avoid one more query, framing the Map here to process legal fee
                srIdWithSR.put(tempRec.HexaBPM__SR__c, new HexaBPM__Service_Request__c(Id = tempRec.HexaBPM__SR__c,SalesOrder__c=tempRec.HexaBPM__SR__r.SalesOrder__c,HexaBPM__Customer__c=tempRec.HexaBPM__SR__r.HexaBPM__Customer__c,LegalFees__c=tempRec.HexaBPM__SR__r.LegalFees__c));
            }
            ALD_DandTSR_Handler_CC.soIdSet.add(tempRec.HexaBPM__SR__r.SalesOrder__c); //Prepare the SO Id Set
        }
        if(!stepsToClose.isEmpty()){
            update stepsToClose;
        }
        if(!srToUpdate.isEmpty()){
            update srToUpdate;
        }
        //Create Other charge
        /*list<SalesOrderOtherCharges__c> otherChargeToInsert = new list<SalesOrderOtherCharges__c>();
//[select id,HexaBPM__Customer__c,SalesOrder__c,LegalFees__c from HexaBPM__Service_Request__c where id in :srIds and LegalFees__c > 0]
for(HexaBPM__Service_Request__c tempSRRecord : srIdWithSR.values()){
otherChargeToInsert.add(new SalesOrderOtherCharges__c(
Account__c = tempSRRecord.HexaBPM__Customer__c,
SalesOrder__c = tempSRRecord.SalesOrder__c,
Amount__c = tempSRRecord.LegalFees__c,
TypeOfCharge__c = Constants.OTHERCHARGE_LEGAL
) );
}
if(!otherChargeToInsert.isEmpty()){
insert otherChargeToInsert;
}*/
        //Create Other charge
        ALD_DandTSR_Handler_CC.createOtherCharge(srIdWithSR);
        //Remove account level flag
        ALD_DandTSR_Handler_CC.checkAndAutoUnflag(srIds,LEGAL_FLAG,ALD_DandTSR_Handler_CC.soIdSet);
        //checkAndAutoUnflag(srIds,LEGAL_FLAG);
    }
    
    //Verify the Cheque Reversal and Create Default SR
   //Verify the Cheque Reversal and Create Default SR
    public static void verifyReversalandCreateDandTSR(set<ID> receiptAckIds){
        set<ID> installmentLineIds = new set<ID>();
        set<ID> preDefaultinstallmentLineIds = new set<ID>();
        for(ReceiptAllocation__c tempRA : [select id,InstallmentLine__c,InstallmentLine__r.InstallmentDate__c,InstallmentLine__r.Default_Date__c,InstallmentLine__r.OutstandingAmountToReceive__c from ReceiptAllocation__c where ReceiptAcknowledgement__c in :receiptAckIds and InstallmentLine__r.InstallmentNumber__c != 1 AND InstallmentLine__c != null]){
            if((tempRA.InstallmentLine__r.InstallmentDate__c+Integer.valueOf(System.Label.BufferForReceiptReversal_Default)) <= System.today()){
           	 	installmentLineIds.add(tempRA.InstallmentLine__c);
            }
            if((tempRA.InstallmentLine__r.InstallmentDate__c+Integer.ValueOf(System.Label.BufferForReceiptReversal_PreDefault)) >= System.today()  && tempRA.InstallmentLine__r.OutstandingAmountToReceive__c > Decimal.valueOf(System.label.DandTBufferAmount)){
                preDefaultinstallmentLineIds.add(tempRA.InstallmentLine__c);
			}
        }
        if(!installmentLineIds.isEmpty()){
            system.debug('installmentLineIds:'+installmentLineIds);
            //createDandTSR(installmentLineIds);
            database.executeBatch(new ValidateCrateDandTSRBatch(installmentLineIds),1);
           // database.executeBatch(new PreDefaultBatch(installmentLineIds),1);
        }
        if(!preDefaultinstallmentLineIds.isEmpty()){
            system.debug('preDefaultinstallmentLineIds:'+preDefaultinstallmentLineIds);
            //createDandTSR(installmentLineIds);
           // database.executeBatch(new ValidateCrateDandTSRBatch(installmentLineIds),1);
            database.executeBatch(new PreDefaultBatch(preDefaultinstallmentLineIds),1);
        }
    }
    
    //Verify the Cheque Clearnce and close Default SR
    public static void verifyandCloseSR(set<ID> receiptAckIds){
        set<ID> installmentLineIds = new set<ID>();
        for(ReceiptAllocation__c tempRA : [select id,InstallmentLine__c from ReceiptAllocation__c where ReceiptAcknowledgement__c in :receiptAckIds and InstallmentLine__r.InstallmentNumber__c != 1 and  InstallmentLine__r.OutstandingAmount__c <=: Decimal.valueOf(System.Label.DandTBufferAmount)]){
            installmentLineIds.add(tempRA.InstallmentLine__c);
        }
        if(!installmentLineIds.isEmpty()){
            closeDandTSR(installmentLineIds);
        }
    }
    /*public static void verifyandCloseParentSR(set<ID> srIds){
Id DandTRecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c',  Constants.DEFAULT_AND_TERMINATION);
set<ID> installmentLineIds = new set<ID>();
for(HexaBPM__Service_Request__c tempRec : [select id from HexaBPM__Service_Request__c where id in :srIds and recordTypeId = :DandTRecordTypeId and InstallmentLine__c!=null]){
installmentLineIds.add(tempRec.InstallmentLine__c);
}
if(!installmentLineIds.isEmpty()){
closeDandTSR(installmentLineIds);
}
}*/
    //generate SOA to be sent with reminder notice
    public static map<id,id> generateSOA(set<Id> docRecordIds){
        
        map<id,id> mapToReturn = new map<id,id>();
        
        map<id,ContentVersion > contentVersionMap = new map<id,ContentVersion >();
        for(Document__c tempRec : [select id,InstallmentLine__r.SalesOrder__c from Document__c where id in : docRecordIds]){
            PageReference pdf = Page.StatementOfAccountDocument;
            pdf.getParameters().put('id',tempRec.InstallmentLine__r.SalesOrder__c);
            contentVersionMap.put(tempRec.Id, new ContentVersion(Title= 'StatementOfAccountDocument.pdf', 
                                                                 PathOnClient ='StatementOfAccountDocument.pdf',
                                                                 VersionData = Test.isRunningTest()? blob.valueOf('Methods defined as TestMethod do not support getContent call') :pdf.getContent(), 
                                                                 origin = 'H'));
        }
        if(!contentVersionMap.isEmpty()){
            insert contentVersionMap.values();
            map<id,ContentVersion> cvMap = new  map<id,ContentVersion>([select id, ContentDocumentId  from ContentVersion where id in :contentVersionMap.values()]);
            list<ContentDocumentLink> documentLinksToCreate = new list<ContentDocumentLink>();
            for(Id docID : contentVersionMap.keySet()){
                mapToReturn.put(docID , cvMap.get(contentVersionMap.get(docID).Id).ContentDocumentId );
                documentLinksToCreate.add(new ContentDocumentLink(contentdocumentid = mapToReturn.get(docID),
                                                                  LinkedEntityId = docID,
                                                                  ShareType ='V'));
                
            }
            insert documentLinksToCreate;
            
        }
        return mapToReturn;
    }
    
    //get Jointowner list for communication
    public static map<id,set<String>> getOwnerEmailList(set<ID> soIds){
        map<id,set<String>> returnMap = new  map<id,set<String>>();
        for(JointOwner__c jo : [select id,SalesOrder__c,Email__c from JointOwner__c where SalesOrder__c in : soIds]){
            if(!returnMap.containsKey(jo.SalesOrder__c)){
                returnMap.put(jo.SalesOrder__c, new set<String>());
            }
            returnMap.get(jo.SalesOrder__c).add(jo.Email__c);
        }
        return returnMap;
    }
    @AuraEnabled
    public static HexaBPM__SR_Doc__c sendFormalDemandLetter(Id srId){
        system.debug('srId::'+srId); 
        if(srId <> null){
            HexaBPM__Service_Request__c srRequest = [SELECT Id,SalesOrder__c,InstallmentLine__c,SalesOrder__r.Contact__c,SalesOrder__r.Account__r.PersonEmail,SalesOrder__r.Contact__r.Email FROM HexaBPM__Service_Request__c WHERE Id=:srId LIMIT 1];
            map<id,Handoverdetails__c> hoDetailMap = new map<id,Handoverdetails__c>();
            for(Handoverdetails__c hoRec : [SELECT id,LastInstallment__c,KAR__c,KAR__r.Email FROM Handoverdetails__c WHERE KAR__c!=null and LastInstallment__c =: srRequest.InstallmentLine__c]){
                hoDetailMap.put(hoRec.LastInstallment__c,hoRec);
            }
            map<id,set<String>> soToJointOwnerMap =  DefaultAndTerminationUtility.getOwnerEmailList(new Set<Id>{srRequest.SalesOrder__c});
            Map<Id,Id> demandNoticeExistCheck = new Map<Id,Id>();
            for(HexaBPM__SR_Doc__c srDoc:[SELECT Id,HexaBPM__Service_Request__c FROM HexaBPM__SR_Doc__c WHERE Name = 'Formal Demand Letter' AND HexaBPM__Service_Request__c=:srId LIMIT 1]){
                demandNoticeExistCheck.put(srDoc.HexaBPM__Service_Request__c,srDoc.Id);
            }
            HexaBPM__SR_Doc__c objSRDoc = new HexaBPM__SR_Doc__c();
            if(demandNoticeExistCheck.containsKey(srId)){
                objSRDoc.Id = demandNoticeExistCheck.get(srId);
            }
            objSRDoc.Name = 'Formal Demand Letter';
            objSRDoc.HexaBPM__Document_Master__c = [SELECT Id FROM HexaBPM__Document_Master__c WHERE Name = 'Formal Demand Letter' LIMIT 1].Id;
            objSRDoc.HexaBPM__SR_Template_Doc__c = [SELECT Id FROM HexaBPM__SR_Template_Docs__c WHERE HexaBPM__Document_Master__c =: objSRDoc.HexaBPM__Document_Master__c LIMIT 1].Id;
            objSRDoc.HexaBPM__Service_Request__c = srId;
            objSRDoc.RecipientEmail__c =  (srRequest.SalesOrder__r.Contact__c !=null ? srRequest.SalesOrder__r.Contact__r.Email : srRequest.SalesOrder__r.Account__r.PersonEmail) + (hoDetailMap.containskey(srRequest.Id)? ','+ hoDetailMap.get(srRequest.Id).KAR__r.Email : '' ) + (soToJointOwnerMap.containsKey(srRequest.SalesOrder__c) ?  ','+ string.join(new list<String>(soToJointOwnerMap.get(srRequest.SalesOrder__c)),',') : '' );
            if(!Test.isRunningTest()){
                objSRDoc.HexaBPM__Generate_Document__c = true;
            }
            return objSRDoc;
        }
        return null;
    }
    @AuraEnabled
    public static void CallfromSendDefaultlwc(id installmentid){            
        database.executeBatch(new ValidateCrateDandTSRBatch(new Set<id>{installmentid}),1);
      }
}