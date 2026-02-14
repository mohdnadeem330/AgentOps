/******************************************************************************************
   *  Author         :   Salma
   *  Company        :   HexaBPM
   *  Date           :   9-April-2017
   *  Description    :   Apex Controller for Uploading Documents in LEX
********************************************************************************************/
public with sharing class LEX_UploadDocumentsController {
         
    /*** Method to fetch all the SR Docs related to the Service Request ***/ 
    @AuraEnabled
    public static List<HexaBPM__SR_Doc__c> getSRDocs(ID SRId) {
        List<HexaBPM__SR_Doc__c> SRDocs = new List<HexaBPM__SR_Doc__c>();
        if(FLSCheckUtil.CheckQueryFieldAccess('Id,Name,createddate,lastmodifieddate,HexaBPM__Document_Description_External__c,HexaBPM__Is_Not_Required__c,'+
                                        +'HexaBPM__Document_Master__r.Name,HexaBPM__Service_Request__c,HexaBPM__Service_Request__r.HexaBPM__Internal_Status_Name__c,'+
                                        +'HexaBPM__Service_Request__r.HexaBPM__External_Status_Name__c,HexaBPM__Doc_ID__c,'+
                                        +'HexaBPM__Customer_Comments__c,HexaBPM__Comments__c,HexaBPM__Document_Type__c,HexaBPM__Rejection_Reason__c,HexaBPM__Status__c', 'HexaBPM__SR_Doc__c')) {
            SRDocs = [select id,Name,createddate,lastmodifieddate,
                      HexaBPM__Document_Description_External__c,
                      HexaBPM__Is_Not_Required__c,
                      HexaBPM__Document_Master__r.Name,
                      HexaBPM__Service_Request__c,
                      HexaBPM__Service_Request__r.HexaBPM__Internal_Status_Name__c,
                      HexaBPM__Service_Request__r.HexaBPM__External_Status_Name__c,
                      HexaBPM__Doc_ID__c,
                      HexaBPM__Customer_Comments__c,
                      HexaBPM__Comments__c,
                      HexaBPM__Document_Type__c,
                      HexaBPM__Rejection_Reason__c,
                      HexaBPM__Status__c 
                      from HexaBPM__SR_Doc__c where HexaBPM__Service_Request__c=:SRId /*and HexaBPM__Sys_IsGenerated_Doc__c=false*/ order by CreatedDate asc]; 
        }
        system.debug('SRDocs==>'+SRDocs);
        return SRDocs; 
    }   
    
    /*** Method to fetch the Attachment ID to show in the document preview screen ***/                                      
    @AuraEnabled
    public static String getAttachmentURL(ID SRID,String AttachmentID) {       
        String AttachmentURL = URL.getSalesforceBaseUrl().toExternalForm()+'/servlet/servlet.FileDownload?file=';
        if(AttachmentID==''){
            /* Getting the first attachment Id when the page is loaded */
            List<HexaBPM__SR_Doc__c> SRDocList;
            if(FLSCheckUtil.CheckQueryFieldAccess('id,Name,HexaBPM__Doc_ID__c', 'HexaBPM__SR_Doc__c')){
                SRDocList = [Select id,Name,HexaBPM__Doc_ID__c from HexaBPM__SR_Doc__c where HexaBPM__Service_Request__c=:SRID order by createdDate DESC];
            }
            if(!SRDocList.isEmpty())
                AttachmentURL+='&'+SRDocList[0].HexaBPM__Doc_ID__c; 
            if(SRDocList.size()==1)//In case there is just one SR Doc attachment, disabling the Next button
                AttachmentURL+='&DisableNext';
        }
        else
           AttachmentURL+='&'+AttachmentID;
       return AttachmentURL;
    }
                                       
    /*** Method to get the next Attachment ID when Next button is clicked in the document preview section***/                                      
    @AuraEnabled
    public static String getNextAttachment(String SRID, String AttachmentID){   
        Integer index = 0;
        String AttachmentURL = URL.getSalesforceBaseUrl().toExternalForm()+'/servlet/servlet.FileDownload?file=';
        List<HexaBPM__SR_Doc__c> SRDocList;
        if(FLSCheckUtil.CheckQueryFieldAccess('id,Name,HexaBPM__Doc_ID__c', 'HexaBPM__SR_Doc__c')){
            SRDocList = [Select id,Name,HexaBPM__Doc_ID__c from HexaBPM__SR_Doc__c where HexaBPM__Service_Request__c=:SRID order by createdDate DESC];
            for(HexaBPM__SR_Doc__c ObjSRDoc : SRDocList){
                if(ObjSRDoc.HexaBPM__Doc_ID__c == AttachmentID)
                    break;
                index++;            
            }
            if(!SRDocList.isEmpty()){
                if(SRDocList.size()==index+2){
                    AttachmentURL +='&'+SRDocList[index+1].HexaBPM__Doc_ID__c+'&'+SRDocList[index+1].Name+'&LastAttachment';
                }else
                    AttachmentURL+='&'+SRDocList[index+1].HexaBPM__Doc_ID__c+'&'+SRDocList[index+1].Name;
            }
        }
        return AttachmentURL;
    }
    
    /*** Method to get the previous Attachment ID when Previous button is clicked in the document preview section***/ 
    @AuraEnabled
    public static String getPreviousAttachment(String SRID, String AttachmentID){
        Integer index = 0;
        String AttachmentURL = URL.getSalesforceBaseUrl().toExternalForm()+'/servlet/servlet.FileDownload?file=';
        List<HexaBPM__SR_Doc__c> SRDocList;
        if(FLSCheckUtil.CheckQueryFieldAccess('id,Name,HexaBPM__Doc_ID__c', 'HexaBPM__SR_Doc__c')){
            SRDocList = [Select id,Name,HexaBPM__Doc_ID__c from HexaBPM__SR_Doc__c where HexaBPM__Service_Request__c=:SRID order by createdDate ASC];
            for(HexaBPM__SR_Doc__c ObjSRDoc : SRDocList){
                 system.debug('ObjSRDoc.HexaBPM__Doc_ID__c=>'+ObjSRDoc.HexaBPM__Doc_ID__c+'-'+AttachmentID);
                if(ObjSRDoc.HexaBPM__Doc_ID__c == AttachmentID)
                    break;
                index++;            
            }  
            system.debug('index==>'+index);
            if(!SRDocList.isEmpty()){
                if(SRDocList.size()==index+2){
                    AttachmentURL +='&'+SRDocList[index+1].HexaBPM__Doc_ID__c+'&'+SRDocList[index+1].Name+'&FirstAttachment';
                }else
                    AttachmentURL+='&'+SRDocList[index-1].HexaBPM__Doc_ID__c+'&'+SRDocList[index-1].Name;
            }
        }
        return AttachmentURL;
    }
    
    /*** Method to save the Uploaded file under the selected SR Doc ***/                                     
    @AuraEnabled
    public static void saveTheFile(ID SRId,Id parentId, String fileName, String base64Data, String contentType,String CustomerComments) { 
        Attachment ObjAttachment;
        try{
            base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8'); 
             //Insert ContentVersion
            ContentVersion cVersion = new ContentVersion();
            cVersion.ContentLocation = 'S'; //S-Document is in Salesforce. E-Document is outside of Salesforce. L-Document is on a Social Netork.
            cVersion.PathOnClient = fileName; //attach.Name;//File name with extention
            cVersion.Origin = 'H'; //C-Content Origin. H-Chatter Origin.
            cVersion.Title = fileName;//Name of the file
            cVersion.VersionData = EncodingUtil.base64Decode(base64Data); //File content
            Insert cVersion;
            
            //After saved the Content Verison, get the ContentDocumentId
            ContentVersion contentVersionRecord;
            for(ContentVersion cvRecord : [SELECT ContentDocumentId,FileExtension
                                            FROM ContentVersion
                                            WHERE Id = :cVersion.Id]){
                contentVersionRecord = cvRecord;
            }
            /*
            ObjAttachment = new Attachment();
            if(Schema.sObjectType.Attachment.fields.parentId.isCreateable())
                ObjAttachment.parentId = parentId;
            if(Schema.sObjectType.Attachment.fields.Body.isCreateable())
                ObjAttachment.Body = EncodingUtil.base64Decode(base64Data);
            if(Schema.sObjectType.Attachment.fields.Name.isCreateable())
                ObjAttachment.Name = fileName;
            if(Schema.sObjectType.Attachment.fields.ContentType.isCreateable())
                ObjAttachment.ContentType = contentType; 
            if(Attachment.SObjectType.getDescribe().isCreateable()){
                insert ObjAttachment;
            }
            
            system.debug('ObjAttachment==>'+ObjAttachment);
			*/
            HexaBPM__SR_Doc__c ObjSRDoc = new HexaBPM__SR_Doc__c(id=parentId);
            if(Schema.sObjectType.HexaBPM__SR_Doc__c.fields.HexaBPM__Customer_Comments__c.isUpdateable())
                ObjSRDoc.HexaBPM__Customer_Comments__c=CustomerComments;
            if(Schema.sObjectType.HexaBPM__SR_Doc__c.fields.HexaBPM__Status__c.isUpdateable())
                ObjSRDoc.HexaBPM__Status__c='Uploaded';
            ObjSRDoc.HexaBPM__Doc_ID__c = contentVersionRecord.ContentDocumentId;
            if(HexaBPM__SR_Doc__c.SObjectType.getDescribe().isUpdateable()){
                update ObjSRDoc;
                system.debug('ObjSRDoc=>'+ObjSRDoc);
            }
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = contentVersionRecord.ContentDocumentId;
            cdl.LinkedEntityId = parentId;
            cdl.ShareType = 'I';
            insert cdl;
			System.debug('cdl>>>' + cdl);
        }catch(Exception e){
            system.debug('Exception IN saveTheFile()====>'+e.getMessage());
        }
    }
 
    /*** Method to fetch the Status picklist values ***/                                      
    @AuraEnabled
    public static List<String> getSRDocStatus(){
        List<String> options = new List<String>();
        Schema.DescribeFieldResult fieldResult = HexaBPM__SR_Doc__c.HexaBPM__Status__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry f: ple) {
            options.add(f.getLabel());
        } 
      // options.remove(2);
       //options.remove(3);
        system.debug('options==>'+options);
        return options;
    }
    
    /*** Method to Update the SR Docs when Save is clicked on the List of SR Docs. Also auto closed the step in case of Documents re-uploaded.***/
    @AuraEnabled
    public static void UpdateSRDocs(String SRDocList,String SRId){
        HexaBPM__SR_Doc__c[] lstUploadableDocs = (HexaBPM__SR_Doc__c[])JSON.deserialize(SRDocList, List<HexaBPM__SR_Doc__c>.class);
        
        if(lstUploadableDocs!=null && lstUploadableDocs.size()>0){
             Savepoint svpoint = Database.setSavepoint();
             
            if(HexaBPM__SR_Doc__c.SObjectType.getDescribe().isCreateable() && HexaBPM__SR_Doc__c.SObjectType.getDescribe().isUpdateable())
                upsert lstUploadableDocs;
            
            //Auto Close Document Re-upload step when the status is set to document reuploaded            
            AutoCloseReuploadDocStep(SRId);
        }   
        
    }  
    
    /*** Generic Method to auto close the Reupload step once the status is set to Re-upload ***/                                     
    public static void AutoCloseReuploadDocStep(ID SRId){
        try{
            List<HexaBPM__Step__c> Step;
            //Query all steps & check if there are any Document Re-upload step open
            if(FLSCheckUtil.CheckQueryFieldAccess('Id,HexaBPM__SR_Step__c,HexaBPM__Status__c', 'HexaBPM__Step__c')){
    
            Step = [select id,HexaBPM__SR_Step__c,HexaBPM__Status__c from HexaBPM__Step__c 
                                             where 
                                             HexaBPM__Status__r.HexaBPM__Type__c!='End' AND 
                                             HexaBPM__Status__r.HexaBPM__Reupload_Document__c = true AND
                                             (HexaBPM__SR__c=:SRId OR HexaBPM__SR__r.HexaBPM__Parent_SR__c=:SRId)];
            }
                if(!Step.isEmpty()){
                //Check is there are any documents are not yet uploaded or approved
                Integer SRDocCount = [select count() from HexaBPM__SR_Doc__c 
                                      where 
                                      HexaBPM__Service_Request__c=:SRId AND 
                                      (HexaBPM__Status__c!='Uploaded' AND HexaBPM__Status__c!='Approved')];
                //If there is no such document with Re-upload or pending status, then close the step
                if(SRDocCount==0){
                      Map<string,string> MapStatusValues = new Map<string,string>();
                      if(FLSCheckUtil.CheckQueryFieldAccess('Id,HexaBPM__Transition__c,HexaBPM__Transition__r.HexaBPM__To__c,HexaBPM__Transition__r.HexaBPM__To__r.HexaBPM__Code__c', 'HexaBPM__Step_Transition__c')){
                          for(HexaBPM__Step_Transition__c ObjTransition:[Select Id,HexaBPM__Transition__c,HexaBPM__Transition__r.HexaBPM__To__c,HexaBPM__Transition__r.HexaBPM__To__r.HexaBPM__Code__c from HexaBPM__Step_Transition__c 
                                                                            where HexaBPM__SR_Step__c=:Step[0].HexaBPM__SR_Step__c]){
                                    MapStatusValues.put(ObjTransition.HexaBPM__Transition__r.HexaBPM__To__r.HexaBPM__Code__c,ObjTransition.HexaBPM__Transition__r.HexaBPM__To__c);
                          }
                      }
                    if(MapStatusValues.containsKey('DOCUMENT_RE_UPLOADED')){
                        if(Schema.sObjectType.HexaBPM__Step__c.fields.HexaBPM__Status__c.isUpdateable())
                        Step[0].HexaBPM__Status__c = MapStatusValues.get('DOCUMENT_RE_UPLOADED');  
                    }
                    if(HexaBPM__Step__c.SObjectType.getDescribe().isUpdateable())
                    update Step;
                }                                          
            }
        }catch(Exception e){
            system.debug('Exception In AutoCloseReuploadDocStep()===>'+e.getMessage());
        }
    }
   
    /*** Method to Enable/Disable Next & Previous Buttons for the document preview section***/
    @AuraEnabled
    public static String EnableDisableButtons(String SRID,String AttachmentID){
        Integer index = 0;
        List<HexaBPM__SR_Doc__c> SRDocList;
        if(FLSCheckUtil.CheckQueryFieldAccess('id,Name,HexaBPM__Doc_ID__c', 'HexaBPM__SR_Doc__c')){
            SRDocList = [Select id,Name,HexaBPM__Doc_ID__c from HexaBPM__SR_Doc__c where HexaBPM__Service_Request__c=:SRID order by createdDate ASC];
        }
        Integer SRDocListSize = SRDocList.size();
        for(HexaBPM__SR_Doc__c ObjSRDoc : SRDocList){
            if(ObjSRDoc.HexaBPM__Doc_ID__c == AttachmentID)
                break;
            index++;            
        }
        if(SRDocListSize-index == SRDocListSize){
            return 'disablePrevious-enableNext';    
        }else if(SRDocListSize-index == 1){
            return 'disableNext-enablePrevious';
        }else
            return 'enablePrevious-enableNext';
    }  
    
    /*** Method to check if the logged in user is a community user or not***/                            
    @AuraEnabled
    public static Boolean CheckIfCommunityUser(){
        Boolean flag = false;
        List<User> UserList;
        if(FLSCheckUtil.CheckQueryFieldAccess('id,ContactId', 'User')){
            UserList = [select id,ContactId from User where Id=:userInfo.getUserId()];
            for(User ObjUser : UserList){
                if(ObjUser.ContactId!=null){
                    flag = true;
                }else
                   flag = false;
            }
        }
        return flag;
    }
}