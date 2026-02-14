public class SalesOrderOtherChargesHandler extends TriggerHandler{
public override void beforeInsertMethod(List<SObject> newList, Map<Id, SObject> newMap) { 
    //newRecord.OutstandingAmountinwords__c
    for(SalesOrderOtherCharges__c newRecord  : (list<SalesOrderOtherCharges__c >) newList){
        if(newRecord.Amount__c  != null ){
            if(newRecord.InvoicedAmount__c  != null){
                newRecord.OutstandingAmountinwords__c = Utilities.amountInWords((newRecord.Amount__c - newRecord.InvoicedAmount__c),'Dhirams','Fils');
            }else{
                newRecord.OutstandingAmountinwords__c = Utilities.amountInWords(newRecord.Amount__c,'Dhirams','Fils');
            }
        }
        //FIN-95 to calculated 5% VAt charges based on list of type of Charges
        List<String> applicableVatTypeOfCharge = System.label.Vat_Calculation_For_Type_Of_Charge_5.split(','); 
        if(newRecord.Amount__c!=null && applicableVatTypeOfCharge.contains(newRecord.TypeOfCharge__c) && (newRecord.VATAmount__c== null||newRecord.VATAmount__c==0)){
            newRecord.VATAmount__c = newRecord.Amount__c * 0.05;
            if(newRecord.AmountWithoutVAT__c==null || newRecord.AmountWithoutVAT__c==0){
                newRecord.AmountWithoutVAT__c = newRecord.Amount__c;
        } 
        if(newRecord.AmountWithoutVAT__c!=null && newRecord.VATAmount__c!=null){
            newRecord.Amount__c = newRecord.AmountWithoutVAT__c + newRecord.VATAmount__c;
        }
        }
        //FIN-95 change ends
    }
}
public override void beforeUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) { 
    system.debug('beforeUpdateMethod ');
    List<Id> soOtherIds = new List<Id>();
    for(SalesOrderOtherCharges__c newRecord  : (list<SalesOrderOtherCharges__c >) newList){
        SalesOrderOtherCharges__c oldRecord = (SalesOrderOtherCharges__c)oldMap.get(newRecord.Id);
        if(newRecord.Amount__c != null ){
            if(newRecord.InvoicedAmount__c != null){
                if(oldRecord.Amount__c != newRecord.Amount__c || 
                    oldRecord.InvoicedAmount__c != newRecord.InvoicedAmount__c){
                        newRecord.OutstandingAmountinwords__c = Utilities.amountInWords((newRecord.Amount__c - newRecord.InvoicedAmount__c),'Dhirams','Fils');
                    }
            }else{
                if(oldRecord.Amount__c != newRecord.Amount__c){
                    newRecord.OutstandingAmountinwords__c = Utilities.amountInWords(newRecord.Amount__c,'Dhirams','Fils');
                    system.debug('++newRecord.OutstandingAmountinwords__c '+newRecord.OutstandingAmountinwords__c);
                }
            }
        }
        //SARAN-NEW-CHANGE_ALDOC_CHANGES-START
        if(newRecord.SyncStatus__c == ALD_Constants.STATUS_INPROGRESS &&  newRecord.Is_Manual_Entry__c) {
            soOtherIds.add(newRecord.Id);
        }
        //SARAN-NEW-CHANGE_ALDOC_CHANGES-END

            //FIN-95 to calculated 5% VAt charges based on list of type of Charges
            // Commenting the above change FIN-95 for bug FIN-178
            /*List<String> applicableVatTypeOfCharge = System.label.Vat_Calculation_For_Type_Of_Charge_5.split(','); 
        if(newRecord.Amount__c!=oldRecord.Amount__c && (newRecord.InvoiceNumber__c==null || newRecord.InvoiceNumber__c=='') && applicableVatTypeOfCharge.contains(newRecord.TypeOfCharge__c) ) {
                            newRecord.VATAmount__c = newRecord.Amount__c * 0.05;
                            newRecord.AmountWithoutVAT__c = newRecord.Amount__c;
                            newRecord.Amount__c = newRecord.AmountWithoutVAT__c + newRecord.VATAmount__c;
        }
        if(newRecord.Amount__c!=null && newRecord.TypeOfCharge__c!=null && applicableVatTypeOfCharge.contains(newRecord.TypeOfCharge__c) && (newRecord.VATAmount__c== null||newRecord.VATAmount__c==0)){
            newRecord.VATAmount__c = newRecord.Amount__c * 0.05;
            if(newRecord.AmountWithoutVAT__c==null || newRecord.AmountWithoutVAT__c==0){
                newRecord.AmountWithoutVAT__c = newRecord.Amount__c;
        } 
        if(newRecord.AmountWithoutVAT__c!=null && newRecord.VATAmount__c!=null){
            newRecord.Amount__c = newRecord.AmountWithoutVAT__c + newRecord.VATAmount__c;
        }
        }*/
        //FIN-95 change ends
    }
    //SARAN-NEW-CHANGE_ALDOC_CHANGES-START
    User usr = Utilities.getLoggedInUserDetail();
    if (usr.Profile.Name != Constants.INTEGRATION_PROFILE && !soOtherIds.isEmpty()) {
        system.debug('via beforeUpdateMethod ');
        ALDOC_OtherChargesHelper.executeUponApproval(soOtherIds);
    }
    //SARAN-NEW-CHANGE_ALDOC_CHANGES-END
}

//*** After Insert Action***//
public override void afterInsertMethod(List<SObject> newList, Map<Id, SObject> newMap) {
    List<Id> soOtherIds = new List<Id>();
    List<SalesOrderOtherCharges__c> createDocuments = new List<SalesOrderOtherCharges__c>();

    for (SalesOrderOtherCharges__c sooc: (list<SalesOrderOtherCharges__c>) newList) {

        if( sooc.TypeOfCharge__c == Constants.OTHER_CHARGES_TYPE_DEBIT_MEMO ){
            createDocuments.add(sooc);
        }
        //Adarsh - for bounced cheque ERP
        if(sooc.SyncStatus__c == ALD_Constants.STATUS_INPROGRESS && sooc.SubType__c == 'Bounced Cheque Amount') {
            soOtherIds.add(sooc.Id);
        }
    }
    User usr = Utilities.getLoggedInUserDetail();
    if (usr.Profile.Name != Constants.INTEGRATION_PROFILE && !soOtherIds.isEmpty()) {
        system.debug('via afterInsertMethod ');
        ALDOC_OtherChargesHelper.executeUponApproval(soOtherIds);
    }

    if(!createDocuments.isEmpty()){
        createSalesOrderOtherChargesDocuments(new List<SalesOrderOtherCharges__c>(createDocuments));
    }
}

public static void createSalesOrderOtherChargesDocuments(List<SalesOrderOtherCharges__c> soocRecords){
    List<Document__c> documentListToInsert = new List<Document__c>();
    map<String,ID> documentRecordTypeMap = new map<String,ID>();
    map<String,list<DocumentPlaceHolder__mdt>> documentMap = DocumentService.getDocumentMetaDataByCategory(new set<String>{Constants.DOCUMENT_PLACEHOLDER_SALES_ORDER_OTHER_CHARGES});
    map<Id,SalesOrderOtherCharges__c> soocIDToRecMap = new map<Id,SalesOrderOtherCharges__c>(soocRecords);

    if(!documentMap.isEmpty() && !soocIDToRecMap.isEmpty()){
        //get Existing Documents
        map<String,Document__c> existingDocMap = new map<String,Document__c>();
        for(Document__c tempDoc : [select id,DocumentType__c,SalesOrderOtherCharges__c from Document__c where SalesOrderOtherCharges__c in :soocIDToRecMap.keySet()]){
                existingDocMap.put(tempDoc.SalesOrderOtherCharges__c+tempDoc.DocumentType__c,tempDoc);
        }

        for(SalesOrderOtherCharges__c soocRecord : soocRecords){
            
            String documentTypeToProcess = Constants.DOCUMENT_PLACEHOLDER_SALES_ORDER_OTHER_CHARGES;                                     
            
            for(DocumentPlaceHolder__mdt tempMetaRec : documentMap.get(documentTypeToProcess)){
                String recordTypeID=null;
                
                if(tempMetaRec.RecordTypeDeveloperName__c!=null ){
                    if(!documentRecordTypeMap.containsKey(tempMetaRec.RecordTypeDeveloperName__c)){
                        documentRecordTypeMap.put(tempMetaRec.RecordTypeDeveloperName__c,Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get(tempMetaRec.RecordTypeDeveloperName__c).getRecordTypeId());
                    }
                    recordTypeID= documentRecordTypeMap.get(tempMetaRec.RecordTypeDeveloperName__c);
                }
                    
                if(!existingDocMap.containsKey(soocRecord.Id + tempMetaRec.DocumentType__c)){
                    Document__c documentRecord = DocumentService.createDocumentRecord('','','',tempMetaRec.DocumentType__c,'','',recordTypeID);
                    documentRecord.DocumentPlaceHolderId__c=tempMetaRec.DeveloperName;
                    documentRecord.SalesOrderOtherCharges__c = soocRecord.Id;  

                    documentListToInsert.add(documentRecord); 
                    existingDocMap.put(soocRecord.Id + tempMetaRec.DocumentType__c,documentRecord);       
                }
            }    
        }
    }
    
    if(!documentListToInsert.isEmpty()){
        insert documentListToInsert;  
    } 
}

/*  public static String convertNumberToWord(Decimal totalAmount){
    String totalAmountString = String.valueOf(totalAmount); // assuming you meant to use d here
    String afterDecimal = totalAmountString.substringAfter('.');
    if(afterDecimal != null && afterDecimal.length() > 9){
        afterDecimal = afterDecimal.substring(0, 8);
    }
    String beforeDecimal;
    if(totalAmount != null){
        beforeDecimal  = NumberToText.convert(Integer.valueOf(totalAmount));
    }
    if(String.isNotBlank(afterDecimal)){
        afterDecimal = NumberToText.convert(Integer.valueOf(afterDecimal) );
    }
    String amountInWords = '';
    if(String.isNotBlank(beforeDecimal))
        amountInWords =  beforeDecimal + ' Dhirams ';
    if(String.isNotBlank(afterDecimal))
        amountInWords = amountInWords + ' and ' +afterDecimal + ' fils Only.' ;
    return amountInWords;
}*/

//ASF-975
public override void afterUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap){
    //Set<Id> oppIdList = new Set<Id>();
    //ASF-875
    Set<Id> resaleCompleteChargesOppIdSet = new Set<Id>();

    for(SalesOrderOtherCharges__c newRec : (list<SalesOrderOtherCharges__c>) newList){
        SalesOrderOtherCharges__c oldRec = (SalesOrderOtherCharges__c)oldmap.get(newRec.Id);

        /*if(newRec.InvoicedAmount__c != oldRec.InvoicedAmount__c && newRec.InvoicedAmount__c >= newRec.Amount__c && newRec.Opportunity__c != null){
            oppIdList.add(newRec.Opportunity__c);
        }*/

        //ASF-875 Harsh@Aldar
        if(newRec.ChargedFromResaleOpp__c && newRec.Opportunity__c != null && newRec.OutstandingAmount__c != oldRec.OutstandingAmount__c && newRec.OutstandingAmount__c == 0){
            resaleCompleteChargesOppIdSet.add(newRec.Opportunity__c);
        }
    }
    
    //ASF-875
    //Commented by Muzammil on 22/10/2024 as it is not requried now.
/*        if(resaleCompleteChargesOppIdSet.size() > 0){
        SalesOrderOtherChargesHelper.handleResaleOpp_PaymentCleared(resaleCompleteChargesOppIdSet);
    }*/
        SalesOrderOtherChargesHelper.customerPaymentStepClosure(newList,oldMap); 
}
}