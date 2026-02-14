global without sharing class CC_ProvisNOCValidationCtrl implements HexaBPM.iCustomCodeExecutable {
    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stpobj){
        string result ='Success';
        try{
            if(stpobj == null || stpobj.HexaBPM__SR__c == null){
                result='CC_ProvisNOCValidationCtrl: Invalid SR or SR Step';
            }else{
                HexaBPM__Step__c stp = [SELECT Id,HexaBPM__Summary__c,HexaBPM__Step_Status__c,Step_Template_Code__c,HexaBPM__SR__c FROM HexaBPM__Step__c WHERE Id =: stpobj.Id];
                HexaBPM__Service_Request__c sRRecord = [SELECT Id,ProvisDocumentUploaded__c,Payment_Extension_Period_In_Days__c,No_Charge_Fee_Required__c, SRType__c, InstallmentLine__c, InstallmentLine__r.OutstandingAmount__c,PaymentExtensionDate__c, PaymentExtensionPeriod__c, ReceiptAcknowledgement__c, ReceiptAcknowledgement__r.Status__c, ReceiptAcknowledgement__r.StatusReason__c,HexaBPM__Customer__c,SalesOrder__c,ChargeCollected__c,Exceptional_Reason__c,Amount__c,ChargeType__c,Credit_Note_Sub_Type__c,SalesOrder__r.Opportunity__c,HexaBPM__Contact__c,InstallmentLine__r.HandoverPayment__c FROM HexaBPM__Service_Request__c WHERE id =: stp.HexaBPM__SR__c  limit 1];
                System.debug('sRRecord'+sRRecord);
                if(stp.HexaBPM__Summary__c == 'Pending upload Provis Docs by Customer' && stp.HexaBPM__Step_Status__c == 'Pending'){
                    if(sRRecord.ProvisDocumentUploaded__c){
                        Id cmpltSts = [SELECT Id FROM HexaBPM__Status__c WHERE Name ='Completed' LIMIT 1].Id;
                        List<HexaBPM__Step__c> stpList = new List<HexaBPM__Step__c>();
                        HexaBPM__Step__c stpSts = new HexaBPM__Step__c();
                        stpSts.Id = [SELECT Id FROM HexaBPM__Step__c WHERE HexaBPM__Summary__c = 'Pending upload Provis Docs by Customer' AND HexaBPM__SR__c =: sRRecord.Id LIMIT 1].Id;
                        stpSts.HexaBPM__Status__c =cmpltSts;
                        update stpSts; 
                    }
                }
                if(stp.Step_Template_Code__c == 'Docs Approved' && stp.HexaBPM__Step_Status__c == 'Approved'){
                    System.debug('Docs Approved');
                    String resultVal = docsApprovedValidation(new Set<Id>{sRRecord.Id});
                    if(resultVal == 'true'){
                        system.debug('Please ensure all the Provis Documents Approved.');
                        result = 'Please ensure all the Provis Documents Approved.';
                    }
                }else if(stp.Step_Template_Code__c == 'Docs Approved' && stp.HexaBPM__Step_Status__c == 'Pending'){
                    dfltCloseStatus(new Set<Id>{sRRecord.Id});
                } 
            }
        }catch(Exception e){
            system.debug('Error:'+e.getMessage());
            result = e.getMessage()+' :CC_ProvisNOCValidationCtrl';
        }
        return result;
    }
    
    /* @InvocableMethod(label='Update Status')
public static void changeProviesDoc(List<Id> srDocId){
Id pendingSts = [SELECT Id FROM HexaBPM__Status__c WHERE Name = 'Pending' LIMIT 1]?.Id;
List<HexaBPM__SR_Doc__c> srDocList=[Select Id,HexaBPM__Service_Request__c From HexaBPM__SR_Doc__c where Id=:srDocId];
if(!srDocList.Isempty()){       
List<HexaBPM__Step__c> srRecord=[SELECT Id,HexaBPM__SR__c,HexaBPM__Status__c FROM HexaBPM__Step__c WHERE HexaBPM__SR__c = :srDocList[0].HexaBPM__Service_Request__c AND HexaBPM__SR__r.SRType__c = 'Property Transfer NOC' AND HexaBPM__Summary__c ='Pending upload Provis Docs by Customer'];
if(!srRecord.Isempty()){
srRecord[0].HexaBPM__Status__c = pendingSts;  
Update srRecord;
}
}*/
    
    //  List<HexaBPM__SR_Doc__c> docUpdList = new List<HexaBPM__SR_Doc__c>();
    // for(HexaBPM__SR_Doc__c srDoc:[SELECT Id FROm HexaBPM__SR_Doc__c WHERE Id IN: srDocId]){
    //     HexaBPM__SR_Doc__c srDocObj = new HexaBPM__SR_Doc__c();
    //     srDocObj.Id = srDoc.Id;
    //     srDocObj.HexaBPM__Status__c = 'Pending Upload';
    //     docUpdList.add(srDocObj);
    // }
    // update docUpdList;
    //}
    
    public static void reOpnRejectedDocs(Set<Id> srDocId){
        List<HexaBPM__SR_Doc__c> docUpdList = new List<HexaBPM__SR_Doc__c>();
        for(HexaBPM__SR_Doc__c srDoc:[SELECT Id FROm HexaBPM__SR_Doc__c WHERE Id IN: srDocId]){
            HexaBPM__SR_Doc__c srDocObj = new HexaBPM__SR_Doc__c();
            srDocObj.Id = srDoc.Id;
            srDocObj.HexaBPM__Status__c = 'Pending Upload';
            docUpdList.add(srDocObj);
        }
        update docUpdList;
    }
    public static String docsApprovedValidation(Set<Id> serviceReqIdset){
        List<HexaBPM__Step__c> updateStepsList = new List<HexaBPM__Step__c>();
        Map<Id,boolean> uploadedDocMap = uploadPROVISdocStepsValidation(serviceReqIdset,'Uploaded');
        System.debug('uploadedDocMap'+uploadedDocMap);
        for(Id srId: serviceReqIdset){
            if(uploadedDocMap.containsKey(srId)){
                return 'true';
            }
        }
        return 'false';
    }
    public static void dfltCloseStatus(Set<Id> serviceReqIdset){
        List<HexaBPM__Step__c> updateStepsList = new List<HexaBPM__Step__c>();
        Id completedSts = [SELECT Id FROM HexaBPM__Status__c WHERE Name = 'Completed' LIMIT 1]?.Id;
        for(HexaBPM__Step__c stp:[SELECT Id,HexaBPM__SR__c FROM HexaBPM__Step__c WHERE HexaBPM__SR__c IN:serviceReqIdset AND HexaBPM__SR__r.SRType__c = 'Property Transfer NOC' AND HexaBPM__Summary__c ='Pending upload Provis Docs by Customer' AND HexaBPM__Step_Status__c = 'Pending' AND HexaBPM__SR__r.ProvisDocumentUploaded__c =: true]){
            system.debug('Inside Pending Upload');
            HexaBPM__Step__c stpObj = new HexaBPM__Step__c();
            stpObj.Id = stp.Id;
            stpObj.HexaBPM__Status__c = completedSts;
            updateStepsList.add(stpObj);
        }
        system.debug('updateStepsList'+updateStepsList);
        update updateStepsList;
    }
    public static void provisDocCloseStp(Set<Id> serviceReqIdset){
        List<HexaBPM__Step__c> updateStepsList = new List<HexaBPM__Step__c>();
        Map<Id,boolean> uploadedDocMap = uploadPROVISdocStepsValidation(serviceReqIdset,'Uploaded');
        system.debug('uploadedDocMap:'+uploadedDocMap);
        Id completedSts = [SELECT Id FROM HexaBPM__Status__c WHERE Name = 'Completed' LIMIT 1]?.Id;
        List<HexaBPM__Service_Request__c> srUpdList = new List<HexaBPM__Service_Request__c>();
        boolean notprovisDocUploaded = false;
        for(Id srId: serviceReqIdset){
            if(!uploadedDocMap.containsKey(srId)){
                HexaBPM__Service_Request__c srReq = new HexaBPM__Service_Request__c();
                srReq.Id = srId;
                srReq.ProvisDocumentUploaded__c = true;
                srUpdList.add(srReq);
            }
        }
        if(!srUpdList.isEmpty()){
            update srUpdList;
        }
        for(HexaBPM__Step__c stp:[SELECT Id,HexaBPM__SR__c FROM HexaBPM__Step__c WHERE HexaBPM__SR__c IN:serviceReqIdset AND HexaBPM__SR__r.SRType__c = 'Property Transfer NOC' AND HexaBPM__Summary__c ='Pending upload Provis Docs by Customer' AND HexaBPM__Step_Status__c = 'Pending']){
            system.debug('stp:'+stp);
            system.debug('!uploadedDocMap.containsKey(stp.HexaBPM__SR__c)'+uploadedDocMap.containsKey(stp.HexaBPM__SR__c));
            if(uploadedDocMap.containsKey(stp.HexaBPM__SR__c) == false){
                system.debug('Inside Pending Upload');
                HexaBPM__Step__c stpObj = new HexaBPM__Step__c();
                stpObj.Id = stp.Id;
                stpObj.HexaBPM__Status__c = completedSts;
                updateStepsList.add(stpObj);
            }
        }
        system.debug('updateStepsList'+updateStepsList);
        update updateStepsList;
    }
    public static Map<Id,boolean> uploadPROVISdocStepsValidation(Set<Id> serviceReqIdset,String Status){
        Map<Id,List<HexaBPM__SR_Doc__c>> srDocMap = new Map<Id,List<HexaBPM__SR_Doc__c>> ();
        Map<Id,boolean> uploadedDocMap = new Map<Id,boolean>();
        // List<String> srDocNames = System.Label.ProvisNOCRequiredDocs.contains(',')?System.Label.ProvisNOCRequiredDocs.split(','):new List<String> {System.Label.ProvisNOCRequiredDocs};
        // List<HexaBPM__Document_Master__c> provisDocList=[Select Id,Name From HexaBPM__Document_Master__c where Is_Provis_Document__c =true];
        //system.debug(provisDocList);
        List<String> srDocNames = new List<String>();
        for(HexaBPM__Document_Master__c provisDoc :[Select Id,Name From HexaBPM__Document_Master__c where Is_Provis_Document__c =true])
        {
            srDocNames.add(provisDoc.Name);
        }
        system.debug('srDocNames'+srDocNames);
        
        List<HexaBPM__SR_Doc__c> sedoc1=[SELECT Id,HexaBPM__Service_Request__c,HexaBPM__Status__c 
                                         FROM HexaBPM__SR_Doc__c 
                                         WHERE HexaBPM__Service_Request__c IN: serviceReqIdset AND 
                                         HexaBPM__Service_Request__r.SRType__c = 'Property Transfer NOC' 
                                         AND Name IN:srDocNames];
        system.debug('sedoc1'+sedoc1);
        for(HexaBPM__SR_Doc__c srDoc: [SELECT Id,HexaBPM__Service_Request__c,HexaBPM__Status__c,Is_Provis_Document_Accepted__c 
                                       FROM HexaBPM__SR_Doc__c 
                                       WHERE HexaBPM__Service_Request__c IN: serviceReqIdset AND 
                                       HexaBPM__Service_Request__r.SRType__c = 'Property Transfer NOC' 
                                       AND Name IN:srDocNames]){
                                           List<HexaBPM__SR_Doc__c> srDocList = new List<HexaBPM__SR_Doc__c>{srDoc};
                                               system.debug('srDocList'+srDocList);
                                           if(srDocMap.containsKey(srDoc.HexaBPM__Service_Request__c)){
                                               srDocList.addAll(srDocMap.get(srDoc.HexaBPM__Service_Request__c));
                                               srDocMap.put(srDoc.HexaBPM__Service_Request__c,srDocList);
                                           }else{
                                               srDocMap.put(srDoc.HexaBPM__Service_Request__c,srDocList);
                                           }
                                       }
        system.debug('srDocMap'+srDocMap);
        
        /* for(Id srId: serviceReqIdset){
for(HexaBPM__SR_Doc__c srDoc: srDocMap.get(srId)){
if(srDoc.HexaBPM__Status__c == Status && Status=='Pending Upload'){
uploadedDocMap.put(srDoc.HexaBPM__Service_Request__c,true);
}
else if(srDoc.HexaBPM__Status__c != Status && Status=='Uploaded')
{
uploadedDocMap.put(srDoc.HexaBPM__Service_Request__c,true);
}
}
}*/
        
        for(Id srId: serviceReqIdset){
            for(HexaBPM__SR_Doc__c srDoc: srDocMap.get(srId)){
                if((srDoc.HexaBPM__Status__c != 'Uploaded' && srDoc.HexaBPM__Status__c != 'Generated') || srDoc.Is_Provis_Document_Accepted__c == false){
                    uploadedDocMap.put(srDoc.HexaBPM__Service_Request__c,true);
                }
                
            }
        }
        system.debug('uploadedDocMap'+uploadedDocMap);
        return uploadedDocMap;
    }
}