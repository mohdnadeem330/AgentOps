/**********************************************************************************************************************
* Name               : CC_UpdateHandoverDetails                                                        
* Description        : This class is used by Handover Process to update required fields handover fields during the process
* Usage              : Handover 
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           paras.bhatt@pwc.com     29 Dec 2022      Initial Draft       
******************************************************************************************************************/
global without sharing class CC_UpdateHandoverDetails implements HexaBPM.iCustomCodeExecutable {
    
    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp){
        string result ='Success';
        try{

            if(stp == null || stp.HexaBPM__SR__c == null){
                result='CC_UpdateHandoverDetails: Invalid SR or SR Step';
            }else{
                HexaBPM__Service_Request__c sRRecord = [SELECT Id,SalesOrder__c,Unit__c,HandoverDetail__c FROM HexaBPM__Service_Request__c WHERE id =: stp.HexaBPM__SR__c  limit 1];
                HexaBPM__Step__c stepRecord = [select id,HexaBPM__Step_Status__c,Step_Template_Code__c from HexaBPM__Step__c where id = :stp.Id limit 1];
                HandoverDetails__c hoRecordToUpdate = new HandoverDetails__c(id = sRRecord.HandoverDetail__c);
                
                if(stepRecord.Step_Template_Code__c == Constants.STEP_NAME_UPLOAD_TITLE_DEED){
                    //Upload Title Deed - Completed
                    hoRecordToUpdate.TitleDeedUploadDate__c =  System.today();
                    hoRecordToUpdate.TitleDeedCompletionDate__c= System.today();
                    hoRecordToUpdate.TitleDeedStatus__c = 'Completed';
                    //hoRecordToUpdate.UtilityTransferStatus__c =  Constants.HO_TRANSSTATUS_INPROGRESS;
                }else if(stepRecord.Step_Template_Code__c == Constants.STEP_NAME_UTILITY_TRANSFER){
                    // Customer Utility Transfer - Completed
                    hoRecordToUpdate.UtilityTransferStatus__c =  Constants.HO_TRANSSTATUS_COMPLTED;
                    hoRecordToUpdate.NOCIssuedDate__c =  System.today();
                    hoRecordToUpdate.UtilityTransferDate__c = System.today();
                    hoRecordToUpdate.KeyAcceptanceDate__c =system.today();
                }
                update hoRecordToUpdate;

                if(stepRecord.Step_Template_Code__c  == Constants.STEP_NAME_KEYHANDOVER_APPOINTMENT){
                    LPCModel lpcDetail = LPCService.getOutstandingLPCforSalesOrder(sRRecord.SalesOrder__c);
                    sRRecord.TotalLPCDue__c = lpcDetail.totalLPCDue!=null?lpcDetail.totalLPCDue.setScale(2):0;
                    sRRecord.LPCCalculatedDate__c = Date.today();
                    update sRRecord;
                }
                //Upload Title Deed - Completed
                //Upload the Document under SO
                if(stepRecord.Step_Template_Code__c == Constants.STEP_NAME_UPLOAD_TITLE_DEED){
                    //get Existing Placeholder
                    list<Document__c> docList = [select id from Document__c where DocumentType__c = :Constants.DOCUMENT_TYPE_TITLE_DEED and SalesOrder__c = :sRRecord.SalesOrder__c ];
                    map<id,HexaBPM__SR_Doc__c> docplaceholder = new map<id,HexaBPM__SR_Doc__c>([select id,HexaBPM__Status__c from HexaBPM__SR_Doc__c where HexaBPM__Service_Request__c = :sRRecord.Id and Name = :Constants.DOCUMENT_TYPE_TITLE_DEED and HexaBPM__Status__c = :Constants.DOCUMENT_STATUS_UPLOADED] );
                    if(docplaceholder.isEmpty()){ return 'Please upload the Title Deed document to proceed.'; }
                    ID recTypeId = Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get(Constants.DOCUMENT_SO_RT).getRecordTypeId();
                    //If not available create new
                    if(docList.isEmpty()){
                        docList.add(new Document__c(    DocumentType__c=Constants.DOCUMENT_TYPE_TITLE_DEED,
                                                        SalesOrder__c = sRRecord.SalesOrder__c,
                                                        recordTypeId= recTypeId,
                                                        Unit__c=sRRecord.Unit__c ));
                        insert docList;
                    }
                    //Fetch the data from existing uploads under SR
                    
                    list<contentDocumentLink> documents = [ select id, ContentDocumentId,linkedEntityId from contentDocumentLink where linkedEntityId in :docplaceholder.keySet() order by SystemModStamp desc limit 1];
                    
                    
                    list<contentDocumentLink> cdlToInsert = new list<contentDocumentLink>();
                    for(Document__c tempDocRec: docList){
                            cdlToInsert.add(new contentDocumentLink(ContentDocumentId = documents[0].ContentDocumentId,
                                                                    LinkedEntityId= tempDocRec.id,ShareType='V',Visibility='InternalUsers'));
                            tempDocRec.Status__c = Constants.DOCUMENT_STATUS_UPLOADED;
                    }
                    
                    if(!cdlToInsert.isEmpty()){
                        insert cdlToInsert;
                    }
                    if(!docList.isEmpty()){
                        update docList;
                    }
                }

            } 
        } catch(Exception e){ result = e.getMessage()+ ' : ' + e.getLineNumber() +' :CC_UpdateHandoverDetails';
        }
        return result;
    }
}