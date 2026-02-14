public without sharing class DDTransactionResponseHandler { 
    
    public static String ADCB = 'Abu Dhabi Commercial Bank';
    public static String FAB = 'First Abu Dhabi Bank';
    public static String RegistrationAckNack = 'Registration AckNack';
    public static String RegistrationResponse = 'Registration Response';
    public static String CollectionResponse = 'Collection Response';
    public static String CollectionAckNack = 'Collection AckNack';
    public static String CancellationResponse   = 'Cancellation Response';
    public static String CancellationAckNack    = 'Cancellation AckNack';
    public static String RegistrationValidationResponse = 'Registration Validation';
    public static Boolean stopExecuteReceiptAckTrigger = false;
    
    public static void parseResponse(List<DDTransaction__c> ddTransactionList) {
        // List<DirectDebitRequest__c> sObjeList              = new List<DirectDebitRequest__c>();
        //List<sObject> sObjeList              = new List<sObject>();
        Map<Id, sObject> sObjeList = new Map<Id, sObject>();
        List<DDTransaction__c> ddTransactionsObjeList      = new List<DDTransaction__c>();
        List<SalesOrder__c> salesOrderObjList              = new List<SalesOrder__c>();
        List<String> ddtResponseString                     = new List<String>();
        List<String> ddtHeaders                            = new List<String>();
        List<String> responseValueString                   = new List<String>();
        Map<String, String> rejectionMap                   = prepareRejectionMap();
        Map<String, Map<String, Map<String, DD_Response_Mapping__mdt>>> finalddHeaderResponseMap = new  Map<String, Map<String, Map<String, DD_Response_Mapping__mdt>>>();
        Map<String, DD_Response_Mapping__mdt> ddresponseMtdMap = new Map<String, DD_Response_Mapping__mdt>();
        Map<String, Direct_Debit_Header__mdt> ddrHeaderMetadataMap = new Map<String, Direct_Debit_Header__mdt>();
        String finalddtResponseString                      = '';
        // String newLineCharacter                            = Label.newLineCharacter;
        
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType myobjectSchema;
        // = schemaMap.get('DirectDebitRequest__c');
        Map<String, Schema.SObjectField> fieldMap;
        // = myobjectSchema.getDescribe().fields.getMap();
        
        // try{
        List<Direct_Debit_Header__mdt> directDebitHeaderMetadat = [SELECT Id,
                                                                   Bank_Name__c,
                                                                   Column_Separator__c,
                                                                   Data_delimiter__c,
                                                                   (SELECT Id,
                                                                    API__c,
                                                                    List_Index__c,
                                                                    Response_Key__c,
                                                                    ResponseType__c
                                                                    FROM DD_Response_Mappings__r)
                                                                   FROM Direct_Debit_Header__mdt];
        
        
        List<DDTransaction__c> directDebitdTransactionList = [SELECT Id,
                                                              DDResponse__c,
                                                              DDBank__c,
                                                              DirectDebitRequest__r.Id,
                                                              DirectDebitRequest__r.SalesOrder__c,
                                                              DirectDebitRequest__r.SalesOrder__r.Status__c,
                                                              DDResponsefiletype__c,
                                                              Receipt_Acknowledgement__r.Id
                                                              FROM DDTransaction__c 
                                                              WHERE Id IN:ddTransactionList];
        system.debug('directDebitdTransactionList:::'+directDebitdTransactionList);
        
        system.debug('directDebitHeaderMetadat:::'+directDebitHeaderMetadat);
        
        if(!directDebitHeaderMetadat.isEmpty()){
            for(Direct_Debit_Header__mdt mdt: directDebitHeaderMetadat){
                Map<String, Map<String, DD_Response_Mapping__mdt>> respMap = new Map<String, Map<String, DD_Response_Mapping__mdt>>();  
                system.debug('mdt.DD_Response_Mappings__r'+mdt.DD_Response_Mappings__r);
                if(mdt.DD_Response_Mappings__r != null){
                    for(DD_Response_Mapping__mdt respmtd: mdt.DD_Response_Mappings__r){
                        
                        Map<String, DD_Response_Mapping__mdt> maps = respMap.get(respmtd.ResponseType__c) != null ? respMap.get(respmtd.ResponseType__c) : new Map<String, DD_Response_Mapping__mdt>();
                        maps.put(string.valueof( Integer.valueof(respmtd.List_Index__c )), respmtd);
                        respMap.put(respmtd.ResponseType__c, maps);
                        Map<String, Map<String, DD_Response_Mapping__mdt>> finalmaps = finalddHeaderResponseMap.get(mdt.Bank_Name__c) != null ? finalddHeaderResponseMap.get(mdt.Bank_Name__c) : new Map<String, Map<String, DD_Response_Mapping__mdt>>();
                        finalmaps.put(respmtd.ResponseType__c, maps);
                        finalddHeaderResponseMap.put(mdt.Bank_Name__c, finalmaps);
                    }
                    
                }
                
                system.debug('finalddHeaderResponseMap1::'+finalddHeaderResponseMap);
                ddrHeaderMetadataMap.put(mdt.Bank_Name__c, mdt);
            }
            system.debug('finalddHeaderResponseMap 2::'+finalddHeaderResponseMap);
        } 
        if(!directDebitdTransactionList.isEmpty()){
            for(DDTransaction__c ddTransaction: directDebitdTransactionList) {
                String dataDelimiter ;
                Integer iterationSize = 0;
                
                Map<String, DD_Response_Mapping__mdt> metadataMap;
                Map<String, Map<String, DD_Response_Mapping__mdt>> initialMetadataResponse = finalddHeaderResponseMap.get(ddTransaction.DDBank__c);
                system.debug('initialMetadataResponse::'+initialMetadataResponse);
                SalesOrder__c salesOrderObj = (SalesOrder__c)(ddTransaction.DirectDebitRequest__r.SalesOrder__c).getSObjectType().newSObject(ddTransaction.DirectDebitRequest__r.SalesOrder__c);
                ddtResponseString = ddTransaction.DDResponse__c.split('\n');
                if(ddTransaction.DDBank__c == ADCB){
                    if(ddTransaction.DDResponse__c.startsWith('NAKHR') || ddTransaction.DDResponse__c.startsWith('ACKHR') ){ finalddtResponseString = ddtResponseString[1];
                        
                    }else if(ddTransaction.DDResponse__c.startsWith('DACDR')){
                        finalddtResponseString = ddtResponseString[0];
                    }
                    system.debug('finalddtResponseString::'+finalddtResponseString);
                    //Created new field to store the Response type 
                    
                        dataDelimiter = ddrHeaderMetadataMap.get(ddTransaction.DDBank__c).Data_delimiter__c;
                    iterationSize = 0;
                    
                } else if(ddTransaction.DDBank__c == FAB){
                    finalddtResponseString = ddtResponseString[0];
                    
                    if(ddTransaction.DDResponse__c.startsWith('ACKNAK') || ddTransaction.DDResponse__c.startsWith('REGVAL')){ dataDelimiter = ddrHeaderMetadataMap.get(ddTransaction.DDBank__c).Data_delimiter__c;
                    }else if(ddTransaction.DDResponse__c.startsWith('DACDR')){dataDelimiter = ddrHeaderMetadataMap.get(ddTransaction.DDBank__c).Column_Separator__c;
                    }
                    iterationSize = 0;
                }
                system.debug('ddTransaction.DDResponsefiletype__c::'+ddTransaction.DDResponsefiletype__c); 
                metadataMap = initialMetadataResponse.get(ddTransaction.DDResponsefiletype__c);
                system.debug('metadataMap:::'+metadataMap);
                if(finalddtResponseString.contains(dataDelimiter+dataDelimiter)) {
                    finalddtResponseString = finalddtResponseString.replace(dataDelimiter+dataDelimiter, dataDelimiter+'Null'+dataDelimiter);
                }
                system.debug('ddtResponseString::'+ddtResponseString);
                system.debug('ddtResponseString::'+ddtResponseString.size());
                for(Integer i = iterationSize; i < ddtResponseString.size(); i++) {
                    sObject sObj;
                    if(ddTransaction.DDResponsefiletype__c.startsWith('Registration') || ddTransaction.DDResponsefiletype__c.startsWith('Cancellation')){
                        sObj = (DirectDebitRequest__c)(ddTransaction.DirectDebitRequest__r.Id).getSObjectType().newSObject(ddTransaction.DirectDebitRequest__r.Id);
                        myobjectSchema = schemaMap.get('DirectDebitRequest__c');
                        fieldMap = myobjectSchema.getDescribe().fields.getMap();
                    }else if(ddTransaction.DDResponsefiletype__c.startsWith('Collection')){
                        //Added by Saikumar as part of story FIN-76 to handle the null value for Receipt_Acknowledgement__r
                        if(ddTransaction.Receipt_Acknowledgement__r != null && ddTransaction.Receipt_Acknowledgement__r.Id != null) {
                            sObj = (ReceiptAcknowledgement__c)(ddTransaction.Receipt_Acknowledgement__r.Id).getSObjectType().newSObject(ddTransaction.Receipt_Acknowledgement__r.Id);
                            myobjectSchema = schemaMap.get('ReceiptAcknowledgement__c');
                            fieldMap = myobjectSchema.getDescribe().fields.getMap();
                        } else {
                            // Skip processing if Receipt_Acknowledgement__r is null
                            continue;
                        }
                    }
                    // DirectDebitRequest__c sObj = (DirectDebitRequest__c)(ddTransaction.DirectDebitRequest__r.Id).getSObjectType().newSObject(ddTransaction.DirectDebitRequest__r.Id);
                    DDTransaction__c ddTransactionsObj = (DDTransaction__c)(ddTransaction.Id).getSObjectType().newSObject(ddTransaction.Id);
                    
                    ddtResponseString[i] = ddtResponseString[i].trim();
                    if(ddtResponseString[i].contains(dataDelimiter+dataDelimiter)) {
                        ddtResponseString[i] = ddtResponseString[i].replace(dataDelimiter+dataDelimiter, dataDelimiter+'Null'+dataDelimiter);
                    }
                    system.debug('dataDelimiter::'+dataDelimiter);
                    if(dataDelimiter == '|' ) {  responseValueString = ddtResponseString[0].split('\\|'); 
                    } else if(dataDelimiter == ','){
                        responseValueString = finalddtResponseString.split(','); 
                    }
                    system.debug('responseValueString:::'+responseValueString);
                    if(metadataMap != null){
                        for(Integer k = 0; k < metadataMap.values().size() ; k++ ) {
                            system.debug('metadataMap.values()[k].API__c::'+metadataMap.values()[k].API__c);
                            if(metadataMap.values()[k].API__c != null && responseValueString.size() > Integer.valueOf(metadataMap.values()[k].List_Index__c)-1){
                                if(fieldMap.get(metadataMap.values()[k].API__c).getDescribe().getType()  == Schema.DisplayType.Date) {
                                    sObj.put(metadataMap.values()[k].API__c, Date.parse(responseValueString[Integer.valueOf(metadataMap.values()[k].List_Index__c)-1]));    
                                }
                                else if(fieldMap.get(metadataMap.values()[k].API__c).getDescribe().getType()  == Schema.DisplayType.Integer ){
                                    sObj.put(metadataMap.values()[k].API__c, Integer.valueOf(responseValueString[Integer.valueOf(metadataMap.values()[k].List_Index__c)-1])); 
                                }
                                else if(fieldMap.get(metadataMap.values()[k].API__c).getDescribe().getType()  == Schema.DisplayType.Double){
                                    sObj.put(metadataMap.values()[k].API__c, Decimal.valueOf(responseValueString[Integer.valueOf(metadataMap.values()[k].List_Index__c)-1])); 
                                }
                                else if(fieldMap.get(metadataMap.values()[k].API__c).getDescribe().getType()  == Schema.DisplayType.Boolean  ){
                                    sObj.put(metadataMap.values()[k].API__c, Boolean.valueOf(responseValueString[Integer.valueOf(metadataMap.values()[k].List_Index__c)-1])); 
                                }
                                else if(fieldMap.get(metadataMap.values()[k].API__c).getDescribe().getType()  == Schema.DisplayType.String || fieldMap.get(metadataMap.values()[k].API__c).getDescribe().getType()  == Schema.DisplayType.Picklist){
                                    if(metadataMap.values()[k].API__c =='Status__c' && responseValueString[0].startsWith('REGVAL') && metadataMap.values()[k].ResponseType__c == RegistrationValidationResponse && responseValueString[Integer.valueOf(metadataMap.values()[k].List_Index__c)-1] == 'Failed'){
                                        ddTransactionsObj.put('TransactionStatus__c', 'Rejected');  sObj.put('Status__c', 'Rejected by Bank'); 
                                    }else if(responseValueString[0].startsWith('REGVAL') && metadataMap.values()[k].ResponseType__c == RegistrationValidationResponse && ddTransactionsObj.TransactionStatus__c == 'Rejected'){
                                        String acceptOrReject = responseValueString[Integer.valueOf(metadataMap.values()[k].List_Index__c)-1];
                                        ddTransactionsObj.put('TransactionStatus__c', 'Rejected');  ddTransactionsObj.put('RejectionReason__c', acceptOrReject);
                                        
                                        sObj.put('Rejection_Reason__c', acceptOrReject); sObj.put('Status__c', 'Rejected by Bank');
                                    }
                                    
                                    if(responseValueString[0].startsWith('DACDR') && metadataMap.values()[k].ResponseType__c == RegistrationResponse){
                                        String acceptOrReject = responseValueString[Integer.valueOf(metadataMap.values()[k].List_Index__c)-1];
                                        String fieldApi = metadataMap.values()[k].API__c;
                                        String responseKey = metadataMap.values()[k].Response_Key__c;
                                         system.debug('acceptOrReject::'+acceptOrReject);
                                        system.debug('fieldApi::'+fieldApi);
                                        if(fieldApi == 'Status__c'){
                                            if( acceptOrReject == 'ACCP'){
                                                system.debug('acceptOrReject::'+acceptOrReject);
                                                ddTransactionsObj.put('TransactionStatus__c', 'Approved');
                                                ddTransactionsObj.put('AckNackResponse__c', '');
                                                sObj.put('Status__c', 'Approved by Bank');
                                                sObj.put('Approveddate__c', system.now());
                                                sObj.put('Rejection_Reason__c', '');
                                            } else if(acceptOrReject.startsWith('RR')){
                                                ddTransactionsObj.put('TransactionStatus__c', 'Rejected');
                                                ddTransactionsObj.put('RejectionReason__c', rejectionMap.get(acceptOrReject));  sObj.put('Rejection_Reason__c', rejectionMap.get(acceptOrReject));
                                                sObj.put('Status__c', 'Rejected by Bank'); sObj.put('RejectedDate__c', system.now());
                                            } 
                                        }
                                        
                                    } else if((responseValueString[0].startsWith('NAKHR') || responseValueString[0].startsWith('ACKHR') || responseValueString[0].startsWith('ACKTR')
                                               || responseValueString[0].startsWith('NAKDR') || responseValueString[0].startsWith('ACKNAK'))
                                              && metadataMap.values()[k].ResponseType__c == RegistrationAckNack){
                                                  
                                                  String acceptOrReject = responseValueString[Integer.valueOf(metadataMap.values()[k].List_Index__c)-1];
                                                  if(ddTransaction.DDBank__c == ADCB){  String status;
                                                      if( responseValueString[0].startsWith('NAKHR')  || responseValueString[0].startsWith('NAKDR')){
                                                          status = 'NAK';
                                                          acceptOrReject = responseValueString[Integer.valueOf(metadataMap.values()[k].List_Index__c)-1];
                                                          sObj.put('Status__c', 'Rejected by Bank');
                                                          sObj.put('RejectedDate__c', system.now());
                                                          sObj.put('Rejection_Reason__c', acceptOrReject);
                                                      }else if(responseValueString[0].startsWith('ACKHR') || responseValueString[0].startsWith('ACKTR') )  {
                                                          status = 'ACK';  sObj.put('Rejection_Reason__c', '');
                                                      }
                                                      ddTransactionsObj.put('TransactionStatus__c', status);
                                                  }else {
                                                      if(metadataMap.values()[k].API__c == 'Status__c' && responseValueString[0].startsWith('ACKNAK') ){
                                                          String status = responseValueString[Integer.valueOf(metadataMap.values()[k].List_Index__c)-1];
                                                          ddTransactionsObj.put('TransactionStatus__c', status);
                                                          if(status == 'NAK'){ sObj.put('Status__c','Rejected by Bank');
                                                              sObj.put('RejectedDate__c', system.now());
                                                              acceptOrReject = responseValueString[Integer.valueOf(metadataMap.values()[k].List_Index__c)-1];
                                                          }else if(status == 'ACK'){  sObj.put('Rejection_Reason__c', '');
                                                          }
                                                      }
                                                  }
                                                  if(ddTransactionsObj.TransactionStatus__c == 'NAK' || ddTransactionsObj.TransactionStatus__c == 'Rejected'){
                                                      ddTransactionsObj.put('AckNackResponse__c', acceptOrReject);
                                                  }else{ ddTransactionsObj.put('AckNackResponse__c', '');
                                                  }
                                              } else if((metadataMap.values()[k].ResponseType__c == CollectionAckNack || metadataMap.values()[k].ResponseType__c == CancellationAckNack) &&
                                                        (responseValueString[0].startsWith('NAKHR') || responseValueString[0].startsWith('ACKHR') 
                                                         || responseValueString[0].startsWith('ACKTR') || responseValueString[0].startsWith('NAKDR') 
                                                         || responseValueString[0].startsWith('ACKNAK')) ) {
                                                             
                                                             
                                                             if(responseValueString[0].startsWith('ACKHR') || responseValueString[0].startsWith('ACKTR')){  ddTransactionsObj.put('TransactionStatus__c', 'ACK');
                                                                 
                                                                 if(metadataMap.values()[k].ResponseType__c == CancellationAckNack){sObj.put('Status__c', 'Cancelled');
                                                                 }
                                                             }
                                                             else if( responseValueString[0].startsWith('NAKHR')  || responseValueString[0].startsWith('NAKDR')){
                                                                 ddTransactionsObj.put('TransactionStatus__c', 'NAK');
                                                                 if(metadataMap.values()[k].ResponseType__c == CollectionAckNack){  sObj.put('DDCollectionStatus__c', 'NAK');
                                                                 }
                                                                 if(metadataMap.values()[k].ResponseType__c == CancellationAckNack){  sObj.put('Status__c', 'Cancellation Rejected');
                                                                 }
                                                             }
                                                         }else if(metadataMap.values()[k].ResponseType__c == CollectionResponse && responseValueString[0].startsWith('DACDR')){
                                                             String acceptOrReject = responseValueString[Integer.valueOf(metadataMap.values()[k].List_Index__c)-1];
                                                             String fieldApi = metadataMap.values()[k].API__c;
                                                             system.debug('acceptOrReject::'+acceptOrReject);
                                                             if(fieldApi == 'DDCollectionStatus__c'){
                                                                 if( acceptOrReject == '0'){
                                                                     ddTransactionsObj.put('TransactionStatus__c', 'Approved');
                                                                     sObj.put('DDCollectionStatus__c', 'Approved'); sObj.put('DDCollectionRejectionReason__c', '');
                                                                     sObj.put('DDCollectionResponse__c', rejectionMap.get(acceptOrReject));
                                                                 } else if(acceptOrReject != '0'){
                                                                     ddTransactionsObj.put('TransactionStatus__c', 'Rejected');
                                                                     sObj.put('DDCollectionStatus__c', 'Rejected');sObj.put('DDCollectionRejectionReason__c',  rejectionMap.get(acceptOrReject));
                                                                     sObj.put('DDCollectionResponse__c','');
                                                                 } 
                                                             }
                                                         }else if(metadataMap.values()[k].ResponseType__c == CancellationResponse && responseValueString[0].startsWith('DACDR')){  ddTransactionsObj.put('TransactionStatus__c', 'Approved');
                                                             sObj.put('Status__c', 'Cancelled');
                                                         }
                                    if(responseValueString[0].startsWith('DACDR') && metadataMap.values()[k].API__c =='DDAreferencenumber__c' && ddTransactionsObj.TransactionStatus__c != 'Rejected'){
                                        sObj.put(metadataMap.values()[k].API__c, String.valueOf(responseValueString[Integer.valueOf(metadataMap.values()[k].List_Index__c)-1].replace('DACDR', ''))); 
                                        if(ddTransaction.DirectDebitRequest__r.SalesOrder__r.Status__c != 'Cancelled'){
                                            salesOrderObj.put('Directdebitauthorityreferencenumber__c',String.valueOf(responseValueString[Integer.valueOf(metadataMap.values()[k].List_Index__c)-1].replace('DACDR', '') ));
                                        }
                                    }else if(metadataMap.values()[k].API__c != 'Status__c' && responseValueString[Integer.valueOf(metadataMap.values()[k].List_Index__c)-1] != 'Null' && metadataMap.values()[k].ResponseType__c != CollectionAckNack &&
                                             metadataMap.values()[k].ResponseType__c != CollectionResponse){
                                        sObj.put(metadataMap.values()[k].API__c, String.valueOf(responseValueString[Integer.valueOf(metadataMap.values()[k].List_Index__c)-1])); 
                                        if(ddTransactionsObj.TransactionStatus__c == 'ACK' || ddTransactionsObj.TransactionStatus__c == 'Approved'){
                                            sObj.put('Rejection_Reason__c', '');
                                        }
                                    }
                                    system.debug('ddTransactionsObj.TransactionStatus__c::'+ddTransactionsObj.TransactionStatus__c);
                                    if(ddTransactionsObj.TransactionStatus__c == 'Rejected' && metadataMap.values()[k].ResponseType__c != CollectionAckNack &&
                                             metadataMap.values()[k].ResponseType__c != CollectionResponse){
                                        sObj.put('DDAreferencenumber__c', ''); salesOrderObj.Directdebitauthorityreferencenumber__c = '';
                                    }
                                }
                                if(ddTransaction.DirectDebitRequest__r.SalesOrder__r.Status__c == 'Cancelled'){ sObj.put('Status__c', 'Approved by bank but SO cancelled');
                                }
                            }
                        }
                    }
                    system.debug('salesOrderObj::'+salesOrderObj);
                    system.debug('ddTransactionsObj::'+ddTransactionsObj);
                    system.debug('sObj::'+sObj);
                    
                    if(!salesOrderObjList.contains(salesOrderObj)){
                        salesOrderObjList.add(salesOrderObj);
                    }
                    if(!ddTransactionsObjeList.contains(ddTransactionsObj)){
                        ddTransactionsObjeList.add(ddTransactionsObj);
                    }
                  //  system.debug('sObjeList.contains(sObj)::'+sObjeList.contains(sObj));
                    if( sObj != null){
                        sObjeList.put(sObj.Id, sObj);
                    }
                    
                    system.debug('sObjeList::'+sObjeList);
                    system.debug('ddTransactionsObjeList::'+ddTransactionsObjeList);
                    
                    system.debug('sObjeList size::'+sObjeList.size());
                    system.debug('ddTransactionsObjeList size::'+ddTransactionsObjeList.size());
                }  
            }
        }
        
        if(Trigger.isAfter){
            if(!sObjeList.isEmpty()){
                update sObjeList.values();
            }
            if(!ddTransactionsObjeList.isEmpty()){
                update ddTransactionsObjeList;
            }
            if(!salesOrderObjList.isEmpty()){
                update salesOrderObjList;
            }
        } 
        /*  } catch(exception e){
LoggerService.save(LoggerService.addApexLog(e,'DDTransactionResponseHandler','parseResponse',''));
} */
    }
    
    public static void updateDDRStatus(List<DDTransaction__c> allDDTransactionList){
        try{
            List<DDTransaction__c> directDebitdTransactionList = [SELECT Id,
                                                              Requesttype__c,
                                                              DirectDebitRequest__c,
                                                              DDRReference__c,
                                                              TransactionStatus__c,
                                                              Receipt_Acknowledgement__c,
                                                              DirectDebitRequest__r.Id,
                                                              DirectDebitRequest__r.SalesOrder__c,
                                                              DirectDebitRequest__r.SalesOrder__r.Status__c,
                                                              Is_EDDS__c,
                                                              RejectionReason__c
                                                              FROM DDTransaction__c 
                                                              WHERE Id IN:allDDTransactionList];
        List<DirectDebitRequest__c> directDebitRequestListToUpdate = new List<DirectDebitRequest__c>();
        List<SalesOrder__c> salesOrderListToUpdate = new List<SalesOrder__c>();
        Map<Id, DirectDebitRequest__c> directDebitRequestListToUpdateMap = new Map<Id, DirectDebitRequest__c>();
        List<ReceiptAcknowledgement__c> ReceiptAcknowledgementList = new List<ReceiptAcknowledgement__c> (); 
        for(DDTransaction__c ddTransaction: directDebitdTransactionList) {
            DirectDebitRequest__c directDebitRequest = new DirectDebitRequest__c();
            directDebitRequest.Id = ddTransaction.DirectDebitRequest__c;
            if(ddTransaction.Requesttype__c =='New Registration'){ 
                if( ddTransaction.TransactionStatus__c == System.Label.SenttoBank) {
                    directDebitRequest.Status__c = System.Label.SenttoBank; 
                   // directDebitRequest.SentTobankDate__c = System.now();
                }else if(ddTransaction.TransactionStatus__c == 'Approved' || ddTransaction.TransactionStatus__c == 'ACK'){
                    directDebitRequest.Status__c = System.Label.ApprovedbyBank; 
                    //directDebitRequest.Approveddate__c = System.now();  
                    if(ddTransaction.Is_EDDS__c == TRUE && ddTransaction.DDRReference__c!=null){//update DDARN on DD and SO if EDDS Approved - Anuroop Vipin
                        if(ddTransaction.DirectDebitRequest__r?.SalesOrder__c!=null){
                            SalesOrder__c salesOrder = new SalesOrder__c();
                            salesOrder.Id = ddTransaction.DirectDebitRequest__r.SalesOrder__c;
                            salesOrder.Directdebitauthorityreferencenumber__c = ddTransaction.DDRReference__c;
                            salesOrder.Payment_Type__c = 'Direct Debit';
                            salesOrderListToUpdate.add(salesOrder);
                        }

                        directDebitRequest.DDAreferencenumber__c = ddTransaction.DDRReference__c;
                    }
                    if(ddTransaction.TransactionStatus__c == 'ACK'){
                        directDebitRequest.AckNak__c = 'ACK';
                    }
                }else if(ddTransaction.TransactionStatus__c == 'Rejected' || ddTransaction.TransactionStatus__c == 'NAK'){ directDebitRequest.Status__c = System.Label.RejectedbyBank; 
                    directDebitRequest.Rejection_Reason__c = ddTransaction.RejectionReason__c;
                   // directDebitRequest.RejectedDate__c = System.now(); 
                    if(ddTransaction.TransactionStatus__c == 'NAK'){ directDebitRequest.AckNak__c = 'NAK';
                    }
                } 
            }
            if(ddTransaction.Requesttype__c =='Cancellation'){
                system.debug('ddTransaction.Requesttype__c::'+ddTransaction.Requesttype__c);   
                system.debug(' ddTransaction.TransactionStatus__c::'+ddTransaction.TransactionStatus__c);
                if( ddTransaction.TransactionStatus__c == System.Label.SenttoBank) {    directDebitRequest.Status__c = 'Cancellation Sent to Bank'; 
                }else if(ddTransaction.TransactionStatus__c == 'Approved' || ddTransaction.TransactionStatus__c == 'ACK'){
                    directDebitRequest.Status__c = 'Cancelled';
                    if(ddTransaction.Is_EDDS__c == TRUE && ddTransaction.DDRReference__c!=null){//clear DDARN from DD and SO if EDDS Cancelled - Anuroop Vipin
                        if(ddTransaction.DirectDebitRequest__r?.SalesOrder__c!=null){
                            SalesOrder__c salesOrder = new SalesOrder__c();
                            salesOrder.Id = ddTransaction.DirectDebitRequest__r.SalesOrder__c;
                            salesOrder.Directdebitauthorityreferencenumber__c = '';
                            salesOrderListToUpdate.add(salesOrder);
                        }

                        directDebitRequest.DDAreferencenumber__c = '';
                    }
                }else if(ddTransaction.TransactionStatus__c == 'Rejected' || ddTransaction.TransactionStatus__c == 'NAK'){  directDebitRequest.Status__c = 'Cancellation Rejected';
                }
            }
            system.debug('directDebitRequestListToUpdateMap::'+directDebitRequestListToUpdateMap);
            if(!directDebitRequestListToUpdate.contains(directDebitRequest)){
                system.debug('directDebitRequest::'+directDebitRequest);
                directDebitRequestListToUpdate.add(directDebitRequest);
                directDebitRequestListToUpdateMap.put(directDebitRequest.Id, directDebitRequest);
            }            
            if(ddTransaction.Receipt_Acknowledgement__c != null && ddTransaction.Requesttype__c == 'Collection'){
               ReceiptAcknowledgement__c ReceiptAcknowledgement = new ReceiptAcknowledgement__c(); 
                ReceiptAcknowledgement.Id = ddTransaction.Receipt_Acknowledgement__c;
                if(ddTransaction.TransactionStatus__c == System.Label.SenttoBank || ddTransaction.TransactionStatus__c == 'Approved' || ddTransaction.TransactionStatus__c == 'Rejected'){
                    ReceiptAcknowledgement.DDCollectionStatus__c = ddTransaction.TransactionStatus__c;
                }
                ReceiptAcknowledgementList.add(ReceiptAcknowledgement);
            }
        }
        system.debug('directDebitRequestListToUpdateMap::'+directDebitRequestListToUpdateMap);
        if(!directDebitRequestListToUpdateMap.values().isEmpty()){
            update directDebitRequestListToUpdateMap.values();
        }
        if(!ReceiptAcknowledgementList.isEmpty()){
            stopExecuteReceiptAckTrigger = true;
            update ReceiptAcknowledgementList;
        }
        if(!salesOrderListToUpdate.isEmpty()){
            update salesOrderListToUpdate;
        }
        }catch(Exception ex){}
    }
    
    public static Map<String, String> prepareRejectionMap(){
        Map<String, String> rejectionMap = new Map<String, String>();
        List<String> rejectionCodeReasonList = new List<String>();
        String rejectionCodes = Label.RejectionCodes;
        rejectionMap.put('RR01', 'Signature Incorrect');
        rejectionMap.put('RR02', 'Signature Missing / Additional Signature(s) Required');
        rejectionMap.put('RR04', 'Invalid Account');
        rejectionMap.put('RR05', 'Title Mismatch');
        rejectionMap.put('RR06', 'Payer Deceased');
        rejectionMap.put('RR07', 'Account Closed');
        rejectionMap.put('RR08', 'Card Cancelled');
        rejectionMap.put('RR09', 'Card Expired');
        rejectionMap.put('RR10', 'Card Blocked');
        rejectionMap.put('RR11', 'Invalid Card');
        rejectionMap.put('RR12', 'Dormant Account');
        rejectionMap.put('RR13', 'Account not denominated in AED');
        rejectionMap.put('RR14', 'Signatory(ies) not authorized for the Mandate Amount');
        rejectionMap.put('RR15', 'Account blocked by Judiciary');
        rejectionMap.put('RR16', 'Account blocked by Law Enforcement Agency');
        rejectionMap.put('RR17', 'Account blocked by Central Bank of the UAE');
        rejectionMap.put('RR18', 'DDA Not Accepted by Paying Bank - Contact Your Bank');
        rejectionMap.put('RR50', 'Invalid Consumer Number');
        rejectionMap.put('RR54', 'Rejected by Originator');
        rejectionMap.put('RR55', 'Unable to obtain Originator confirmation');
        rejectionMap.put('RR90', 'Compliance Issues');
        rejectionMap.put('RR91', 'Scanned DDA Unusable');
        rejectionMap.put('RR92', 'Details mismatch with Scanned DDA');
        rejectionMap.put('0','Accepted CLAIMED AMOUNT');
        rejectionMap.put('1','Accepted PARTIAL AMOUNT (ONLY FOR LOANS / FINANCES)');
        rejectionMap.put('A','Account Closed');
        rejectionMap.put('C','Compliance Issues');
        rejectionMap.put('D','Payer Deceased');
        rejectionMap.put('E','Card Blocked');
        rejectionMap.put('F','Card Expired');
        rejectionMap.put('G','Card Cancelled');
        rejectionMap.put('I','Insufficient Funds');
        rejectionMap.put('L','Card Limit Exceeded');
        rejectionMap.put('M','Claim dishonored at the request of the Sponsoring Bank / Originator');
        rejectionMap.put('N','Dormant Account');
        rejectionMap.put('O','DDA Cancelled');
        rejectionMap.put('P','Payment Not Honored by Paying Bank – Payer to Contact Bank');
        rejectionMap.put('R','DDR details inconsistent with DDA details');
        rejectionMap.put('S','Payment Stopped/Refused');
        rejectionMap.put('T','Technical Issues at Paying Bank – Auto No-Pay Response from UAEDDS');
        rejectionMap.put('U','Amount Not Yet Due');
        rejectionMap.put('V','Account Closed – Mandated by CBUAE / Law Enforcement / Judiciary');
        rejectionMap.put('W','Account Closed – Internal Compliance / Commercial Issues');
        rejectionMap.put('X','Account blocked by Judiciary');
        rejectionMap.put('Y','Account blocked by Law Enforcement Agency');
        rejectionMap.put('Z','Account blocked by Central Bank of the UAE');
        return rejectionMap;       
    }
}