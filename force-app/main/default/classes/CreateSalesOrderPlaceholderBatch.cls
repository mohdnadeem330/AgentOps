/**********************************************************************************************************************
* Name               : CreateSalesOrderPlaceholderBatch                                                       
* Description        : For Sales Order it will create the Document Placeholder.
* Usage              : 1 time batch to be executed after data migration                                                      
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           paras.bhatt@pwc.com     10 Feb 2022      Initial Draft       
******************************************************************************************************************/
//Example:
//database.executeBatch(new CreateSalesOrderPlaceholderBatch(' and id=\'a1926000002rcuKAAQ\'',Constants.DOCUMENT_PLACEHOLDER_CATEGORY_BOOKING));
global class CreateSalesOrderPlaceholderBatch implements Database.Batchable<sObject>,Database.Stateful{
    string whereClause;
    string documentType;
    global CreateSalesOrderPlaceholderBatch(string inputWhereClause,string inputDocumentType){
        whereClause = inputWhereClause;
        documentType = inputDocumentType;
    }
    global Database.QueryLocator start(Database.BatchableContext bc) {
        DateTime currentDT = system.now();//.addHours(-2);
        String query='select id,Opportunity__c,ProjectName__c from SalesOrder__c where id!= null '+ whereClause;
        system.debug(query);
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext bc, List<SalesOrder__c> scope){
        map<id,SalesOrder__c> salesOrderMap = new  map<id,SalesOrder__c>(scope);
        system.debug(salesOrderMap);
        List<Document__c> documentListToInsert = new List<Document__c>();
        map<string,ID> documentRecordTypeMap = new map<string,ID>();
        //get Document Metadata
        map<string,list<DocumentPlaceHolder__mdt>> documentMap = DocumentService.getDocumentMetaDataByCategory(new set<String>{documentType});
        system.debug(documentType);
        system.debug(documentMap);
        if(!documentMap.isEmpty()){
            //get Existing Documents
            map<string,Document__c> existingDocMap = new map<string,Document__c>();
            for(Document__c tempDoc : [select id,DocumentType__c,SalesOrder__c from Document__c where SalesOrder__c in :salesOrderMap.keySet()]){
                    existingDocMap.put(tempDoc.SalesOrder__c+tempDoc.DocumentType__c,tempDoc);
            }

            for(SalesOrder__c newSalesOrder : salesOrderMap.values()){
                for(DocumentPlaceHolder__mdt tempMetaRec : documentMap.get(documentType)){
                    //Skip if project setting doesn't match
                    if(tempMetaRec.ProjectName__c!=null && !tempMetaRec.ProjectName__c.equalsIgnoreCase(newSalesOrder.ProjectName__c)){
                        continue;
                    }
                    string recordTypeID=null;
                    if(tempMetaRec.RecordTypeDeveloperName__c!=null ){
                        if(!documentRecordTypeMap.containsKey(tempMetaRec.RecordTypeDeveloperName__c)){
                            documentRecordTypeMap.put(tempMetaRec.RecordTypeDeveloperName__c,Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get(tempMetaRec.RecordTypeDeveloperName__c).getRecordTypeId());
                        }
                        recordTypeID= documentRecordTypeMap.get(tempMetaRec.RecordTypeDeveloperName__c);
                    }
                    
                    if(!existingDocMap.containsKey( newSalesOrder.Id + tempMetaRec.DocumentType__c)){
                        Document__c documentRecord = DocumentService.createDocumentRecord(newSalesOrder.Opportunity__c,'','',tempMetaRec.DocumentType__c,newSalesOrder.Id,'',recordTypeID);
                        documentRecord.SendForESign__c= tempMetaRec.eSignRequired__c;
                        documentRecord.DocumentPlaceHolderId__c=tempMetaRec.DeveloperName;
                        //Async issue, need to generate docs in different transaction
                        documentRecord.GenerateDocument__c =false;
                        documentListToInsert.add(documentRecord);        
                    }
                }
            }
        }
        
        if(!documentListToInsert.isEmpty()){
          insert documentListToInsert;  
        } 
    }    
    global void finish(Database.BatchableContext bc){}    
}